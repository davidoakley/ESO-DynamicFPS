local logger = LibDebugLogger(FPSManager.name)

local function onCombatState(_, inCombat)
  FPSManager.isInCombat = inCombat
  FPSManager.lastActiveTime = GetGameTimeSeconds()
  FPSManager.SetActive()
end

local function onDialogBegin(_, optionCount)
  FPSManager.isInDialog = true
  FPSManager.logger:Debug("FPSManager: onDialogBegin "..optionCount)
  FPSManager.SetActive()
end

local function onDialogEnd(_)
  FPSManager.isInDialog = false
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

local function onLogout(_)
  logger:Info("FPSManager: onLogout; restoring MinFrameTime to "..FPSManager.originalMinFrameTime)
  FPSManager.paused = true
  SetCVar("MinFrameTime.2", ""..FPSManager.originalMinFrameTime)
end

local function onLogoutCanceled(_)
  logger:Info("FPSManager: onLogoutCanceled")
  FPSManager.paused = false
  FPSManager.SetActive()
end

function FPSManager.RegisterCallbacks()
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

  ZO_PreHook("Logout", onLogout)
  ZO_PreHook("Quit", onLogout)
  ZO_PreHook("CancelLogout", onLogoutCanceled)
end
