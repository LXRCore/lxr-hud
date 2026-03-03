--[[
    ██╗     ██╗  ██╗██████╗        ██╗  ██╗██╗   ██╗██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║  ██║██║   ██║██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████║██║   ██║██║  ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██╔══██║██║   ██║██║  ██║
    ███████╗██╔╝ ██╗██║  ██║       ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    🐺 LXR HUD System - Server Side

    Handles server-side commands for balance checks, dispatched via LXR-Core.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    Store:       https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ COMMANDS ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

exports['lxr-core']:AddCommand('cash', 'Check Cash Balance', {}, false, function(source, args)
    local Player = exports['lxr-core']:GetPlayer(source)
    local cashamount = Player.PlayerData.money.cash
    TriggerClientEvent('lxr-core:client:Notify', source, Lang:t('info.cash_balance', {amount = '$' .. cashamount}), 'success', 5000)
end)

exports['lxr-core']:AddCommand('bank', 'Check Bank Balance', {}, false, function(source, args)
    local Player = exports['lxr-core']:GetPlayer(source)
    local bankamount = Player.PlayerData.money.bank
    TriggerClientEvent('lxr-core:client:Notify', source, Lang:t('info.bank_balance', {amount = '$' .. bankamount}), 'success', 5000)
end)