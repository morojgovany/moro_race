Config = {}
Config.devMode = false -- set to true for debug prints and auto copy in clipboard
Config.bringOwnMount = false -- set to true if players bring their own mount (must mount it to begin)
Config.mountType = `a_c_donkey_01` -- must be set if bringOwnMount is false
-- Use /addCp to copy the config coords to clipboard (also shows in console if devMode is true)
-- Use `/addArrow f` or `/addArrow b` (for backward and forward arrow) to add arrows to a checkpoint
-- You can set as many checkpoints/arrows as you want
Config.raceCoords = {
    [1] = {coords = vector4(-6236.54, -3798.51, -18.12, 129.61), arrows = {
        { coords = vector4(-6230.55, -3799.56, -17.64, 125.82), pitch = 90.0, roll = 0.0 },
    }},
    [2] = { coords = vector4(-6265.50, -3812.26, -25.50, 97.10), arrows = {
        { coords = vector4(-6253.86, -3813.85, -23.31, 284.49), pitch = -90.0, roll = 0.0 },
        { coords = vector4(-6254.59, -3805.47, -22.38, 128.13), pitch = 90.0, roll = 0.0 },
    } },
    [3] = { coords = vector4(-6223.66, -3788.67, -17.46, 310.75), arrows = {
        { coords = vector4(-6249.28, -3812.46, -22.09, 108.15), pitch = -90.0, roll = 0.0 },
    } },
}

Config.playerLimit = 4 -- set to 0 for unlimited players
Config.fireOnFinish = false -- set to true to enable explosions on finish line
Config.fireOffset = 5.0 -- add explosion this many units on the left and right of the finish line
Config.raceTimeout = 300 -- Seconds before the race automatically ends (set to 0 to disable)
Config.startCoords = vector3(-6223.96, -3789.82, -17.44) -- prompt coords to register
Config.startSpacing = 2.5 -- distance between players at start
-- be careful / some keys are unavailable when on horse (if you set bringOwnMount to true)
Config.registerKey = 0xE30CD707 -- R
Config.startKey = 0xC7B5340A -- Enter
-- translations
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
-- notification function, change it to fit your notification system
Config.notification = function(data)
    if type(data) ~= 'table' then return end
    local message = data.message
    if not message then return end
    local duration = data.duration or 5000
    local label = data.label or Config.promptGroupName or 'Notification' -- if your systems needs labels
    if IsDuplicityVersion() then -- This is the server events
        local target = data.target
        if not target then
            target = -1 -- all players
            -- Change it by your notification system (server side)
            TriggerClientEvent('vorp:TipRight', target, message, 5000)
        end
    else
        -- Change it by your notification system (client side)
        TriggerEvent('vorp:TipRight', message, 5000)
    end
    return duration
end
-- blip config https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/useful_info_from_rpfs/textures/blips_mp/README.md
Config.blip = {
    enable = true,
    coords = Config.startCoords,
    sprite = `blip_mp_playlist_races`,
    scale = 0.8,
    color = `BLIP_MODIFIER_MP_COLOR_32`,
    name = "Race"
}
