local _, pml = ...
local frame = pml.frame
local events = pml.events

------------------------------------------------------------
-- REGISTER EVENTS
------------------------------------------------------------
for event in pairs(events) do
  frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function(self, event, ...)
  if events[event] then
    events[event](self, ...)
  end
end)

------------------------------------------------------------
-- SECURE HOOK TO CHECK ON PLAYER FORFEIT
------------------------------------------------------------
if C_PetBattles and C_PetBattles.ForfeitGame then
  hooksecurefunc(C_PetBattles, "ForfeitGame", function()
    if PMLDB.battles then
      PMLDB.battles.playerForfeit = true
    end
  end)
end

--------------------------------------------------
-- PUBLIC API
--------------------------------------------------
_G.PetMastersLeagueLogs = _G.PetMastersLeagueLogs or {}

function _G.PetMastersLeagueLogs.Show()
  frame:Show()
end

function _G.PetMastersLeagueLogs.Hide()
  frame:Hide()
end

function _G.PetMastersLeagueLogs.Toggle()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end

------------------------------------------------------------
-- SLASH COMMAND
------------------------------------------------------------
SLASH_PETMASTERSLEAGUELOGS1 = "/pml"
SlashCmdList["PETMASTERSLEAGUELOGS"] = function()
  if frame:IsShown() then frame:Hide() else frame:Show() end
end
