local _, pml = ...
local v = pml.vars
local d = pml.defaults
local Utils = pml.utils

-------------------------------------------------
-- SIMPLE PRINT HELPER - global utility
-------------------------------------------------
Utils.printPrefix = v.blue .. "[PML]|r:"
function Utils:Print(...)
  print(self.printPrefix, ...)
end

-------------------------------------------------
-- SAFE GETTERS / HELPERS
-------------------------------------------------
function Utils:SafeGet(tbl, key, fb)
  if tbl and tbl[key] ~= nil then return tbl[key] end
  return fb
end

function Utils:SafeCall(obj, method, ...)
  if type(obj) == "table" then
    local fn = obj[method]
    if type(fn) == "function" then
      return fn(obj, ...)
    end
  end
end

-------------------------------------------------
--- SAFE SETTERS - text and background colors
-------------------------------------------------
function Utils:SafeSetColorTexture(tex, color)
  if not tex or not color then return end
  if tex.SetColorTexture then
    tex:SetColorTexture(color[1], color[2], color[3], color[4])
  end
end

function Utils:SafeSetTextColor(fs, color)
  if not fs or not color then return end
  if fs.SetTextColor then
    fs:SetTextColor(color[1], color[2], color[3])
  end
end

-----------------------------------------------------------------
-- THEME / COLOR HELPERS
-----------------------------------------------------------------
function Utils:GetCurrentTheme()
  return {
    themeName = PMLDB.themeName,
    bg = PMLDB.bgColor,
    text = PMLDB.textColor,
    msg = PMLDB.msgColor,
  }
end

function Utils:SafeSetPointsAndHide(p)
  if p then
    p:SetAllPoints()
    p:Hide()
  end
end

-------------------------------------------------------------
-- LOG CLEANING HELPER
-------------------------------------------------------------
function Utils:StripColorsAndTextures(s)
  if type(s) ~= "string" then
    return "" -- prevent ALL crashes and formatting bugs
  end

  local keepGoing = 1
  while keepGoing > 0
  do
    s, keepGoing = string.gsub(s, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1")
  end

  return string.gsub(s, "|T.-|t", "")
end

-------------------------------------------------------------
-- TIME HELPERS - for the logs
-------------------------------------------------------------
local function GetRegionTimeFormat()
  local region = C_CVar.GetCVar("portal")
  if region == "US" then
    return "day: %m-%d-%Y | time: %I:%M:%S %p"
  else
    return "day: %d-%m-%Y | time: %H:%M:%S"
  end
end

function Utils:GetFormattedTimestamp()
  local timeFormat = GetRegionTimeFormat()
  return date(timeFormat)
end

function Utils:GetDurationAsText(duration)
  local minutes = v.floor(duration / 60)
  local seconds = duration % 60
  return minutes > 0 and string.format("%dm %ds", minutes, seconds) or string.format("%ds", seconds)
end

-------------------------------------------------------------
-- UI MESSAGE HELPERS - for when select all is clicked
-------------------------------------------------------------
function Utils:CreateTopMessage(panel)
  local msg = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  msg:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -10)
  self:SafeSetTextColor(msg, PMLDB.msgColor or d.MSG_COLOR)
  msg:SetText("")
  return msg
end

-- Show a message for a limited duration
function Utils:ShowMessage(fontString, text)
  if not fontString then return end
  fontString:SetText(text)
  C_Timer.After(PMLDB.msgDuration or d.MSG_DURATION, function()
    fontString:SetText("")
  end)
end
