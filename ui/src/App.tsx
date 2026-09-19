/* LXR-HUD — the frame | © 2026 iBoss21 / LXRCore
   Messages: init { locale, lang, layout, settings, brand, warnAt, help } · show · hide · update { data } · pulse { key } · settings { open, settings }
   The client diffs, so `update` carries only changed keys (false = gone). */
import { useEffect, useMemo, useRef, useState, type PointerEvent as RPointerEvent } from 'react';
import { onMessage, applyChrome, makeT, post, pad, type Msg } from './nui';

type Settings = {
  opacity: number; scale: number; compass: boolean; status: boolean; weapon: boolean; mount: boolean; clock: boolean; identity: boolean; money: boolean; help: boolean; voice: boolean;
  minimap: 'radar' | 'off'; style: 'bars' | 'rings'; preset: 'classic' | 'compact' | 'cinematic'; cinema: boolean; cinemaBar: number;
  showId: boolean; showBank: boolean; showBlood: boolean; showJob: boolean; positions: Record<string, { x: number; y: number }>;
  grid: number;   // snap step in px while editing (0 = free)
};
type Layout = { compass: boolean; clock: boolean; identity: boolean; money: boolean; status: string[]; weapon: boolean; mount: boolean; speedUnit: string };
type Snapshot = Record<string, any>;
type Help = { id: string; key: string };

const MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
const CARD: Record<number, string> = { 0: 'N', 45: 'NE', 90: 'E', 135: 'SE', 180: 'S', 225: 'SW', 270: 'W', 315: 'NW' };
const TICK = 12; // px per 5°
const ELEMENTS = ['brand', 'compass', 'right', 'status', 'bottomright', 'help'] as const;
type Element = typeof ELEMENTS[number] | `stat:${string}` | `item:${string}`;   // stat:<key> / item:<name> — every bar, ring, chip and panel can be dragged on its own
const fmt = (n: number) => { n = Number(n || 0); return n.toLocaleString('en-US', { minimumFractionDigits: Number.isInteger(n) ? 0 : 2, maximumFractionDigits: 2 }); };
const clamp = (v: number, a: number, b: number) => Math.max(a, Math.min(b, v));

/* the three starting layouts: where each block anchors (CSS class) — positions are offsets on top */
const PRESETS: Record<Settings['preset'], Record<Element, string>> = {
  classic:   { brand: 'tl', compass: 'tc', right: 'tr', status: 'bl', bottomright: 'br', help: 'bc' },
  compact:   { brand: 'tl', compass: 'tc', right: 'tr', status: 'bc', bottomright: 'br', help: 'bc2' },
  cinematic: { brand: 'none', compass: 'tc', right: 'tr', status: 'bl', bottomright: 'br', help: 'none' },
};

function Tape({ heading }: { heading: number }) {
  const ticks = useMemo(() => {
    const out: { key: string; cls: string; label?: string }[] = [];
    for (let turn = -1; turn <= 1; turn++) for (let deg = 0; deg < 360; deg += 5) {
      const major = deg % 45 === 0, minor = deg % 15 === 0 && !major;
      out.push({ key: turn + ':' + deg, cls: 'hud-tick' + (major ? ' hud-tick--major' : minor ? ' hud-tick--minor' : ''), label: major ? CARD[deg] : minor ? String(deg) : undefined });
    }
    return out;
  }, []);
  return (
    <div className="hud-compass__strip">
      <div className="hud-compass__tape" style={{ transform: `translateX(${-(360 + heading) * (TICK / 5)}px)` }}>
        {ticks.map((tk) => <div key={tk.key} className={tk.cls}>{tk.label && <span className="hud-tick__label">{tk.label}</span>}</div>)}
      </div>
      <div className="hud-compass__needle" />
    </div>
  );
}


/* status icons — simple strokes in the kit's bone, one per core */
const ICON: Record<string, string> = {
  health: 'M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z',
  stamina: 'M13 3L5 14h6l-1 7 8-11h-6l1-7z',
  hunger: 'M7 3v8a2 2 0 0 0 2 2v8M7 3v6M11 3v6M17 3c-2 0-3 2-3 5v3h3v10',
  thirst: 'M12 3s6 7 6 11a6 6 0 0 1-12 0c0-4 6-11 6-11z',
  cleanliness: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3zM19 16l.8 2.2L22 19l-2.2.8L19 22l-.8-2.2L16 19l2.2-.8L19 16z',
  stress: 'M3 12h3l2-6 3 12 3-9 2 5 2-2h3',
  drunk: 'M8 3h8l-1 7a3 3 0 0 1-6 0zM12 13v6M9 21h6',
  temp: 'M10 4a2 2 0 0 1 4 0v9.5a4 4 0 1 1-4 0zM12 8v9',
};
function Icon({ k }: { k: string }) { return <svg className="hud-ico" viewBox="0 0 24 24"><path d={ICON[k] || 'M12 4v16M4 12h16'} /></svg>; }

function Ring({ v, cls }: { v: number; cls: string }) {
  const r = 20, c = 2 * Math.PI * r;
  return (
    <svg className={'hud-ring ' + cls} viewBox="0 0 48 48"><circle className="hud-ring__track" cx="24" cy="24" r={r} /><circle className="hud-ring__fill" cx="24" cy="24" r={r} strokeDasharray={c} strokeDashoffset={c * (1 - clamp(v, 0, 100) / 100)} /></svg>
  );
}

export function App() {
  const [L, setL] = useState<Record<string, string>>({});
  const [layout, setLayout] = useState<Layout | null>(null);
  const [settings, setSettings] = useState<Settings | null>(null);
  const [draft, setDraft] = useState<Settings | null>(null);          // what the settings page edits
  const [warnAt, setWarnAt] = useState<Record<string, number>>({});
  const [help, setHelp] = useState<Help[]>([]);
  const [shown, setShown] = useState(false);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(false);
  const [pulse, setPulse] = useState<string | null>(null);
  const [S, setS] = useState<Snapshot>({});
  const [code, setCode] = useState('');
  const [confirmReset, setConfirmReset] = useState(false);
  const drag = useRef<{ el: Element; sx: number; sy: number; ox: number; oy: number } | null>(null);
  const lastEl = useRef<Element | null>(null);   // the piece last touched: arrow keys nudge it
  const t = (k: string) => L['ui.' + k] || k.replace(/_/g, ' ');

  useEffect(() => onMessage((m: Msg) => {
    applyChrome(m);
    if (m.action === 'init') { setL(m.locale || {}); setLayout(m.layout); setSettings(m.settings); setWarnAt(m.warnAt || {}); setHelp(m.help || []); setS({}); }
    else if (m.action === 'show') setShown(true);
    else if (m.action === 'hide') setShown(false);
    else if (m.action === 'update') setS((s) => ({ ...s, ...(m.data || {}) }));
    else if (m.action === 'heading') setS((s) => ({ ...s, heading: m.heading }));
    else if (m.action === 'pulse') { setPulse(m.key); setTimeout(() => setPulse(null), 600); }
    else if (m.action === 'settings') { setOpen(!!m.open); if (m.open) { setDraft({ ...(m.settings || settings) }); setConfirmReset(false); } }
  }), [settings]);
  useEffect(() => {
    const k = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { if (editing) finishEdit(true); else if (open) post('closeSettings'); return; }
      if (editing && e.key.startsWith('Arrow')) { e.preventDefault(); const step = e.shiftKey ? 10 : 1; nudge(e.key === 'ArrowLeft' ? -step : e.key === 'ArrowRight' ? step : 0, e.key === 'ArrowUp' ? -step : e.key === 'ArrowDown' ? step : 0); }
    };
    document.addEventListener('keydown', k); return () => document.removeEventListener('keydown', k);
  });
  useEffect(() => { document.body.classList.toggle('has-radar', !settings || settings.minimap !== 'off'); }, [settings]);

  const cur = editing && draft ? draft : settings;
  if (!layout || !cur) return null;
  const preset = PRESETS[cur.preset] || PRESETS.classic;
  const posStyle = (el: Element) => { const p = cur.positions?.[el]; return p ? { transform: `translate(${p.x}px, ${p.y}px)` } : undefined; };
  const anchor = (el: typeof ELEMENTS[number]) => 'hud-el hud-el--' + el + ' hud-a-' + preset[el] + (editing ? ' is-edit' : '');
  const stat = (key: string) => clamp(Number(S[key] ?? 100), 0, 100);
  const low = (key: string, v: number) => (warnAt[key] != null ? v <= warnAt[key] : key === 'health' && v <= 20);

  /* ── edit layout: drag blocks, save offsets ── */
  const onDown = (el: Element) => (e: RPointerEvent) => { if (!editing || !draft) return; const p = draft.positions?.[el] || { x: 0, y: 0 }; drag.current = { el, sx: e.clientX, sy: e.clientY, ox: p.x, oy: p.y }; lastEl.current = el; (e.target as HTMLElement).setPointerCapture?.(e.pointerId); };
  const snap = (v: number) => { const g = draft?.grid || 0; return g > 0 ? Math.round(v / g) * g : Math.round(v); };
  const onMove = (e: RPointerEvent) => { const d = drag.current; if (!d || !draft) return; setDraft({ ...draft, positions: { ...draft.positions, [d.el]: { x: snap(d.ox + e.clientX - d.sx), y: snap(d.oy + e.clientY - d.sy) } } }); };
  const nudge = (dx: number, dy: number) => { const d = drag.current; if (!draft || !lastEl.current) return; const el = lastEl.current; const p = draft.positions?.[el] || { x: 0, y: 0 }; setDraft({ ...draft, positions: { ...draft.positions, [el]: { x: p.x + dx, y: p.y + dy } } }); void d; };
  const onUp = () => { drag.current = null; };
  const part = (el: Element) => ({ onPointerDown: (e: RPointerEvent) => { if (!editing) return; e.stopPropagation(); onDown(el)(e); }, style: posStyle(el), className: editing ? ' is-edit-item' : '' });
  const statDrag = (key: string) => part(('stat:' + key) as Element);
  const startEdit = () => { setEditing(true); setOpen(false); post('edit', { on: true }); };
  const finishEdit = (save: boolean) => { setEditing(false); post('edit', { on: false }); if (save && draft) { setSettings(draft); post('settings', { settings: draft }); } post('closeSettings'); };

  /* ── settings page helpers ── */
  const set = (k: keyof Settings, v: any) => setDraft((d) => (d ? { ...d, [k]: v } : d));
  const save = () => { if (!draft) return; setSettings(draft); post('settings', { settings: draft }); post('closeSettings'); };
  const exportCode = () => { if (!draft) return; setCode(btoa(unescape(encodeURIComponent(JSON.stringify(draft))))); };
  const importCode = () => { try { const d = JSON.parse(decodeURIComponent(escape(atob(code.trim())))); if (d && typeof d === 'object') setDraft({ ...draft!, ...d }); } catch { /* not a frame code */ } };
  const resetAll = () => { if (!draft) return; setDraft({ ...draft, positions: {}, preset: 'classic', style: 'bars', scale: 1, opacity: 1, cinema: false }); setConfirmReset(false); };

  const w = S.weapon, m = S.mount, clock = S.clock;
  const money = layout.money && cur.money;

  return (
    <>
      {cur.cinema && <><div className="hud-cinema hud-cinema--top" style={{ height: cur.cinemaBar }} /><div className="hud-cinema hud-cinema--bottom" style={{ height: cur.cinemaBar }} /></>}

      <div className={'hud' + (shown || editing ? '' : ' lxr-hidden') + (editing ? ' is-editing' : '')} style={{ opacity: cur.opacity, ['--hud-scale' as any]: cur.scale }} onPointerMove={onMove} onPointerUp={onUp}>
        {/* brand */}
        {preset.brand !== 'none' && (
          <div className={anchor('brand')} style={posStyle('brand')} onPointerDown={onDown('brand')}>
            <div className="hud-brand"><img src="img/lxrcore-logo.png" alt="" /><span className="lxr-mono">{S.brandName || ''}</span>{cur.voice && <span className={'hud-voice' + (S.talking ? ' is-on' : '')} title={t('voice')}><i /></span>}</div>
          </div>
        )}

        {/* compass */}
        {layout.compass && cur.compass && (
          <div className={anchor('compass')} style={posStyle('compass')} onPointerDown={onDown('compass')}>
            <div className="hud-compass"><Tape heading={Number(S.heading || 0)} /><div className="hud-compass__place"><span className="lxr-mono">{String(Math.round(S.heading || 0)).padStart(3, '0')}</span><span className="hud-compass__name">{S.place || ''}</span></div></div>
          </div>
        )}

        {/* clock · identity · money */}
        <div className={anchor('right')} style={posStyle('right')} onPointerDown={onDown('right')}>
          <div className="hud-right">
            {layout.clock && cur.clock && clock && <div className={'hud-chips' + part('item:clock').className} style={part('item:clock').style} onPointerDown={part('item:clock').onPointerDown}><span className="hud-chip lxr-mono">{t('month_' + MONTHS[((clock.month || 1) - 1) % 12])} {clock.day}, {clock.year}</span><span className="hud-chip lxr-mono">{pad(clock.hour)}:{pad(clock.minute)}</span>{S.temp && <span className={'hud-chip lxr-mono hud-chip--temp' + (S.temp.feel !== 'fine' ? ' is-' + S.temp.feel : '') + (pulse === 'temp' ? ' pulse' : '')} title={t('feel_' + S.temp.feel)}><Icon k="temp" />{S.temp.unit === 'f' ? Math.round(S.temp.felt * 9 / 5 + 32) + '°F' : S.temp.felt + '°C'}</span>}</div>}
            {layout.identity && cur.identity && (
              <div className={'hud-id' + part('item:identity').className} style={part('item:identity').style} onPointerDown={part('item:identity').onPointerDown}>
                {cur.showId && S.id != null && <span className="hud-chip lxr-mono hud-chip--id">#{S.id}</span>}
                <span className="hud-id__name">{S.name || ''}</span>
                {cur.showJob && S.job && <span className="hud-chip hud-chip--job lxr-mono">{[S.job.label, S.job.grade].filter(Boolean).join(' · ')}</span>}
              </div>
            )}
            {money && (
              <div className={'hud-money' + part('item:money').className} style={part('item:money').style} onPointerDown={part('item:money').onPointerDown}>
                <span className="hud-money__cash lxr-num">${fmt(S.cash)}</span>
                {cur.showBank && <span className="hud-money__bank lxr-mono">{t('bank')} ${fmt(S.bank)}</span>}
                {cur.showBlood && Number(S.blood) > 0 && <span className="hud-money__blood lxr-mono">{t('blood')} ${fmt(S.blood)}</span>}
              </div>
            )}
          </div>
        </div>

        {/* status */}
        {cur.status && (
          <div className={anchor('status')} style={posStyle('status')} onPointerDown={onDown('status')}>
            <div className={'hud-status hud-status--' + cur.style}>
              {layout.status.map((key) => {
                const v = stat(key); const isLow = low(key, v);
                return cur.style === 'rings' ? (
                  <div key={key} className={'hud-ringstat' + (isLow ? ' is-low' : '') + (pulse === key ? ' pulse' : '') + statDrag(key).className} style={statDrag(key).style} onPointerDown={statDrag(key).onPointerDown} title={t(key)}><Ring v={v} cls={'hud-ring--' + key} /><span className="hud-ringstat__ico"><Icon k={key} /></span><span className="hud-ringstat__val lxr-mono">{Math.round(v)}</span><span className="hud-ringstat__label lxr-mono">{t(key)}</span></div>
                ) : (
                  <div key={key} className={'hud-stat hud-stat--' + key + (isLow ? ' is-low' : '') + (pulse === key ? ' pulse' : '') + statDrag(key).className} style={statDrag(key).style} onPointerDown={statDrag(key).onPointerDown}>
                    <div className="hud-stat__top"><Icon k={key} /><span className="lxr-mono hud-stat__label">{t(key)}</span><span className="hud-stat__val">{Math.round(v)}</span></div>
                    <div className="lxr-meter"><div className="lxr-meter-fill" style={{ width: v + '%' }} /></div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* weapon + mount */}
        <div className={anchor('bottomright')} style={posStyle('bottomright')} onPointerDown={onDown('bottomright')}>
          <div className="hud-right-b">
            {m && layout.mount && cur.mount && (
              <div className={'hud-mount' + part('item:mount').className} style={part('item:mount').style} onPointerDown={part('item:mount').onPointerDown}>
                <div className="hud-mount__speed"><span className="lxr-num">{m.speed}</span><span className="lxr-mono">{t('unit_' + (m.unit || 'mph'))}</span></div>
                {m.kind === 'horse' && <div className="hud-mount__cores"><div className="hud-core"><span className="lxr-mono">{t('horse_health')}</span><div className="lxr-meter"><div className="lxr-meter-fill" style={{ width: (m.health || 0) + '%' }} /></div></div><div className="hud-core"><span className="lxr-mono">{t('horse_stamina')}</span><div className="lxr-meter"><div className="lxr-meter-fill" style={{ width: (m.stamina || 0) + '%' }} /></div></div></div>}
              </div>
            )}
            {w && layout.weapon && cur.weapon && <div className={'hud-weapon' + part('item:weapon').className} style={part('item:weapon').style} onPointerDown={part('item:weapon').onPointerDown}><span className="hud-weapon__name">{w.label}</span><span className="hud-weapon__ammo lxr-num">{w.ammo ?? ''}</span></div>}
          </div>
        </div>

        {/* a frame where the game draws its radar (bottom-left) — a lumi-style border, ours */}
        {cur.minimap !== 'off' && preset.brand !== 'none' && <div className={'hud-el hud-el--radar hud-a-radar' + (editing ? ' is-edit' : '')} style={posStyle('item:radar' as Element)} onPointerDown={onDown('item:radar' as Element)}><div className="hud-radarframe" /></div>}

        {/* key hints */}
        {cur.help && preset.help !== 'none' && help.length > 0 && (
          <div className={anchor('help')} style={posStyle('help')} onPointerDown={onDown('help')}>
            <div className="hud-help">{help.map((h) => <span key={h.id} className={'hud-help__k' + part(('item:help:' + h.id) as Element).className} style={part(('item:help:' + h.id) as Element).style} onPointerDown={part(('item:help:' + h.id) as Element).onPointerDown}><span className="lxr-key">{h.key}</span><span className="lxr-mono">{t('help_' + h.id)}</span></span>)}</div>
          </div>
        )}

        {editing && draft && draft.grid > 0 && <div className="hud-grid" style={{ backgroundSize: `${draft.grid}px ${draft.grid}px` }} />}
        {editing && (
          <div className="hud-editbar lxr-hit">
            <span className="lxr-mono lxr-t-ash">{t('edit_hint')}</span><span className="lxr-grow" />
            <span className="lxr-mono lxr-t-smoke">{t('grid')}</span>
            <div className="hud-seg">{[0, 8, 16, 32].map((g) => <button key={g} className="lxr-chip" aria-pressed={(draft?.grid || 0) === g} onClick={() => set('grid', g)}>{g === 0 ? t('grid_off') : g}</button>)}</div>
            {lastEl.current && draft?.positions?.[lastEl.current] && <span className="lxr-mono lxr-t-smoke hud-editbar__pos">{lastEl.current.replace(/^(stat|item):/, '')} {draft.positions[lastEl.current].x} · {draft.positions[lastEl.current].y}</span>}
            <button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => setDraft((d) => (d ? { ...d, positions: {} } : d))}>{t('reset_positions')}</button>
            <button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => finishEdit(false)}>{t('cancel')}</button>
            <button className="lxr-btn lxr-btn-sm" onClick={() => finishEdit(true)}>{t('save')}</button>
          </div>
        )}
      </div>

      {/* settings page */}
      {open && draft && !editing && (
        <div className="hud-settings">
          <div className="hud-settings__box lxr-hit">
            <div className="hud-settings__head"><div><span className="lxr-mono lxr-t-ash">{t('settings_eyebrow')}</span><h2 className="lxr-cut">{t('settings_title')}</h2></div><button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => post('closeSettings')}>{t('close')}</button></div>
            <div className="hud-settings__cols">
              <div className="hud-settings__col">
                <div className="hud-set__group lxr-mono lxr-t-ash">{t('group_frame')}</div>
                <div className="hud-set"><span>{t('preset')}</span><div className="hud-seg">{(['classic', 'compact', 'cinematic'] as const).map((p) => <button key={p} className="lxr-chip" aria-pressed={draft.preset === p} onClick={() => set('preset', p)}>{t('preset_' + p)}</button>)}</div></div>
                <div className="hud-set"><span>{t('style')}</span><div className="hud-seg">{(['bars', 'rings'] as const).map((p) => <button key={p} className="lxr-chip" aria-pressed={draft.style === p} onClick={() => set('style', p)}>{t('style_' + p)}</button>)}</div></div>
                <label className="hud-set"><span>{t('opacity')} · {Math.round(draft.opacity * 100)}%</span><input type="range" min={0.3} max={1} step={0.05} value={draft.opacity} onChange={(e) => set('opacity', Number(e.target.value))} /></label>
                <label className="hud-set"><span>{t('scale')} · {Math.round(draft.scale * 100)}%</span><input type="range" min={0.7} max={1.4} step={0.05} value={draft.scale} onChange={(e) => set('scale', Number(e.target.value))} /></label>
                <div className="hud-set"><span>{t('minimap')}</span><div className="hud-seg"><button className="lxr-chip" aria-pressed={draft.minimap === 'radar'} onClick={() => set('minimap', 'radar')}>{t('minimap_radar')}</button><button className="lxr-chip" aria-pressed={draft.minimap === 'off'} onClick={() => set('minimap', 'off')}>{t('minimap_off')}</button></div></div>
                <label className="hud-set hud-set--row"><span>{t('cinema')}</span><input type="checkbox" checked={draft.cinema} onChange={(e) => set('cinema', e.target.checked)} /></label>
                {draft.cinema && <label className="hud-set"><span>{t('cinema_bar')} · {draft.cinemaBar}px</span><input type="range" min={40} max={200} step={10} value={draft.cinemaBar} onChange={(e) => set('cinemaBar', Number(e.target.value))} /></label>}
                <button className="lxr-btn" onClick={startEdit}>{t('edit_layout')}</button>
              </div>
              <div className="hud-settings__col">
                <div className="hud-set__group lxr-mono lxr-t-ash">{t('group_show')}</div>
                {(['compass', 'clock', 'identity', 'money', 'status', 'weapon', 'mount', 'help', 'voice', 'showId', 'showJob', 'showBank', 'showBlood'] as const).map((k) => (
                  <label key={k} className="hud-set hud-set--row"><span>{t('show_' + k)}</span><input type="checkbox" checked={draft[k] !== false} onChange={(e) => set(k, e.target.checked)} /></label>
                ))}
              </div>
            </div>
            <div className="hud-set__group lxr-mono lxr-t-ash">{t('group_code')}</div>
            <div className="hud-code"><input className="lxr-input" value={code} placeholder={t('code_hint')} onChange={(e) => setCode(e.target.value)} /><button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={exportCode}>{t('code_export')}</button><button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={importCode}>{t('code_import')}</button></div>
            <div className="hud-settings__foot">
              {confirmReset ? <><span className="lxr-mono lxr-t-ash">{t('reset_confirm')}</span><button className="lxr-btn lxr-btn-bad lxr-btn-sm" onClick={resetAll}>{t('reset')}</button><button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => setConfirmReset(false)}>{t('cancel')}</button></> : <button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => setConfirmReset(true)}>{t('reset')}</button>}
              <span className="lxr-grow" />
              <button className="lxr-btn" onClick={save}>{t('save')}</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
