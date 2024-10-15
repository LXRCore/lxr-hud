exports['lxr-core']:AddCommand('cash', 'Check Cash Balance', {}, false, function(source, args)
    local Player = exports['lxr-core']:GetPlayer(source)
    local cashamount = Player.PlayerData.money.cash
    TriggerClientEvent('QBCore:Notify', source, 9, '$'..cashamount, 5000)
end)

exports['lxr-core']:AddCommand('bank', 'Check Bank Balance', {}, false, function(source, args)
    local Player = exports['lxr-core']:GetPlayer(source)
    local bankamount = Player.PlayerData.money.bank
    TriggerClientEvent('QBCore:Notify', source, 9, '$'..bankamount, 5000)
end)