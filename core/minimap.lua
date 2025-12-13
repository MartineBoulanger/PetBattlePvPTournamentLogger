local addonName, pml = ...
local v = pml.vars
local d = pml.defaults
local Minimap = pml.minimap

local okLDB, LDB = pcall(function() return LibStub("LibDataBroker-1.1") end)
local okLDI, LDI = pcall(function() return LibStub("LibDBIcon-1.0") end)
local LEFT_MOUSE_BUTTON = [[|TInterface\TutorialFrame\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283|t ]]
local iconName = addonName .. "_Minimap"

-----------------------------------------------------------------
-- SAFETY CHECK
-----------------------------------------------------------------
if not (okLDB and okLDI and LDB and LDI) then
  function Minimap:Init() end
  function Minimap:Toggle() end
  function Minimap:IsShown() return false end
  return
end

-----------------------------------------------------------------
-- CREATE THE LDB OBJECT
-----------------------------------------------------------------
local broker = LDB:NewDataObject(iconName, {
  type = "launcher",
  icon = "Interface\\Addons\\PetMastersLeagueLogs\\media\\PML_Icon.tga",
  OnClick = function(_, button)
    local frame = pml.frame
    if frame and frame.SetShown then
      frame:SetShown(not frame:IsShown())
    end
  end,
  OnTooltipShow = function(tooltip)
    tooltip:AddLine(v.green .. "Pet Masters League Logs|r")
    tooltip:AddLine(LEFT_MOUSE_BUTTON .. "Toggle the addon")
  end,
})

-----------------------------------------------------------------
-- INITIALIZE MINIMAP ICON
-----------------------------------------------------------------
function Minimap:Init()
  PMLDB.minimapSettings = PMLDB.minimapSettings or {
    hide = d.MINIMAP,
    minimapPos = d.MINIMAP_POS,
  }

  LDI:Register(iconName, broker, PMLDB.minimapSettings)

  if PMLDB.minimapSettings.hide then
    LDI:Hide(iconName)
  else
    LDI:Show(iconName)
  end
end

-----------------------------------------------------------------
-- TOGGLE VISIBILITY
-----------------------------------------------------------------
function Minimap:Toggle(show)
  local hide = not show
  PMLDB.minimapSettings.hide = hide

  if hide then
    LDI:Hide(iconName)
  else
    LDI:Show(iconName)
  end
end

-----------------------------------------------------------------
-- IS SHOWN?
-----------------------------------------------------------------
function Minimap:IsShown()
  return not (PMLDB.minimapSettings and PMLDB.minimapSettings.hide)
end
