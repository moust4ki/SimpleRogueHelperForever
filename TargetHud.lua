local _, SRH = ...
local L = SRH.L

-- Under the target's health bar (an option, the window, off at first): on
-- the enemy's own nameplate, the energy, with its marks (EnergyMarks.lua),
-- and the combo points centered under it, all in the one place the eye
-- already is, drawn with the game's own art (the personal resource
-- display's). It sits under the nameplate's cast bar, never over it (a cast
-- to kick). It works in combat too, where the game may hide these values
-- from addons: they go straight to status bars, which show them without
-- the addon reading them, and no size is read (the nameplate may keep its
-- own from addons). A combo point is a bar of its own from i - 1 to i: full
-- once there are i, whatever the count, hidden or not.
local HUD = {}
SRH.TargetHud = HUD

local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
-- The combo points as the game draws them (20 x 20, 4 apart)
local BAR_H, PIP, PIP_GAP, PIPS = 12, 20, 4, 5
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
-- The frame: the energy bar, the combo points centered under it
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
    f:SetHeight(BAR_H + 8 + PIP)
    f:Hide()
    self.frame = f
    self.energy = energyBar(f, art)
    self.energy:SetPoint("TOPLEFT")
    self.energy:SetPoint("TOPRIGHT")
    self.energy:SetHeight(BAR_H)
    local row = CreateFrame("Frame", nil, f)
    row:SetSize(PIPS * PIP + (PIPS - 1) * PIP_GAP, PIP)
    row:SetPoint("TOP", self.energy, "BOTTOM", 0, -8)
    self.pips = {}
    for i = 1, PIPS do self.pips[i] = comboPoint(row, i, art) end
    -- The marks, on its energy bar while the option is on
    self.host = SRH.EnergyMarks:AddHost(function() return HUD:Enabled() and HUD.energy or nil end, BAR_H)
end

---------------------------------------------------------------------------
-- Where it goes: the target's nameplate, under its cast bar. Nothing to
-- show it on (no enemy targeted, its nameplate not shown, not a rogue, the
-- option off): hidden
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
    local cast = plate.UnitFrame and plate.UnitFrame.CastBarsContainer
    f:SetParent(plate)
    f:ClearAllPoints()
    -- (the energy bar's frame reaches 3 above it)
    if cast then
        f:SetPoint("TOPLEFT", cast, "BOTTOMLEFT", 0, -4)
        f:SetPoint("TOPRIGHT", cast, "BOTTOMRIGHT", 0, -4)
    else
        -- (a nameplate made otherwise: under it, as wide as its bars)
        f:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 12, -4)
        f:SetPoint("TOPRIGHT", plate, "BOTTOMRIGHT", -12, -4)
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

function HUD:Update()
    if not self.frame:IsShown() then return end
    pcall(setEnergy, self.energy)
    -- (the count only handed on, never tested: it may be hidden)
    local ok, points = pcall(GetComboPoints, "player", "target")
    if not ok then points = 0 end
    for _, pip in ipairs(self.pips) do
        pip.on:SetValue(points)
        if pip.gem then pip.gem:SetValue(points) end
    end
end

---------------------------------------------------------------------------
-- The window's row (EnergyMarks' rows, first): the option, and why nothing
-- shows when the game's enemy nameplates are off
---------------------------------------------------------------------------
function HUD:Rows(b)
    b.check({ id = "hud", label = L.HUD_OPTION, tip = L.TIP_HUD,
        get = function() return HUD:Enabled() end,
        set = function(v) HUD:SetEnabled(v) end })
    if self:Enabled() and GetCVarBool and not GetCVarBool("nameplateShowEnemies") then
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
