local addonName, pml = ...
local v = pml.vars
local d = pml.defaults
local utils = pml.utils
local frame = pml.frame
local Events = pml.events

Events.PLAYER_LOGIN = function(self, ...)
  -----------------------------------------------------------------
  -- INIT MINIMAP BUTTON ON PLAYER LOGIN
  -----------------------------------------------------------------
  if pml.minimap and pml.minimap.Init then
    pml.minimap:Init()
  end
end

Events.ADDON_LOADED = function(self, addonNameLoaded)
  if addonNameLoaded ~= addonName then return end
  -----------------------------------------------------------------
  -- DEFAULTS SETTINGS
  -----------------------------------------------------------------
  PMLDB.isPvp = PMLDB.isPvp or d.IS_PVP
  PMLDB.frameWidth = PMLDB.frameWidth or d.FRAME_WIDTH
  PMLDB.frameHeight = PMLDB.frameHeight or d.FRAME_HEIGHT
  PMLDB.themeName = PMLDB.themeName or d.THEME_NAME
  PMLDB.bgColor = PMLDB.bgColor or d.BG_COLOR
  PMLDB.textColor = PMLDB.textColor or d.TEXT_COLOR
  PMLDB.msgColor = PMLDB.msgColor or d.MSG_COLOR
  PMLDB.locked = PMLDB.locked or d.LOCKED
  PMLDB.fontSize = PMLDB.fontSize or d.FONT_SIZE
  PMLDB.opacity = PMLDB.opacity or d.OPACITY
  PMLDB.msgDuration = PMLDB.msgDuration or d.MSG_DURATION
  PMLDB.showMinimap = (PMLDB.showMinimap ~= d.MINIMAP)
  PMLDB.minimapPos = PMLDB.minimapPos or d.MINIMAP_POS
  PMLDB.framePoint = PMLDB.framePoint or nil

  -----------------------------------------------------------------
  -- INIT UI
  -----------------------------------------------------------------
  if pml.UI and pml.UI.Init then
    pml.UI:Init()
  end

  -----------------------------------------------------------------
  -- APPLY THEME
  -----------------------------------------------------------------
  if pml.theme and pml.theme.Apply then
    pml.theme:Apply(PMLDB.themeName)
  end

  -----------------------------------------------------------------
  -- CHECK SAVED LOGS & SHOW INFO MESSAGE
  -----------------------------------------------------------------
  local logColor = (#BattleLogs == d.MAX_LOGS) and v.red or v.green
  utils:Print("addon loaded. Saved logs:", logColor .. #BattleLogs .. "|r.",
    "Open with: " .. v.yellow .. "/pml|r")

  if #BattleLogs == d.MAX_LOGS then
    utils:Print(v.orange ..
      "max number of saved logs reached, the oldest log will be deleted before a new log will be saved.|r")
  end
end

Events.PET_BATTLE_OPENING_START = function(self)
  PMLDB.isPvp = not C_PetBattles.IsPlayerNPC(2)

  if not PMLDB.isPvp then
    utils:Print(v.orange .. "not a PvP battle! Skipping log.|r")
    frame:UnregisterEvent("PET_BATTLE_CLOSE")
    frame:UnregisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
    frame:UnregisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
    frame:UnregisterEvent("PET_BATTLE_FINAL_ROUND")
    return
  end

  if pml.panels and pml.panels.logs and pml.panels.logs.StartNewBattle then
    pml.panels.logs:StartNewBattle()
  end

  frame:RegisterEvent("PET_BATTLE_CLOSE")
  frame:RegisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
  frame:RegisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
  frame:RegisterEvent("PET_BATTLE_FINAL_ROUND")
end

Events.PET_BATTLE_OPENING_DONE = function(self)
  if pml.panels and pml.panels.logs and pml.panels.logs.OnPetBattleOpeningDone then
    pml.panels.logs:OnPetBattleOpeningDone()
  end
end

Events.PET_BATTLE_CLOSE = function(self)
  if pml.panels and pml.panels.logs and pml.panels.logs.SaveBattleLog then
    pml.panels.logs:SaveBattleLog()
  end

  frame:UnregisterEvent("PET_BATTLE_CLOSE")
  frame:UnregisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
  frame:UnregisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
  frame:UnregisterEvent("PET_BATTLE_FINAL_ROUND")

  if PMLDB.isPvp then utils:Print(v.yellow .. "battle ended at:|r", utils:GetFormattedTimestamp()) end
end

Events.CHAT_MSG_PET_BATTLE_COMBAT_LOG = function(self, msg)
  if pml.panels and pml.panels.logs and pml.panels.logs.OnPetBattleSaveChatMsg then
    pml.panels.logs:OnPetBattleSaveChatMsg(msg)
  end
end

Events.PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE = function(self, round)
  if pml.panels and pml.panels.logs and pml.panels.logs.OnPetBattleSaveRounds then
    pml.panels.logs:OnPetBattleSaveRounds(round)
  end
end

Events.PET_BATTLE_FINAL_ROUND = function(self, winner)
  if pml.panels and pml.panels.logs and pml.panels.logs.FinalizeBattleResult then
    pml.panels.logs:FinalizeBattleResult(winner)
  end
end
