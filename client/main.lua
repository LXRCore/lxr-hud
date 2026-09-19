--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-HUD — Client: reads the world, feeds the page, consumes, settings
     ═══════════════════════════════════════════════════════════════════════════
     One loop at Config.Layout.refreshMs while the HUD is visible; every value
     is diffed and only changes reach the page. Needs come from the core's
     state bags, money and job from PlayerData, everything else from natives.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local N = Citizen.InvokeNative
local shown, hidden, settingsOpen = false, false, false
local last = {}
local settings = nil
local consuming = false
local MPH, KMH = 2.236936, 3.6

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⚙️ SETTINGS (per client, KVP)
-- ═══════════════════════════════════════════════════════════════════════════════
local function loadSettings()
    local raw = GetResourceKvpString('lxr-hud:settings')
    local ok, t = pcall(json.decode, raw or '')
    settings = {}
    for k, v in pairs(Config.Settings.defaults) do settings[k] = v end
    if ok and type(t) == 'table' then for k, v in pairs(t) do if settings[k] ~= nil then settings[k] = v end end end
    return settings
end
local function saveSettings() SetResourceKvp('lxr-hud:settings', json.encode(settings)) end
local function applyRadar() DisplayRadar(settings.minimap ~= 'off') end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📡 SOURCES
-- ═══════════════════════════════════════════════════════════════════════════════
local function core(ped, idx) return N(0x36731AC041289BB1, ped, idx, Citizen.ResultAsInteger()) end -- GET_ATTRIBUTE_CORE_VALUE
local function need(k) local v = LocalPlayer.state[k] return v ~= nil and tonumber(v) or ((LXRCore.PlayerData.metadata or {})[k]) end
local function heading(ped) return (360 - GetEntityHeading(ped)) % 360 end

local function nearestPlace(pos)
    local best, bestD = nil, math.huge
    for _, p in ipairs(Config.Places) do
        local d = #(pos - p.coords)
        if d < p.radius and d < bestD then best, bestD = p.label, d end
    end
    return best
end

local function clock()
    local h, m = GetClockHours(), GetClockMinutes()
    local day, month, year = GetClockDayOfMonth(), GetClockMonth() + 1, GetClockYear()
    if Config.Layout.year then year = Config.Layout.year end
    return { hour = h, minute = m, day = day, month = month, year = year }
end

local function weapon(ped)
    local ok, hash = GetCurrentPedWeapon(ped, true)
    if not ok or not hash or hash == joaat('WEAPON_UNARMED') then return nil end
    local label
    for name, def in pairs(LXRCore.Shared.Weapons or {}) do
        if joaat(name) == hash then label = def.label break end
    end
    local ammo = GetAmmoInPedWeapon(ped, hash)
    return { label = label or ('0x%X'):format(hash), ammo = ammo }
end

local function mount(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local u = Config.Layout.speedUnit == 'kmh' and KMH or MPH
        return { kind = 'wagon', speed = math.floor(GetEntitySpeed(veh) * u + 0.5), unit = Config.Layout.speedUnit }
    end
    local horse = N(0xE7E11B8DCBED1058, ped, Citizen.ResultAsInteger()) -- GET_MOUNT
    if horse and horse ~= 0 then
        local u = Config.Layout.speedUnit == 'kmh' and KMH or MPH
        return { kind = 'horse', speed = math.floor(GetEntitySpeed(horse) * u + 0.5), unit = Config.Layout.speedUnit, health = core(horse, 0), stamina = core(horse, 1) }
    end
    return nil
end

local function snapshot()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local pd = LXRCore.PlayerData or {}
    local job = LocalPlayer.state.job or pd.job or {}
    local jobDef = LXRCore.Shared.Jobs and LXRCore.Shared.Jobs[job.name]
    local grade = jobDef and jobDef.grades and jobDef.grades[tostring(job.grade or 0)]
    return {
        health = math.floor(GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped)) * 100 + 0.5),
        stamina = core(ped, 1),
        hunger = need('hunger') or 100, thirst = need('thirst') or 100, cleanliness = need('cleanliness') or 100, stress = need('stress') or 0,
        place = nearestPlace(pos),   -- the heading has its own fast tick below
        clock = clock(),
        name = pd.charinfo and (pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname) or '',
        job = { label = jobDef and jobDef.label or job.name or '', grade = grade and grade.name or '', onduty = job.onduty },
        cash = pd.money and pd.money.cash or 0, bank = pd.money and pd.money.bank or 0, blood = pd.money and pd.money.bloodmoney or 0,
        id = GetPlayerServerId(PlayerId()), talking = MumbleIsPlayerTalking(PlayerId()) == true,
        weapon = weapon(ped), mount = mount(ped),
        dead = pd.metadata and pd.metadata.isdead or false,
    }
end

local function diff(a, b)
    if type(a) ~= type(b) then return true end
    if type(a) ~= 'table' then return a ~= b end
    for k, v in pairs(a) do if diff(v, b[k]) then return true end end
    for k in pairs(b) do if a[k] == nil then return true end end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔁 LOOP
-- ═══════════════════════════════════════════════════════════════════════════════
local function show(on)
    if shown == on then return end
    shown = on
    SendNUIMessage({ action = on and 'show' or 'hide' })
end

-- the compass: 20 Hz while the frame is up, only when the heading moved (one small message)
CreateThread(function()
    local last = -1
    while true do
        Wait(shown and 50 or 500)
        if shown then
            local h = heading(PlayerPedId())
            if math.abs(h - last) > 0.3 then last = h SendNUIMessage({ action = 'heading', heading = h }) end
        end
    end
end)

CreateThread(function()
    loadSettings()
    while true do
        Wait(Config.Layout.refreshMs)
        local loggedIn = LocalPlayer.state.isLoggedIn == true
        -- down while any page has the mouse (inventory, creator, shops …) so nothing paints under it
        local visible = loggedIn and not hidden and not IsNuiFocused() and not (Config.Layout.hideWhilePaused and IsPauseMenuActive())
        show(visible)
        if visible then
            local s = snapshot()
            local out = {}
            for k, v in pairs(s) do if diff(v, last[k]) then out[k] = v end end
            for k in pairs(last) do if s[k] == nil then out[k] = false end end
            if next(out) then SendNUIMessage({ action = 'update', data = out }) last = s end
            -- activity for the server's decay multipliers, once every few seconds
            local ped = PlayerPedId()
            local act = (s.mount and s.mount.kind == 'horse' and s.mount.speed > 8) and 'riding' or (IsPedRunning(ped) or IsPedSprinting(ped)) and 'running' or 'idle'
            if act ~= last._act and (GetGameTimer() - (last._actAt or 0)) > 5000 then last._act = act last._actAt = GetGameTimer() TriggerServerEvent('lxr-hud:server:activity', act) end
        end
    end
end)

-- the game's own cores and meters: _UITUTORIAL_SET_RPG_ICON_VISIBILITY per icon (2 = hidden, 0 = the game decides).
-- eRpgIcons: 0 stamina, 1 stamina core, 2 deadeye, 3 deadeye core, 4 health, 5 health core,
--            6 horse health, 7 horse health core, 8 horse stamina, 9 horse stamina core, 10 horse courage, 11 horse courage core
-- _SHOW_PLAYER_CORES alone is not enough: the HUD re-shows them after a death or a resurrect
local function nativeCores()
    local h = Config.Layout.hideNativeCores or {}
    for icon = 0, 5 do N(0xC116E6DF68DCE667, icon, h.player and 2 or 0) end
    for icon = 6, 11 do N(0xC116E6DF68DCE667, icon, h.horse and 2 or 0) end
    N(0x50C803A4CD5932C5, not h.player) -- _SHOW_PLAYER_CORES
    N(0xD4EE21B7CC7FD350, not h.horse)  -- _SHOW_HORSE_CORES
end
RegisterNetEvent('lxr-doctor:client:revive', function() Wait(1000) nativeCores() end)
CreateThread(function()   -- and re-asserted every few seconds: a respawn, a resurrect or a cutscene brings them back
    while true do Wait(5000) if LocalPlayer.state.isLoggedIn then nativeCores() end end
end)

-- first paint: locale, layout, settings, brand
local function init()
    nativeCores()
    SendNUIMessage({ action = 'init', locale = Lang.bundle(), lang = Config.Lang, layout = Config.Layout, settings = settings or loadSettings(), brand = LXRCore.Brand, warnAt = Config.Needs.warnAt, help = Config.Help })
    applyRadar()
    last = {}
end
RegisterNetEvent('lxr:client:loaded', function() init() end)
AddEventHandler('onResourceStart', function(res) if res == GetCurrentResourceName() then CreateThread(function() Wait(500) init() end) end end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🍞 CONSUME / EFFECTS / STARVE
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('lxr-hud:client:consume', function(c)
    if consuming then return end
    consuming = true
    local ped = PlayerPedId()
    local a = Config.Consumables.anims[c.anim] or Config.Consumables.anims.eat
    local prop
    if a.dict then
        RequestAnimDict(a.dict)
        local t = 0
        while not HasAnimDictLoaded(a.dict) and t < 50 do Wait(10) t = t + 1 end
        if HasAnimDictLoaded(a.dict) then TaskPlayAnim(ped, a.dict, a.anim, 2.0, 2.0, c.time or Config.Consumables.defaultMs, 31, 0.0, false, false, false) end
    end
    local propName = c.prop and ((Config.Consumables.props or {})[c.prop] or c.prop) or a.prop
    local model = propName and joaat(propName) or nil
    if model and IsModelInCdimage(model) then
        RequestModel(model)
        local t = 0
        while not HasModelLoaded(model) and t < 50 do Wait(10) t = t + 1 end
        if HasModelLoaded(model) then
            local pos = GetEntityCoords(ped)
            prop = CreateObject(model, pos.x, pos.y, pos.z, true, true, false)
            AttachEntityToEntity(prop, ped, GetEntityBoneIndexByName(ped, 'SKEL_L_Hand'), 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        end
    end
    local done = true
    if GetResourceState('lxr-nui') == 'started' then
        local finished = nil
        exports['lxr-nui']:Progress({ label = c.label, duration = c.time or Config.Consumables.defaultMs, canCancel = true }, function(f) finished = f end)
        while finished == nil do Wait(50) end
        done = finished
    else
        Wait(c.time or Config.Consumables.defaultMs)
    end
    if prop and DoesEntityExist(prop) then DeleteObject(prop) end
    ClearPedTasks(ped)
    consuming = false
    if done then TriggerServerEvent('lxr-hud:server:consumed', c.name) end
end)

RegisterNetEvent('lxr-hud:client:effects', function(applied)
    local ped = PlayerPedId()
    if applied.health then
        local max = GetEntityMaxHealth(ped)
        SetEntityHealth(ped, math.min(max, GetEntityHealth(ped) + math.floor(max * applied.health / 100)))
    end
    local function bump(idx, v) N(0xC6258F41D86676E0, ped, idx, math.max(0, math.min(100, core(ped, idx) + v))) end -- _SET_ATTRIBUTE_CORE_VALUE
    if applied.stamina then
        if Config.Consumables.stamina.core then bump(1, applied.stamina) end
        N(0x675680D089BFA21F, ped, math.min(100.0, N(0x775A1CA7893AA8B5, ped, Citizen.ResultAsFloat()) + applied.stamina + 0.0)) -- stamina bar
    end
    if applied.core_health then bump(0, applied.core_health) end
    if applied.core_stamina then bump(1, applied.core_stamina) end
end)

RegisterNetEvent('lxr-hud:client:starve', function(damage)
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end
    SetEntityHealth(ped, math.max(1, GetEntityHealth(ped) - (tonumber(damage) or 4)))
    SendNUIMessage({ action = 'pulse', key = (need('hunger') or 1) <= 0 and 'hunger' or 'thirst' })
end)

-- stress from shooting
CreateThread(function()
    if not Config.Stress.trackShooting then return end
    local lastShot = 0
    while true do
        Wait(250)
        if shown and IsPedShooting(PlayerPedId()) and GetGameTimer() - lastShot > 900 then lastShot = GetGameTimer() TriggerServerEvent('lxr-hud:server:shot') end
    end
end)

-- stress effects: camera shake by bracket
CreateThread(function()
    while true do
        local stress = need('stress') or 0
        local b
        for _, br in ipairs(Config.Stress.brackets) do if stress >= br.min and stress < br.max then b = br end end
        if b and shown then
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', b.intensity)
            Wait(b.everyMs)
        else
            Wait(3000)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🪟 SETTINGS PANEL / TOGGLE
-- ═══════════════════════════════════════════════════════════════════════════════
local function openSettings()
    if settingsOpen then return end
    settingsOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'settings', open = true, settings = settings or loadSettings(), brand = LXRCore.Brand })
end
RegisterNUICallback('settings', function(d, cb)
    cb('ok')
    if type(d.settings) == 'table' then
        for k, v in pairs(d.settings) do if Config.Settings.defaults[k] ~= nil then settings[k] = v end end
        saveSettings() applyRadar()
        SendNUIMessage({ action = 'init', locale = Lang.bundle(), lang = Config.Lang, layout = Config.Layout, settings = settings, brand = LXRCore.Brand, warnAt = Config.Needs.warnAt, help = Config.Help })
        last = {}
    end
end)
RegisterNUICallback('closeSettings', function(_, cb) cb('ok') settingsOpen = false SetNuiFocus(false, false) SendNUIMessage({ action = 'settings', open = false }) end)
-- edit layout: the page keeps the cursor while elements are dragged; the HUD stays drawn under it
RegisterNUICallback('edit', function(d, cb) cb('ok') settingsOpen = d.on == true SetNuiFocus(d.on == true, d.on == true) end)

RegisterCommand(Config.Settings.command, function() if LocalPlayer.state.isLoggedIn then openSettings() end end, false)
RegisterCommand('togglehud', function() hidden = not hidden end, false)
TriggerEvent('chat:addSuggestion', '/' .. Config.Settings.command, Lang:t('command.settings'))
TriggerEvent('chat:addSuggestion', '/togglehud', Lang:t('command.toggle'))

exports('Hide', function(on) hidden = on and true or false end)
exports('IsShown', function() return shown end)
exports('GetSnapshot', snapshot)
