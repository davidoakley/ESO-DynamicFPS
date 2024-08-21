FPSManager = {
  name = "FPSManager",           -- Matches folder and Manifest file names.
  version = "0.1.0",                -- A nuisance to match to the Manifest.
  author = "SirNightstorm",
  color = "DDFFEE",             -- Used in menu titles and so on.
  menuName = "FPS Manager",          -- A UNIQUE identifier for menu object.
  svName = "FPSManager_SavedVariables",
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
  afkDelay = 180,

  showAlerts = false
}

local logger = LibDebugLogger(FPSManager.name)
FPSManager.logger = logger

local ACTIVE_CHECK_DELAY_MS = 1000
local IDLE_CHECK_DELAY_MS = 200

-- local currentFPS = 0
local currentState = nil

---@type number
local lastActiveTime = 0

local hasFocus = true
local isInCombat = false
local isInDialog = false

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

function FPSManager.ForceUpdateState()
  currentState = nil
end

function FPSManager.UpdateState()
  local state
  local gameTime = GetGameTimeSeconds()

  if isInCombat then
    state = "combat"
  elseif gameTime < lastActiveTime + FPSManager.savedVars.idleDelay or
         (isInDialog and gameTime < lastActiveTime + FPSManager.savedVars.afkDelay) then
    state = "active"
  elseif gameTime < lastActiveTime + FPSManager.savedVars.afkDelay then
    state = "idle"
  else
    state = "afk"
  end

  FPSManager.SetState(state)
end

---Update FPSManager.currentState, and make any necessary game setting changes
---@param state string The state to update to
function FPSManager.SetState(state)
  if state ~= currentState then
    local newFPS
    local newDelayMS
    local colour
  
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
  
    EVENT_MANAGER:UnregisterForUpdate(FPSManager.name.."_CheckIdle")
    SetCVar("MinFrameTime.2", ""..(1 / newFPS))
    ZO_PerformanceMetersFramerateMeterLabel:SetColor(colour:UnpackRGB())
    if newDelayMS > 0 then
      logger:Debug("FPSManager: Setting FPS to "..state..": "..newFPS.."fps, idle check every "..newDelayMS.."ms")
      EVENT_MANAGER:RegisterForUpdate(FPSManager.name.."_Update", newDelayMS, FPSManager.Update)
    else
      logger:Debug("FPSManager: Setting FPS to "..state..": "..newFPS.."fps")
    end

    if FPSManager.savedVars.showAlerts then
      ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, "FPSManager: "..ucFirst(state))
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

  local gameTime = GetGameTimeSeconds()
  if not isPlayerIdle() then
    logger:Debug("FPSManager: not idle")
    lastActiveTime = gameTime
  else
    logger:Debug("FPSManager: Idle "..(gameTime - lastActiveTime).."s")
  end
  FPSManager.UpdateState()
end

local function onCombatState(_, inCombat)
  isInCombat = inCombat
  lastActiveTime = GetGameTimeSeconds()
  FPSManager.SetActive()
end

local function onDialogBegin(_, optionCount)
  isInDialog = true
  logger:Debug("FPSManager: onDialogBegin "..optionCount)
  FPSManager.SetActive()
end

local function onDialogEnd(_)
  isInDialog = false
  logger:Debug("FPSManager: onDialogEnd")
  FPSManager.SetActive()
end

local function onDialogUpdate(_)
  logger:Debug("FPSManager: onDialogUpdate")
  FPSManager.SetActive()
end

local function setActiveOnEvent(eventName, event)
  EVENT_MANAGER:RegisterForEvent(FPSManager.name..eventName, event, function()
    -- logger:Debug("FPSManager: event "..eventName)
    FPSManager.SetActive()
  end)
end

local function initialise()
  FPSManager.savedVars = ZO_SavedVars:NewAccountWide(FPSManager.svName, 1, nil, defaultSavedVars)

  logger:Info("FPSManager initialising")

  -- Settings menu in Settings.lua.
  FPSManager.LoadSettings()

  FPSManager.SetActive()

  EVENT_MANAGER:RegisterForEvent(FPSManager.name.."_Combat", EVENT_PLAYER_COMBAT_STATE, onCombatState)

	EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_CHATTER_BEGIN, onDialogBegin)
	EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_CONVERSATION_UPDATED, onDialogUpdate)
	EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_QUEST_OFFERED, onDialogUpdate)
	EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_QUEST_COMPLETE_DIALOG, onDialogUpdate)
	EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_CHATTER_END, onDialogEnd)

  setActiveOnEvent("PlayerActivated", EVENT_PLAYER_ACTIVATED)
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
