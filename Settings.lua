-- Settings menu.
function FPSManager.LoadSettings()
    local LAM = LibAddonMenu2

    local panelData = {
        type = "panel",
        name = FPSManager.menuName,
        displayName = FPSManager.menuName, -- FPSManager.Colorize(FPSManager.menuName),
        author = FPSManager.author, -- FPSManager.Colorize(FPSManager.author, "AAF0BB"),
        version = FPSManager.version,
        slashCommand = "/fpsmanager",
        registerForRefresh = true,
        registerForDefaults = true,
    }
    LAM:RegisterAddonPanel(FPSManager.menuName, panelData)

    local optionsTable = {}

    table.insert(optionsTable, {
        type = "header",
        name = ZO_HIGHLIGHT_TEXT:Colorize("Monitor Refresh Rate"),
        width = "full",	--or "half" (optional)
    })

    table.insert(optionsTable, {
        type = "description",
        title = nil,	--(optional)
        text = "Choose a refresh rate (FPS) for each game state. 60fps is standard for PC gaming, but your monitor may support higher values.",
        width = "full",	--or "half" (optional)
    })

    table.insert(optionsTable, {
        type = "slider",
        name = "Combat FPS",
        tooltip = "FPS when in combat",
        min = 10,
        max = 240,
        step = 5,	--(optional)
        getFunc = function() return FPSManager.savedVars.combatFPS end,
        setFunc = function(value) FPSManager.savedVars.combatFPS = value end,
        width = "full",	--or "half" (optional)
        default = 60,	--(optional)
    })

    table.insert(optionsTable, {
        type = "slider",
        name = "Active FPS",
        tooltip = "FPS when active but not in combat",
        min = 10,
        max = 240,
        step = 5,	--(optional)
        getFunc = function() return FPSManager.savedVars.activeFPS end,
        setFunc = function(value) FPSManager.savedVars.activeFPS = value end,
        width = "full",	--or "half" (optional)
        default = 60,	--(optional)
    })

    table.insert(optionsTable, {
        type = "slider",
        name = "Idle FPS",
        tooltip = "FPS when inactive",
        min = 10,
        max = 240,
        step = 5,	--(optional)
        getFunc = function() return FPSManager.savedVars.idleFPS end,
        setFunc = function(value) FPSManager.savedVars.idleFPS = value end,
        width = "full",	--or "half" (optional)
        default = 30,	--(optional)
    })

    table.insert(optionsTable, {
        type = "slider",
        name = "AFK FPS",
        tooltip = "FPS when away from keyboard",
        min = 10,
        max = 240,
        step = 5,	--(optional)
        getFunc = function() return FPSManager.savedVars.afkFPS end,
        setFunc = function(value) FPSManager.savedVars.afkFPS = value end,
        width = "full",	--or "half" (optional)
        default = 10,	--(optional)
    })

    table.insert(optionsTable, {
        type = "header",
        name = ZO_HIGHLIGHT_TEXT:Colorize("Idle Timeouts"),
        width = "full",	--or "half" (optional)
    })

    table.insert(optionsTable, {
        type = "description",
        -- title = "Idle Timeouts",	--(optional)
        title = nil,	--(optional)
        text = "Choose how long before FPS Manager will switch your game to a lower FPS",
        width = "full",	--or "half" (optional)
    })

    table.insert(optionsTable, {
        type = "slider",
        name = "Idle Timeout (seconds)",
        tooltip = "Time inactive before entering the Idle state",
        min = 15,
        max = 20*60,
        step = 15,	--(optional)
        getFunc = function() return FPSManager.savedVars.idleDelay end,
        setFunc = function(value) FPSManager.savedVars.idleDelay = value end,
        width = "full",	--or "half" (optional)
        default = 30,	--(optional)
    })

    table.insert(optionsTable, {
        type = "slider",
        name = "AFK Timeout (seconds)",
        tooltip = "Time inactive before entering the AFK (away from keyboard) state",
        min = 60,
        max = 20*60,
        step = 15,	--(optional)
        getFunc = function() return FPSManager.savedVars.afkDelay end,
        setFunc = function(value) FPSManager.savedVars.afkDelay = value end,
        width = "full",	--or "half" (optional)
        default = 60,	--(optional)
    })

    table.insert(optionsTable, {
        type = "header",
        name = ZO_HIGHLIGHT_TEXT:Colorize("Other Settings"),
        width = "full",	--or "half" (optional)
    })

    table.insert(
        optionsTable,
        {
            type = "checkbox",
            name = "Show alerts",
            tooltip = "Show an alert in the top-right corner of the screen when FPSManager's state changes",
            getFunc = function() return FPSManager.savedVars.showAlerts end,
            setFunc = function(value) FPSManager.savedVars.showAlerts = value end,
            width = "full", --or "half",
            requiresReload = false,
        }
    )

    LAM:RegisterOptionControls(FPSManager.menuName, optionsTable)
end
