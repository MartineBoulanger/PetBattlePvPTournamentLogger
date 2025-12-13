local _, pml = ...
local v = pml.vars
local d = pml.defaults
local U = pml.utils
local T = pml.templates
local B = pml.breeds

local DB = PMLDB.battles
local frame = pml.frame
local logsPanel = frame.logsPanel
local usagePanel = frame.usagePanel

-------------------------------------------------------------
-- EVENTS FUNCTIONS
-------------------------------------------------------------
function pml.panels.logs:StartNewBattle()
  DB.logSaved = nil
  DB.lastFight = {
    timestamp = U.GetFormattedTimestamp(),
    duration = 0,
    rounds = 0,
    result = "",
    forfeit = false,
    pets = {},
    battle = {}
  }

  DB.playerForfeit = nil
  DB.startTime = GetTime()

  U:Print(v.yellow .. "battle started at:|r", DB.lastFight.timestamp)
end

function pml.panels.logs:OnPetBattleOpeningDone()
  -----------------------------------------------------------------
  -- CHECK PVP FLAG
  -----------------------------------------------------------------
  if PMLDB.isPvp then
    for owner = 1, 2 do
      for i = 1, C_PetBattles.GetNumPets(owner) do
        v.tinsert(DB.lastFight.pets, pml.panels.usage:SavePetUsage(owner, i) or false)
      end
    end
  else
    return
  end
end

function pml.panels.logs:OnPetBattleSaveRounds(round)
  DB.lastFight.rounds = round
end

function pml.panels.logs:OnPetBattleSaveChatMsg(msg)
  v.tinsert(DB.lastFight.battle, msg)
end

function pml.panels.logs:FinalizeBattleResult(winner)
  if DB.startTime then
    DB.lastFight.duration = v.ceil(GetTime() - DB.startTime)
  end

  if winner == 1 then
    DB.lastFight.result = "WIN"
  else
    local allyAlive, enemyAlive
    local numAlly = C_PetBattles.GetNumPets(1)
    local numEnemy = C_PetBattles.GetNumPets(2)

    for i = 1, 3 do
      local health = C_PetBattles.GetHealth(1, i)
      if health and health > 0 and i <= numAlly then
        allyAlive = true
      end
      health = C_PetBattles.GetHealth(2, i)
      if health and health > 0 and i <= numEnemy then
        enemyAlive = true
      end
    end

    if allyAlive and enemyAlive then
      DB.lastFight.forfeit = true

      if DB.playerForfeit then
        DB.lastFight.result = "LOSS"
        v.tinsert(DB.lastFight.battle, "\nPlayer forfeits.")
      else
        DB.lastFight.result = "WIN"
        v.tinsert(DB.lastFight.battle, "\nOpponent forfeits.")
      end
    elseif not allyAlive and not enemyAlive then
      DB.lastFight.result = "DRAW"
    else
      DB.lastFight.result = "LOSS"
    end
  end
end

function pml.panels.logs:SaveBattleLog()
  if not DB.logSaved then
    v.tinsert(BattleLogs, DB.lastFight)

    -----------------------------------------------------------------
    -- REMOVE OLDEST BATTLE WHEN MAC LOGS IS REACHED
    -----------------------------------------------------------------
    if #BattleLogs > d.MAX_LOGS then
      local removedLog = v.tremove(BattleLogs, 1)
      pml.panels.usage:UpdatePetUsage(removedLog)
      U:Print(v.red .. "oldest battle removed!|r")
    end

    DB.logSaved = true
    U:Print(v.green .. "battle saved.|r Total saved logs:", v.blue .. #BattleLogs .. "|r")
  end
end

-------------------------------------------------------------
-- FUNCTIONS FOR THE BATTLE LOGS PANEL
-------------------------------------------------------------
function pml.panels.logs:GetFormattedLogText()
  local logText = "PvP Pet Battle Logs\n\n"

  for i, log in ipairs(BattleLogs) do
    logText = logText .. string.format("Battle %d:\n\n", i)
    logText = logText .. "Timestamp: " .. log.timestamp .. "\n\n"
    logText = logText .. "Result: " .. log.result .. "\n"
    logText = logText .. "Duration: " .. U:GetDurationAsText(log.duration) .. "\n"
    logText = logText .. "Rounds: " .. log.rounds .. "\n\n"

    -------------------------------------------------------------
    -- FORMAT PLAYER AND OPPONENT TEAMS
    -------------------------------------------------------------
    local playerTeam = {}
    local opponentTeam = {}

    for index = 1, 3 do
      local pet = log.pets[index]
      if pet and pet.name then
        v.tinsert(playerTeam, pet.name)
      else
        v.tinsert(playerTeam, "Unknown")
      end
    end

    for index = 4, 6 do
      local pet = log.pets[index]
      if pet and pet.name then
        v.tinsert(opponentTeam, pet.name)
      else
        v.tinsert(opponentTeam, "Unknown")
      end
    end

    logText = logText .. "Player's Team: " .. table.concat(playerTeam, ", ") .. "\n"
    logText = logText .. "Opponent's Team: " .. table.concat(opponentTeam, ", ") .. "\n\n"

    -------------------------------------------------------------
    -- ADD COMBAT LOG TO THE TEXT
    -------------------------------------------------------------
    logText = logText .. "The Fight:\n\n"
    for _, entry in ipairs(log.battle) do
      if entry:find(PET_BATTLE_COMBAT_LOG_NEW_ROUND) then
        logText = logText .. "\n"
      end
      logText = logText .. U:StripColorsAndTextures(entry) .. "\n"
    end

    logText = logText ..
        "\n------------------------------------------------------------------------------------------\n\n"
  end

  -------------------------------------------------------------
  -- ADD PET USAGE SUMMARY TO THE TEXT
  -------------------------------------------------------------
  logText = logText .. pml.panels.usage:GetPetUsageText()
  return logText
end

-------------------------------------------------------------
-- FUNCTIONS FOR THE PET USAGE PANEL
-------------------------------------------------------------
function pml.panels.usage:SavePetUsage(owner, petIndex)
  local speciesID = C_PetBattles.GetPetSpeciesID(owner, petIndex)
  local petType = C_PetBattles.GetPetType(owner, petIndex)
  local _, speciesName = C_PetBattles.GetName(owner, petIndex)
  local maxHealth = C_PetBattles.GetMaxHealth(owner, petIndex)
  local power = C_PetBattles.GetPower(owner, petIndex)
  local speed = C_PetBattles.GetSpeed(owner, petIndex)
  local quality = C_PetBattles.GetBreedQuality(owner, petIndex) + 1
  local flying = false

  if petType == 3 and (C_PetBattles.GetHealth(owner, petIndex) / maxHealth) > 0.5 then
    flying = true
  end

  local breed = B:CalculateBreedId(speciesID, quality, maxHealth, power, speed, flying)
  local breedID = B:RetrieveBreedName(breed)

  if speciesID and speciesName and petType and maxHealth and power and speed and breedID then
    if not PetUsage[speciesID] then
      PetUsage[speciesID] = {}
    end

    -------------------------------------------------------------
    -- CHECK ON PET BREED EXISTENCE
    -------------------------------------------------------------
    if not PetUsage[speciesID][breedID] then
      -------------------------------------------------------------
      -- NEW BREED? - create new ebtry
      -------------------------------------------------------------
      PetUsage[speciesID][breedID] = {
        speciesID = speciesID,
        name = speciesName,
        type = B:RetrieveTypeName(petType),
        health = maxHealth,
        power = power,
        speed = speed,
        played = 1,
        breed = breedID
      }
    else
      -------------------------------------------------------------
      -- BREED ALREADY TRACKED - increment usage
      -------------------------------------------------------------
      PetUsage[speciesID][breedID].played = PetUsage[speciesID][breedID].played + 1
    end

    -------------------------------------------------------------
    -- SAVE TO LAST FIGHT LOG
    -------------------------------------------------------------
    local pet = { speciesID = speciesID, breedID = breedID, name = speciesName }

    return pet
  end
end

function pml.panels.usage:GetPetUsageText()
  local usageText = "Pet Usage Summary\n\n"
  PetUsage = PetUsage or {}
  for speciesID, breedTable in pairs(PetUsage) do
    for breedID, pet in pairs(breedTable) do
      usageText = usageText .. string.format(
        "%s (%s, H%d/P%d/S%d, %s) - Played: %d\n",
        pet.name,
        pet.type,
        pet.health,
        pet.power,
        pet.speed,
        pet.breed,
        pet.played
      )
    end
  end
  return usageText
end

function pml.panels.usage:UpdatePetUsage(removedLog)
  for _, pet in ipairs(removedLog.pets) do
    local speciesID = pet.speciesID
    local breedID = pet.breed

    local speciesUsage = PetUsage[speciesID]
    if speciesUsage and speciesUsage[breedID] then
      speciesUsage[breedID].played = speciesUsage[breedID].played - 1

      -------------------------------------------------------------
      -- CLEAN UP - if played hits zero
      -------------------------------------------------------------
      if speciesUsage[breedID].played <= 0 then
        speciesUsage[breedID] = nil
      end

      -------------------------------------------------------------
      -- CLEAN UP PET - if all breeds are gone
      -------------------------------------------------------------
      if next(speciesUsage) == nil then
        PetUsage[speciesID] = nil
      end
    end
  end
end

-------------------------------------------------------------
-- SCROLLFRAMES + EDITBOXES
-------------------------------------------------------------
local function CreateEditBox(panel)
  if not panel then return nil, nil end

  local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 20, -40)
  scroll:SetPoint("BOTTOMRIGHT", -40, -20)

  local editBox = CreateFrame("EditBox", nil, scroll)
  editBox:SetHeight(panel:GetHeight())
  editBox:SetWidth(panel:GetWidth())
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:EnableMouse(true)

  local fontSize = PMLDB.fontSize or d.FONT_SIZE
  editBox:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "")

  scroll:SetScrollChild(editBox)

  editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  editBox:SetScript("OnMouseDown", function(self) self:SetFocus() end)

  return editBox, scroll
end

local logsEditBox, logsScrollFrame = CreateEditBox(logsPanel)
local usageEditBox, usageScrollFrame = CreateEditBox(usagePanel)

logsPanel.editBox = logsEditBox
logsPanel.scroll = logsScrollFrame

usagePanel.editBox = usageEditBox
usagePanel.scroll = usageScrollFrame


logsPanel:SetScript("OnShow", function()
  logsPanel.editBox:SetFont("Fonts\\FRIZQT__.TTF", PMLDB.fontSize, "")
  local text = pml.panels.logs:GetFormattedLogText()
  logsPanel.editBox:SetText(text)
end)

usagePanel:SetScript("OnShow", function()
  usagePanel.editBox:SetFont("Fonts\\FRIZQT__.TTF", PMLDB.fontSize, "")
  local text = pml.panels.usage:GetPetUsageText()
  usagePanel.editBox:SetText(text)
end)

-------------------------------------------------------------
-- SELECT ALL BUTTONS
-------------------------------------------------------------
local copyLogsBtn, copyUsageBtn
copyLogsBtn = T.button:Create(logsPanel, "Select All", "TOPRIGHT", logsPanel, "TOPRIGHT", -5, -5)
copyUsageBtn = T.button:Create(usagePanel, "Select All", "TOPRIGHT", usagePanel, "TOPRIGHT", -5, -5)

logsPanel.logsMsg = (U and U.CreateTopMessage) and U:CreateTopMessage(logsPanel) or nil
usagePanel.usageMsg = (U and U.CreateTopMessage) and U:CreateTopMessage(usagePanel) or nil

copyLogsBtn:SetScript("OnClick", function()
  logsPanel.editBox:HighlightText()
  logsPanel.editBox:SetFocus()
  U:ShowMessage(logsPanel.logsMsg, "Battle Logs text selected! Press Ctrl+C to copy.")
end)

copyUsageBtn:SetScript("OnClick", function()
  usagePanel.editBox:HighlightText()
  usagePanel.editBox:SetFocus()
  U:ShowMessage(usagePanel.usageMsg, "Pet Usage text selected! Press Ctrl+C to copy.")
end)
