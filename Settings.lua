-- Settings menu.
local logger = LibDebugLogger(FPSManager.name)

function FPSManager.LoadSettings()
  local LAM = LibAddonMenu2
  local sv = FPSManager.savedVars
  if sv == nil then return end

  local panelData = {
    type = "panel",
    name = FPSManager.menuName,
    displayName = FPSManager.menuName, -- FPSManager.Colorize(FPSManager.menuName),
    author = FPSManager.author, -- FPSManager.Colorize(FPSManager.author, "AAF0BB"),
    version = FPSManager.version,
    -- slashCommand = "/fpsmanager",
    registerForRefresh = true,
    registerForDefaults = true,
  }
  FPSManager.settingsPanel = LAM:RegisterAddonPanel(FPSManager.menuName, panelData)

  local optionsTable = {}

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = "Enable dynamic FPS",
      tooltip = "Enable to dynamically alter your monitor's refresh rate. Disable to keep it fixed.",
      getFunc = function() return FPSManager.savedVars.enabled end,
      setFunc = function(value)
        sv.enabled = value
        FPSManager.OnEnabledChanged(value)
        end,
      width = "full", --or "half",
      requiresReload = false,
    }
  )

  table.insert(optionsTable, {
    type = "slider",
    name = "Static FPS",
    tooltip = "Refresh rate when Dynamic FPS is disabled",
    disabled = function() return sv.enabled end,
    min = 30,
    max = 240,
    step = 5,	--(optional)
    getFunc = function() return sv.fixedFPS end,
    setFunc = function(value)
      sv.fixedFPS = value
      if not sv.enabled then
        logger:Info("FPSManager setting to fixed "..sv.fixedFPS.."fps")
        SetCVar("MinFrameTime.2", ""..(1 / sv.fixedFPS))
      end
    end,
    width = "full",	--or "half" (optional)
    default = 100,	--(optional)
  })

  local disabledFunc = function() return not sv.enabled end

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
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "slider",
    name = "Combat FPS",
    tooltip = "FPS when in combat",
    min = 10,
    max = 240,
    step = 5,	--(optional)
    getFunc = function() return sv.combatFPS end,
    setFunc = function(value) sv.combatFPS = value end,
    width = "full",	--or "half" (optional)
    default = 60,	--(optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "slider",
    name = "Active FPS",
    tooltip = "FPS when active but not in combat",
    min = 10,
    max = 240,
    step = 5,	--(optional)
    getFunc = function() return sv.activeFPS end,
    setFunc = function(value) sv.activeFPS = value end,
    width = "full",	--or "half" (optional)
    default = 60,	--(optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "slider",
    name = "Idle FPS",
    tooltip = "FPS when inactive",
    min = 10,
    max = 240,
    step = 5,	--(optional)
    getFunc = function() return sv.idleFPS end,
    setFunc = function(value) sv.idleFPS = value end,
    width = "full",	--or "half" (optional)
    default = 30,	--(optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "slider",
    name = "AFK FPS",
    tooltip = "FPS when away from keyboard",
    min = 10,
    max = 240,
    step = 5,	--(optional)
    getFunc = function() return sv.afkFPS end,
    setFunc = function(value) sv.afkFPS = value end,
    width = "full",	--or "half" (optional)
    default = 10,	--(optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "header",
    name = ZO_HIGHLIGHT_TEXT:Colorize("Idle Timeouts"),
    width = "full",	--or "half" (optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "description",
    -- title = "Idle Timeouts",	--(optional)
    title = nil,	--(optional)
    text = "Choose how long before FPS Manager will switch your game to a lower FPS",
    width = "full",	--or "half" (optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "slider",
    name = "Idle Timeout (seconds)",
    tooltip = "Time inactive before entering the Idle state",
    min = 15,
    max = 20*60,
    step = 15,	--(optional)
    getFunc = function() return sv.idleDelay end,
    setFunc = function(value) sv.idleDelay = value end,
    width = "full",	--or "half" (optional)
    default = 30,	--(optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "slider",
    name = "AFK Timeout (seconds)",
    tooltip = "Time inactive before entering the AFK (away from keyboard) state",
    min = 60,
    max = 20*60,
    step = 15,	--(optional)
    getFunc = function() return sv.afkDelay end,
    setFunc = function(value) sv.afkDelay = value end,
    width = "full",	--or "half" (optional)
    default = 60,	--(optional)
    disabled = disabledFunc
  })

  table.insert(optionsTable, {
    type = "header",
    name = ZO_HIGHLIGHT_TEXT:Colorize("Other Settings"),
    width = "full",	--or "half" (optional)
    disabled = disabledFunc
  })

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = "Show alerts",
      tooltip = "Show an alert in the top-right corner of the screen when FPSManager's state changes",
      getFunc = function() return sv.showAlerts end,
      setFunc = function(value) sv.showAlerts = value end,
      width = "full", --or "half",
      requiresReload = false,
      disabled = disabledFunc
    }
  )

  LAM:RegisterOptionControls(FPSManager.menuName, optionsTable)
end
