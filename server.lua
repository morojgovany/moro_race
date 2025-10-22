local raceStarted = false
local passedCheckpoints = {}
local raceWinnerAnnounced = false
local registeredPlayers = {}
local raceParticipants = {}
local totalParticipants = 0
local finishedParticipants = 0
local function resetRaceData()
    passedCheckpoints = {}
    raceParticipants = {}
    totalParticipants = 0
    finishedParticipants = 0
end

local function finalizeRace(reason)
    if raceStarted or totalParticipants > 0 then
        TriggerClientEvent('moro_race:stopRace', -1, reason)
    end
    raceStarted = false
    raceWinnerAnnounced = false
    resetRaceData()
    registeredPlayers = {}
end

local function checkRaceCompletion()
    if not raceStarted then
        return
    end
    if totalParticipants > 0 and finishedParticipants >= totalParticipants then
        finalizeRace('finished')
    end
end

local function markParticipantFinished(playerId)
    local participant = raceParticipants[playerId]
    if participant and not participant.finished then
        participant.finished = true
        finishedParticipants = finishedParticipants + 1
    end
end

local function startRaceForPlayers(playerIds)
    if raceStarted then
        return false
    end
    resetRaceData()
    local participants = {}
    for index = 1, #playerIds do
        local playerId = tonumber(playerIds[index])
        if playerId then
            participants[#participants + 1] = playerId
            raceParticipants[playerId] = { finished = false }
            passedCheckpoints[playerId] = passedCheckpoints[playerId] or {}
        end
    end
    totalParticipants = #participants
    if totalParticipants == 0 then
        resetRaceData()
        return false
    end
    raceStarted = true
    raceWinnerAnnounced = false
    finishedParticipants = 0
    for index, playerId in ipairs(participants) do
        TriggerClientEvent('moro_race:startRace', playerId, passedCheckpoints[playerId], index, totalParticipants)
    end
    registeredPlayers = {}
    return true
end

RegisterNetEvent('moro_race:register')
AddEventHandler('moro_race:register', function()
    local _source = source
    if not _source then
        return
    end
    if raceStarted then return end
    if Config.playerLimit and Config.playerLimit > 0 and #registeredPlayers >= Config.playerLimit then
        Config.notification({
            target = _source,
            message = Config.messages.playerLimitReached,
            duration = 5000,
            label = Config.promptGroupName,
        })
        return
    end
    for i = 1, #registeredPlayers do
        if registeredPlayers[i] == _source then
            return
        end
    end
    registeredPlayers[#registeredPlayers + 1] = _source
end)

RegisterNetEvent('moro_race:initiateRace')
AddEventHandler('moro_race:initiateRace', function()
    local _source = tonumber(source)
    if not _source or raceStarted then return end
    local isRegistered = false
    for i = 1, #registeredPlayers do
        if registeredPlayers[i] == _source then
            isRegistered = true
            break
        end
    end
    if not isRegistered then return end
    startRaceForPlayers(registeredPlayers)
end)

RegisterNetEvent('moro_race:checkpoint')
AddEventHandler('moro_race:checkpoint', function(id)
    local playerId = tonumber(source)
    if not playerId then return end
    local participant = raceParticipants[playerId]
    if not participant then return end
    passedCheckpoints[playerId] = passedCheckpoints[playerId] or {}
    if passedCheckpoints[playerId][id] then return end
    if not Config.raceCoords[id] then return end
    passedCheckpoints[playerId][id] = true
    TriggerClientEvent('moro_race:checkpointPassed', playerId, id)
    if id == #Config.raceCoords then
        if not raceWinnerAnnounced then
            local playerName = GetPlayerName(playerId) or 'Unknown' -- Adapt to your framework if needed
            Config.notification({
                message = Config.messages.raceWinner:format(playerName),
                duration = 5000,
                label = Config.promptGroupName,
            })
            raceWinnerAnnounced = true
        end
        markParticipantFinished(playerId)
        checkRaceCompletion()
    end
end)

RegisterNetEvent('moro_race:playerMissingMount')
AddEventHandler('moro_race:playerMissingMount', function()
    local playerId = tonumber(source)
    if not playerId then return end
    if raceParticipants[playerId] then
        markParticipantFinished(playerId)
        raceParticipants[playerId] = nil
        passedCheckpoints[playerId] = nil
        checkRaceCompletion()
    end
end)

RegisterNetEvent('moro_race:timeoutReached')
AddEventHandler('moro_race:timeoutReached', function()
    local playerId = tonumber(source)
    if not playerId or not raceStarted then
        return
    end
    if not raceParticipants[playerId] then
        return
    end
    finalizeRace('timeout')
end)

AddEventHandler('playerDropped', function()
    local _source = tonumber(source)
    if not _source then return end
    if raceStarted then
        markParticipantFinished(_source)
        checkRaceCompletion()
    else
        for index = #registeredPlayers, 1, -1 do
            if registeredPlayers[index] == _source then
                registeredPlayers[index] = registeredPlayers[#registeredPlayers]
                registeredPlayers[#registeredPlayers] = nil
                break
            end
        end
    end
end)
