ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('ms_fakeplate:buyPlate', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.Price

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        exports.ox_inventory:AddItem(source, Config.Items.EmptyPlate, 1)
        TriggerClientEvent('ox_lib:notify', source, {
            title = Locale('purchase_success_title'),
            description = Locale('purchase_success_desc'),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = Locale('purchase_error_title'),
            description = Locale('purchase_error_desc'),
            type = 'error'
        })
    end
end)

RegisterNetEvent('ms_fakeplate:removePlate', function()
    local player = source
    exports.ox_inventory:RemoveItem(player, Config.Items.EmptyPlate, 1)
    exports.ox_inventory:AddItem(player, Config.Items.RealPlate, 1)
end)

RegisterNetEvent('ms_fakeplate:removeRealPlate', function()
    local player = source
    exports.ox_inventory:RemoveItem(player, Config.Items.RealPlate, 1)
end)
