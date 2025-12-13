local _, pml = ...
local d = pml.defaults
local U = pml.utils
local Theme = pml.theme

-----------------------------------------------------------------
-- FUNCTION TO APPLY THEME
-----------------------------------------------------------------
function Theme:Apply(themeName)
  local tn = themeName or PMLDB.themeName or d.THEME_NAME or "Dark"
  local theme = d.THEMES[tn] or d.THEMES[d.THEME_NAME or "Dark"]

  -----------------------------------------------------------------
  -- FALLBACK TO DEFAULTS
  -----------------------------------------------------------------
  if not theme then
    theme = {
      bgColor = d.BG_COLOR,
      textColor = d.TEXT_COLOR,
      msgColor = d.MSG_COLOR
    }
  end

  -----------------------------------------------------------------
  -- PERSIST THEME
  -----------------------------------------------------------------
  PMLDB.themeName = tn
  PMLDB.bgColor = theme.bgColor
  PMLDB.textColor = theme.textColor
  PMLDB.msgColor = theme.msgColor

  local frame = pml.frame
  if not frame then return end

  -----------------------------------------------------------------
  -- APPLY TO FRAME PIECES - if present
  -----------------------------------------------------------------
  U:SafeSetColorTexture(frame.Bg, PMLDB.bgColor)
  U:SafeSetColorTexture(frame.InsetBg, PMLDB.bgColor)
  U:SafeSetColorTexture(frame.TitleBg, PMLDB.bgColor)
  U:SafeSetColorTexture(frame.TopTileStreaks, PMLDB.bgColor)

  -----------------------------------------------------------------
  -- TITLE TEXT
  -----------------------------------------------------------------
  U:SafeSetTextColor(frame.title, PMLDB.textColor)
  U:SafeSetTextColor(frame.TitleText, PMLDB.textColor)

  -----------------------------------------------------------------
  -- PANELS
  -----------------------------------------------------------------
  local lp = frame.logsPanel
  local up = frame.usagePanel
  local sp = frame.settingsPanel

  local function applyPanel(panel)
    if not panel then return end

    if panel.editBox and panel.editBox.SetTextColor then
      if U.SafeSetTextColor then
        U:SafeSetTextColor(panel.editBox, PMLDB.textColor)
      end
    end

    if panel.logsMsg then
      if U.SafeSetTextColor then
        U:SafeSetTextColor(panel.logsMsg, PMLDB.msgColor)
      end
    end

    if panel.usageMsg then
      if U.SafeSetTextColor then
        U:SafeSetTextColor(panel.usageMsg, PMLDB.msgColor)
      end
    end
  end

  applyPanel(lp)
  applyPanel(up)

  if sp then
    local function colorLabel(obj, color)
      if obj and U.SafeSetTextColor then
        U:SafeSetTextColor(obj, color)
      end
    end

    colorLabel(sp.title, PMLDB.textColor)
    colorLabel(sp.locked and sp.locked.text, PMLDB.textColor)
    colorLabel(sp.minimap and sp.minimap.text, PMLDB.textColor)
    colorLabel(sp.fontSize and sp.fontSize.label, PMLDB.textColor)
    colorLabel(sp.opacity and sp.opacity.label, PMLDB.textColor)
    colorLabel(sp.msgDuration and sp.msgDuration.label, PMLDB.textColor)
    colorLabel(sp.themeLabel, PMLDB.textColor)
    colorLabel(sp.editBox, PMLDB.textColor)
  end

  -----------------------------------------------------------------
  -- APPLY OPACITY
  -----------------------------------------------------------------
  if PMLDB.opacity then
    local a = PMLDB.opacity
    if frame.Bg then frame.Bg:SetAlpha(a) end
    if frame.InsetBg then frame.InsetBg:SetAlpha(a) end
    if frame.TopTileStreaks then frame.TopTileStreaks:SetAlpha(a) end
  end

  -----------------------------------------------------------------
  -- APPLY FONT SIZE
  -----------------------------------------------------------------
  if PMLDB.fontSize then
    if lp and lp.editBox then
      lp.editBox:SetFont("Fonts\\FRIZQT__.TTF", PMLDB.fontSize, "")
    end
    if up and up.editBox then
      up.editBox:SetFont("Fonts\\FRIZQT__.TTF", PMLDB.fontSize, "")
    end
  end

  -----------------------------------------------------------------
  -- APPLY MSG DURATION - if set
  -----------------------------------------------------------------
  if PMLDB.msgDuration then
    PMLDB.msgDuration = PMLDB.msgDuration or d.MSG_DURATION
  end
end
