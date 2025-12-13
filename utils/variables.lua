local addonName, pml = ...
pml = pml or {}
_G[addonName] = pml

-----------------------------
-- load global tables
-----------------------------
PBPTL_Arrays = PBPTL_Arrays or {}
BattleLogs = BattleLogs or {}
PetUsage = PetUsage or {}
PMLDB = PMLDB or {}

-----------------------------
-- main frame creation
-----------------------------
pml.frame = CreateFrame("Frame", "PetMastersLeagueLogsFrame", UIParent, "BasicFrameTemplateWithInset")

-----------------------------
-- basic metadata
-----------------------------
pml.name = addonName
pml.tocVersion = "3.0.0"

-----------------------------
-- saved variables
-----------------------------
pml.vars = {
  -- helpers
  min = _G.math.min,
  max = _G.math.max,
  abs = _G.math.abs,
  floor = _G.math.floor,
  ceil = _G.math.ceil,
  tinsert = _G.table.insert,
  tremove = _G.table.remove,
  -- colors
  white = '|cFFFFFFFF',
  blue = '|cff3FC7EB',
  yellow = '|cffFFFF00',
  green = '|cff00FF00',
  red = '|cffC41E3A',
  orange = '|cffFF7F3F',
}

-----------------------------
-- DEFAULT CONSTANT VALUES
-----------------------------
pml.defaults = pml.defaults or {}
local d = pml.defaults
d.IS_PTR = select(4, _G.GetBuildInfo()) ~= C_AddOns.GetAddOnMetadata(addonName, "Interface")
d.MAX_LOGS = 10
d.IS_PVP = false
d.FRAME_WIDTH = 600
d.FRAME_HEIGHT = 400
d.FRAME_MIN_WIDTH = 500
d.FRAME_MIN_HEIGHT = 400
d.BUTTON_HEIGHT = 24
d.BUTTON_WIDTH = 100
d.SLIDER_WIDTH = 200
d.SLIDER_HEIGHT = 16
d.DROPDOWN_WIDTH = 150
d.CHECKBOX_SIZE = 24
d.LOCKED = false
d.FONT_SIZE = 11
d.OPACITY = 1
d.MSG_DURATION = 5
d.THEMES = {
  Dark = {
    bgColor = { 0.03, 0.03, 0.03, 0.95 },
    textColor = { 1, 1, 1 },
    msgColor = { 1, 0.81, 0 },
  },
  Classic = {
    bgColor = { 0.65, 0.55, 0.40, 0.95 },
    textColor = { 0, 0, 0 },
    msgColor = { 0, 0.21, 1 },
  },
  Light = {
    bgColor = { 0.60, 0.60, 0.60, 0.95 },
    textColor = { 0.05, 0.05, 0.05 },
    msgColor = { 0.78, 0.12, 0.23 },
  }
}
d.THEME_NAME = "Dark"
d.BG_COLOR = { 0.03, 0.03, 0.03, 0.95 }
d.TEXT_COLOR = { 1, 1, 1 }
d.MSG_COLOR = { 1, 0.81, 0 }
d.MINIMAP = false
d.MINIMAP_POS = 145
d.PET_TYPES = {
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

-----------------------------
-- ensure template exists
-----------------------------
pml.templates = pml.templates or {}

-----------------------------
-- ensure panels exists
-----------------------------
pml.panels = pml.panels or {
  logs = {},
  usage = {},
  settings = {},
}

-----------------------------
-- ensure UI exists
-----------------------------
pml.UI = pml.UI or {}

-----------------------------
-- ensure other templates exists
-----------------------------
pml.utils = pml.utils or {}
pml.breeds = pml.breeds or {}
pml.theme = pml.theme or {}
pml.minimap = pml.minimap or {}
pml.events = pml.events or {}


-----------------------------
-- ensure the table for storing the battle logs before saving exists
-----------------------------
PMLDB.battles = PMLDB.battles or {}

-----------------------------
-- ensure minimap settings table exists
-----------------------------
PMLDB.minimapSettings = PMLDB.minimapSettings or {
  hide = d.MINIMAP,
  minimapPos = d.MINIMAP_POS
}
