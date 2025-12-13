local _, pml = ...
local d = pml.defaults

pml.templates = pml.templates or {}
local T = pml.templates

T.dropdown = T.dropdown or {}

function T.dropdown:Create(parent, text, anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local safeName = "PMLDropdown_" .. tostring(text):gsub("%W", "")
  local dd = CreateFrame("Button", safeName, parent, "UIDropDownMenuTemplate")
  dd:SetPoint(anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local w = (type(PMLDB) == 'table' and PMLDB.dropdownWidth) or d.DROPDOWN_WIDTH
  UIDropDownMenu_SetWidth(dd, w)
  return dd
end
