local _, pml = ...
local UI = pml.UI

------------------------------------------------------------
-- BUILD UI
------------------------------------------------------------
function UI:Init()
  if self._inited then return end

  local v = pml.vars
  local d = pml.defaults
  local U = pml.utils
  local T = pml.templates
  local theme = pml.theme
  local frame = pml.frame

  if not (frame and frame.GetName) then
    frame = CreateFrame("Frame", "PetMastersLeagueLogsFrame", UIParent, "BasicFrameTemplateWithInset")
    pml.frame = frame
  end
  self.frame = frame

  -----------------------------------------------------------------
  -- REMOVE NINESLICE - if present
  -----------------------------------------------------------------
  if frame.NineSlice then frame.NineSlice:Hide() end

  -----------------------------------------------------------------
  -- FRAME BACKGROUND TEXTURES
  -----------------------------------------------------------------
  frame.Bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.Bg:SetAllPoints(frame)

  -----------------------------------------------------------------
  -- APPLY BACKGROUND COLOR
  -----------------------------------------------------------------
  local bgColor = PMLDB.bgColor or (theme and U:SafeCall(theme, "GetColor", "bg")) or d.BG_COLOR
  if type(frame.Bg.SetColorTexture) == "function" then
    U:SafeSetTextColor(frame.Bg, bgColor)
  end

  -----------------------------------------------------------------
  -- KEEP THE TEMPLATE'S INSETBG/TITLEBG/TOPTILESTREAKS - if present
  -----------------------------------------------------------------
  frame.InsetBg = frame.InsetBg or frame:CreateTexture(nil, "BORDER")
  frame.TitleBg = frame.TitleBg or frame:CreateTexture(nil, "ARTWORK")
  frame.TopTileStreaks = frame.TopTileStreaks or frame:CreateTexture(nil, "ARTWORK")

  -----------------------------------------------------------------
  -- FRAME SIZE
  -----------------------------------------------------------------
  local width = PMLDB.frameWidth or d.FRAME_WIDTH
  local height = PMLDB.frameHeight or d.FRAME_HEIGHT
  frame:SetSize(width, height)
  frame:SetPoint("CENTER")
  frame:Hide()

  -----------------------------------------------------------------
  -- CLOSE WITH ESC
  -----------------------------------------------------------------
  local tinsert = (v and v.tinsert) or table.insert
  if type(UISpecialFrames) == "table" and tinsert then
    -----------------------------------------------------------------
    -- AVOID DUPLICATES
    -----------------------------------------------------------------
    local found = false
    for i = 1, #UISpecialFrames do
      if UISpecialFrames[i] == "PetMastersLeagueLogsFrame" then
        found = true; break
      end
    end
    if not found then tinsert(UISpecialFrames, "PetMastersLeagueLogsFrame") end
  end

  -----------------------------------------------------------------
  -- TITLE
  -----------------------------------------------------------------
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
  frame.title:SetText("Pet Masters League Logs")

  -----------------------------------------------------------------
  -- APPLY TEXT COLOR
  -----------------------------------------------------------------
  local textColor = PMLDB.textColor or (theme and U:SafeCall(theme, "GetColor", "text")) or d.TEXT_COLOR
  if type(U.SafeSetTextColor) == "function" then
    U:SafeSetTextColor(frame.title, textColor)
  else
    -----------------------------------------------------------------
    -- FALLBACK - if present
    -----------------------------------------------------------------
    if frame.title.SetTextColor then
      frame.title:SetTextColor(textColor[1], textColor[2], textColor[3])
    end
  end

  -----------------------------------------------------------------
  -- MOUSE & DRAGGING
  -----------------------------------------------------------------
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)

  frame:SetScript("OnDragStart", function(self)
    if not (PMLDB and PMLDB.locked) then self:StartMoving() end
  end)

  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    PMLDB.framePoint = { point, "UIParent", relativePoint, x, y }
  end)

  -----------------------------------------------------------------
  -- RESTORE PREVIOUS POSITION - if present
  -----------------------------------------------------------------
  if PMLDB.framePoint and PMLDB.framePoint[1] then
    local p = PMLDB.framePoint
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[3] or p[1], p[4] or 0, p[5] or 0)
  else
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
  end

  -------------------------------------------------------------
  -- CONTENT CONTAINER
  -------------------------------------------------------------
  frame.content = CreateFrame("Frame", "PMLContentContainer", frame)
  frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
  frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 100)

  -------------------------------------------------------------
  -- PANELS
  -------------------------------------------------------------
  frame.logsPanel = CreateFrame("Frame", "PMLLogsPanel", frame.content)
  frame.usagePanel = CreateFrame("Frame", "PMLUsagePanel", frame.content)
  frame.settingsPanel = CreateFrame("Frame", "PMLSettingsPanel", frame.content)

  -----------------------------------------------------------------
  -- USE SAFE UTIL TO SET POINTS AND HIDE - if available
  -----------------------------------------------------------------
  U:SafeSetPointsAndHide(frame.logsPanel)
  U:SafeSetPointsAndHide(frame.usagePanel)
  U:SafeSetPointsAndHide(frame.settingsPanel)

  function frame:ShowPanel(panel)
    frame.logsPanel:Hide()
    frame.usagePanel:Hide()
    frame.settingsPanel:Hide()
    panel:Show()
  end

  -------------------------------------------------------------
  -- BUTTONS - use templates if available
  -------------------------------------------------------------
  frame.showLogsButton = T.button:Create(frame, "Battle Logs", "BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 10)
  frame.showUsageButton = T.button:Create(frame, "Pet Usage", "LEFT", frame.showLogsButton, "RIGHT", 10, 0)
  frame.deleteDataButton = T.button:Create(frame, "Delete Logs", "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 10)
  frame.settingsPanelButton = T.button:Create(frame, "Settings", "RIGHT", frame.deleteDataButton, "LEFT", -10, 0)

  frame.showLogsButton:SetScript("OnClick", function() frame:ShowPanel(frame.logsPanel) end)
  frame.showUsageButton:SetScript("OnClick", function() frame:ShowPanel(frame.usagePanel) end)
  frame.settingsPanelButton:SetScript("OnClick", function() frame:ShowPanel(frame.settingsPanel) end)
  frame.deleteDataButton:SetScript("OnClick", function()
    StaticPopup_Show("DELETE_ALL_DATA_CONFIRM")
  end)

  -----------------------------------------------------------------
  -- DELETE CONFIRMATION DIALOG
  -----------------------------------------------------------------
  StaticPopupDialogs = StaticPopupDialogs or {}
  StaticPopupDialogs["DELETE_ALL_DATA_CONFIRM"] = StaticPopupDialogs["DELETE_ALL_DATA_CONFIRM"] or {
    text = "Are you sure you want to delete all battle logs and pet usage data?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
      BattleLogs = {}
      PetUsage = {}
      if PMLDB then PMLDB.isPvp = d.IS_PVP or false end
      if frame.logsPanel then frame.logsPanel:Hide() end
      if frame.usagePanel then frame.usagePanel:Hide() end
      if frame.settingsPanel then frame.settingsPanel:Hide() end
      local red = (v and v.red) or "|cffC41E3A"
      U:Print((red or "") .. "All pet battle logs and pet usage data have been deleted.|r")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  -----------------------------------------------------------------
  -- EXPOSE FRAME TO PML
  -----------------------------------------------------------------
  pml.frame = frame
  self._inited = true
end

-----------------------------------------------------------------
-- CONVENIENCE: INIT IF PMLDB ALREADY EXISTS
-----------------------------------------------------------------
if PMLDB then
  UI:Init()
end
