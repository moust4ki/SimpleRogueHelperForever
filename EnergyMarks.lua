local _, SRH = ...
local L = SRH.L

-- Energy marks (from Easy Controller - Forever's test, EnergyMarks.lua): on
-- the game's personal resource display (Edit Mode), the rogue's energy bar
-- gets a thin mark at the energy each chosen spell costs (the game's cost:
-- a talent that lowers it moves it), dim below it, lit once there is
-- enough energy to cast it. Chosen per character (the addon's window). The
-- same marks on the energy bar above the target's health bar (an option,
-- TargetHud.lua). In
-- combat the game may hide power from addons (secret values): the marks are
-- placed out of it when they can't be in it (the maximum and the costs
-- change outside fights), and lit through the game's own UnitPowerPercent
-- with step curves, handed to the textures.
local EM = {}
SRH.EnergyMarks = EM

local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
local DIM, LIT = { 1, 1, 1, 0.35 }, { 1, 0.85, 0.2, 1 }
local WIDTH = 2

local function isRogue() return select(2, UnitClass("player")) == "ROGUE" end

local function powerBar()
    local prd = PersonalResourceDisplayFrame
    return prd and prd.PowerBar or nil
end

---------------------------------------------------------------------------
-- What is marked: this character's (its own saved variables), by spell
-- name (a new rank keeps it)
---------------------------------------------------------------------------
function EM:Marked()
    local db = SRH.db
    if type(db.marks) ~= "table" then db.marks = {} end
    local marked = db.marks
    -- (a file edited by hand: only names set to true)
    for k, v in pairs(marked) do
        if type(k) ~= "string" or v ~= true then marked[k] = nil end
    end
    return marked
end

function EM:SetMarked(name, on)
    self:Marked()[name] = on and true or nil
    self:Layout()
end

---------------------------------------------------------------------------
-- The spell book's spells that cost energy: { name, id, cost, icon }, the
-- cheapest first
---------------------------------------------------------------------------
local function energyCost(id)
    local ok, cost = pcall(function()
        local costs = C_Spell and C_Spell.GetSpellPowerCost and C_Spell.GetSpellPowerCost(id)
        for _, c in ipairs(costs or {}) do
            if c.type == ENERGY and type(c.cost) == "number" and c.cost > 0 then return c.cost end
        end
    end)
    return ok and cost or nil
end
EM.EnergyCost = energyCost

function EM:Spells()
    local list, seen = {}, {}
    local book = C_SpellBook
    if not (book and book.GetNumSpellBookSkillLines) then return list end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    for line = 1, book.GetNumSpellBookSkillLines() do
        local info = book.GetSpellBookSkillLineInfo(line)
        if info and not info.shouldHide then
            for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = book.GetSpellBookItemInfo(i, bank)
                if item and item.spellID and item.name and not item.isPassive and not item.isOffSpec
                    and (not spellType or item.itemType == spellType) and not seen[item.name] then
                    local cost = energyCost(item.spellID)
                    if cost then
                        seen[item.name] = true
                        list[#list + 1] = { name = item.name, id = item.spellID, cost = cost, icon = item.iconID }
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.cost ~= b.cost then return a.cost < b.cost end
        return a.name < b.name
    end)
    return list
end

---------------------------------------------------------------------------
-- The marks: on the bar (its child: shown, scaled and moved with it)
---------------------------------------------------------------------------
local stepCurves
local function curvesOk()
    if stepCurves == nil then
        stepCurves = (C_CurveUtil and C_CurveUtil.CreateColorCurve and UnitPowerPercent and CreateColor) and true or false
    end
    return stepCurves
end

-- Lit at `cost` and above: a step from dim to lit half an energy below it
-- (the game's percentage, a float, never falls just short of it)
local function litCurve(cost, max)
    if not curvesOk() then return nil end
    local ok, curve = pcall(function()
        local c = C_CurveUtil.CreateColorCurve()
        local step = Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step
        if step and c.SetType then c:SetType(step) end
        c:AddPoint(0, CreateColor(DIM[1], DIM[2], DIM[3], DIM[4]))
        c:AddPoint((cost - 0.5) / max, CreateColor(LIT[1], LIT[2], LIT[3], LIT[4]))
        return c
    end)
    return ok and curve or nil
end

-- The bars the marks go on (hosts): the personal resource display's
-- (EM.prd), and the one above the target's health bar (TargetHud.lua, an
-- option). getBar() gives the bar, nil when there is none now. A host with
-- a `height` (the bar's, its own) places each mark where a hidden status
-- bar of the mark, from 0 to the maximum, ends at the cost: no size read
-- (the target's nameplate may keep it from addons, in combat too)
local Host = {}
Host.__index = Host
EM.hosts = {}

function EM:AddHost(getBar, height)
    local host = setmetatable({ getBar = getBar, height = height, marks = {} }, Host)
    self.hosts[#self.hosts + 1] = host
    return host
end

EM.prd = EM:AddHost(powerBar)

function Host:Build(bar)
    if self.frame and self.frame:GetParent() == bar then return end
    local f = self.frame or CreateFrame("Frame")
    f:SetParent(bar)
    f:ClearAllPoints()
    f:SetAllPoints(bar)
    -- (a host bar of our own: its child is above it already)
    if not self.height then f:SetFrameLevel((bar:GetFrameLevel() or 0) + 5) end
    self.frame = f
    -- The bar resized (Edit Mode): placed again
    if not self.height and not self.hooked and bar.HookScript then
        self.hooked = true
        bar:HookScript("OnSizeChanged", function() EM:Layout() end)
    end
end

function Host:Hide()
    if self.frame then self.frame:Hide() end
end

-- Each cost's mark, the others hidden
function Host:Place(bar, costs, max)
    self:Build(bar)
    local width, height
    if not self.height then width, height = bar:GetWidth() or 0, bar:GetHeight() or 0 end
    for i, cost in ipairs(costs) do
        local m = self.marks[i]
        if not m then
            m = { tex = self.frame:CreateTexture(nil, "OVERLAY") }
            m.tex:SetColorTexture(1, 1, 1, 1)
            if self.height then
                m.at = CreateFrame("StatusBar", nil, self.frame)
                m.at:SetAllPoints(self.frame)
                m.at:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                m.at:SetStatusBarColor(0, 0, 0, 0)
            end
            self.marks[i] = m
        end
        m.cost, m.curve = cost, litCurve(cost, max)
        m.tex:ClearAllPoints()
        if self.height then
            m.at:SetMinMaxValues(0, max)
            m.at:SetValue(cost)
            m.tex:SetSize(WIDTH, self.height + 4)
            m.tex:SetPoint("CENTER", m.at:GetStatusBarTexture(), "RIGHT", 0, 0)
        else
            m.tex:SetSize(WIDTH, height + 4)
            m.tex:SetPoint("CENTER", bar, "LEFT", width * cost / max, 0)
        end
        m.tex:Show()
    end
    for i = #costs + 1, #self.marks do
        self.marks[i].tex:Hide()
        self.marks[i].cost = nil
    end
    self.frame:SetShown(#costs > 0)
end

-- Placed where each chosen spell's cost is, on every host bar there is
function EM:Layout()
    if not SRH.db then return end
    local bars, any = {}, false
    for i, host in ipairs(self.hosts) do
        bars[i] = host.getBar()
        any = any or bars[i] ~= nil
    end
    if not (any and isRogue() and (UnitPowerType and UnitPowerType("player")) == ENERGY) then
        for _, host in ipairs(self.hosts) do host:Hide() end
        return
    end
    local ok, max = pcall(function()
        local m = UnitPowerMax("player", ENERGY)
        return (m and m > 0) and m or nil
    end)
    -- (hidden from addons now: as they were, placed again after the fight)
    if not (ok and max) then
        self.pending = true
        return
    end
    self.pending = nil
    local marked = self:Marked()
    local costs = {}
    for _, sp in ipairs(self:Spells()) do
        if marked[sp.name] and sp.cost < max then costs[#costs + 1] = sp.cost end
    end
    for i, host in ipairs(self.hosts) do
        if bars[i] then host:Place(bars[i], costs, max) else host:Hide() end
    end
    self:Light()
end

local function curveColor(m)
    m.tex:SetVertexColor(UnitPowerPercent("player", ENERGY, false, m.curve):GetRGBA())
end

local function plainColor(m)
    local c = UnitPower("player", ENERGY) >= m.cost and LIT or DIM
    m.tex:SetVertexColor(c[1], c[2], c[3], c[4])
end

-- Lit or dim, as the energy is now
function Host:Light()
    if not (self.frame and self.frame:IsShown()) then return end
    for _, m in ipairs(self.marks) do
        if m.cost then
            if not (m.curve and pcall(curveColor, m)) and not pcall(plainColor, m) then
                m.tex:SetVertexColor(DIM[1], DIM[2], DIM[3], DIM[4])
            end
        end
    end
end

function EM:Light()
    for _, host in ipairs(self.hosts) do host:Light() end
end

---------------------------------------------------------------------------
-- The window's rows (Window.lua): the option of the target's health bar,
-- then this character's energy spells, each marked or not. b.header(text),
-- b.info(text), b.check{ id, label, tip, get, set }
---------------------------------------------------------------------------
function EM:Rows(b)
    b.header(L.MARKS_NAME)
    if not isRogue() then
        b.info(L.MARKS_ROGUE_ONLY)
        return
    end
    -- First, the option: the marks above the target's health bar too
    local hud = SRH.TargetHud
    if hud then hud:Rows(b) end
    if not powerBar() and not (hud and hud:Enabled()) then b.info(L.MARKS_NO_DISPLAY) end
    local spells = self:Spells()
    if #spells == 0 then
        b.info(L.MARKS_NO_SPELL)
        return
    end
    for _, sp in ipairs(spells) do
        local label = sp.icon and format("|T%s:16:16:0:0|t %s (%d)", sp.icon, sp.name, sp.cost)
            or format("%s (%d)", sp.name, sp.cost)
        b.check({ id = "em_" .. sp.name, label = label, tip = L.TIP_MARKS_SPELL,
            get = function() return EM:Marked()[sp.name] == true end,
            set = function(v) EM:SetMarked(sp.name, v) end })
    end
end

---------------------------------------------------------------------------
-- Events. The talent ones differ between clients (an event this one
-- doesn't know stops RegisterEvent): each tried alone
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "PLAYER_TALENT_UPDATE", "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER", "PLAYER_REGEN_ENABLED", "UNIT_POWER_FREQUENT",
    "CHARACTER_POINTS_CHANGED", "TRAIT_CONFIG_UPDATED", "LEARNED_SPELL_IN_SKILL_LINE" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_POWER_FREQUENT" then
        if unit == "player" then EM:Light() end
    elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        if unit == "player" then EM:Layout() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if EM.pending then EM:Layout() end
    else
        EM:Layout()
    end
end)
