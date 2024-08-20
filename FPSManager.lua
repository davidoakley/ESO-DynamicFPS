FPSManager = {
  name            = "FPSManager",           -- Matches folder and Manifest file names.
  -- version         = "1.0",                -- A nuisance to match to the Manifest.
  author          = "SirNightstorm",
  color           = "DDFFEE",             -- Used in menu titles and so on.
  menuName        = "FPS Manager",          -- A UNIQUE identifier for menu object.
  svName          = "FPSManager_SavedVariables",
}

-- Default settings.
local defaultSavedVars = {
  -- firstLoad = true,                   -- First time the addon is loaded ever.
  -- accountWide = false,                -- Load settings from account savedVars, instead of character.
  activeFPS = 60,
  combatFPS = 165,
  idleFPS = 30,
  afkFPS = 10,

  idleDelay = 30,
  afkDelay = 180
}

local logger = LibDebugLogger(FPSManager.name)
FPSManager.logger = logger

local ACTIVE_CHECK_DELAY_MS = 1000
local IDLE_CHECK_DELAY_MS = 200

-- local currentFPS = 0
local currentState = nil
local idleTimeMS = 0 -- TODO: Use GetGameTimeSeconds()
local hasFocus = true
local isInCombat = false

function FPSManager.SetActive()
  idleTimeMS = 0
  FPSManager.UpdateState()
end

function FPSManager.ForceUpdateState()
  currentState = nil
end

function FPSManager.UpdateState()
  local state

  if isInCombat then
    state = "combat"
  elseif idleTimeMS < FPSManager.savedVars.idleDelay*1000 then
    state = "active"
  else
    state = "idle"
  end

  FPSManager.SetState(state)
end

function FPSManager.SetState(state)
  if state ~= currentState then
    local newFPS
    local newDelayMS
    local r, g, b, a = 1, 1, 1, 1
  
    if state == "combat" then
      newFPS = FPSManager.savedVars.combatFPS
      newDelayMS = 0
      r, g, b = 1, 0.5, 0.5
    elseif state == "active" then
      newFPS = FPSManager.savedVars.activeFPS
      newDelayMS = ACTIVE_CHECK_DELAY_MS
      r, g, b, a = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    elseif state == "idle" then
      newFPS = FPSManager.savedVars.idleFPS
      newDelayMS = IDLE_CHECK_DELAY_MS
      r, g, b = 0.75, 1, 0.65
    end
  
    EVENT_MANAGER:UnregisterForUpdate(FPSManager.name.."_CheckIdle")
    SetCVar("MinFrameTime.2", ""..(1 / newFPS))
    ZO_PerformanceMetersFramerateMeterLabel:SetColor(r, g, b, a)
    if newDelayMS > 0 then
      logger:Debug("FPSManager: Setting FPS to "..state..": "..newFPS.."fps, idle check every "..newDelayMS.."ms")
      EVENT_MANAGER:RegisterForUpdate(FPSManager.name.."_Update", newDelayMS, FPSManager.Update)
    else
      logger:Debug("FPSManager: Setting FPS to "..state..": "..newFPS.."fps")
    end
    -- currentFPS = newFPS
    currentState = state
  end
end

local x_old, y_old, h_old = GetMapPlayerPosition("player")
local heading_old = GetPlayerCameraHeading()
function FPSManager.Update()
  -- logger:Debug("FPSManager: IdleCheck")

  local function isPlayerIdle()
      -- Check if in combat
      if IsUnitInCombat("player") then return false end

      if not hasFocus then return true end

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

  if not isPlayerIdle() then
    --logger:Debug("FPSManager: not idle")
    idleTimeMS = 0
  else
    idleTimeMS = idleTimeMS + ACTIVE_CHECK_DELAY_MS
    logger:Debug("FPSManager: Idle "..idleTimeMS.."ms")
  end
  FPSManager.UpdateState()
end

local function onCombatState(_, inCombat)
  isInCombat = inCombat
  idleTimeMS = 0
  FPSManager.SetActive()
end

local function setActiveOnEvent(eventName, event)
  EVENT_MANAGER:RegisterForEvent(FPSManager.name..eventName, event, FPSManager.SetActive)
end

local function initialise()
  FPSManager.savedVars = ZO_SavedVars:NewAccountWide(FPSManager.svName, 1, nil, defaultSavedVars)

  logger:Info("FPSManager initialising")

  -- Settings menu in Settings.lua.
  FPSManager.LoadSettings()

  FPSManager.SetActive()

  EVENT_MANAGER:RegisterForEvent(FPSManager.name.."_Combat", EVENT_PLAYER_COMBAT_STATE, onCombatState)

  setActiveOnEvent("UIMovement", EVENT_NEW_MOVEMENT_IN_UI_MODE)
  setActiveOnEvent("MouseDown", EVENT_GLOBAL_MOUSE_DOWN)
  setActiveOnEvent("MouseUp", EVENT_GLOBAL_MOUSE_UP)
  setActiveOnEvent("LayerPopped", EVENT_ACTION_LAYER_POPPED)
  setActiveOnEvent("LayerPushed", EVENT_ACTION_LAYER_PUSHED)
  setActiveOnEvent("EndFastTravel", EVENT_END_FAST_TRAVEL_INTERACTION)
  setActiveOnEvent("EndFastTravelKeep", EVENT_END_FAST_TRAVEL_KEEP_INTERACTION)
  setActiveOnEvent("ClientInteract", EVENT_CLIENT_INTERACT_RESULT)
end

function FPSManager.OnAddOnLoaded(_, addonName)
  -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
  if addonName ~= FPSManager.name then return end

  initialise()
  --unregister the event again as our addon was loaded now and we do not need it anymore to be run for each other addon that will load
  EVENT_MANAGER:UnregisterForEvent(FPSManager.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_ADD_ON_LOADED, FPSManager.OnAddOnLoaded)
