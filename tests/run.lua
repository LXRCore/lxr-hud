--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-HUD — Offline tests: config sanity, consumable coverage, locale parity
     Requires a sibling checkout of lxr-core (../lxr-core).
     Usage (from the lxr-hud folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE .. ' (set LXR_CORE_PATH)') os.exit(2) end
local Shim = require('tests.lib.fxshim')

for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua' }) do Shim.load(CORE .. '/' .. f) end
local Items = LXRShared.Items
Config = nil
Locale = nil
Shim.load('shared/locale.lua')
Shim.load('locales/en.lua')
Shim.load('locales/ka.lua')
Shim.load('config.lua')

local passed, failed = 0, 0
local function test(name, fn)
    local okT, err = xpcall(fn, debug.traceback)
    if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end
end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-hud offline tests')

test('needs config is coherent', function()
    for _, k in ipairs({ 'hunger', 'thirst', 'cleanliness', 'stress' }) do
        assert(Config.Needs.decay[k] ~= nil, 'decay ' .. k)
        assert(Config.Needs.floors[k] < Config.Needs.ceilings[k], 'range ' .. k)
    end
    assert(Config.Needs.decay.stress < 0, 'stress falls on its own')
    assert(Config.Needs.tickMs >= 10000)
    for _, key in ipairs(Config.Layout.status) do assert(Locale.Bundles.en['ui.' .. key], 'status label ' .. key) end
end)

test('every catalog consumable has an animation the HUD knows', function()
    local n, missing = 0, {}
    for name, def in pairs(Items) do
        local mine = false
        if type(def.effects) == 'table' then for k in pairs(def.effects) do if k:sub(1, 6) ~= 'horse_' then mine = true end end end
        if mine then
            n = n + 1
            local anim = def.use and def.use.anim
            if anim and not Config.Consumables.anims[anim] and anim ~= 'inspect' and anim ~= 'read' and anim ~= 'craft' then missing[#missing + 1] = name .. ':' .. anim end
            for k, v in pairs(def.effects) do assert(math.abs(v) <= Config.Security.maxEffect, name .. ' effect ' .. k .. ' exceeds maxEffect') end
        end
    end
    assert(n > 50, 'consumables found: ' .. n)
    eq(#missing, 0, 'missing anims: ' .. table.concat(missing, ', '))
end)

test('places have coords and radii; stress brackets tile 50..100', function()
    for _, p in ipairs(Config.Places) do assert(p.label and p.coords and p.radius > 0) end
    local last = 50
    for _, b in ipairs(Config.Stress.brackets) do eq(b.min, last, 'bracket gap') last = b.max end
    assert(last >= 100)
end)

test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)

print(('%d passed, %d failed'):format(passed, failed))

if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local msgs = {
        { action = 'init', locale = Lang.bundle(), lang = Config.Lang, layout = Config.Layout, settings = Config.Settings.defaults, brand = { name = 'The Land of Wolves', theme = 'night' }, warnAt = Config.Needs.warnAt },
        { action = 'show' },
        { action = 'update', data = { health = 82, stamina = 64, hunger = 18, thirst = 57, cleanliness = 71, stress = 33, heading = 292, place = 'Valentine',
            clock = { hour = 17, minute = 42, day = 12, month = 5, year = 1899 }, name = 'Sadie Adler', job = { label = 'Deputy', grade = 'Deputy' }, cash = 12.5, bank = 140,
            weapon = { label = 'Cattleman Revolver', ammo = 31 }, mount = { kind = 'horse', speed = 14, unit = 'mph', health = 90, stamina = 66 } } },
    }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode(msgs) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
