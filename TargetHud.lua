local _, SRH = ...
local L = SRH.L

-- Under the target's health bar (an option, the window, off at first): on
-- the enemy's own nameplate, the energy, with its marks (EnergyMarks.lua),
-- and the combo points centered under it, all in the one place the eye
-- already is. It sits under the nameplate's cast bar, never over it (a cast
-- to kick). It works in combat too, where the game may hide these values
-- from addons: they go straight to status bars, which show them without
-- the addon reading them, and no size is read (the nameplate may keep its
-- own from addons). A combo point is a bar of its own from i - 1 to i: full
-- once there are i, whatever the count, hidden or not.
local HUD = {}
SRH.TargetHud = HUD

local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
local BAR_H, PIP, PIP_GAP, PIPS = 6, 9, 4, 5
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local COMBO = { 1, 0.3, 0.15 }

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
local function statusBar(parent, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture(WHITE)
    bar:SetStatusBarColor(r, g, b, 1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.65)
    return bar
end

function HUD:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetHeight(BAR_H + 3 + PIP)
    f:Hide()
    self.frame = f
    local c = PowerBarColor and PowerBarColor.ENERGY
    self.energy = statusBar(f, c and c.r or 1, c and c.g or 1, c and c.b or 0)
    self.energy:SetPoint("TOPLEFT")
    self.energy:SetPoint("TOPRIGHT")
    self.energy:SetHeight(BAR_H)
    local row = CreateFrame("Frame", nil, f)
    row:SetSize(PIPS * PIP + (PIPS - 1) * PIP_GAP, PIP)
    row:SetPoint("TOP", self.energy, "BOTTOM", 0, -3)
    self.pips = {}
    for i = 1, PIPS do
        local pip = statusBar(row, COMBO[1], COMBO[2], COMBO[3])
        pip:SetSize(PIP, PIP)
        pip:SetPoint("LEFT", row, "LEFT", (i - 1) * (PIP + PIP_GAP), 0)
        pip:SetMinMaxValues(i - 1, i)
        pip:SetValue(0)
        local mask = pip:CreateMaskTexture()
        mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints()
        pip:GetStatusBarTexture():AddMaskTexture(mask)
        pip.bg:AddMaskTexture(mask)
        self.pips[i] = pip
    end
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
    if cast then
        f:SetPoint("TOPLEFT", cast, "BOTTOMLEFT", 0, -2)
        f:SetPoint("TOPRIGHT", cast, "BOTTOMRIGHT", 0, -2)
    else
        -- (a nameplate made otherwise: under it, as wide as its bars)
        f:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 12, -2)
        f:SetPoint("TOPRIGHT", plate, "BOTTOMRIGHT", -12, -2)
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
    for _, pip in ipairs(self.pips) do pip:SetValue(points) end
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
