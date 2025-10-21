Config = {}
Config.devMode = true
Config.bringOwnMount = false
Config.raceCoords = {
    [1] = { coords = vector4(671.29, -77.04, 151.14, 332.98), arrows = {
        { coords = vector4(662.37, -103.65, 150.04, 331.56), pitch = 90.0, roll = 0.0 },
        }
    },
    [2] = {
        coords = vector4(650.45, -101.98, 149.87, 337.47),
        arrows = {
            { coords = vector4(667.92, -26.96, 153.51, 215.28), pitch = -90.0, roll = 0.0 },
        }
    },
}

Config.mountType = `a_c_donkey_01`
Config.playerLimit = 4
Config.fireOnFinish = true
Config.fireOffset = 5.0 -- add explosion this many units on the left and right of the finish line
Config.raceTimeout = 300 -- Seconds before the race automatically ends (set to 0 to disable)
Config.startCoords = vector3(660.39, -108.31, 149.95)
Config.startSpacing = 2.5
Config.registerKey = 0xE30CD707 -- R
Config.startKey = 0xC7B5340A -- Enter
Config.prompts = {
    register = "Register",
    start = "Start race",
}
Config.promptGroupName = "Race"
Config.messages = {
    registerSuccess = "You are registered",
    missingMount = "You must be on a mount to participate",
    raceStarting = "The race begins!",
    raceFinished = "You finished the race, time: %.2f seconds",
    raceWinner = "The race is over ! %s is the winner!",
    raceTimeout = "The time limit has been reached, the race is over.",
    mountTooFar = "Your horse is too far.",
    playerLimitReached = "The maximum number of participants has been reached.",
}
Config.notification = function(data)
    if type(data) ~= 'table' then return end
    local message = data.message
    if not message then return end
    local duration = data.duration or 5000
    local label = data.label or Config.promptGroupName or 'Notification' -- if your systems needs labels
    if IsDuplicityVersion() then -- This is the server events
        local target = data.target
        if target then
            -- Change it by your notification system (server side)
            TriggerClientEvent('vorp:TipRight', target, message, 5000)
        end
    else
        -- Change it by your notification system (client side)
        TriggerEvent('vorp:TipRight', message, 5000)
    end
    return duration
end
Config.blip = {
    enable = true,
    coords = Config.startCoords,
    sprite = `blip_mp_playlist_races`,
    scale = 0.8,
    color = `BLIP_MODIFIER_MP_COLOR_32`,
    name = "Race"
}
