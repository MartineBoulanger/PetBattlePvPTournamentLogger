local _, pml = ...
local d = pml.defaults

pml.templates = pml.templates or {}
local T = pml.templates

T.slider = T.slider or {}

function T.slider:Create(parent, minVal, maxVal, step, anchorPoint, relativeTo, relativePoint, xOff, yOff, labelText)
  local safeName = "PMLSlider_" .. tostring(labelText):gsub("%W", "")

  local slider = CreateFrame("Slider", safeName, parent, "OptionsSliderTemplate")
  slider:SetPoint(anchorPoint, relativeTo, relativePoint, xOff, yOff)
  local w = (type(PMLDB) == 'table' and PMLDB.sliderWidth) or d.SLIDER_WIDTH
  local h = (type(PMLDB) == 'table' and PMLDB.sliderHeight) or d.SLIDER_HEIGHT
  slider:SetSize(w, h)
  slider:SetMinMaxValues(minVal, maxVal)
  slider:SetValueStep(step)
  slider:SetObeyStepOnDrag(true)

  ----------------------------------------------------
  -- MAIN LABEL - above the slider
  ----------------------------------------------------
  slider.label = _G[safeName .. "Text"] or slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  slider.label:SetPoint("BOTTOM", slider, "TOP", 0, 5)
  slider.label:SetText(labelText or "")

  ----------------------------------------------------
  -- PROTECT BUILT-IN LOW/HIGH FONTSTRINGS
  ----------------------------------------------------
  slider.Low  = _G[safeName .. "Low"]
  slider.High = _G[safeName .. "High"]

  if slider.Low then slider.Low:SetText(minVal) end
  if slider.High then slider.High:SetText(maxVal) end

  return slider
end
