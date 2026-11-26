local _, SRH = ...
local L = SRH.L

-- Energy marks (from Easy Controller - Forever's test, EnergyMarks.lua): on
-- the game's personal resource display (Edit Mode), the rogue's energy bar
-- gets up to five thin marks, each at the energy the player sets (the
-- addon's window, per character), dim below it, lit once there is that
-- much. Fixed values: nothing read of the spells' costs. The same marks on
-- the energy bar above the target's health bar (an option, TargetHud.lua).
-- In combat the game may hide power from addons (secret values): the marks
-- are placed with the last maximum known (placed again after the fight),
-- and lit through the game's own UnitPowerPercent with step curves, handed
-- to the textures.
local EM = {}
SRH.EnergyMarks = EM

local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3
local DIM, LIT = { 1, 1, 1, 0.35 }, { 1, 0.85, 0.2, 1 }
local WIDTH = 2
local SLOTS = 5
EM.SLOTS = SLOTS

local function isRogue() return select(2, UnitClass("player")) == "ROGUE" end

local function powerBar()
    local prd = PersonalResourceDisplayFrame
    return prd and prd.PowerBar or nil
end

local function inCombat()
    return InCombatLockdown and InCombatLockdown() == true
end

-- The maximum energy, nil while the game hides it from addons
local function readMax()
    local ok, max = pcall(function()
        local m = UnitPowerMax("player", ENERGY)
        return (m and m > 0) and m or nil
    end)
    return ok and max or nil
end

---------------------------------------------------------------------------
-- The values: this character's (its own saved variables), five of them,
-- each an energy or 0 (none)
---------------------------------------------------------------------------
-- (a file edited by hand: what isn't a whole energy, none)
function EM:Values()
    local db = SRH.db
    if type(db.values) ~= "table" then db.values = {} end
    local values = db.values
    for k in pairs(values) do
        if type(k) ~= "number" or k < 1 or k > SLOTS or k % 1 ~= 0 then values[k] = nil end
    end
    for i = 1, SLOTS do
        local v = values[i]
        if type(v) ~= "number" or v < 0 or v % 1 ~= 0 then values[i] = 0 end
    end
    return values
end

-- The highest value: the maximum energy, less one (a mark there would only
-- light at full)
function EM:Top()
    return (readMax() or self.max or 100) - 1
end

-- One less or more (the D-pad, a right click, the wheel), staying at the
-- ends; `wrap` (A, a click): past the highest, none again
function EM:Step(i, delta, wrap)
    local values, top = self:Values(), self:Top()
    local v = values[i] + delta
    if wrap and v > top then v = 0 end
    if wrap and v < 0 then v = top end
    values[i] = math.max(0, math.min(top, v))
    self:Layout()
end

---------------------------------------------------------------------------
-- 1.1 and before: marks by spell (marks = { [spell name] = true }), at the
-- cost the game gave. Once, each spell marked becomes a value (the five
-- cheapest), its regular cost: the one kept (costs, 1.1.1's test builds),
-- else the game's, read when WoW Forever's Poised can't lower it (out of a
-- fight, the energy below full). Then the spells are forgotten. A value
-- set meanwhile: none taken
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

local function belowMax()
    local ok, below = pcall(function()
        return UnitPower("player", ENERGY) < UnitPowerMax("player", ENERGY)
    end)
    return ok and below == true
end

-- The spell book's energy costs by name, nil while it isn't there
local function bookCosts()
    local book = C_SpellBook
    if not (book and book.GetNumSpellBookSkillLines) or book.GetNumSpellBookSkillLines() == 0 then return nil end
    local costs = {}
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    for line = 1, book.GetNumSpellBookSkillLines() do
        local info = book.GetSpellBookSkillLineInfo(line)
        if info then
            for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = book.GetSpellBookItemInfo(i, bank)
                if item and item.spellID and item.name and not item.isPassive and not costs[item.name] then
                    costs[item.name] = energyCost(item.spellID)
                end
            end
        end
    end
    return costs
end

function EM:Migrate()
    local db = SRH.db
    if db.marks == nil then return end
    local values, names, set = self:Values(), {}, false
    if type(db.marks) == "table" and isRogue() then
        for name, on in pairs(db.marks) do
            if type(name) == "string" and on == true then names[#names + 1] = name end
        end
    end
    for i = 1, SLOTS do set = set or values[i] > 0 end
    if #names > 0 and not set then
        local kept = type(db.costs) == "table" and db.costs or {}
        local costs, book = {}, nil
        for _, name in ipairs(names) do
            local cost = kept[name]
            if not (type(cost) == "number" and cost > 0 and cost % 1 == 0) then
                if not book then
                    -- (the game's: not yet, if Poised may lower it)
                    if inCombat() or not belowMax() then return end
                    book = bookCosts()
                    if not book then return end
                end
                cost = book[name]
            end
            if cost then costs[#costs + 1] = cost end
        end
        table.sort(costs)
        for i = 1, math.min(SLOTS, #costs) do values[i] = costs[i] end
    end
    db.marks, db.costs = nil, nil
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

-- Lit at `value` and above: a step from dim to lit half an energy below it
-- (the game's percentage, a float, never falls just short of it)
local function litCurve(value, max)
    if not curvesOk() then return nil end
    local ok, curve = pcall(function()
        local c = C_CurveUtil.CreateColorCurve()
        local step = Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step
        if step and c.SetType then c:SetType(step) end
        c:AddPoint(0, CreateColor(DIM[1], DIM[2], DIM[3], DIM[4]))
        c:AddPoint((value - 0.5) / max, CreateColor(LIT[1], LIT[2], LIT[3], LIT[4]))
        return c
    end)
    return ok and curve or nil
end

-- The bars the marks go on (hosts): the personal resource display's
-- (EM.prd), and the one above the target's health bar (TargetHud.lua, an
-- option). getBar() gives the bar, nil when there is none now. A host with
-- a `height` (the bar's, its own) places each mark where a hidden status
-- bar of the mark, from 0 to the maximum, ends at its value: no size read
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

-- Each value's mark, the others hidden
function Host:Place(bar, values, max)
    self:Build(bar)
    local width, height
    if not self.height then width, height = bar:GetWidth() or 0, bar:GetHeight() or 0 end
    for i, value in ipairs(values) do
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
        m.value, m.curve = value, litCurve(value, max)
        m.tex:ClearAllPoints()
        if self.height then
            m.at:SetMinMaxValues(0, max)
            m.at:SetValue(value)
            m.tex:SetSize(WIDTH, self.height + 4)
            m.tex:SetPoint("CENTER", m.at:GetStatusBarTexture(), "RIGHT", 0, 0)
        else
            m.tex:SetSize(WIDTH, height + 4)
            m.tex:SetPoint("CENTER", bar, "LEFT", width * value / max, 0)
        end
        m.tex:Show()
    end
    for i = #values + 1, #self.marks do
        self.marks[i].tex:Hide()
        self.marks[i].value = nil
    end
    self.frame:SetShown(#values > 0)
end

-- Placed at each value, on every host bar there is
function EM:Layout()
    if not SRH.db then return end
    self:Migrate()
    local bars, any = {}, false
    for i, host in ipairs(self.hosts) do
        bars[i] = host.getBar()
        any = any or bars[i] ~= nil
    end
    if not (any and isRogue() and (UnitPowerType and UnitPowerType("player")) == ENERGY) then
        for _, host in ipairs(self.hosts) do host:Hide() end
        return
    end
    local max = readMax()
    if max then
        self.max, self.pending = max, nil
    else
        -- (hidden from addons now: the last one known, a fight doesn't change
        -- it; placed again after the fight)
        self.pending = true
        max = self.max
        if not max then return end
    end
    -- (in the order of their values; one at the maximum or above: none)
    local values = {}
    for _, v in ipairs(self:Values()) do
        if v > 0 and v < max then values[#values + 1] = v end
    end
    table.sort(values)
    for i, host in ipairs(self.hosts) do
        if bars[i] then host:Place(bars[i], values, max) else host:Hide() end
    end
    self:Light()
end

local function curveColor(m)
    m.tex:SetVertexColor(UnitPowerPercent("player", ENERGY, false, m.curve):GetRGBA())
end

local function plainColor(m)
    local c = UnitPower("player", ENERGY) >= m.value and LIT or DIM
    m.tex:SetVertexColor(c[1], c[2], c[3], c[4])
end

-- Lit or dim, as the energy is now
function Host:Light()
    if not (self.frame and self.frame:IsShown()) then return end
    for _, m in ipairs(self.marks) do
        if m.value then
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
-- then the five marks, each a value. b.header(text), b.info(text),
-- b.check{ id, label, tip, get, set }, b.value{ id, label, tip, text, step }
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
    for i = 1, SLOTS do
        b.value({ id = "mark" .. i, label = format(L.MARK_N, i), tip = L.TIP_MARK,
            text = function()
                local v = EM:Values()[i]
                return v > 0 and format("%d", v) or L.MARK_NONE
            end,
            step = function(delta, wrap) EM:Step(i, delta, wrap) end })
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "PLAYER_REGEN_ENABLED", "UNIT_POWER_FREQUENT" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_POWER_FREQUENT" then
        if unit == "player" then
            EM:Light()
            -- (1.1's marks by spell, waiting for the energy below full)
            if SRH.db and SRH.db.marks ~= nil then EM:Layout() end
        end
    elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        if unit == "player" then EM:Layout() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if EM.pending or (SRH.db and SRH.db.marks ~= nil) then EM:Layout() end
    else
        EM:Layout()
    end
end)
