local crosshairKvp = 0 -- Manages the crosshair setting
local disableV = false -- Prevents cam management
local wasInVehicle = false -- A check for if they were in the vehicle.
local disableAim = false -- Variable used to check if their aim should be disabled whilst in a vehicle.
local changeCooldown, lastView = 0, 0

local blacklistcars = Config.BlackListedCars

BlackListedCarGuns = Config.BlackListedCarGuns

QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand("crosshair", function(source, args, rawCommand)
    local hexArg = string.sub(rawCommand, 11)
    if #hexArg > 0 then
        SetResourceKvp('crosshairColor', hexArg)
        QBCore.Functions.Notify('Crosshair color updated', 'success')
        SendNUIMessage({ display = "reticleColor", color = hexArg })
    elseif GetResourceKvpInt('crosshair') == 2 then
        SetResourceKvpInt('crosshair', 1)
        crosshairKVP = 1
        QBCore.Functions.Notify('Crosshair Enabled', 'success')
    else
        SetResourceKvpInt('crosshair', 2)
        crosshairKVP = 0
        QBCore.Functions.Notify('Crosshair Disabled', 'error')
        SendNUIMessage({ display = "reticleHide" })
    end
end, false)

TriggerEvent('chat:addSuggestion', '/crosshair', 'Toggle the crosshair', {
    { name="color", help="(Optional) Put a hex value here like #FFFFFF."}
})

local function setViewMode(viewmode)
    for i = 1, 7 do
        SetCamViewModeForContext(i, viewmode)
    end
    SetFollowPedCamViewMode(viewmode)
    SetFollowVehicleCamViewMode(viewmode)
end

exports('setViewMode', setViewMode) -- exports['intensecam']:setViewMode(4)

local function manageKvp()

    if GetResourceKvpInt('crosshair') == 0 then 
        SetResourceKvpInt("crosshair", 1) 
        crosshairKVP = 1 
    end

    if not GetResourceKvpString('crosshairColor') then 
        SetResourceKvp("crosshairColor", '#FFFFFF')
    end

    if GetResourceKvpInt('crosshair') == 1 then crosshairKVP = 1 end
    if GetResourceKvpInt('crosshair') == 2 then crosshairKVP = 0 end
    if GetResourceKvpInt('crosshair') == 3 then crosshairKVP = 2 end

    SendNUIMessage({ display = "reticleColor", color = GetResourceKvpString('crosshairColor') })

end

local function manageCrosshair(toggle)
    if crosshairKVP > 0 then
        if toggle then 
            if not crosshairenabled then
                SendNUIMessage({ display = "reticleShow" })
                crosshairenabled = true
            end
        elseif crosshairenabled then
            SendNUIMessage({ display = "reticleHide" }) 
            crosshairenabled = false
        end
    elseif crosshairenabled then
        SendNUIMessage({ display = "reticleHide" }) 
        crosshairenabled = false
    end
end

local shouldDisable = false;

local function forceFp(plyId)
    SetCamEffect(0)
    local currCam, currVehCam = GetFollowPedCamViewMode(), GetFollowVehicleCamViewMode()
    if currCam ~= 4 or currVehCam ~= 4 then
        lastView = GetFollowPedCamViewMode()
        setViewMode(4)
        changeCooldown = GetGameTimer() + 2500
        shouldDisable = true
    elseif currCam == 0 then
        SetPlayerCanDoDriveBy(plyId, false)
        disableAim = true
    end

    if GetCamViewModeForContext(GetCamActiveViewModeContext()) ~= 4 then 
        SetPlayerCanDoDriveBy(plyId, false)
        disableAim = true
    elseif disableAim then
        disableAim = false
        SetPlayerCanDoDriveBy(plyId, true)
    end

    disableV = true
end



local function exitFp(plyId)
    shouldDisable = true;
    local currCam = GetFollowPedCamViewMode()
    if currCam == 1 or currCam == 2 then
        if wasInVehicle then 
            SetFollowPedCamViewMode(0)
            SetFollowVehicleCamViewMode(0)
            while GetFollowPedCamViewMode() ~= 0 do
                Wait(0)
                SetFollowPedCamViewMode(0)
                SetFollowVehicleCamViewMode(0)
            end
        else
            setViewMode(4)
            shouldDisable = true
        end
    end
    if disableAim then SetPlayerCanDoDriveBy(plyId, true) disableAim = false end;
    wasInVehicle = false
end

local plyPed = PlayerPedId()
local isArmed = false;
local isInHeli = false;

CreateThread(function()
    while true do
        Wait(1000)
        plyPed = PlayerPedId()
        isArmed = IsPedArmed(plyPed, 4) and GetSelectedPedWeapon(plyPed) ~= -1569615261
        isInHeli = IsPedInAnyHeli(plyPed)
    end
end)

local function SomethingDumb(plyId)
    manageCrosshair(false)

    if changeCooldown ~= 0 then
        if changeCooldown < GetGameTimer() then
            changeCooldown = 0
            setViewMode(lastView)
        end
    end

    if (GetFollowPedCamViewMode() == 2 or GetFollowVehicleCamViewMode() == 2) and not isInHeli then
        setViewMode(4)
        shouldDisable = true
    end

    if disableAim then
        SetPlayerCanDoDriveBy(plyId, true)
        disableAim = false
    end

    disableV = false
end

CreateThread(function() 
    
    Wait(100)
    manageKvp()

    local plyId = PlayerId()
    SetPlayerLockon(plyId, false)
    
    while true do
        Wait(0)

        if isArmed then
            if disableV then DisableControlAction(1, 0, true) end
            DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
        end

        local hash = GetSelectedPedWeapon(plyPed)
        local car = GetVehiclePedIsIn(plyPed, false)

        if car then
            if car ~= 0 and BlackListedCarGuns[hash] then
                SetPlayerCanDoDriveBy(plyId, false)
            else
                SetPlayerCanDoDriveBy(plyId, true)
            end
        end

        if isArmed then
            local isAiming = IsPlayerFreeAiming(plyId)
            if not isAiming then isAiming = IsAimCamActive() end
            if isAiming then
                manageCrosshair(true)
                local vehicle = GetVehiclePedIsIn(plyPed, false)
                local model = GetEntityModel(vehicle)
                local inVehicle = vehicle ~= 0
                local class = GetVehicleClass(vehicle)
                local isBike = class == 8 or class == 13 or blacklistcars[model]
                if inVehicle and isAiming and not isBike then
                    wasInVehicle = true
                    if shouldDisable and not disableAim then
                        SetPlayerCanDoDriveBy(plyId, false)
                        shouldDisable = false;
                        disableAim = true;
                        while IsAimCamActive() do Wait(100) end
                        Wait(300)
                    end
                    forceFp(plyId)
                else
                    disableV = false
                    exitFp(plyId)
                end
            else
                SomethingDumb(plyId)
            end
        else
            SomethingDumb(plyId)
        end

    end
end)

local vehicleHoodFp = false;

CreateThread(function()
    while true do
        Wait(2500)
        if GetProfileSetting(243) == 1 then
            if not vehicleHoodFp then
                QBCore.Functions.Notify('Disable first person on the hood setting.', 'error')
                vehicleHoodFp = true
                FreezeEntityPosition(PlayerPedId(), vehicleHoodFp)
            end
        elseif vehicleHoodFp then
            vehicleHoodFp = false
            FreezeEntityPosition(PlayerPedId(), vehicleHoodFp)
            QBCore.Functions.Notify('Woo! Thanks for changing that setting.', 'success')
        end
    end
end)