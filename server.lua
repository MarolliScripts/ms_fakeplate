ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('wise_fakeplate:buyPlate', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = 1000

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        exports.ox_inventory:AddItem(source, 'pustatablica', 1)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Sukces',
            description = 'Zakupiłeś pustą tablicę.',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Błąd',
            description = 'Nie masz wystarczającej ilości pieniędzy.',
            type = 'error'
        })
    end
end)

RegisterNetEvent('wise_fakeplate:removePlate', function()
    local player = source
    exports.ox_inventory:RemoveItem(player, 'pustatablica', 1)
    exports.ox_inventory:AddItem(player, 'tablica', 1)
end)

RegisterNetEvent('wise_fakeplate:removeRealPlate', function()
    local player = source
    exports.ox_inventory:RemoveItem(player, 'tablica', 1)
end)
