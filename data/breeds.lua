local _, pml = ...
local v = pml.vars
local d = pml.defaults
local U = pml.utils
local Breeds = pml.breeds

-----------------------------------------------------------------
-- CHECK & INIT THE PET DATA ARRAY
-----------------------------------------------------------------
if not PBPTL_Arrays.BasePetStats then
  PBPTL_Arrays.InitializeArrays()
else
  if U and U.Print then
    U:Print(v.red .. "ERROR:|r BasePetStats not initialized.")
  else
    print(v.red .. "ERROR:|r BasePetStats not initialized.")
  end
  return "ERR-INIT", -1, { "ERR-INIT" }
end

-----------------------------------------------------------------
-- FUNCTIONS FOR BREED CALCULATION AND RETRIEVAL
-----------------------------------------------------------------
function Breeds:RetrieveTypeName(petType)
  return (petType and d.PET_TYPES) and d.PET_TYPES[petType] or "Unknown"
end

function Breeds:CalculateBreedId(speciesID, quality, maxHealth, power, speed, flying)
  local breedID, newQL, minQL, maxQL

  if (quality < 1) then
    quality = 2
    minQL = 1
    if d.IS_PTR then
      maxQL = 6
    else
      maxQL = 4
    end
  else
    minQL = quality
    maxQL = quality
  end

  if not PBPTL_Arrays.BasePetStats[speciesID] then
    return "NEW", quality, { "NEW" }
  end

  local iHealth = PBPTL_Arrays.BasePetStats[speciesID][1] * 10
  local iPower = PBPTL_Arrays.BasePetStats[speciesID][2] * 10
  local iSpeed = PBPTL_Arrays.BasePetStats[speciesID][3] * 10

  local tHealth = maxHealth * 100
  local tPower = power * 100
  local tSpeed = speed * 100

  if flying then tSpeed = tSpeed / 1.5 end

  local lowest
  local level = 25
  for i = minQL, maxQL do
    newQL = PBPTL_Arrays.RealRarityValues[i] * 20 * level

    local diff3 = (v.abs(((iHealth + 5) * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 5) * newQL) - tPower) +
        v.abs(((iSpeed + 5) * newQL) - tSpeed)

    local diff4 = (v.abs((iHealth * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 20) * newQL) - tPower) +
        v.abs((iSpeed * newQL) - tSpeed)

    local diff5 = (v.abs((iHealth * newQL * 5 + 10000) - tHealth) / 5) + v.abs((iPower * newQL) - tPower) +
        v.abs(((iSpeed + 20) * newQL) - tSpeed)

    local diff6 = (v.abs(((iHealth + 20) * newQL * 5 + 10000) - tHealth) / 5) + v.abs((iPower * newQL) - tPower) +
        v.abs((iSpeed * newQL) - tSpeed)

    local diff7 = (v.abs(((iHealth + 9) * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 9) * newQL) - tPower) +
        v.abs((iSpeed * newQL) - tSpeed)

    local diff8 = (v.abs((iHealth * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 9) * newQL) - tPower) +
        v.abs(((iSpeed + 9) * newQL) - tSpeed)

    local diff9 = (v.abs(((iHealth + 9) * newQL * 5 + 10000) - tHealth) / 5) + v.abs((iPower * newQL) - tPower) +
        v.abs(((iSpeed + 9) * newQL) - tSpeed)

    local diff10 = (v.abs(((iHealth + 4) * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 9) * newQL) - tPower) +
        v.abs(((iSpeed + 4) * newQL) - tSpeed)

    local diff11 = (v.abs(((iHealth + 4) * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 4) * newQL) - tPower) +
        v.abs(((iSpeed + 9) * newQL) - tSpeed)

    local diff12 = (v.abs(((iHealth + 9) * newQL * 5 + 10000) - tHealth) / 5) + v.abs(((iPower + 4) * newQL) - tPower) +
        v.abs(((iSpeed + 4) * newQL) - tSpeed)

    local current = v.min(diff3, diff4, diff5, diff6, diff7, diff8, diff9, diff10, diff11, diff12)

    if not lowest or current < lowest then
      lowest = current
      quality = i

      if (lowest == diff3) then
        breedID = 3
      elseif (lowest == diff4) then
        breedID = 4
      elseif (lowest == diff5) then
        breedID = 5
      elseif (lowest == diff6) then
        breedID = 6
      elseif (lowest == diff7) then
        breedID = 7
      elseif (lowest == diff8) then
        breedID = 8
      elseif (lowest == diff9) then
        breedID = 9
      elseif (lowest == diff10) then
        breedID = 10
      elseif (lowest == diff11) then
        breedID = 11
      elseif (lowest == diff12) then
        breedID = 12
      else
        return "ERR-MIN", -1, { "ERR-MIN" }
      end
    end
  end

  if breedID then
    return breedID, quality
  else
    return "ERR-CAL", -1, { "ERR-CAL" }
  end
end

function Breeds:RetrieveBreedName(breedID)
  if not breedID then return "ERR-ELY" end -- Should be impossible (keeping for debug)

  if (string.sub(tostring(breedID), 1, 3) == "ERR") or (tostring(breedID) == "???") or (tostring(breedID) == "NEW") then
    return breedID
  end

  local numberBreed = tonumber(breedID)
  if (numberBreed == 3) then
    return "B/B"
  elseif (numberBreed == 4) then
    return "P/P"
  elseif (numberBreed == 5) then
    return "S/S"
  elseif (numberBreed == 6) then
    return "H/H"
  elseif (numberBreed == 7) then
    return "H/P"
  elseif (numberBreed == 8) then
    return "P/S"
  elseif (numberBreed == 9) then
    return "H/S"
  elseif (numberBreed == 10) then
    return "P/B"
  elseif (numberBreed == 11) then
    return "S/B"
  elseif (numberBreed == 12) then
    return "H/B"
  else
    return "ERR-NAM" -- Should be impossible (keeping for debug)
  end
end
