--==--==--==--
-- Config
--==--==--==--

config = {
    controls = {
        -- [[Controls, list can be found here : https://docs.fivem.net/game-references/controls/]]
        openKey = 22, -- [[X/Square]]
        goUp = 24, -- [[Right Trigger]]
        goDown = 25, -- [[Left Trigger]]
        turnLeft = 5, -- [[Right Stick Left]]
        turnRight = 6, -- [[Right Stick Right]]
        goForward = 32,  -- [[Left Stick Forward]]
        goBackward = 33, -- [[Left Stick Back]]
        changeSpeed = 28, -- [[L3]]
    },

    speeds = {
        -- [[If you wish to change the speeds or labels there are associated with then here is the place.]]
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
        h = 3, -- [[How much you rotate. ]]
    },

    holdTime = 1000, -- [[Time in milliseconds to hold the button to toggle no-clip]]

    -- [[Background colour of the buttons. (It may be the standard black on first opening, just re-opening.)]]
    bgR = 0, -- [[Red]]
    bgG = 0, -- [[Green]]
    bgB = 0, -- [[Blue]]
    bgA = 80, -- [[Alpha]]
}

--==--==--==--
-- End Of Config
--==--==--==--

noclipActive = false -- [[Wouldn't touch this.]]
index = 1 -- [[Used to determine the index of the speeds table.]]
noclipToggleStart = 0 -- [[Timer for hold-to-toggle logic.]]

-- Custom scaling function for trigger input
local function scaleTriggerInput(input)
    if input <= 0.5 then
        -- Scale input from 0% to 50% trigger press: 0% to 25% speed
        return input * 0.5
    else
        -- Scale input from 50% to 100% trigger press: 25% to 100% speed
        return 0.25 + (input - 0.5) * 1.5
    end
end

Citizen.CreateThread(function()
    buttons = setupScaleform("instructional_buttons")
    currentSpeed = config.speeds[index].speed

    -- Define constant "Slow" speed for up/down movement
    local slowSpeed = 0.5

    while true do
        Citizen.Wait(1)

        -- Check for hold-to-toggle logic
        if IsControlPressed(1, config.controls.openKey) then
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
                SetVehicleRadioEnabled(noclipEntity, not noclipActive) -- [[Stop radio from appearing when going upwards.]]
            end
        else
            noclipToggleStart = 0 -- Reset the timer if button is released early
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

            -- Calculate upward/downward speed using fixed "Slow" speed
            local upInput = GetControlNormal(0, config.controls.goUp) -- Right Trigger
            local downInput = GetControlNormal(0, config.controls.goDown) -- Left Trigger
            zoff = (scaleTriggerInput(upInput) - scaleTriggerInput(downInput)) * (slowSpeed + 0.3)

            -- Forward and backward movement
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

            -- Lock camera to entity orientation
            local entityHeading = GetEntityHeading(noclipEntity)
            SetGameplayCamRelativeHeading(0) -- Align to entity heading
            SetGameplayCamRelativePitch(0, 1.0) -- Align to entity pitch

            local newPos = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, yoff, zoff)
            local heading = GetEntityHeading(noclipEntity)
            SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
            SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
            SetEntityHeading(noclipEntity, heading)
            SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, noclipActive, noclipActive, noclipActive)
        end
    end
end)

--==--==--==--
-- End Of Script
--==--==--==--
