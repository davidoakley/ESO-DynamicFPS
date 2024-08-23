local function onCombatState(_, inCombat)
  DynamicFPS.isInCombat = inCombat
  DynamicFPS.lastActiveTime = GetGameTimeSeconds()
  DynamicFPS.SetActive()
end

local function onDialogBegin(_, optionCount)
  DynamicFPS.isInDialog = true
  DynamicFPS.LogDebug("onDialogBegin "..optionCount)
  DynamicFPS.SetActive()
end

local function onDialogEnd(_)
  DynamicFPS.isInDialog = false
  DynamicFPS.LogDebug("onDialogEnd")
  DynamicFPS.SetActive()
end

local function onDialogUpdate(_)
  DynamicFPS.LogDebug("onDialogUpdate")
  DynamicFPS.SetActive()
end

local function setActiveOnEvent(eventName, event)
  EVENT_MANAGER:RegisterForEvent(DynamicFPS.name..eventName, event, function()
    DynamicFPS.LogDebug("event "..eventName)
    DynamicFPS.SetActive()
  end)
end

local function onLogoutHook(_)
  if not DynamicFPS.savedVars.enabled then return end
  DynamicFPS.LogInfo("onLogout; restoring to "..DynamicFPS.savedVars.fixedFPS.."fps")
  DynamicFPS.paused = true
  SetCVar("MinFrameTime.2", ""..(1 / DynamicFPS.savedVars.fixedFPS))
end

local function onLogoutCanceledHook(_)
  if not DynamicFPS.savedVars.enabled then return end
  DynamicFPS.LogInfo("onLogoutCanceled")
  DynamicFPS.paused = false
  DynamicFPS.SetActive()
end

--- @return table
function DynamicFPS.GetCallbacks()
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

function DynamicFPS.RegisterCallbacks()
  if DynamicFPS.callbacksRegistered then return end

  local callbacks = DynamicFPS.GetCallbacks()
  for eventCode, data in pairs(callbacks) do
    if data.callback ~= nil then
      -- DynamicFPS.LogDebug(eventCode..": "..data.name .. ": callback")
      EVENT_MANAGER:RegisterForEvent(DynamicFPS.name..data.name, eventCode, data.callback)
    else
      -- DynamicFPS.LogDebug(eventCode..": "..data.name .. ": setActiveOnEvent")
      setActiveOnEvent(data.name, eventCode)
    end
  end

  if not DynamicFPS.hooksRegistered then
    ZO_PreHook("Logout", onLogoutHook)
    ZO_PreHook("Quit", onLogoutHook)
    ZO_PreHook("CancelLogout", onLogoutCanceledHook)
    DynamicFPS.hooksRegistered = true
  end

  DynamicFPS.callbacksRegistered = true
end

function DynamicFPS.UnregisterCallbacks()
  if not DynamicFPS.callbacksRegistered then return end

  local callbacks = DynamicFPS.GetCallbacks()
  for eventCode, data in pairs(callbacks) do
    EVENT_MANAGER:UnregisterForEvent(DynamicFPS.name, eventCode)
  end
end
