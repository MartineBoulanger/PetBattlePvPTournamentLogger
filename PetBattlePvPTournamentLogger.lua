local frame = CreateFrame("Frame", "PetBattlePvPTournamentLoggerFrame", UIParent, "BasicFrameTemplateWithInset")

-- To set the max of battle logs that can be saved -> 5 is the max number of battles played in a pvp match
local maxLogs = 10
local isPvpPetBattle = false

-- Variable to set the pet type in readable text in the pet usage summary
local petTypeNames = {
  [1] = "Humanoid",
  [2] = "Dragonkin",
  [3] = "Flying",
  [4] = "Undead",
  [5] = "Critter",
  [6] = "Magic",
  [7] = "Elemental",
  [8] = "Beast",
  [9] = "Aquatic",
  [10] = "Mechanical"
}

-- Set the frame size and placement
frame:SetSize(600, 400)
frame:SetPoint("CENTER")
frame:Hide()  -- Hide frame by default

-- Register the frame with UISpecialFrames to make it closable with the Escape key
tinsert(UISpecialFrames, "PetBattlePvPTournamentLoggerFrame")

-- Set frame title
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
frame.title:SetText("Pet Battle PvP Tournament Logger")

-- ScrollFrame to contain the EditBox (textarea-like)
frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
frame.scrollFrame:SetSize(520, 300)
frame.scrollFrame:SetPoint("TOP", frame, "TOP", -10, -40)

-- EditBox to display logs or usage information
frame.editBox = CreateFrame("EditBox", nil, frame.scrollFrame)
frame.editBox:SetMultiLine(true)
frame.editBox:SetFontObject("ChatFontNormal")
frame.editBox:SetSize(500, 400)  -- Set height larger than the scroll frame to enable scrolling
frame.editBox:SetAutoFocus(true)
frame.editBox:SetTextInsets(0, 0, 0, 0)

-- Hide EditBox and ScrollFrame on Escape key
frame.editBox:SetScript("OnEscapePressed", function(self)
  self:ClearFocus()
  frame.scrollFrame:Hide()
end)

-- Link the ScrollFrame to the EditBox and enable scrolling
frame.scrollFrame:SetScrollChild(frame.editBox)

-- Show Battle Logs Button
frame.showLogsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.showLogsButton:SetSize(120, 22)
frame.showLogsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
frame.showLogsButton:SetText("Show Battle Logs")
frame.showLogsButton:SetScript("OnClick", function()
  frame:ShowLogs()
end)

-- Show Pet Usage Button
frame.showUsageButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.showUsageButton:SetSize(120, 22)
frame.showUsageButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
frame.showUsageButton:SetText("Show Pet Usage")
frame.showUsageButton:SetScript("OnClick", function()
    frame:ShowUsage()
end)

-- Delete All Data Button
frame.deleteDataButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.deleteDataButton:SetSize(120, 22)
frame.deleteDataButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
frame.deleteDataButton:SetText("Delete All Data")
frame.deleteDataButton:SetScript("OnClick", function()
    frame:DeleteAllData()
end)

-- Slash command to toggle the addon frame -> tried to keep it easy to remember
SLASH_PETBATTLEPVPTOURNAMENTLOGGER1 = "/petpvplog"
SlashCmdList["PETBATTLEPVPTOURNAMENTLOGGER"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame.scrollFrame:Hide()
        frame:Show()
    end
end

-- Registering the event for when a player logs in
frame:RegisterEvent("PLAYER_LOGIN")

-- Set the script to trigger the PLAYER_LOGIN event, and as well to set the other events
frame:SetScript("OnEvent",function(self,event,...)
  if event == "PLAYER_LOGIN" then
    -- Initialize the saved variables for the battle logs and pet usage
    BattleLogs = BattleLogs or {}
    PetUsage = PetUsage or {}

    -- Registering events that will always be needed for the addon to work
    frame:RegisterEvent("PET_BATTLE_OPENING_DONE")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")

    -- Shows in the chat when the addon has been loaded and how many battle logs are still saved
    print("|cff3FC7EBPet Battle PvP Tournament Logger|r is initialized with", #BattleLogs, "logs saved. To open the addon, type: |cffFFFF00/petpvplog|r")
    -- Checks if there are 10 battle logs saved, and then sends out a warning message in the chat upon player login
    if #BattleLogs == maxLogs then print("|cffC41E3AYou have reach the max of 10 saved battle logs, please make sure you delete the old battle logs before you start a new PvP match|r") end
  else
    frame:HandleEvent(event,...)
  end
end)

-- watch for player forfeiting a match (playerForfeit is nil'ed during PET_BATTLE_OPENING_START)
hooksecurefunc(C_PetBattles,"ForfeitGame",function() frame.playerForfeit=true end)

-- Function to handle all the pet battle events needed to make this addon to work properly
function frame:HandleEvent(event,...)
  if event == "PET_BATTLE_OPENING_START" then
    -- Check if the battle is PvP by verifying if the opponent is not an NPC
    isPvpPetBattle = not C_PetBattles.IsPlayerNPC(2)

    -- If it's not a PvP match, display a warning and exit the function
    if not isPvpPetBattle then
      print("|cffFFFF00Pet battle is not a PvP pet battle, the battle log will not be saved.|r")
      return  -- Exit function to avoid logging
    end

    self:StartNewBattle()

    -- Register relevant events for the pet battle data collection
    frame:RegisterEvent("PET_BATTLE_CLOSE")
    frame:RegisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
    frame:RegisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
    frame:RegisterEvent("PET_BATTLE_FINAL_ROUND")
  elseif event == "PET_BATTLE_OPENING_DONE" then
    self:OnPetBattleOpeningDone()
  elseif event == "CHAT_MSG_PET_BATTLE_COMBAT_LOG" then
    self:OnPetBattleSaveChatMsg(...)
  elseif event == "PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE" then
    self:OnPetBattleSaveRounds(...)
  elseif event == "PET_BATTLE_FINAL_ROUND" then
    self:FinalizeBattleResult(...)
  elseif event == "PET_BATTLE_CLOSE" then
    self:SaveBattleLog()

    -- Unregister events that collect the pet battle, so this won't mess up the next pet battle
    frame:UnregisterEvent("PET_BATTLE_FINAL_ROUND")
    frame:UnregisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
    frame:UnregisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
    frame:UnregisterEvent("PET_BATTLE_CLOSE")

    if isPvpPetBattle then print("|cffFFFF00PvP pet battle ended at:|r ", frame:GetFormattedTimestamp()) end
  end
end

-- Local function to get the region and set date format to the region
local function GetRegionTimeFormat()
  -- Get the region from the portal option in the GetCVar
  local region = C_CVar.GetCVar("portal")
  if region == "US" then
      -- Format for US region (MM-DD-YYYY and 12-hour time with AM/PM)
      return "day: %m-%d-%Y | time: %I:%M:%S %p"
  else
      -- Format for EU and other regions (DD-MM-YYYY and 24-hour time)
      return "day: %d-%m-%Y | time: %H:%M:%S"
  end
end

-- Function to get the current timestamp in the correct format
function frame:GetFormattedTimestamp()
  local timeFormat = GetRegionTimeFormat()
  return date(timeFormat)
end

-- Function to set everything to default values before starting a new battle
function frame:StartNewBattle()
  -- Initialize logging for PvP battle
  frame.logSaved = nil
  frame.lastFight = {
      timestamp = frame:GetFormattedTimestamp(),
      duration = 0,
      rounds = 0,
      result = "",
      forfeit = false,  -- Track if a player or opponent forfeits
      pets = {},        -- Table to store pet information for this battle
      battle = {}       -- Table to store combat log entries
  }

  -- Reset forfeit tracking and start the timer
  frame.playerForfeit = nil
  frame.startTime = GetTime()

  print("|cffFFFF00PvP pet battle started at:|r ", frame.lastFight.timestamp)
end

-- Set the selected pets on each team
function frame:OnPetBattleOpeningDone()
  if isPvpPetBattle then
    for owner = 1, 2 do
      for i = 1, C_PetBattles.GetNumPets(owner) do
        tinsert(frame.lastFight.pets, frame:SavePetUsage(owner,i) or false)
      end
    end
  else
    return
  end
end

-- save the pet data to the frame.lastFight.pets and the PetUsage tables
function frame:SavePetUsage(owner,petIndex)
  -- Log pets for both teams
  local speciesID = C_PetBattles.GetPetSpeciesID(owner,petIndex)
  local petType = C_PetBattles.GetPetType(owner,petIndex)
  local _, speciesName = C_PetBattles.GetName(owner,petIndex)
  local maxHealth = C_PetBattles.GetMaxHealth(owner,petIndex)
  local power = C_PetBattles.GetPower(owner,petIndex)
  local speed = C_PetBattles.GetSpeed(owner,petIndex)

  -- If speciesID, speciesName and petType are found set the pet data PetUsage and frame.lastFight.pets
  if speciesID and speciesName and petType and maxHealth and power and speed then
    -- Check if the pet is already in PetUsage
    if not PetUsage[speciesID] then
      -- If pet is new, add it to PetUsage
      PetUsage[speciesID] = {
        speciesID = speciesID,
        name = speciesName,
        type = frame:RetrieveTypeName(petType),
        health = maxHealth,
        power = power,
        speed  = speed,
        played = 1
      }
    else
      -- If pet already exists, increment the played count
      PetUsage[speciesID].played = PetUsage[speciesID].played + 1
    end

    -- Add pet instance to frame.lastFight.pets for the current battle log
    local pet = { speciesID = speciesID, name = speciesName }

    return pet
  end
end

-- Event gets triggered when a round is completed
function frame:OnPetBattleSaveRounds(round)
  frame.lastFight.rounds = round
end

-- every line in the pet battle combat tab is from a CHAT_MSG_PET_BATTLE_COMBAT_LOG
-- this will copy the line to the lastFight table
function frame:OnPetBattleSaveChatMsg(msg)
  tinsert(frame.lastFight.battle, msg)
end

-- Get the battle duration as text
function frame:GetDurationAsText(duration)
  local minutes = math.floor(duration/60)
  local seconds = duration%60
  return minutes > 0 and string.format("%dm %ds", minutes, seconds) or string.format("%ds", seconds)
end

-- Finalizing the battle, setting the correct data to the correct variable so the log can be saved correctly
function frame:FinalizeBattleResult(winner)
  -- To check if there is a start time set, so the duration of the battle can be calculated
  if frame.startTime then
    frame.lastFight.duration = math.ceil(GetTime() - frame.startTime)
  end

  -- To check if the player is the winner, or that the battle is a LOSS or a DRAW
  if winner == 1 then
    frame.lastFight.result = "WIN"
  else
    local allyAlive,enemyAlive
    local numAlly = C_PetBattles.GetNumPets(1)
    local numEnemy = C_PetBattles.GetNumPets(2)
    for i = 1, 3 do
      local health = C_PetBattles.GetHealth(1,i)
      if health and health > 0 and i <= numAlly then
        allyAlive = true
      end
      health = C_PetBattles.GetHealth(2,i)
      if health and health > 0 and i <= numEnemy then
        enemyAlive = true
      end
    end
    if allyAlive and enemyAlive then
      frame.lastFight.forfeit = true
      if frame.playerForfeit then
        frame.lastFight.result = "LOSS"
        tinsert(frame.lastFight.battle, "\nPlayer forfeits.")
      else
        frame.lastFight.result = "WIN"
        tinsert(frame.lastFight.battle, "\nOpponent forfeits.")
      end
    elseif not allyAlive and not enemyAlive then
      frame.lastFight.result = "DRAW"
    else
      frame.lastFight.result = "LOSS"
    end
  end
end

-- Function to save the battle to the saved variable BattleLogs, and to check if the maxLogs is not exceeded
function frame:SaveBattleLog()
  if not frame.logSaved then
    print("Saving new PvP pet battle log...")
    tinsert(BattleLogs, frame.lastFight)

    -- Remove only one log if the total exceeds 5
    if #BattleLogs > maxLogs then
      local removedLog = table.remove(BattleLogs, 1) -- remove the oldest battle log and sets the oldest log in the removedLog variable
      frame:UpdatePetUsage(removedLog) -- sends the removedLog to the UpdatePetUsage function to update the pet usage summary
      print("|cffC41E3AOldest PvP pet battle log removed!|r")
    end

    -- Set flag to prevent duplicate saves
    frame.logSaved = true
    print("PvP pet battle log saved. |cff3FC7EBTotal saved logs:", #BattleLogs, "|r")
  end
end

-- Funtion to update the pet usage for when maxLogs has been reached and the oldest battle log has been removed
function frame:UpdatePetUsage(removedLog)
  for _, pet in ipairs(removedLog.pets) do
    if PetUsage[pet.speciesID] then
      PetUsage[pet.speciesID].played = PetUsage[pet.speciesID].played - 1
      if PetUsage[pet.speciesID].played <= 0 then
        PetUsage[pet.speciesID] = nil
      end
    end
  end
end

-- Function to show logs in the EditBox
function frame:ShowLogs()
  local logText = frame:GetFormattedLogText()
  frame.editBox:SetText(logText)
  frame.scrollFrame:Show()
end

-- Function to show pet usage in the EditBox
function frame:ShowUsage()
  local usageText = frame:GetPetUsageText()
  frame.editBox:SetText(usageText)
  frame.scrollFrame:Show()
end

-- Define a confirmation dialog for deleting all data
StaticPopupDialogs["DELETE_ALL_DATA_CONFIRM"] = {
  text = "Are you sure you want to delete all PvP pet battle and pet usage data?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function()
      -- Delete all data if the player confirms
      frame:DeleteAllDataConfirmed()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3, -- Keep the dialog in a unique slot
}

-- Function to show the confirmation dialog
function frame:DeleteAllData()
  StaticPopup_Show("DELETE_ALL_DATA_CONFIRM")
end

-- Function to perform the actual deletion (called only if confirmed)
function frame:DeleteAllDataConfirmed()
  BattleLogs = {}
  PetUsage = {}
  isPvpPetBattle = false
  frame.scrollFrame:Hide()
  print("|cffFFFF00All PvP pet battle logs and pet usage data have been deleted.|r")
end

-- Local function that strips all textures and colors from the logs
local function stripColorsAndTextures(s)
  local keepGoing = 1
  while keepGoing > 0
  do
     s, keepGoing = string.gsub(s,"|c%x%x%x%x%x%x%x%x(.-)|r","%1")
  end
  return string.gsub(s, "|T.-|t", "")
end

-- Function to set the formatted text from each log in the EditBox
function frame:GetFormattedLogText()
  local logText = "PvP Pet Battle Logs\n\n"
  for i, log in ipairs(BattleLogs) do
      logText = logText .. string.format("Battle %d:", i) .. "\n\n"
      logText = logText .. "Timestamp: " .. log.timestamp .."\n\n" -- Timestamp
      logText = logText .. "Result: " .. log.result .. "\n" -- Result
      logText = logText .. "Duration: " .. frame:GetDurationAsText(log.duration) .. "\n" -- Duration
      logText = logText .. "Rounds: " .. log.rounds .. "\n\n" -- Rounds played
      logText = logText .. "Player's Team: " .. log.pets[1].name .. ', ' .. log.pets[2].name .. ', ' .. log.pets[3].name .. "\n"
      logText = logText .. "Opponent's Team: " .. log.pets[4].name .. ', ' .. log.pets[5].name .. ', ' .. log.pets[6].name .. "\n\n"
      logText = logText .. "The Fight:\n\n"
      for _, entry in ipairs(log.battle) do
          if entry:find(PET_BATTLE_COMBAT_LOG_NEW_ROUND) then
            logText = logText .. "\n"  -- Add a newline before the round
          end
          logText = logText .. stripColorsAndTextures(entry) .. "\n"
      end
      logText = logText .. "\n-------------------------------------------------------------------------------------------\n\n"
  end

  logText = logText .. frame:GetPetUsageText()
  return logText
end

-- Function to set the formatted text for the pet usage in the EditBox
function frame:GetPetUsageText()
  local usageText = "Pet Usage Summary\n\n"
  for _, pet in pairs(PetUsage) do
    usageText = usageText .. string.format("%s (%s, H%d/P%d/S%d) - Played: %d\n", pet.name, pet.type, pet.health, pet.power, pet.speed, pet.played)
  end
  return usageText
end

-- Function to get the pet type in readable text
function frame:RetrieveTypeName(petType)
  return petType and petTypeNames[petType] or "Unknown"
end