Config = {}
Config.devMode = false
Config.bringOwnMount = false
Config.mountType = `a_c_donkey_01`
Config.raceTimeout = 300 -- Seconds before the race automatically ends (set to 0 to disable)
Config.startCoords = vector3(1969.41, -4741.98, 41.94)
Config.startSpacing = 2.5
Config.registerKey = 0xDFF812F9 -- E
Config.startKey = 0x760A9C6F -- G
Config.prompts = {
    register = "Register",
    start = "Start race",
}
Config.promptGroupName = "Race"
Config.messages = {
    registerSuccess = "Tu es inscrit à la course",
    missingMount = "Tu dois être sur une monture pour participer",
    raceStarting = "La course commence !",
    raceFinished = "Tu as terminé la course. Temps: %.2f secondes",
    raceWinner = "La course est terminée ! %s est le vainqueur !",
    raceTimeout = "Le temps imparti est écoulé, la course est terminée.",
}
Config.notification = function(data)
    if type(data) ~= 'table' then return end
    local message = data.message
    if not message then return end
    local duration = data.duration or 5000
    local label = data.label or Config.promptGroupName or 'Notification'
    if IsDuplicityVersion() then -- This is the server events
        local target = data.target
        if target then
            -- Change it by your notification system (server side)
            TriggerClientEvent('vorp:TipRight', message, 5000)
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
Config.raceCoords = {
    [1] = {
        coords = vector4(1944.81, -4718.91, 42.95, 58.07),
        arrows = {}
    },
    [2] = {
        coords = vector4(1903.03, -4694.57, 45.82, 20.72),
        arrows = {
            {
                coords = vector4(1926.01, -4711.40, 43.32, 77.24),
                pitch = 90.0,
                roll = 0.0
            },
            {
                coords = vector4(1902.80, -4709.25, 43.69, 10.43),
                pitch = 90.0,
                roll = 0.0
            },
        }
    },
}
