local _, pml = ...
local d = pml.defaults

pml.templates = pml.templates or {}
local T = pml.templates

T.button = T.button or {}

function T.button:Create(parent, text, anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local safeName = "PMLButton_" .. tostring(text):gsub("%W", "")
  local btn = CreateFrame("Button", safeName, parent, "UIPanelButtonTemplate")
  btn:SetPoint(anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local w = (type(PMLDB) == 'table' and PMLDB.buttonWidth) or d.BUTTON_WIDTH
  local h = (type(PMLDB) == 'table' and PMLDB.buttonHeight) or d.BUTTON_HEIGHT
  btn:SetSize(w, h)
  btn:SetText(text)
  return btn
end
