FPSManager = {
  name = "FPSManager",           -- Matches folder and Manifest file names.
  version = "0.1.0",                -- A nuisance to match to the Manifest.
  author = "SirNightstorm",
  color = "DDFFEE",             -- Used in menu titles and so on.
  menuName = "FPS Manager",          -- A UNIQUE identifier for menu object.
  svName = "FPSManager_SavedVariables",

  isInCombat = false,
  isInDialog = false,
  hasFocus = true,
  paused = false,
  -- originalMinFrameTime = 0.01,
  callbacksRegistered =false,
  hooksRegistered = false,
}

-- Default settings.
local defaultSavedVars = {
  -- firstLoad = true,                   -- First time the addon is loaded ever.
  activeFPS = 60,
  combatFPS = 165,
  idleFPS = 30,
  afkFPS = 10,

  idleDelay = 30,
  afkDelay = 180,

  showAlerts = false,
  enabled = true,
  fixedFPS = nil
}
FPSManager.savedVars = defaultSavedVars

local logger = LibDebugLogger(FPSManager.name)
FPSManager.logger = logger

local ACTIVE_CHECK_DELAY_MS = 1000
local IDLE_CHECK_DELAY_MS = 200

-- local currentFPS = 0
local currentState = nil

---@type number
local lastActiveTime = 0

local activeLabelColour = ZO_TOOLTIP_DEFAULT_COLOR
local idleLabelColour = ZO_ColorDef:New("c0ffa6")
local afkLabelColour = ZO_ColorDef:New("66aaff")
local combatLabelColour = ZO_ColorDef:New("ff9966")

local function ucFirst(str)
  return (str:gsub("^%l", string.upper))
end

function FPSManager.SetActive()
  lastActiveTime = GetGameTimeSeconds()
  FPSManager.UpdateState()
end

function FPSManager.UpdateState()
  local state
  local inactiveTime = GetGameTimeSeconds() - lastActiveTime

  if FPSManager.isInCombat then
    state = "combat"
  elseif inactiveTime >= FPSManager.savedVars.afkDelay then
    state = "afk"
  elseif inactiveTime >= FPSManager.savedVars.idleDelay and not FPSManager.isInDialog then
    state = "idle"
  else
    state = "active"
  end

  FPSManager.SetState(state)
end

---Update FPSManager.currentState, and make any necessary game setting changes
---@param state string The state to update to
function FPSManager.SetState(state)
  if FPSManager.paused or not FPSManager.savedVars.enabled then return end

  if state ~= currentState then
    local newFPS
    local newDelayMS
    local colour = activeLabelColour
  
    if state == "combat" then
      newFPS = FPSManager.savedVars.combatFPS
      newDelayMS = 0
      colour = combatLabelColour
    elseif state == "active" then
      newFPS = FPSManager.savedVars.activeFPS
      newDelayMS = ACTIVE_CHECK_DELAY_MS
      colour = activeLabelColour
    elseif state == "idle" then
      newFPS = FPSManager.savedVars.idleFPS
      newDelayMS = IDLE_CHECK_DELAY_MS
      colour = idleLabelColour
    elseif state == "afk" then
      newFPS = FPSManager.savedVars.afkFPS
      newDelayMS = IDLE_CHECK_DELAY_MS
      colour = afkLabelColour
    end
  
    EVENT_MANAGER:UnregisterForUpdate(FPSManager.name.."_Update")
    SetCVar("MinFrameTime.2", ""..(1 / newFPS))
    ZO_PerformanceMetersFramerateMeterLabel:SetColor(colour:UnpackRGB())
    if newDelayMS > 0 then
      logger:Debug("Setting FPS to "..state..": "..newFPS.."fps, idle check every "..newDelayMS.."ms")
      EVENT_MANAGER:RegisterForUpdate(FPSManager.name.."_Update", newDelayMS, FPSManager.Update)
    else
      logger:Debug("Setting FPS to "..state..": "..newFPS.."fps")
    end

    if FPSManager.savedVars.showAlerts then
      ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, ucFirst(state))
    end
    -- currentFPS = newFPS
    currentState = state
  end
end

local x_old, y_old, h_old = GetMapPlayerPosition("player")
local heading_old = GetPlayerCameraHeading()
function FPSManager.Update()
  if FPSManager.paused or not FPSManager.savedVars.enabled then return end
  -- logger:Debug("Update")

  local function isPlayerIdle()
      -- Check if in combat
      if IsUnitInCombat("player") then return false end

      if not FPSManager.hasFocus then return true end

      -- Comparing current position and heading with data of last run
      local x_new, y_new, h_new = GetMapPlayerPosition("player")
      local heading_new = GetPlayerCameraHeading()

      if x_old == x_new and y_old == y_new and h_old == h_new and heading_new == heading_old then
          return true
      else
          x_old, y_old, h_old, heading_old = x_new, y_new, h_new, heading_new
          return false
      end
  end

  local gameTime = GetGameTimeSeconds()
  if not isPlayerIdle() then
    --logger:Debug("Not idle")
    lastActiveTime = gameTime
  else
    --logger:Debug("Idle "..(gameTime - lastActiveTime).."s")
  end
  FPSManager.UpdateState()
end

function FPSManager.OnEnabledChanged(enabled)
  if enabled then
    logger:Info("FPSManager enabling")
    FPSManager.SetActive()
    FPSManager.RegisterCallbacks()
  else
    logger:Info("FPSManager disabling")
    FPSManager.UnregisterCallbacks()
    EVENT_MANAGER:UnregisterForUpdate(FPSManager.name.."_CheckIdle")
    SetCVar("MinFrameTime.2", ""..(1 / FPSManager.savedVars.fixedFPS))
  end
end

local function onSlashCommand(extra)
  if extra == "on" or extra == "enable" then
    FPSManager.savedVars.enabled = true
  elseif extra == "off" or extra == "disable" then
    FPSManager.savedVars.enabled = false
  elseif extra == "" or extra == nil then
    LibAddonMenu2:OpenToPanel(FPSManager.settingsPanel)
  end
  FPSManager.OnEnabledChanged(FPSManager.savedVars.enabled)
end

local function initialise()
  FPSManager.savedVars = ZO_SavedVars:NewAccountWide(FPSManager.svName, 1, nil, defaultSavedVars)

  local originalMinFrameTime = GetCVar("MinFrameTime.2")
  if FPSManager.savedVars.enabled then
    logger:Info("FPSManager initialising")
  else
    logger:Info("FPSManager disabled - setting fixed "..FPSManager.savedVars.fixedFPS.."fps")
  end

  if FPSManager.savedVars.fixedFPS == nil then
    FPSManager.savedVars.fixedFPS = math.floor(1 / originalMinFrameTime + 0.5)
  end

  FPSManager.LoadSettings()

  FPSManager.OnEnabledChanged(FPSManager.savedVars.enabled)

  SLASH_COMMANDS["/fpsm"] = onSlashCommand
end

local function onAddOnLoaded(_, addonName)
  -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
  if addonName ~= FPSManager.name then return end

  initialise()

  --unregister the event again as our addon was loaded now and we do not need it anymore to be run for each other addon that will load
  EVENT_MANAGER:UnregisterForEvent(FPSManager.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_ADD_ON_LOADED, onAddOnLoaded)
