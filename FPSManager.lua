FPSManager = {}
FPSManager.name = "FPSManager"
FPSManager.svName = "FPSManager_SavedVariables"

local logger = LibDebugLogger(FPSManager.name)

local ACTIVE_FPS = 60
local ACTIVE_CHECK_DELAY_MS = 5 * 1000

local IDLE_DELAY_MS = 60 * 1000

local IDLE_FPS = 10
local IDLE_CHECK_DELAY_MS = 200

local COMBAT_FPS = 165

local currentFPS = 0
local idleTimeMS = 0
local hasFocus = true
local isIdle = false
local isInCombat = false

local function setActive(active, callback)
  local newFPS
  local newDelayMS
  local reason
  local r, g, b, a = 1, 1, 1, 1

  if active then
    if isInCombat then
      newFPS = COMBAT_FPS
      newDelayMS = 0
      reason = "combat"
      r, g, b = 1, 0.5, 0.5
    else
      newFPS = ACTIVE_FPS
      newDelayMS = ACTIVE_CHECK_DELAY_MS
      reason = "active"
      r, g, b, a = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    end
    idleTimeMS = 0
    isIdle = false
  else
    newFPS = IDLE_FPS
    newDelayMS = IDLE_CHECK_DELAY_MS
    reason = "idle"
    r, g, b = 0.75, 1, 0.65
  end
  if newFPS ~= currentFPS then
    EVENT_MANAGER:UnregisterForUpdate(FPSManager.name.."_CheckIdle")
    SetCVar("MinFrameTime.2", ""..(1 / newFPS))
    ZO_PerformanceMetersFramerateMeterLabel:SetColor(r, g, b, a)
    if newDelayMS > 0 then
      logger:Debug("FPSManager: Setting FPS to "..reason..": "..newFPS.."fps, idle check every "..newDelayMS.."ms")
      EVENT_MANAGER:RegisterForUpdate(FPSManager.name.."_CheckIdle", newDelayMS, callback)
    else
      logger:Debug("FPSManager: Setting FPS to "..reason..": "..newFPS.."fps")
    end
    currentFPS = newFPS
  end
end

local x_old, y_old, h_old = GetMapPlayerPosition("player")
local heading_old = GetPlayerCameraHeading()
local function IdleCheck()
    -- d("FPSManager: IdleCheck")

    local function IsPlayerIdle()
        -- Check if in combat
        if IsUnitInCombat("player") then return false end
        -- Compareing current plosition and heading with data of last run
        local x_new, y_new, h_new = GetMapPlayerPosition("player")
        local heading_new = GetPlayerCameraHeading()

        if x_old == x_new and y_old == y_new and h_old == h_new and heading_new == heading_old then
            return true
        else
            x_old, y_old, h_old, heading_old = x_new, y_new, h_new, heading_new
            return false
        end
    end

    if not IsPlayerIdle() then
      idleTimeMS = 0
      isIdle = false
      -- d("FPSManager: not idle")
      if hasFocus then
        setActive(true, IdleCheck)
      end
    else
      if not isIdle then
        idleTimeMS = idleTimeMS + ACTIVE_CHECK_DELAY_MS
        -- d("FPSManager: Idle "..idleTimeMS.."ms")
        if idleTimeMS >= IDLE_DELAY_MS then
          isIdle = true
          if hasFocus then
            setActive(false, IdleCheck)
          end
        end
      -- else
      --   d("FPSManager: already idle")
      end
    end
end

local function OnCombatState(_, inCombat)
  isInCombat = inCombat
  setActive(true, IdleCheck)
end

local function setActiveTrue()
  setActive(true, IdleCheck)
end

function FPSManager.Initialize()
  -- FPSManager.saved = ZO_SavedVars:NewAccountWide(FPSManager.svName, 1, nil, FPSManager.default)

  logger:Debug("FPSManager initialising")
  setActive(true, IdleCheck)

  EVENT_MANAGER:RegisterForEvent(FPSManager.name.."_Combat", EVENT_PLAYER_COMBAT_STATE, OnCombatState)

  EVENT_MANAGER:RegisterForEvent(FPSManager.name.."_UIMovement", EVENT_NEW_MOVEMENT_IN_UI_MODE, setActiveTrue)
  EVENT_MANAGER:RegisterForEvent(FPSManager.name.."_MouseDown", EVENT_GLOBAL_MOUSE_DOWN, setActiveTrue)
  EVENT_MANAGER:RegisterForEvent(FPSManager.name.."MouseUp", EVENT_GLOBAL_MOUSE_UP, setActiveTrue)
end


-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function FPSManager.OnAddOnLoaded(event, addonName)
  -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
  if addonName ~= FPSManager.name then return end

  FPSManager.Initialize()
  --unregister the event again as our addon was loaded now and we do not need it anymore to be run for each other addon that will load
  EVENT_MANAGER:UnregisterForEvent(FPSManager.name, EVENT_ADD_ON_LOADED) 
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
-->This event EVENT_ADD_ON_LOADED will be called for EACH of the addns/libraries enabled, this is why there needs to be a check against the addon name
-->within your callback function! Else the very first addon loaded would run your code + all following addons too.
EVENT_MANAGER:RegisterForEvent(FPSManager.name, EVENT_ADD_ON_LOADED, FPSManager.OnAddOnLoaded)
