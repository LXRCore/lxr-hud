# Changelog — lxr-hud

## 3.0.0 — 2026-09-17
* Rebuilt on the LXRCore v3 native API; the multi-framework layer is gone.
* HUD: compass tape with nearest place, clock and date, identity, money, six-meter body row, weapon and rounds, mount speed and horse cores.
* Needs move to the server: decay per tick with riding/running multipliers, starving damage, nerves that fall on their own; `GetNeed / SetNeed / AddNeed / AddStress / RemoveStress` exports.
* Consumables: every core catalog item with `effects` becomes usable (animation, prop, cancellable progress, charges for refillables); horse feed stays with lxr-horses.
* `/hud` settings panel persisted per client; `/togglehud`; LXR Night / Morning themes; EN + KA; offline tests.
