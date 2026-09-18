--[[
    ██╗     ██╗  ██╗██████╗       ██╗  ██╗██╗   ██╗██████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██║  ██║██║   ██║██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗███████║██║   ██║██║  ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██║██║   ██║██║  ██║
    ███████╗██╔╝ ██╗██║  ██║      ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    LXR Core - HUD & Needs

    The frame around the world: compass and place, date and hour, name and
    trade, cash and bank, the body (health, stamina, hunger, thirst,
    cleanliness, stress), the gun in hand and the horse under you. It also owns
    the needs: they decay on the server, food and drink from the core catalog
    restore them, and every value lives in the core's replicated state bags.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/ZHMKVYyhBa (development)
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.02 ms (one 250 ms loop while the HUD is shown; nothing when hidden)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LAYOUT (what is on screen) ════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Layout = {
    compass    = true,   -- heading strip top-centre with the nearest place under it
    clock      = true,   -- hour and date (the game clock, in the server year)
    identity   = true,   -- name and trade top-right
    money      = true,   -- cash, bank and blood money under the name
    status     = { 'health', 'stamina', 'hunger', 'thirst', 'cleanliness', 'stress' }, -- bottom-left row, in this order
    weapon     = true,   -- gun in hand + rounds bottom-right
    mount      = true,   -- horse / wagon panel when mounted: speed, horse health and stamina
    hideWhilePaused = true,
    refreshMs  = 250,    -- the client loop; values are only sent to the page when they change
    speedUnit  = 'mph',  -- 'mph' | 'kmh'
    year       = 1899,   -- shown with the game date (match lxr-core Config.Server.year)
}

-- player-side settings (persisted per client with KVP; the /hud command opens the panel)
Config.Settings = {
    command   = 'hud',
    -- every key here can be changed by the player in /hud and is saved per client (KVP)
    defaults  = {
        opacity = 1.0, scale = 1.0,
        compass = true, status = true, weapon = true, mount = true, clock = true, identity = true, money = true, help = true, voice = true,
        minimap = 'radar',           -- 'radar' | 'off'
        style = 'bars',              -- status row: 'bars' | 'rings'
        preset = 'classic',          -- 'classic' | 'compact' | 'cinematic' — a starting layout; positions below override it
        cinema = false, cinemaBar = 90,   -- letterbox bars, px
        showId = true, showBank = true, showBlood = true, showJob = true,
        positions = {},              -- element → { x, y } offsets from the preset, set in Edit layout
    },
}

-- key hints along the bottom (the player can hide them); labels come from the locale (ui.help_<id>)
Config.Help = {
    { id = 'satchel', key = 'I' },
    { id = 'census',  key = 'F9' },
    { id = 'hud',     key = '/hud' },
    { id = 'map',     key = 'M' },
}

-- Places for the compass strip: nearest one within `radius` is shown
Config.Places = {
    { label = 'Valentine',    coords = vector3(-300.0, 800.0, 118.0),   radius = 260.0 },
    { label = 'Saint Denis',  coords = vector3(2600.0, -1250.0, 50.0),  radius = 520.0 },
    { label = 'Blackwater',   coords = vector3(-800.0, -1300.0, 43.0),  radius = 300.0 },
    { label = 'Rhodes',       coords = vector3(1330.0, -1300.0, 77.0),  radius = 260.0 },
    { label = 'Strawberry',   coords = vector3(-1790.0, -390.0, 160.0), radius = 220.0 },
    { label = 'Annesburg',    coords = vector3(2930.0, 1360.0, 60.0),   radius = 260.0 },
    { label = 'Van Horn',     coords = vector3(2970.0, 560.0, 45.0),    radius = 220.0 },
    { label = 'Emerald Ranch',coords = vector3(1420.0, 300.0, 88.0),    radius = 240.0 },
    { label = 'Armadillo',    coords = vector3(-3670.0, -2620.0, -13.0), radius = 260.0 },
    { label = 'Tumbleweed',   coords = vector3(-5510.0, -2960.0, -1.0), radius = 260.0 },
    { label = 'Lagras',       coords = vector3(2060.0, -600.0, 42.0),   radius = 200.0 },
    { label = 'Colter',       coords = vector3(-1350.0, 2420.0, 308.0), radius = 240.0 },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ NEEDS (server-owned) ══════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Needs = {
    tickMs      = 60000,              -- one tick a minute
    decay       = { hunger = 0.45, thirst = 0.65, cleanliness = 0.12, stress = -0.35 }, -- per tick (stress falls on its own)
    riding      = { hunger = 1.2, thirst = 1.5 },   -- multipliers while on a horse or running (client reports activity)
    floors      = { hunger = 0, thirst = 0, cleanliness = 0, stress = 0 },
    ceilings    = { hunger = 100, thirst = 100, cleanliness = 100, stress = 100 },
    starve      = { damage = 4, everyMs = 30000 },  -- health lost while hunger or thirst sits at 0
    warnAt      = { hunger = 20, thirst = 20 },     -- the HUD blinks the icon under this
    dirtyAt     = 25,                                -- cleanliness under this: shopkeepers may refuse, dogs bark (other resources read it)
}

-- Every core catalog item with `effects` becomes usable here (eat / drink / smoke / heal …).
Config.Consumables = {
    register   = true,
    defaultMs  = 2500,                -- when the item has no `use.time`
    skipPrefix = { 'horse_' },        -- effects that belong to another resource (horse feed is lxr-horses')
    anims = {                          -- by the catalog's `use.anim` key
        eat   = { dict = 'mech_inventory@eating@multi_bite@sphere_d8-2_sandwich', anim = 'quick_left_hand', prop = 'p_bread01x' },
        drink = { dict = 'mech_inventory@drinking@canteen', anim = 'drink_left_hand', prop = 'p_canteen01x' },
        drink_bottle = { dict = 'mech_inventory@item@_templates@bottle@lid_small_l@unarmed@cork', anim = 'quick_left_hand', prop = 'p_bottlebeer01x' },
        smoke = { dict = 'mech_inventory@smoking@cigar', anim = 'base', prop = 'p_cigar01x' },
        heal  = { dict = 'mech_inventory@item@_templates@bottle@lid_small_l@unarmed@cork', anim = 'quick_left_hand', prop = 'p_bottleliquor01x' },
        inject = { dict = 'mech_inventory@item@_templates@bottle@lid_small_l@unarmed@cork', anim = 'quick_left_hand' },
    },
    stamina    = { core = true },     -- effects.stamina refills the stamina core on the client
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ STRESS ════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Stress = {
    -- camera shake per bracket while stress sits in it; `everyMs` between shakes
    brackets = {
        { min = 50, max = 65,  intensity = 0.10, everyMs = 50000 },
        { min = 65, max = 80,  intensity = 0.18, everyMs = 35000 },
        { min = 80, max = 95,  intensity = 0.26, everyMs = 22000 },
        { min = 95, max = 101, intensity = 0.34, everyMs = 14000 },
    },
    gainOnShot   = 1.0,  -- other resources add stress through exports; shooting adds this per shot when `trackShooting`
    trackShooting = true,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Security = {
    rateLimit     = { burst = 30, windowMs = 10000 },
    maxEffect     = 100,    -- a single consumable may not move a need by more than this
}

Config.Debug = { printBanner = true }
