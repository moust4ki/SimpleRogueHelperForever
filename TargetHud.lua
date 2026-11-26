local _, SRH = ...
local L = SRH.L

-- Above the target's health bar (an option, the window, off at first): on
-- the enemy's own nameplate, from the top, the combo points, then the
-- energy with its marks (EnergyMarks.lua), right on the health bar, all in
-- the one place the eye already is, drawn with the game's own art (the
-- personal resource display's), clear of the character under the nameplate
-- (the target's debuffs, shown above its health bar, may lie over them:
-- chosen so). It works in combat too, where the game may hide these values
-- from addons: they go straight to status bars, which show them without
-- the addon reading them, and no size is read (the nameplate may keep its
-- own from addons). A combo point is a bar of its own from i - 1 to i: full
-- once there are i, whatever the count, hidden or not. The energy as a
-- number on its bar, a choice: handed to the text as the game gives it.
local HUD = {}
SRH.TargetHud = HUD

local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
-- The combo points as the game draws them (20 x 20, 4 apart), at the scale
-- it gives them on a nameplate (Retail's own, ClassNameplateBarRogueFrame)
local BAR_H, PIP, PIP_GAP, PIPS, PIP_SCALE = 12, 20, 4, 5, 0.7
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local COMBO = { 1, 0.3, 0.15 }

-- The game's own look, the personal resource display's: its energy bar
-- and frame, the rogue's combo points (shadow, dark orb; lit: orb and red
-- gem). A client without them: plain bars
local ART = {
    bar = "UI-HUD-CoolDownManager-Bar", barBG = "UI-HUD-CoolDownManager-Bar-BG",
    shadow = "uf-roguecp-bg-shadow", off = "uf-roguecp-bg-dis", on = "uf-roguecp-bg", gem = "uf-roguecp-icon-red",
}

local function atlasInfo(name)
    local get = C_Texture and C_Texture.GetAtlasInfo
    return get and get(name) or nil
end

local function gameArt()
    for _, name in pairs(ART) do
        if not atlasInfo(name) then return false end
    end
    return true
end

local function isRogue() return select(2, UnitClass("player")) == "ROGUE" end

function HUD:Enabled()
    return SRH.db ~= nil and SRH.db.hud == true
end

function HUD:SetEnabled(on)
    SRH.db.hud = on and true or false
    self:Attach()
    SRH.EnergyMarks:Layout()
end

---------------------------------------------------------------------------
-- The player's choices (this character's): above or below the health bar,
-- the space between them, the size (the energy bar's thickness and the
-- combo points; as wide as the health bar whatever the size); and the
-- energy as a number on its bar, or not (hudText, off at first)
---------------------------------------------------------------------------
local CHOICES = {
    hudPos = { values = { "above", "below" }, default = "above" },
    hudGap = { min = 0, max = 30, step = 2, default = 6 },
    hudScale = { min = 0.5, max = 1.5, step = 0.1, default = 1 },
}
HUD.CHOICES = CHOICES

-- A saved file edited by hand: what isn't one of the choices, the default
function HUD:CleanSettings(db)
    for key, c in pairs(CHOICES) do
        local v, ok = db[key], false
        if c.values then
            for _, value in ipairs(c.values) do ok = ok or v == value end
        else
            ok = type(v) == "number" and v >= c.min and v <= c.max
        end
        if not ok then db[key] = c.default end
    end
    if type(db.hudText) ~= "boolean" then db.hudText = false end
end

function HUD:SetText(on)
    SRH.db.hudText = on and true or false
    self:Attach()
end

-- The next value (delta 1) or the one before (-1); `wrap`: past the last,
-- the first again (A, a click), else it stays there (the D-pad)
function HUD:Step(key, delta, wrap)
    local c, db = CHOICES[key], SRH.db
    if c.values then
        local n, i = #c.values, 1
        for j, value in ipairs(c.values) do
            if value == db[key] then i = j end
        end
        db[key] = c.values[(i - 1 + delta) % n + 1]
    else
        local count = math.floor((c.max - c.min) / c.step + 0.5)
        local i = math.floor((db[key] - c.min) / c.step + 0.5) + delta
        if wrap and i > count then i = 0 end
        if wrap and i < 0 then i = count end
        i = math.max(0, math.min(count, i))
        -- (from the steps: no drift of the decimals)
        db[key] = c.min + i * c.step
    end
    self:Attach()
end

---------------------------------------------------------------------------
-- The frame: the energy bar, the combo points centered over it
---------------------------------------------------------------------------
local function plainBar(parent, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture(WHITE)
    bar:SetStatusBarColor(r, g, b, 1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.65)
    return bar
end

-- The energy, as on the personal resource display: its bar, its frame
-- (which reaches past the bar, as there)
local function energyBar(parent, art)
    local c = PowerBarColor and PowerBarColor.ENERGY
    local r, g, b = c and c.r or 1, c and c.g or 1, c and c.b or 0
    if not art then return plainBar(parent, r, g, b) end
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture(ART.bar)
    bar:SetStatusBarColor(r, g, b, 1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAtlas(ART.barBG)
    bar.bg:SetPoint("TOPLEFT", -2, 3)
    bar.bg:SetPoint("BOTTOMRIGHT", 6, -7)
    return bar
end

-- Lit, a layer of the combo point drawn over `parent`: a bar from i - 1 to
-- i whose fill is the game's art, its own size
local function litLayer(parent, i, atlas)
    local info = atlasInfo(atlas)
    local layer = CreateFrame("StatusBar", nil, parent)
    layer:SetSize(info and info.width or PIP, info and info.height or PIP)
    layer:SetPoint("CENTER", parent, "CENTER", 0, 0)
    layer:SetStatusBarTexture(atlas)
    layer:SetMinMaxValues(i - 1, i)
    layer:SetValue(0)
    return layer
end

-- Combo point i: the game's shadow and dark orb; over them, lit, its orb
-- and red gem (each layer the child of the one under it: drawn above it)
local function comboPoint(row, i, art)
    local pip = CreateFrame("Frame", nil, row)
    pip:SetSize(PIP, PIP)
    pip:SetPoint("LEFT", row, "LEFT", (i - 1) * (PIP + PIP_GAP), 0)
    if art then
        pip.shadow = pip:CreateTexture(nil, "BACKGROUND", nil, -1)
        pip.shadow:SetAtlas(ART.shadow, true)
        pip.shadow:SetPoint("CENTER", 0, -4)
        pip.off = pip:CreateTexture(nil, "BACKGROUND")
        pip.off:SetAtlas(ART.off, true)
        pip.off:SetPoint("CENTER")
        pip.on = litLayer(pip, i, ART.on)
        pip.gem = litLayer(pip.on, i, ART.gem)
        return pip
    end
    pip.on = plainBar(pip, COMBO[1], COMBO[2], COMBO[3])
    pip.on:SetAllPoints()
    pip.on:SetMinMaxValues(i - 1, i)
    pip.on:SetValue(0)
    local mask = pip.on:CreateMaskTexture()
    mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints()
    pip.on:GetStatusBarTexture():AddMaskTexture(mask)
    pip.on.bg:AddMaskTexture(mask)
    return pip
end

function HUD:Build()
    if self.frame then return end
    local art = gameArt()
    self.art = art
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetHeight(BAR_H + 8 + PIP * PIP_SCALE)
    f:Hide()
    self.frame = f
    self.energy = energyBar(f, art)
    self.energy:SetHeight(BAR_H)
    local row = CreateFrame("Frame", nil, f)
    row:SetScale(PIP_SCALE)
    row:SetSize(PIPS * PIP + (PIPS - 1) * PIP_GAP, PIP)
    self.row = row
    self.pips = {}
    for i = 1, PIPS do self.pips[i] = comboPoint(row, i, art) end
    -- The marks, on its energy bar while the option is on
    self.host = SRH.EnergyMarks:AddHost(function() return HUD:Enabled() and HUD.energy or nil end, BAR_H)
    -- The energy as a number (a choice), centered on its bar, over the
    -- marks (their frame made now, this one above it), in the game's own
    -- font for a bar's value
    self.host:Build(self.energy)
    local number = CreateFrame("Frame", nil, self.energy)
    number:SetAllPoints(self.energy)
    number:SetFrameLevel(self.host.frame:GetFrameLevel() + 2)
    number.text = number:CreateFontString(nil, "OVERLAY")
    local font = TextStatusBarText or GameFontHighlightSmall
    if font then number.text:SetFontObject(font) end
    number.text:SetPoint("CENTER", self.energy, "CENTER", 0, 0)
    number:Hide()
    self.number = number
end

-- In the order the place chosen asks: above the health bar, the combo
-- points over the energy, the energy on the health bar; below, the energy
-- first, the combo points under it. (The combo points' offsets are in their
-- own scale: clear of the energy frame, which reaches 3 above the bar and
-- 7 under it, and of their shadow.)
function HUD:Arrange()
    local f, energy, row = self.frame, self.energy, self.row
    f:SetScale(SRH.db.hudScale)
    energy:ClearAllPoints()
    row:ClearAllPoints()
    if SRH.db.hudPos == "below" then
        energy:SetPoint("TOPLEFT")
        energy:SetPoint("TOPRIGHT")
        row:SetPoint("TOP", energy, "BOTTOM", 0, -12)
    else
        energy:SetPoint("BOTTOMLEFT")
        energy:SetPoint("BOTTOMRIGHT")
        row:SetPoint("BOTTOM", energy, "TOP", 0, 10)
    end
    self.number:SetShown(SRH.db.hudText == true)
end

---------------------------------------------------------------------------
-- Where it goes: the target's nameplate, above or below its health bar as
-- chosen, the space chosen away, as wide. Nothing to show it on (no enemy
-- targeted, its nameplate not shown, not a rogue, the option off): hidden
---------------------------------------------------------------------------
local function targetPlate()
    local get = C_NamePlate and C_NamePlate.GetNamePlateForUnit
    if not get then return nil end
    local ok, plate = pcall(get, "target")
    return ok and plate or nil
end

function HUD:Attach()
    local f = self.frame
    local plate
    if self:Enabled() and isRogue() and (UnitPowerType and UnitPowerType("player")) == ENERGY
        and UnitExists("target") and UnitCanAttack("player", "target") then
        plate = targetPlate()
    end
    if not plate then
        f:Hide()
        return
    end
    self:Arrange()
    local health = plate.UnitFrame and plate.UnitFrame.HealthBarsContainer
    -- (a nameplate made otherwise: its own bounds, as wide as its bars)
    local to, inset = health or plate, health and 0 or 12
    -- (the offset in the frame's own scale: the space chosen whatever the size)
    local gap = SRH.db.hudGap / SRH.db.hudScale
    f:SetParent(plate)
    f:ClearAllPoints()
    if SRH.db.hudPos == "below" then
        f:SetPoint("TOPLEFT", to, "BOTTOMLEFT", inset, -gap)
        f:SetPoint("TOPRIGHT", to, "BOTTOMRIGHT", -inset, -gap)
    else
        f:SetPoint("BOTTOMLEFT", to, "TOPLEFT", inset, gap)
        f:SetPoint("BOTTOMRIGHT", to, "TOPRIGHT", -inset, gap)
    end
    f:Show()
    self:Update()
end

-- The energy and the combo points as they are now (given to the bars as
-- the game gives them)
local function setEnergy(bar)
    bar:SetMinMaxValues(0, UnitPowerMax("player", ENERGY))
    bar:SetValue(UnitPower("player", ENERGY))
end

-- (the text takes it hidden too; formatted by the game if not as it is)
local function setNumber(text)
    local power = UnitPower("player", ENERGY)
    if not pcall(text.SetText, text, power) then text:SetFormattedText("%d", power) end
end

function HUD:Update()
    if not self.frame:IsShown() then return end
    pcall(setEnergy, self.energy)
    if self.number:IsShown() and not pcall(setNumber, self.number.text) then self.number.text:SetText("") end
    -- (the count only handed on, never tested: it may be hidden)
    local ok, points = pcall(GetComboPoints, "player", "target")
    if not ok then points = 0 end
    for _, pip in ipairs(self.pips) do
        pip.on:SetValue(points)
        if pip.gem then pip.gem:SetValue(points) end
    end
end

---------------------------------------------------------------------------
-- The window's rows (EnergyMarks' rows, first): the option, while it is on
-- its choices (b.value{ id, label, tip, text, step }, the number a check),
-- and why nothing shows
-- when the game's enemy nameplates are off
---------------------------------------------------------------------------
local function choiceRow(b, key, label, tip, text)
    b.value({ id = key, label = label, tip = tip, text = text,
        step = function(delta, wrap) HUD:Step(key, delta, wrap) end })
end

function HUD:Rows(b)
    b.check({ id = "hud", label = L.HUD_OPTION, tip = L.TIP_HUD,
        get = function() return HUD:Enabled() end,
        set = function(v) HUD:SetEnabled(v) end })
    if not self:Enabled() then return end
    local db = SRH.db
    choiceRow(b, "hudPos", L.HUD_POSITION, L.TIP_HUD_POSITION,
        function() return db.hudPos == "below" and L.HUD_BELOW or L.HUD_ABOVE end)
    choiceRow(b, "hudGap", L.HUD_GAP, L.TIP_HUD_GAP, function() return format("%d", db.hudGap) end)
    choiceRow(b, "hudScale", L.HUD_SCALE, L.TIP_HUD_SCALE,
        function() return format("%d %%", math.floor(db.hudScale * 100 + 0.5)) end)
    b.check({ id = "hudText", label = L.HUD_TEXT, tip = L.TIP_HUD_TEXT,
        get = function() return db.hudText == true end,
        set = function(v) HUD:SetText(v) end })
    if GetCVarBool and not GetCVarBool("nameplateShowEnemies") then
        b.info(format(L.HUD_NO_NAMEPLATES, NAMEPLATE_OPTIONS_LABEL or "Nameplates"))
    end
end

---------------------------------------------------------------------------
-- Events (COMBO_TARGET_CHANGED: the points moved to a new target, the same
-- count; an event this client may not know)
---------------------------------------------------------------------------
HUD:Build()
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "COMBO_TARGET_CHANGED" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        if unit == "player" then HUD:Update() end
    elseif event == "COMBO_TARGET_CHANGED" then
        HUD:Update()
    elseif event == "UNIT_DISPLAYPOWER" then
        if unit == "player" then HUD:Attach() end
    else
        HUD:Attach()
    end
end)
