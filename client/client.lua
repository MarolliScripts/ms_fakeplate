local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
end

local function hasItem(name)
    local ok, count = pcall(function() return exports.ox_inventory:Search('count', name) end)
    if ok and type(count) == 'number' then
        return count > 0
    end
    ok, count = pcall(function() return exports.ox_inventory:GetItemCount(name) end)
    if ok and type(count) == 'number' then
        return count > 0
    end
    return false
end

local function notify(typeKey, descKey)
    local title = typeKey == 'error' and Locale('purchase_error_title') or Locale('purchase_success_title')
    local description = Locale(descKey)
    if lib and lib.notify then
        lib.notify({ title = title, description = description, type = typeKey })
    else
        print((typeKey or 'info') .. ': ' .. title .. ' - ' .. description)
    end
end

local function hasFakePlateItem()
    return hasItem(Config.Items.EmptyPlate)
end

local function hasRealPlateItem()
    return hasItem(Config.Items.RealPlate)
end

local function resolveVehicle(arg)
    local veh = nil
    if arg ~= nil then
        if type(arg) == 'number' then
            veh = arg
        elseif type(arg) == 'table' then
            if type(arg.entity) == 'number' then
                veh = arg.entity
            elseif type(arg.vehicle) == 'number' then
                veh = arg.vehicle
            elseif type(arg[1]) == 'number' then
                veh = arg[1]
            end
        end
    end
    if veh and DoesEntityExist(veh) and GetEntityType(veh) == 2 then
        return veh
    end
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    return GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
end

local function generateRandomPlate()
    local plate = ''
    for i = 1, 3 do
        plate = plate .. string.char(math.random(65, 90))
    end
    for i = 1, 4 do
        plate = plate .. string.char(math.random(48, 57))
    end
    return plate
end

local originalPlates = {}

local function isPlayerAtRearOfVehicle(vehicle)
    if not vehicle or type(vehicle) ~= 'number' or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleRearCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.0)
    local distance = #(playerCoords - vehicleRearCoords)
    return distance < 1.0
end

CreateThread(function()
    loadModel(Config.NPC.model)
    if not HasModelLoaded(Config.NPC.model) then return end

    local ped = CreatePed(4, Config.NPC.model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'ms_fakeplate_buy',
            icon = 'fa-solid fa-car',
            label = Locale('buy_empty_plate'),
            distance = Config.NPC.distance,
            onSelect = function()
                TriggerServerEvent('ms_fakeplate:buyPlate')
            end
        }
    })
end)

exports.ox_target:addGlobalVehicle({
    {
        name = 'ms_fakeplate_change',
        event = 'ms_fakeplate:changePlate',
        label = Locale('change_plate_label'),
        icon = 'fa-solid fa-exchange-alt',
        canInteract = function(entity)
            return hasFakePlateItem() and isPlayerAtRearOfVehicle(entity)
        end,
    },
    {
        name = 'ms_fakeplate_restore',
        event = 'ms_fakeplate:restorePlate',
        label = Locale('restore_plate_label'),
        icon = 'fa-solid fa-wrench',
        canInteract = function(entity)
            return hasRealPlateItem() and isPlayerAtRearOfVehicle(entity)
        end,
    },
})

RegisterNetEvent('ms_fakeplate:changePlate', function(entity)
    local vehicle = resolveVehicle(entity)

    if not vehicle then
        notify('error', 'error_no_vehicle')
        return
    end

    if not hasFakePlateItem() then
        notify('error', 'error_no_fake_plate')
        return
    end

    if not isPlayerAtRearOfVehicle(vehicle) then
        notify('error', 'error_rear_vehicle')
        return
    end

    local originalPlate = GetVehicleNumberPlateText(vehicle)
    local newPlate = generateRandomPlate()

    local cfg = {
        duration = Config.Progress.duration,
        label = Locale('progress_changing_plate'),
        useWhileDead = false,
        canCancel = false,
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 1 },
        disable = { move = true, car = true, combat = true },
    }
    if type(vector3) == 'function' then
        cfg.prop = { model = `prop_tool_screwdvr02`, pos = vector3(0.15, 0.0, 0.01), rot = vector3(90.0, 0.0, 0.0) }
    else
        cfg.prop = { model = `prop_tool_screwdvr02` }
    end
    local success = false
    if lib and lib.progressBar then
        success = lib.progressBar(cfg)
    else
        Citizen.Wait(cfg.duration)
        success = true
    end
    if success then
        local key = NetworkGetNetworkIdFromEntity(vehicle)
        if not key or key == 0 then
            key = vehicle
        end
        originalPlates[key] = originalPlate
        NetworkRequestControlOfEntity(vehicle)
        local start = GetGameTimer()
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() - start < 2000 do
            Citizen.Wait(0)
        end
        SetVehicleNumberPlateText(vehicle, newPlate)
        TriggerServerEvent('ms_fakeplate:removePlate')
        if lib and lib.notify then
            lib.notify({ title = Locale('purchase_success_title'), description = Locale('success_changed_plate'), type = 'success' })
        else
            print(Locale('success_changed_plate'))
        end
    else
        print(Locale('cancelled_change'))
    end
end)

RegisterNetEvent('ms_fakeplate:restorePlate', function(entity)
    local vehicle = resolveVehicle(entity)

    if not vehicle then
        notify('error', 'error_no_vehicle')
        return
    end

    if not isPlayerAtRearOfVehicle(vehicle) then
        notify('error', 'error_rear_vehicle')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local originalPlate = originalPlates[netId]
    if not originalPlate or originalPlate == '' then
        notify('error', 'error_no_saved_plate')
        return
    end

    local cfg = {
        duration = Config.Progress.duration,
        label = Locale('progress_restoring_plate'),
        useWhileDead = false,
        canCancel = false,
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 1 },
        disable = { move = true, car = true, combat = true },
    }
    if type(vector3) == 'function' then
        cfg.prop = { model = `prop_tool_screwdvr02`, pos = vector3(0.15, 0.0, 0.01), rot = vector3(90.0, 0.0, 0.0) }
    else
        cfg.prop = { model = `prop_tool_screwdvr02` }
    end
    local success = false
    if lib and lib.progressBar then
        success = lib.progressBar(cfg)
    else
        Citizen.Wait(cfg.duration)
        success = true
    end
    if success then
        NetworkRequestControlOfEntity(vehicle)
        local start = GetGameTimer()
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() - start < 2000 do
            Citizen.Wait(0)
        end
        local key = NetworkGetNetworkIdFromEntity(vehicle)
        if not key or key == 0 then
            key = vehicle
        end
        local plateToRestore = originalPlates[key]
        if not plateToRestore or plateToRestore == '' then
            notify('error', 'error_no_saved_plate')
            return
        end
        SetVehicleNumberPlateText(vehicle, plateToRestore)
        TriggerServerEvent('ms_fakeplate:removeRealPlate')
        if lib and lib.notify then
            lib.notify({ title = Locale('purchase_success_title'), description = Locale('success_restored_plate'), type = 'success' })
        else
            print(Locale('success_restored_plate'))
        end
    else
        print(Locale('cancelled_restore'))
    end
end)
