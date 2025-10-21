local raceStarted = false
local passedCheckpoints = {}
local arrows = {}
local fireRings = {}
local nextCheckpoint = 1
local promptGroup = GetRandomIntInRange(0, 0xffffff)
local registerPrompt = nil
local startPrompt = nil
local isRegistered = false
local raceStartTime = 0
local timeoutTriggered = false
local raceMount = nil
local spawnedRaceMount = false
local blip = nil
local drawMarkerOn = false

local function loadBlip()
    if Config.blip.enable then
        blip = BlipAddForCoords(1664425300, Config.blip.coords.x, Config.blip.coords.y, Config.blip.coords.z)
        SetBlipSprite(blip, Config.blip.sprite, true)
        SetBlipScale(blip, 1.0)
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, Config.blip.color)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.blip.name)
    end
end

local function calculateStartData(spawnIndex, totalParticipants)
    local startCoords = Config.startCoords
    local directionX = 1.0
    local directionY = 0.0
    local heading = 0.0
    local firstCheckpoint = Config.raceCoords[1]
    if firstCheckpoint and firstCheckpoint.coords then
        local deltaX = firstCheckpoint.coords.x - startCoords.x
        local deltaY = firstCheckpoint.coords.y - startCoords.y
        if deltaX ~= 0.0 or deltaY ~= 0.0 then
            heading = GetHeadingFromVector_2d(deltaX, deltaY)
            local magnitude = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))
            if magnitude > 0.0 then
                directionX = deltaX / magnitude
                directionY = deltaY / magnitude
            end
        end
    end
    local rightX = -directionY
    local rightY = directionX
    local participants = totalParticipants or 1
    if participants < 1 then
        participants = 1
    end
    local index = spawnIndex or 1
    if index < 1 then
        index = 1
    end
    local spacing = Config.startSpacing or 2.5
    local offset = ((index - 1) - (participants - 1) / 2) * spacing
    local spawnCoords = vector3(
        startCoords.x + (rightX * offset),
        startCoords.y + (rightY * offset),
        startCoords.z
    )
    return spawnCoords, heading
end

Citizen.CreateThread(function()
    while true do
        local t = 1000
        if drawMarkerOn then
            Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17, Config.blip.coords.x, Config.blip.coords.y, Config.blip.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 0.4, 255, 255, 255, 80, 0, 0, 2, 0, 0, 0, 0)
            t = 0
        end
        Wait(t)
    end
end)

local function loadPrompts()
    local str = CreateVarString(10, 'LITERAL_STRING', Config.prompts.register)
    registerPrompt = PromptRegisterBegin()
    PromptSetControlAction(registerPrompt, Config.registerKey)
    PromptSetText(registerPrompt, str)
    PromptSetEnabled(registerPrompt, 1)
    PromptSetVisible(registerPrompt, 1)
    PromptSetStandardMode(registerPrompt, 1)
    PromptSetGroup(registerPrompt, promptGroup)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, registerPrompt, true)
    PromptRegisterEnd(registerPrompt)

    str = CreateVarString(10, 'LITERAL_STRING', Config.prompts.start)
    startPrompt = PromptRegisterBegin()
    PromptSetControlAction(startPrompt, Config.startKey)
    PromptSetText(startPrompt, str)
    PromptSetEnabled(startPrompt, 1)
    PromptSetStandardMode(startPrompt, 1)
    PromptSetGroup(startPrompt, promptGroup)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, startPrompt, true)
    PromptRegisterEnd(startPrompt)
end

local function startTimer()
    raceStartTime = GetGameTimer()
    local serverTime = GetCloudTimeAsInt()
    SendNUIMessage({
        action = 'showTimer',
        serverTime = serverTime,
        startTime = serverTime
    })
end

local function stopTimer()
    SendNUIMessage({ action = 'hide' })
end

local function getNextCheckpointId(checkpoints)
    for i = 1, #Config.raceCoords do
        if not checkpoints[i] then
            return i
        end
    end
    return #Config.raceCoords + 1
end


local function startRaceTimeoutWatcher()
    local configuredTimeout = tonumber(Config.raceTimeout)
    if not configuredTimeout or configuredTimeout <= 0 then
        return
    end
    local timeoutMs = math.floor(configuredTimeout * 1000)
    if timeoutMs <= 0 then
        return
    end
    timeoutTriggered = false
    Citizen.CreateThread(function()
        while raceStarted do
            if timeoutTriggered then
                break
            end
            if raceStartTime > 0 then
                local elapsed = GetGameTimer() - raceStartTime
                if elapsed >= timeoutMs then
                    timeoutTriggered = true
                    TriggerServerEvent('moro_race:timeoutReached')
                    break
                end
            end
            Wait(500)
        end
    end)
end


local function createArrow(checkpointIndex, arrowIndex)
    local arrowData = Config.raceCoords[checkpointIndex].arrows[arrowIndex]
    if not arrowData then return end
    local ptfx = 'scr_net_player_signal'
    local ptfxName = 'scr_net_player_signal'
    local coords = arrowData.coords
    local arrowCoords = vector3(coords.x, coords.y, coords.z)
    local heading = coords.w
    while not HasNamedPtfxAssetLoaded(ptfx) do
        Wait(10)
    end
    UseParticleFxAsset(ptfx)
    arrows[checkpointIndex] = arrows[checkpointIndex] or {}
    arrows[checkpointIndex][arrowIndex] = StartParticleFxLoopedAtCoord(ptfxName, arrowCoords, arrowData.pitch, arrowData.roll, heading, 1.0, true, false, false, true)
end

local function deleteArrow(checkpointIndex, arrowIndex)
    if arrows[checkpointIndex] and arrows[checkpointIndex][arrowIndex] then
        StopParticleFxLooped(arrows[checkpointIndex][arrowIndex], 0)
        arrows[checkpointIndex][arrowIndex] = nil
        if not next(arrows[checkpointIndex]) then
            arrows[checkpointIndex] = nil
        end
    end
end

local function createCheckpointArrows(index)
    if Config.raceCoords[index] and Config.raceCoords[index].arrows then
        for arrowIndex in pairs(Config.raceCoords[index].arrows) do
            createArrow(index, arrowIndex)
        end
    end
end

local function deleteCheckpointArrows(index)
    if Config.raceCoords[index] and Config.raceCoords[index].arrows then
        for arrowIndex in pairs(Config.raceCoords[index].arrows) do
            deleteArrow(index, arrowIndex)
        end
    end
end

local function createFireRing(index)
    local coords = Config.raceCoords[index].coords
    if not coords then return end
    local ptfx = 'scr_net_target_races'
    local ptfxName = 'scr_net_target_fire_ring_mp'
    local fireRingCoords = vector3(coords.x, coords.y, coords.z)
    local heading = coords.w
    while not HasNamedPtfxAssetLoaded(ptfx) do
        Wait(10)
    end
    UseParticleFxAsset(ptfx)
    fireRings[index] = StartParticleFxLoopedAtCoord(ptfxName, fireRingCoords, 0.0, 0.0, heading, 4.0, true, false, false, true)
end

local function deleteFireRing(index)
    if fireRings[index] then
        StopParticleFxLooped(fireRings[index], 0)
        fireRings[index] = nil
    end
end

Citizen.CreateThread(function()
    if not LocalPlayer.state.IsInSession then
        repeat Wait(500) until LocalPlayer.state.IsInSession and LocalPlayer.state.Character and not IsLoadingScreenVisible() and not IsScreenFadedOut()
    end
    loadPrompts()
    loadBlip()
    local startCoords = Config.startCoords
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - startCoords)
        if dist < 20.0 and not raceStarted then
            drawMarkerOn = true
        else
            drawMarkerOn = false
        end
        if dist < 2.0 and not raceStarted then
            wait = 0
            PromptSetActiveGroupThisFrame(promptGroup, Config.promptGroupName)
            if not isRegistered then
                PromptSetEnabled(registerPrompt, true)
                PromptSetEnabled(startPrompt, false)
                if Citizen.InvokeNative(0xC92AC953F0A982AE, registerPrompt) then
                    if Config.bringOwnMount then
                        local mount = GetMount(ped)
                        if mount and DoesEntityExist(mount) then
                            TriggerServerEvent('moro_race:register')
                            isRegistered = true
                            Config.notification({
                                message = Config.messages.registerSuccess,
                                duration = 5000,
                                label = Config.promptGroupName,
                            })
                        else
                            Config.notification({
                                message = Config.messages.missingMount,
                                duration = 5000,
                                label = Config.promptGroupName,
                            })
                        end
                    else
                        TriggerServerEvent('moro_race:register')
                        isRegistered = true
                        Config.notification({
                            message = Config.messages.registerSuccess,
                            duration = 5000,
                            label = Config.promptGroupName,
                        })
                    end
                end
            else
                PromptSetEnabled(registerPrompt, false)
                PromptSetEnabled(startPrompt, true)
                if Citizen.InvokeNative(0xC92AC953F0A982AE, startPrompt) then
                    if Config.bringOwnMount then
                        local mount = GetMount(ped)
                        if not mount or not DoesEntityExist(mount) then
                            Config.notification({
                                message = Config.messages.missingMount,
                                duration = 5000,
                                label = Config.promptGroupName,
                            })
                        else
                            TriggerServerEvent('moro_race:initiateRace')
                        end
                    else
                        TriggerServerEvent('moro_race:initiateRace')
                    end
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('moro_race:startRace')
AddEventHandler('moro_race:startRace', function(savedCheckpoints, spawnIndex, totalParticipants)
    local playerPed = PlayerPedId()
    if Config.bringOwnMount then
        local mount = GetMount(playerPed)
        if not mount or not DoesEntityExist(mount) then
            Config.notification({
                message = Config.messages.missingMount,
                duration = 5000,
                label = Config.promptGroupName,
            })
            TriggerServerEvent('moro_race:playerMissingMount')
            return
        end
    end
    raceStarted = true
    isRegistered = false
    passedCheckpoints = savedCheckpoints or {}
    nextCheckpoint = getNextCheckpointId(passedCheckpoints)
    timeoutTriggered = false
    raceStartTime = 0
    local spawnCoords, spawnHeading = calculateStartData(spawnIndex, totalParticipants)
    spawnedRaceMount = false
    if not Config.bringOwnMount then
        local model = Config.mountType or `a_c_donkey_01`
        if type(model) == 'string' then
            model = joaat(model)
        end
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end
        if raceMount and DoesEntityExist(raceMount) then
            DeleteEntity(raceMount)
        end
        raceMount = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, spawnHeading, true, true, true, true)
        TaskMountAnimal(playerPed, raceMount, 1000, -1, 2.0, 1, 0, 0)
        SetRandomOutfitVariation(raceMount, true)
        PlaceEntityOnGroundProperly(raceMount)
        SetEntityHeading(raceMount, spawnHeading)
        SetEntityHeading(playerPed, spawnHeading)
        SetModelAsNoLongerNeeded(model)
        spawnedRaceMount = true
    else
        raceMount = GetMount(playerPed)
        if raceMount and DoesEntityExist(raceMount) then
            SetEntityCoords(raceMount, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, false, false, false, true)
            SetEntityHeading(raceMount, spawnHeading)
            PlaceEntityOnGroundProperly(raceMount)
            if not IsPedOnMount(playerPed) then
                TaskMountAnimal(playerPed, raceMount, 1000, -1, 2.0, 1, 0, 0)
            end
            SetEntityCoords(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
            SetEntityHeading(playerPed, spawnHeading)
        end
    end
    createCheckpointArrows(nextCheckpoint)
    startRaceTimeoutWatcher()
    local actualHorse = raceMount or GetMount(PlayerPedId())
    if actualHorse and DoesEntityExist(actualHorse) then
        local freezeDuration = 3000
        FreezeEntityPosition(actualHorse, true)
        SetTimeout(freezeDuration, function()
            FreezeEntityPosition(actualHorse, false)
        end)
    end
    local freezeDuration = 3000
    TriggerEvent('moro_race:startCountDown')
    FreezeEntityPosition(playerPed, true)
    if actualHorse and DoesEntityExist(actualHorse) then
        FreezeEntityPosition(actualHorse, true)
    end
    SetTimeout(freezeDuration, function()
        FreezeEntityPosition(playerPed, false)
        if actualHorse and DoesEntityExist(actualHorse) then
            FreezeEntityPosition(actualHorse, false)
        end
        Config.notification({
            message = Config.messages.raceStarting,
            duration = 5000,
            label = Config.promptGroupName,
        })
    end)
    Citizen.CreateThread(function()
        while raceStarted do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            if Config.raceCoords[nextCheckpoint] and Config.raceCoords[nextCheckpoint].arrows then
                for arrowIndex, data in pairs(Config.raceCoords[nextCheckpoint].arrows) do
                    local arrowCoords = vector3(data.coords.x, data.coords.y, data.coords.z)
                    if #(playerCoords - arrowCoords) < 80.0 then
                        if not (arrows[nextCheckpoint] and arrows[nextCheckpoint][arrowIndex]) then
                            createArrow(nextCheckpoint, arrowIndex)
                        end
                    elseif arrows[nextCheckpoint] and arrows[nextCheckpoint][arrowIndex] then
                        deleteArrow(nextCheckpoint, arrowIndex)
                    end
                end
            end
            if Config.raceCoords[nextCheckpoint] then
                local data = Config.raceCoords[nextCheckpoint].coords
                if raceStarted and data then
                    local fireRingCoords = vector3(data.x, data.y, data.z)
                    if #(playerCoords - fireRingCoords) < 80.0 then
                        if not fireRings[nextCheckpoint] then
                            createFireRing(nextCheckpoint)
                        end
                    elseif fireRings[nextCheckpoint] then
                        deleteFireRing(nextCheckpoint)
                    end
                else
                    for index in pairs(fireRings) do
                        deleteFireRing(index)
                    end
                end
            end
            Wait(1000)
        end
    end)
    Citizen.CreateThread(function()
        while raceStarted do
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            if Config.raceCoords[nextCheckpoint] then
                local data = Config.raceCoords[nextCheckpoint].coords
                if data then
                    local checkpointCoords = vector3(data.x, data.y, data.z)
                    if #(coords - checkpointCoords) < 5.0 then
                        TriggerServerEvent('moro_race:checkpoint', nextCheckpoint)
                    end
                end
            end
            Wait(100)
        end
    end)
end)

RegisterNetEvent('moro_race:startCountDown')
AddEventHandler('moro_race:startCountDown', function()
    SendNUIMessage({
        action = 'showCountdown',
    })
    Citizen.InvokeNative(0x0F2A2175734926D8, "321_GO", "RDRO_Race_sounds")
    Citizen.InvokeNative(0x0F2A2175734926D8, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET")
    PlaySoundFrontend("321_GO", "RDRO_Race_sounds", true, 0)
    Wait(3000)
    PlaySoundFrontend("CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true, 0)
    startTimer()
end)


RegisterNetEvent('moro_race:stopRace')
AddEventHandler('moro_race:stopRace', function(reason)
    local timedOut = reason == 'timeout'
    local wasRacing = raceStarted
    raceStarted = false
    nextCheckpoint = 1
    passedCheckpoints = {}
    isRegistered = false
    timeoutTriggered = false
    raceStartTime = 0
    stopTimer()
    if timedOut and wasRacing and Config.messages and Config.messages.raceTimeout then
        Config.notification({
            message = Config.messages.raceTimeout,
            duration = 5000,
            label = Config.promptGroupName,
        })
    end
    if spawnedRaceMount and raceMount and DoesEntityExist(raceMount) then
        DeleteEntity(raceMount)
    end
    raceMount = nil
    spawnedRaceMount = false
    for index in pairs(fireRings) do
        deleteFireRing(index)
    end
    fireRings = {}
    for checkpointIndex, arrowGroup in pairs(arrows) do
        for arrowIndex in pairs(arrowGroup) do
            deleteArrow(checkpointIndex, arrowIndex)
        end
    end
    arrows = {}
end)

RegisterNetEvent('moro_race:checkpointPassed')
AddEventHandler('moro_race:checkpointPassed', function(id)
    if not passedCheckpoints[id] then
        passedCheckpoints[id] = true
        deleteFireRing(id)
        deleteCheckpointArrows(id)
        if id == nextCheckpoint then
            nextCheckpoint = nextCheckpoint + 1
            createCheckpointArrows(nextCheckpoint)
        end
    end
    Citizen.InvokeNative(0x0F2A2175734926D8, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET');
    PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 0)
    if id == #Config.raceCoords then
        local total = (GetGameTimer() - raceStartTime) / 1000
        stopTimer()
        Config.notification({
            message = Config.messages.raceFinished:format(total),
            duration = 5000,
            label = Config.promptGroupName,
        })
        if spawnedRaceMount then
            TaskDismountAnimal(PlayerPedId(), 0, 0, 0, 0, 0)
            Wait(3000)
            if raceMount and DoesEntityExist(raceMount) then
                DeleteEntity(raceMount)
            end
        end
        raceMount = nil
        spawnedRaceMount = false
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        raceStarted = false
        nextCheckpoint = 1
        passedCheckpoints = {}
        isRegistered = false
        timeoutTriggered = false
        raceStartTime = 0
        stopTimer()
        if spawnedRaceMount and raceMount and DoesEntityExist(raceMount) then
            DeleteEntity(raceMount)
        end
        raceMount = nil
        spawnedRaceMount = false
        for index in pairs(fireRings) do
            deleteFireRing(index)
        end
        fireRings = {}
        for checkpointIndex, arrowGroup in pairs(arrows) do
            for arrowIndex in pairs(arrowGroup) do
                deleteArrow(checkpointIndex, arrowIndex)
            end
        end
        arrows = {}
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
            blip = nil
        end
    end
end)

if Config.devMode then
    RegisterCommand('addCp', function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local snippet = string.format("{ coords = vector4(%.2f, %.2f, %.2f, %.2f), arrows = {} },", coords.x, coords.y, coords.z, heading)
        print(snippet)
    end)

    RegisterCommand('addArrow', function(source, args)
        local direction = args[1]
        if direction ~= 'left' and direction ~= 'right' then
            print('You must set an arrow direction')
            return
        end
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local pitch = direction == 'left' and 90.0 or -90.0
        local snippet = string.format("{ coords = vector4(%.2f, %.2f, %.2f, %.2f), pitch = %.1f, roll = 0.0 },", coords.x, coords.y, coords.z, heading, pitch)
        print(snippet)
    end)
end
