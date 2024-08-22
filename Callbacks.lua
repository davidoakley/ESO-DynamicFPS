local logger = LibDebugLogger(FPSManager.name)

local function onCombatState(_, inCombat)
  FPSManager.isInCombat = inCombat
  FPSManager.lastActiveTime = GetGameTimeSeconds()
  FPSManager.SetActive()
end

local function onDialogBegin(_, optionCount)
  FPSManager.isInDialog = true
  logger:Debug("onDialogBegin "..optionCount)
  FPSManager.SetActive()
end

local function onDialogEnd(_)
  FPSManager.isInDialog = false
  logger:Debug("onDialogEnd")
  FPSManager.SetActive()
end

local function onDialogUpdate(_)
  logger:Debug("onDialogUpdate")
  FPSManager.SetActive()
end

local function setActiveOnEvent(eventName, event)
  EVENT_MANAGER:RegisterForEvent(FPSManager.name..eventName, event, function()
    logger:Debug("event "..eventName)
    FPSManager.SetActive()
  end)
end

local function onLogoutHook(_)
  if not FPSManager.savedVars.enabled then return end
  logger:Info("onLogout; restoring to "..FPSManager.savedVars.fixedFPS.."fps")
  FPSManager.paused = true
  SetCVar("MinFrameTime.2", ""..(1 / FPSManager.savedVars.fixedFPS))
end

local function onLogoutCanceledHook(_)
  if not FPSManager.savedVars.enabled then return end
  logger:Info("onLogoutCanceled")
  FPSManager.paused = false
  FPSManager.SetActive()
end

--- @return table
function FPSManager.GetCallbacks()
  local callbacks = {
    [EVENT_PLAYER_COMBAT_STATE] = { callback = onCombatState, name = "CombatState" },

    [EVENT_CHATTER_BEGIN] = { callback = onDialogBegin, name = "ChatterBegin" },
    [EVENT_CONVERSATION_UPDATED] = { callback = onDialogUpdate, name = "ConversationUpdated" },
    [EVENT_QUEST_OFFERED] = { callback = onDialogUpdate, name = "QuestOffered" },
    [EVENT_QUEST_COMPLETE_DIALOG] = { callback = onDialogUpdate, name = "QuestComplete" },
    [EVENT_CHATTER_END] = { callback = onDialogEnd, name = "ChatterEnd" },

    [EVENT_PLAYER_ACTIVATED] = { name = "PlayerActivated" },
    [EVENT_NEW_MOVEMENT_IN_UI_MODE] = { name = "UIMovement" },
    [EVENT_GLOBAL_MOUSE_DOWN] = { name = "MouseDown" },
    [EVENT_GLOBAL_MOUSE_UP] = { name = "MouseUp" },
    [EVENT_ACTION_LAYER_POPPED] = { name = "LayerPopped" },
    [EVENT_ACTION_LAYER_PUSHED] = { name = "LayerPushed" },
    [EVENT_END_FAST_TRAVEL_INTERACTION] = { name = "EndFastTravel" },
    [EVENT_END_FAST_TRAVEL_KEEP_INTERACTION] = { name = "EndFastTravelKeep" },
    [EVENT_CLIENT_INTERACT_RESULT] = { name = "ClientInteract" },
  }
  return callbacks
end

function FPSManager.RegisterCallbacks()
  if FPSManager.callbacksRegistered then return end

  local callbacks = FPSManager.GetCallbacks()
  for eventCode, data in pairs(callbacks) do
    if data.callback ~= nil then
      -- logger:Debug(eventCode..": "..data.name .. ": callback")
      EVENT_MANAGER:RegisterForEvent(FPSManager.name..data.name, eventCode, data.callback)
    else
      -- logger:Debug(eventCode..": "..data.name .. ": setActiveOnEvent")
      setActiveOnEvent(data.name, eventCode)
    end
  end

  if not FPSManager.hooksRegistered then
    ZO_PreHook("Logout", onLogoutHook)
    ZO_PreHook("Quit", onLogoutHook)
    ZO_PreHook("CancelLogout", onLogoutCanceledHook)
    FPSManager.hooksRegistered = true
  end

  FPSManager.callbacksRegistered = true
end

function FPSManager.UnregisterCallbacks()
  if not FPSManager.callbacksRegistered then return end

  local callbacks = FPSManager.GetCallbacks()
  for eventCode, data in pairs(callbacks) do
    EVENT_MANAGER:UnregisterForEvent(FPSManager.name, eventCode)
  end
end
