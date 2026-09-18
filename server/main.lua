--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-HUD — Server: needs decay, consumables, stress, exports
     ═══════════════════════════════════════════════════════════════════════════
     Needs live in the core's replicated state bags (hunger, thirst,
     cleanliness, stress) and are persisted by the core on save. This file
     ticks them down, registers every catalog item with `effects` as a usable
     item, and offers exports so other resources can push a need around.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local RES = GetCurrentResourceName()
local NEEDS = { 'hunger', 'thirst', 'cleanliness', 'stress' }
local activity = {}   -- src → 'idle' | 'riding' | 'running' (client-reported, only scales decay)
local starving = {}   -- src → last damage tick
local buckets = {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function clamp(k, v) return math.max(Config.Needs.floors[k] or 0, math.min(Config.Needs.ceilings[k] or 100, v)) end
local function round1(v) return math.floor(v * 10 + 0.5) / 10 end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧭 NEEDS
-- ═══════════════════════════════════════════════════════════════════════════════
local function get(src, k)
    local v = Player(src).state[k]
    if v == nil then
        local P = LXRCore.Functions.GetPlayer(src)
        v = P and P.PlayerData.metadata[k]
    end
    return tonumber(v) or (k == 'stress' and 0 or 100)
end

local function set(src, k, v)
    local P = LXRCore.Functions.GetPlayer(src)
    if not P then return end
    v = round1(clamp(k, v))
    Player(src).state:set(k, v, true)
    P.Functions.SetMetaData(k, v)
    return v
end

local function add(src, k, delta)
    if not delta or delta == 0 then return get(src, k) end
    return set(src, k, get(src, k) + delta)
end

CreateThread(function()
    while true do
        Wait(Config.Needs.tickMs)
        for _, src in ipairs(GetPlayers()) do
            src = tonumber(src)
            local P = LXRCore.Functions.GetPlayer(src)
            if P and not P.PlayerData.metadata.isdead then
                local act = activity[src]
                local mult = (act == 'riding' or act == 'running') and Config.Needs.riding or nil
                for _, k in ipairs(NEEDS) do
                    local d = Config.Needs.decay[k] or 0
                    if mult and mult[k] then d = d * mult[k] end
                    if d ~= 0 then add(src, k, -d) end
                end
            end
        end
    end
end)

-- starving / dehydration: the client applies the damage (it owns the ped), the server decides when
CreateThread(function()
    while true do
        Wait(5000)
        local now = GetGameTimer()
        for _, src in ipairs(GetPlayers()) do
            src = tonumber(src)
            if (get(src, 'hunger') <= 0 or get(src, 'thirst') <= 0) and now - (starving[src] or 0) >= Config.Needs.starve.everyMs then
                starving[src] = now
                TriggerClientEvent('lxr-hud:client:starve', src, Config.Needs.starve.damage)
            end
        end
    end
end)

RegisterNetEvent('lxr-hud:server:activity', function(kind)
    local src = source
    if limited(src) then return end
    if kind == 'riding' or kind == 'running' or kind == 'idle' then activity[src] = kind end
end)
RegisterNetEvent('lxr-hud:server:shot', function()
    local src = source
    if limited(src) or not Config.Stress.trackShooting then return end
    add(src, 'stress', Config.Stress.gainOnShot)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🍞 CONSUMABLES — every catalog item with `effects`
-- ═══════════════════════════════════════════════════════════════════════════════
-- items whose every effect belongs to another resource (horse feed) are not ours
local function ours(def)
    if type(def.effects) ~= 'table' or not next(def.effects) then return false end
    for k in pairs(def.effects) do
        local skip = false
        for _, pre in ipairs(Config.Consumables.skipPrefix or {}) do if k:sub(1, #pre) == pre then skip = true end end
        if not skip then return true end
    end
    return false
end

local function consume(src, item)
    local P = LXRCore.Functions.GetPlayer(src)
    local def = LXRCore.Shared.Items[item.name]
    if not P or not def or type(def.effects) ~= 'table' then return end
    local use = def.use or {}
    -- the client plays the animation and reports back; the effect lands when it finishes
    TriggerClientEvent('lxr-hud:client:consume', src, { name = item.name, label = def.label, anim = use.anim or (def.effects.thirst and 'drink' or 'eat'), time = use.time or Config.Consumables.defaultMs, prop = use.prop })
end

RegisterNetEvent('lxr-hud:server:consumed', function(name)
    local src = source
    if limited(src) then return end
    local P = LXRCore.Functions.GetPlayer(src)
    local def = LXRCore.Shared.Items[name]
    if not P or not def or type(def.effects) ~= 'table' then return end
    local held = LXRCore.Inventory and LXRCore.Inventory.GetItem and LXRCore.Inventory.GetItem(src, name) or P.Functions.GetItemByName(name)
    if not held then return end
    local use = def.use or {}
    -- charges (canteen) or consumption
    if use.consume == false then
        local info = held.info or {}
        local charges = tonumber(info.charges)
        if charges then
            if charges <= 0 then return LXRCore.Notify(src, Lang:t('error.empty', { item = def.label }), 'error') end
            info.charges = charges - 1
            P.Functions.RemoveItem(name, 1, held.slot, 'consumable charge')
            P.Functions.AddItem(name, 1, held.slot, info, 'consumable charge')
        end
    else
        if not P.Functions.RemoveItem(name, 1, held.slot, 'consumed') then return end
    end
    local applied = {}
    for k, v in pairs(def.effects) do
        v = math.max(-Config.Security.maxEffect, math.min(Config.Security.maxEffect, tonumber(v) or 0))
        if k == 'hunger' or k == 'thirst' or k == 'cleanliness' or k == 'stress' then applied[k] = add(src, k, v)
        elseif k == 'health' or k == 'stamina' or k == 'core_health' or k == 'core_stamina' then applied[k] = v end -- the client applies bars and cores
    end
    TriggerClientEvent('lxr-hud:client:effects', src, applied)
    LXRCore.Emit('lxr:needs:consumed', {}, src, name, def.effects)
end)

CreateThread(function()
    if not Config.Consumables.register then return end
    local n = 0
    for name, def in pairs(LXRCore.Shared.Items) do
        if ours(def) then
            LXRCore.Items.RegisterUsable(name, consume)
            n = n + 1
        end
    end
    if Config.Debug.printBanner then print(('^1[lxr-hud]^7 v%s — %d consumables registered, needs tick every %ds'):format(GetResourceMetadata(RES, 'version', 0), n, Config.Needs.tickMs // 1000)) end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════════
exports('GetNeed', get)
exports('SetNeed', set)
exports('AddNeed', add)
exports('AddStress', function(src, n) return add(src, 'stress', n) end)
exports('RemoveStress', function(src, n) return add(src, 'stress', -(n or 0)) end)

AddEventHandler('playerDropped', function() activity[source] = nil starving[source] = nil buckets[source] = nil end)
