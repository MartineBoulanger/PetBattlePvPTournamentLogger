local _, pml = ...
local v = pml.vars
local d = pml.defaults
local U = pml.utils
local T = pml.templates
local Theme = pml.theme
local Minimap = pml.minimap
local frame = pml.frame
local panel = frame.settingsPanel

-------------------------------------------------------------
-- FRAME RESIZING
-------------------------------------------------------------
frame:SetResizable(true)

-- Respect ADDON_LOADED defaults
local MIN_W = PMLDB.frameMinWidth or d.FRAME_MIN_WIDTH
local MIN_H = PMLDB.frameMinHeight or d.FRAME_MIN_HEIGHT

if frame.SetMinResize then
  frame:SetMinResize(MIN_W, MIN_H)
end

frame.resizeHandle = CreateFrame("Button", nil, frame)
frame.resizeHandle:SetSize(16, 16)
frame.resizeHandle:SetPoint("BOTTOMRIGHT")
frame.resizeHandle.texture = frame.resizeHandle:CreateTexture(nil, "OVERLAY")
frame.resizeHandle.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
frame.resizeHandle.texture:SetAllPoints(frame.resizeHandle)

frame.resizeHandle:SetScript("OnMouseDown", function(self, button)
  if button == "LeftButton" and not PMLDB.locked then
    frame:StartSizing("BOTTOMRIGHT")
  end
end)

frame.resizeHandle:SetScript("OnMouseUp", function(self)
  frame:StopMovingOrSizing()
  local w, h = frame:GetSize()

  if w < MIN_W then w = MIN_W end
  if h < MIN_H then h = MIN_H end

  frame:SetSize(w, h)
  PMLDB.frameWidth  = w
  PMLDB.frameHeight = h
end)

-- Restore saved size
frame:SetSize(PMLDB.frameWidth or d.FRAME_WIDTH, PMLDB.frameHeight or d.FRAME_HEIGHT)

-------------------------------------------------------------
-- SETTINGS PANEL
-------------------------------------------------------------
panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
panel.title:SetPoint("TOPLEFT", 20, -10)
panel.title:SetText("Settings")

U:SafeSetTextColor(panel.title, PMLDB.textColor)

-------------------------------------------------------------
-- LOCKED CHECKBOX
-------------------------------------------------------------
panel.locked = T.checkbox:Create(panel, "Lock the addon frame", "TOPLEFT", panel, "TOPLEFT", 40, -40)
panel.locked:SetChecked(PMLDB.locked or d.LOCKED)
panel.locked:SetScript("OnClick", function(self)
  PMLDB.locked = self:GetChecked()
end)

-------------------------------------------------------------
-- MINIMAP CHECKBOX
-------------------------------------------------------------
panel.minimap = T.checkbox:Create(panel, "Show minimap button", "TOPLEFT", panel.locked, "BOTTOMLEFT", 0, -10)
local miniHide = PMLDB.minimapSettings and PMLDB.minimapSettings.hide
panel.minimap:SetChecked(not miniHide or d.MINIMAP)
panel.minimap:SetScript("OnClick", function(self)
  local visible = self:GetChecked()

  PMLDB.minimapSettings = PMLDB.minimapSettings or { hide = d.MINIMAP, minimapPos = d.MINIMAP_POS }
  PMLDB.minimapSettings.hide = not visible

  if Minimap and Minimap.Toggle then
    Minimap:Toggle(visible)
  end
end)

-------------------------------------------------------------
-- FONT SIZE SLIDER
-------------------------------------------------------------
panel.fontSize = T.slider:Create(panel, 8, 18, 1, "TOPLEFT", panel.minimap, "BOTTOMLEFT", 0, -40, "Logs Font Size")
panel.fontSize:SetValue(PMLDB.fontSize or d.FONT_SIZE)
panel.fontSize:SetScript("OnValueChanged", function(self, value)
  value = v.floor(value)
  PMLDB.fontSize = value

  if frame.logsPanel and frame.logsPanel.editBox then
    frame.logsPanel.editBox:SetFont("Fonts\\FRIZQT__.TTF", value, "")
  end

  if frame.usagePanel and frame.usagePanel.editBox then
    frame.usagePanel.editBox:SetFont("Fonts\\FRIZQT__.TTF", value, "")
  end

  self.label:SetText("Logs Font Size: " .. value)
end)

-------------------------------------------------------------
-- OPACITY SLIDER
-------------------------------------------------------------
panel.opacity = T.slider:Create(panel, 0.1, 1, 0.1, "TOPLEFT", panel.fontSize, "BOTTOMLEFT", 0, -40, "Background Opacity")
panel.opacity:SetValue(PMLDB.opacity or d.OPACITY)
panel.opacity:SetScript("OnValueChanged", function(self, value)
  PMLDB.opacity = value

  if frame.Bg then frame.Bg:SetAlpha(value) end
  if frame.InsetBg then frame.InsetBg:SetAlpha(value) end
  if frame.TopTileStreaks then frame.TopTileStreaks:SetAlpha(value) end

  self.label:SetText("Background Opacity: " .. string.format("%.1f", value))
end)

-------------------------------------------------------------
-- MESSAGE DURATION SLIDER
-------------------------------------------------------------
panel.msgDuration = T.slider:Create(panel, 2, 10, 1, "TOPLEFT", panel.opacity, "BOTTOMLEFT", 0, -40,
  "Selected Text Duration")
panel.msgDuration:SetValue(PMLDB.msgDuration or d.MSG_DURATION)
panel.msgDuration:SetScript("OnValueChanged", function(self, value)
  value = v.floor(value)
  PMLDB.msgDuration = value

  panel.msgDuration.label:SetText("Selected Text Duration: " .. value .. " sec")
end)

-------------------------------------------------------------
-- RESET BUTTON
-------------------------------------------------------------
local resetBtn = T.button:Create(panel, "Reset Settings", "TOPRIGHT", panel, "TOPRIGHT", -40, -40)
resetBtn:SetScript("OnClick", function()
  PMLDB.locked = d.LOCKED
  PMLDB.minimapSettings = { hide = d.MINIMAP, minimapPos = d.MINIMAP_POS }
  PMLDB.fontSize = d.FONT_SIZE
  PMLDB.opacity = d.OPACITY
  PMLDB.msgDuration = d.MSG_DURATION
  PMLDB.themeName = d.THEME_NAME
  PMLDB.bgColor = d.BG_COLOR
  PMLDB.textColor = d.TEXT_COLOR
  PMLDB.msgColor = d.MSG_COLOR
  PMLDB.frameWidth = d.FRAME_WIDTH
  PMLDB.frameHeight = d.FRAME_HEIGHT
  PMLDB.framePoint = nil

  frame:ClearAllPoints()
  frame:SetSize(d.FRAME_WIDTH, d.FRAME_HEIGHT)
  frame:SetPoint("CENTER")

  ReloadUI()
end)

-------------------------------------------------------------
-- THEME DROPDOWN
-------------------------------------------------------------
panel.themeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
panel.themeLabel:SetPoint("TOPRIGHT", resetBtn, "BOTTOMRIGHT", -45, -40)
panel.themeLabel:SetText("Addon Theme")

U:SafeSetTextColor(panel.themeLabel, PMLDB.textColor)

panel.theme = T.dropdown:Create(panel, "Theme Choice", "TOPRIGHT", resetBtn, "BOTTOMRIGHT", 15, -60)

UIDropDownMenu_Initialize(panel.theme, function()
  for themeName, data in pairs(d.THEMES) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = themeName
    info.func = function()
      PMLDB.themeName = themeName
      PMLDB.bgColor   = data.bgColor
      PMLDB.textColor = data.textColor
      PMLDB.msgColor  = data.msgColor

      UIDropDownMenu_SetSelectedName(panel.theme, themeName)

      if Theme and Theme.Apply then
        Theme:Apply(themeName)
      end
    end
    UIDropDownMenu_AddButton(info)
  end
end)

-------------------------------------------------------------
-- REFRESH ON SHOW
-------------------------------------------------------------
panel:SetScript("OnShow", function()
  panel.locked:SetChecked(PMLDB.locked)
  panel.minimap:SetChecked(not (PMLDB.minimapSettings and PMLDB.minimapSettings.hide))
  panel.fontSize:SetValue(PMLDB.fontSize)
  panel.opacity:SetValue(PMLDB.opacity)
  panel.msgDuration:SetValue(PMLDB.msgDuration)

  UIDropDownMenu_SetSelectedName(panel.theme, PMLDB.themeName)
end)
