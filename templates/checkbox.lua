local _, pml = ...
local d = pml.defaults

pml.templates = pml.templates or {}
local T = pml.templates

T.checkbox = T.checkbox or {}

function T.checkbox:Create(parent, text, anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local safeName = "PMLCheckbox_" .. tostring(text):gsub("%W", "")
  local chk = CreateFrame("CheckButton", safeName, parent, "UICheckButtonTemplate")
  chk:SetPoint(anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local size = (type(PMLDB) == 'table' and PMLDB.checkboxSize) or d.CHECKBOX_SIZE
  chk:SetSize(size, size)
  if chk.text then
    chk.text:SetText(text)
  else
    -- fallback: create a fontstring
    chk.text = chk:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    chk.text:SetPoint("LEFT", chk, "RIGHT", 4, 0)
    chk.text:SetText(text)
  end
  return chk
end
