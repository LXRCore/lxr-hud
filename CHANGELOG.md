# Changelog — lxr-hud

## 3.1.2 — 2026-09-19
* The game's own cores and meters are hidden for real: `_UITUTORIAL_SET_RPG_ICON_VISIBILITY` per icon (health, stamina, dead eye, the horse's), re-asserted after a revive and every few seconds — `_SHOW_PLAYER_CORES` alone came back after a death, and two health readings (the game's core is a different stat from the bar) stood side by side. `Config.Layout.hideNativeCores`.

## 3.1.1 — 2026-09-19
* Consumables: the catalog's plain prop words (mug, canteen, bottle_beer …) map to game models that exist (`Config.Consumables.props`); unknown models are skipped instead of failing the animation.
* Fix: the loop died on the first tick (`NetworkIsPlayerTalking` is not a RedM native) — nothing updated, the compass froze. The talking flag comes from mumble now.
* The HUD stays down while any page has the mouse (inventory, creator, shops) and until the character stands in the world (core `isLoggedIn` flips on spawn).
* The game's own player and horse cores are switched off — the frame draws them.

## 3.0.0 — 2026-09-17
* Rebuilt on the LXRCore v3 native API; the multi-framework layer is gone.
* HUD: compass tape with nearest place, clock and date, identity, money, six-meter body row, weapon and rounds, mount speed and horse cores.
* Needs move to the server: decay per tick with riding/running multipliers, starving damage, nerves that fall on their own; `GetNeed / SetNeed / AddNeed / AddStress / RemoveStress` exports.
* Consumables: every core catalog item with `effects` becomes usable (animation, prop, cancellable progress, charges for refillables); horse feed stays with lxr-horses.
* `/hud` settings panel persisted per client; `/togglehud`; LXR Night / Morning themes; EN + KA; offline tests.
