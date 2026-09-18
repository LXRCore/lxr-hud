/* LXR-HUD — page logic | © 2026 iBoss21 / LXRCore
   Messages: init { locale, lang, layout, settings, brand, warnAt } · show · hide · update { data } · pulse { key } · settings { open, settings }
   The client diffs, so `update` carries only changed keys (false = gone). */
(function () {
  const $ = (id) => document.getElementById(id);
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-hud';
  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).catch(() => {});
  let L = {}, layout = null, settings = {}, warnAt = {}, S = {};
  const t = (k) => L['ui.' + k] || k.replace(/_/g, ' ');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const pad = (n) => String(n).padStart(2, '0');
  const money = (n) => { n = Number(n || 0); return n.toLocaleString('en-US', { minimumFractionDigits: Number.isInteger(n) ? 0 : 2, maximumFractionDigits: 2 }); };
  const MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
  const CARD = { 0: 'N', 45: 'NE', 90: 'E', 135: 'SE', 180: 'S', 225: 'SW', 270: 'W', 315: 'NW' };

  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { el.textContent = t(el.dataset.l); }); }

  // ─── compass tape: 3 turns of ticks so the strip can scroll without seams ───
  function buildTape() {
    const tape = $('tape'); tape.innerHTML = '';
    for (let turn = -1; turn <= 1; turn++) for (let deg = 0; deg < 360; deg += 5) {
      const el = document.createElement('div');
      const major = deg % 45 === 0, minor = deg % 15 === 0 && !major;
      el.className = 'hud-tick' + (major ? ' hud-tick--major' : minor ? ' hud-tick--minor' : '');
      if (major) el.innerHTML = `<span class="hud-tick__label">${CARD[deg]}</span>`;
      else if (minor) el.innerHTML = `<span class="hud-tick__label">${deg}</span>`;
      tape.appendChild(el);
    }
  }
  const TICK = 12; // px per 5°
  function setHeading(deg) { $('tape').style.transform = `translateX(${-(360 + deg) * (TICK / 5)}px)`; $('heading').textContent = String(Math.round(deg)).padStart(3, '0'); }

  // ─── status row ───
  function buildStatus() {
    const host = $('status'); host.innerHTML = '';
    for (const key of layout.status) {
      const el = document.createElement('div');
      el.className = 'hud-stat hud-stat--' + key; el.id = 'st-' + key;
      el.innerHTML = `<div class="hud-stat__top"><span class="lxr-mono hud-stat__label">${esc(t(key))}</span><span class="hud-stat__val">100</span></div><div class="lxr-meter"><div class="lxr-meter-fill"></div></div>`;
      host.appendChild(el);
    }
  }
  function setStat(key, v) {
    const el = $('st-' + key); if (!el) return;
    v = Math.max(0, Math.min(100, Number(v) || 0));
    el.querySelector('.hud-stat__val').textContent = Math.round(v);
    el.querySelector('.lxr-meter-fill').style.width = v + '%';
    const low = warnAt[key] != null ? v <= warnAt[key] : (key === 'health' && v <= 20);
    el.classList.toggle('is-low', low);
  }

  // ─── settings ───
  function applySettings() {
    document.documentElement.style.setProperty('--hud-opacity', settings.opacity == null ? 1 : settings.opacity);
    $('compass').classList.toggle('lxr-hidden', !(layout && layout.compass) || settings.compass === false);
    $('status').classList.toggle('lxr-hidden', settings.status === false);
    $('identity').classList.toggle('lxr-hidden', !(layout && layout.identity));
    $('money').classList.toggle('lxr-hidden', !(layout && layout.money));
    $('clock-row').classList.toggle('lxr-hidden', !(layout && layout.clock));
  }
  function renderSettingsForm() {
    document.querySelectorAll('#settings [data-s]').forEach(inp => { if (inp.type === 'checkbox') inp.checked = settings[inp.dataset.s] !== false; else inp.value = settings[inp.dataset.s]; });
    document.querySelectorAll('#settings [data-mm]').forEach(b => b.setAttribute('aria-pressed', settings.minimap === b.dataset.mm ? 'true' : 'false'));
  }
  document.querySelectorAll('#settings [data-mm]').forEach(b => b.addEventListener('click', () => { settings.minimap = b.dataset.mm; renderSettingsForm(); }));
  $('s-save').addEventListener('click', () => {
    document.querySelectorAll('#settings [data-s]').forEach(inp => { settings[inp.dataset.s] = inp.type === 'checkbox' ? inp.checked : Number(inp.value); });
    post('settings', { settings }); post('closeSettings');
  });
  $('s-close').addEventListener('click', () => post('closeSettings'));
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && !$('settings').classList.contains('lxr-hidden')) post('closeSettings'); });

  // ─── updates ───
  function update(d) {
    Object.assign(S, d);
    if (d.heading != null) setHeading(d.heading);
    if (d.place !== undefined) $('place').textContent = d.place || '';
    if (d.clock) { $('time').textContent = `${pad(d.clock.hour)}:${pad(d.clock.minute)}`; $('date').textContent = `${t('month_' + MONTHS[(d.clock.month - 1) % 12])} ${d.clock.day}, ${d.clock.year}`; }
    if (d.name != null) $('name').textContent = d.name;
    if (d.job) $('job').textContent = [d.job.label, d.job.grade].filter(Boolean).join(' · ');
    if (d.cash != null) $('cash').textContent = money(d.cash);
    if (d.bank != null) $('bank').textContent = money(d.bank);
    for (const k of ['health', 'stamina', 'hunger', 'thirst', 'cleanliness', 'stress']) if (d[k] != null) setStat(k, d[k]);
    if (d.weapon !== undefined) {
      const w = d.weapon;
      $('weapon').classList.toggle('lxr-hidden', !w || settings.weapon === false || !(layout && layout.weapon));
      if (w) { $('w-name').textContent = w.label; $('w-ammo').textContent = w.ammo != null ? w.ammo : ''; }
    }
    if (d.mount !== undefined) {
      const m = d.mount;
      $('mount').classList.toggle('lxr-hidden', !m || settings.mount === false || !(layout && layout.mount));
      if (m) {
        $('speed').textContent = m.speed; $('unit').textContent = t('unit_' + (m.unit || 'mph'));
        $('mount-cores').classList.toggle('lxr-hidden', m.kind !== 'horse');
        if (m.kind === 'horse') { $('m-health').style.width = (m.health || 0) + '%'; $('m-stamina').style.width = (m.stamina || 0) + '%'; }
      }
    }
  }

  window.addEventListener('message', (e) => {
    const m = e.data || {};
    const th = m.theme || (m.brand && m.brand.theme); if (th) document.documentElement.dataset.theme = th;
    if (m.action === 'init') { L = m.locale || {}; layout = m.layout; settings = m.settings || {}; warnAt = m.warnAt || {}; document.body.classList.toggle('lang-ka', m.lang === 'ka'); $('brand-name').textContent = (m.brand && m.brand.name) || ''; applyLocale(); buildTape(); buildStatus(); applySettings(); S = {}; }
    else if (m.action === 'show') $('hud').classList.remove('lxr-hidden');
    else if (m.action === 'hide') $('hud').classList.add('lxr-hidden');
    else if (m.action === 'update') update(m.data || {});
    else if (m.action === 'pulse') { const el = $('st-' + m.key); if (el) { el.classList.remove('pulse'); void el.offsetWidth; el.classList.add('pulse'); } }
    else if (m.action === 'settings') { $('settings').classList.toggle('lxr-hidden', !m.open); if (m.open) { settings = m.settings || settings; renderSettingsForm(); } }
  });
  if (window.__LXR_MOCK__) { for (const msg of window.__LXR_MOCK__) window.postMessage(msg, '*'); }
})();
