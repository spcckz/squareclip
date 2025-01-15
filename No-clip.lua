--==--==--==--
-- Config
--==--==--==--

config = {
    controls = {
        -- [[Controls, list can be found here : https://docs.fivem.net/game-references/controls/]]
        goUp = 24, -- [[Right Trigger]]
        goDown = 25, -- [[Left Trigger]]
        turnLeft = 5, -- [[Right Stick Left]]
        turnRight = 6, -- [[Right Stick Right]]
        goForward = 32,  -- [[Left Stick Forward]]
        goBackward = 33, -- [[Left Stick Back]]
        changeSpeed = 28, -- [[L3]]
    },

    speeds = {
        { label = "Very Slow", speed = 0 },
        { label = "Slow", speed = 0.5 },
        { label = "Normal", speed = 2 },
        { label = "Fast", speed = 4 },
        { label = "Very Fast", speed = 6 },
        { label = "Extremely Fast", speed = 10 },
        { label = "Extremely Fast v2.0", speed = 20 },
        { label = "Max Speed", speed = 25 }
    },

    offsets = {
        y = 0.5, -- [[How much distance you move forward and backward while the respective button is pressed]]
        z = 0.2, -- [[How much distance you move upward and downward while the respective button is pressed]]
        h = 3, -- [[How much you rotate. ]],
    },

    holdTime = 1000, -- [[Time in milliseconds to hold the button to toggle no-clip]]
}

--==--==--==--
-- End Of Config
--==--==--==--

noclipActive = false
index = 1
noclipToggleStart = 0

local function scaleTriggerInput(input)
    if input <= 0.5 then
        return input * 0.5
    else
        return 0.25 + (input - 0.5) * 1.5
    end
end

local function setAlpha(alpha)
    local ped = PlayerPedId()
    SetEntityAlpha(ped, alpha, false)
end

Citizen.CreateThread(function()
    buttons = setupScaleform("instructional_buttons")
    currentSpeed = config.speeds[index].speed
    local slowSpeed = 0.5

    while true do
        Citizen.Wait(1)

        -- Check for simultaneous hold-to-toggle logic
        if IsControlPressed(1, 21) and IsControlPressed(1, 22) then
            if noclipToggleStart == 0 then
                noclipToggleStart = GetGameTimer()
            elseif GetGameTimer() - noclipToggleStart >= config.holdTime then
                noclipActive = not noclipActive
                noclipToggleStart = 0 -- Reset the timer

                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    noclipEntity = GetVehiclePedIsIn(PlayerPedId(), false)
                else
                    noclipEntity = PlayerPedId()
                end

                SetEntityCollision(noclipEntity, not noclipActive, not noclipActive)
                FreezeEntityPosition(noclipEntity, noclipActive)
                SetEntityInvincible(noclipEntity, noclipActive)
                SetVehicleRadioEnabled(noclipEntity, not noclipActive)

                -- Change player alpha based on noclip status
                if noclipActive then
                    setAlpha(125) -- Set alpha transparency when noclip is active
                else
                    setAlpha(255) -- Reset to default when noclip is disabled
                    
                    -- Simulate pressing button 87 (Throttle) for 500 milliseconds when noclip is disabled
                    TriggerEvent("simulateThrottleBlip", 500)
                end
            end
        else
            noclipToggleStart = 0 -- Reset the timer if buttons are released early
        end

        if noclipActive then
            DrawScaleformMovieFullscreen(buttons)

            local yoff = 0.0
            local zoff = 0.0

            if IsControlJustPressed(1, config.controls.changeSpeed) then
                if index ~= 8 then
                    index = index + 1
                    currentSpeed = config.speeds[index].speed
                else
                    currentSpeed = config.speeds[1].speed
                    index = 1
                end
                setupScaleform("instructional_buttons")
            end

            DisableControls()

            local upInput = GetControlNormal(0, config.controls.goUp)
            local downInput = GetControlNormal(0, config.controls.goDown)
            zoff = (scaleTriggerInput(upInput) - scaleTriggerInput(downInput)) * (slowSpeed + 0.3)

            if IsDisabledControlPressed(0, config.controls.goForward) then
                yoff = config.offsets.y * (currentSpeed + 0.3)
            end

            if IsDisabledControlPressed(0, config.controls.goBackward) then
                yoff = -config.offsets.y * (currentSpeed + 0.3)
            end

            if IsDisabledControlPressed(0, config.controls.turnLeft) then
                SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity) + config.offsets.h)
            end

            if IsDisabledControlPressed(0, config.controls.turnRight) then
                SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity) - config.offsets.h)
            end

            local entityHeading = GetEntityHeading(noclipEntity)
            SetGameplayCamRelativeHeading(0)
            SetGameplayCamRelativePitch(0, 1.0)

            local newPos = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, yoff, zoff)
            local heading = GetEntityHeading(noclipEntity)
            SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
            SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
            SetEntityHeading(noclipEntity, heading)
            SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, noclipActive, noclipActive, noclipActive)

            -- Display text when noclip is enabled
            SetTextScale(0.5, 0.5)  -- Text size halved
            SetTextColour(255, 255, 255, 255)  -- White text
            SetTextOutline()  -- Add black outline
            SetTextCentre(true)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName("NOCLIP ENABLED")
            EndTextCommandDisplayText(0.5, 0.5)
        end
    end
end)

-- Simulate a throttle blip for a given duration by directly modifying vehicle throttle
RegisterNetEvent("simulateThrottleBlip")
AddEventHandler("simulateThrottleBlip", function(duration)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        -- Get the current throttle input of the vehicle and simulate pressing throttle
        local throttle = 1.0 -- Maximum throttle input
        local startTime = GetGameTimer()

        while GetGameTimer() - startTime < duration do
            -- Apply throttle force to simulate a blip
            ApplyForceToEntity(vehicle, 1, 0.0, 0.0, throttle, false, false, false, false, false, false)
            Citizen.Wait(0)
        end
    end
end)
