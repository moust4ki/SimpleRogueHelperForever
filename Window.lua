local _, SRH = ...
local L = SRH.L

-- The addon's settings window (/srh, its key binding, Escape > Options >
-- AddOns): this character's energy spells, each marked or not
-- (EnergyMarks.lua gives the rows). Driven with the gamepad (D-pad up /
-- down: move, A: check, B: close, LB / RB or D-pad left / right: page) or
-- the mouse. As Easy Controller - Forever's panel it is our own frame, never
-- a game panel: while it is shown the pad is bound to hidden buttons of
-- ours, out of combat only (a button held when it opens: once released),
-- and let go when it hides. A fight closes it.
local W = {}
SRH.Window = W

local WIDTH, ROW_H, PER_PAGE, PAD = 380, 26, 8, 14
local GOLD = { 1, 0.82, 0 }
local GREY = { 0.62, 0.62, 0.62 }

---------------------------------------------------------------------------
-- Pad input while open: hidden buttons bound with priority
---------------------------------------------------------------------------
local NAV = {
    PADDUP = "UP", PADDDOWN = "DOWN", PADDLEFT = "LEFT", PADDRIGHT = "RIGHT",
    PAD1 = "A", PAD2 = "B", PADLSHOULDER = "LB", PADRSHOULDER = "RB", ESCAPE = "B",
}
-- Held triggers may add modifiers to the keys
local PREFIXES = { "", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-" }
local REPEAT = { UP = true, DOWN = true }
local BUTTON = "SimpleRogueHelperPad"
W.NAV, W.BUTTON = NAV, BUTTON

-- The help bar's buttons: the game's own icons when this client has them
local GLYPHS = {
    A = { "Gamepad_Ltr_A_64", "Gamepad_Ltr_A_32" },
    B = { "Gamepad_Ltr_B_64", "Gamepad_Ltr_B_32" },
    LB = { "Gamepad_Ltr_LShoulder_64", "Gamepad_Gen_LShoulder_64" },
    RB = { "Gamepad_Ltr_RShoulder_64", "Gamepad_Gen_RShoulder_64" },
}

local function glyph(key)
    for _, name in ipairs(GLYPHS[key]) do
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
            return format("|A:%s:16:16|a", name)
        end
    end
    return "|cffffd100" .. key .. "|r"
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

---------------------------------------------------------------------------
-- The rows: EnergyMarks' header, its notes, its checks (8 a page)
---------------------------------------------------------------------------
function W:Refresh()
    local keep = self.checks and self.checks[self.focus or 0] and self.checks[self.focus].id
    local header, infos, checks = nil, {}, {}
    SRH.EnergyMarks:Rows({
        header = function(text) header = header or text end,
        info = function(text) infos[#infos + 1] = text end,
        check = function(row) checks[#checks + 1] = row end,
    })
    self.header, self.infos, self.checks = header, infos, checks
    -- Back on the spell focused before, else the first
    self.focus = 1
    for i, row in ipairs(checks) do
        if row.id == keep then self.focus = i end
    end
end

function W:Pages()
    return math.max(1, math.ceil(#(self.checks or {}) / PER_PAGE))
end

function W:Page()
    return math.ceil((self.focus or 1) / PER_PAGE)
end

function W:Move(delta)
    local n = #self.checks
    if n == 0 then return end
    self.focus = clamp(self.focus + delta, 1, n)
    self:Render()
end

-- Another page, on the same line of it (or the last one there is)
function W:StepPage(delta)
    local n = #self.checks
    local page = clamp(self:Page() + delta, 1, self:Pages())
    if n == 0 or page == self:Page() then return end
    local line = (self.focus - 1) % PER_PAGE
    self.focus = math.min(n, (page - 1) * PER_PAGE + line + 1)
    self:Render()
end

-- A (or a click): the focused spell marked, or not any more
function W:Act(index)
    local row = self.checks[index or self.focus]
    if not row then return end
    self.focus = index or self.focus
    row.set(not row.get())
    self:Render()
end

function W:Press(name)
    if name == "UP" or name == "DOWN" then
        self:Move(name == "UP" and -1 or 1)
    elseif name == "LB" or name == "LEFT" or name == "RB" or name == "RIGHT" then
        self:StepPage((name == "LB" or name == "LEFT") and -1 or 1)
    elseif name == "A" then
        self:Act()
    elseif name == "B" then
        self:Close()
    end
end

---------------------------------------------------------------------------
-- The frame: a dark box with a thin gold rim, its title, the rows, the page
-- and the help bar
---------------------------------------------------------------------------
local function text(parent, font, color)
    local t = parent:CreateFontString(nil, "OVERLAY", font)
    t:SetJustifyH("LEFT")
    if color then t:SetTextColor(color[1], color[2], color[3]) end
    return t
end

local function rim(f)
    local edges = {
        { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
    }
    for _, e in ipairs(edges) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.55)
        t:SetPoint(e[1])
        t:SetPoint(e[2])
        if e[3] then t:SetWidth(e[3]) end
        if e[4] then t:SetHeight(e[4]) end
    end
end

local function newRow(f)
    local row = CreateFrame("Button", nil, f)
    row:SetSize(WIDTH - 2 * PAD, ROW_H)
    row.hl = row:CreateTexture(nil, "BACKGROUND")
    row.hl:SetAllPoints()
    row.hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.14)
    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.9)
    row.bar:SetPoint("TOPLEFT")
    row.bar:SetPoint("BOTTOMLEFT")
    row.bar:SetWidth(2)
    -- The check box
    row.box = row:CreateTexture(nil, "ARTWORK")
    row.box:SetColorTexture(0.6, 0.6, 0.6, 0.9)
    row.box:SetSize(16, 16)
    row.box:SetPoint("LEFT", 8, 0)
    row.inner = row:CreateTexture(nil, "ARTWORK", nil, 1)
    row.inner:SetColorTexture(0.08, 0.08, 0.08, 1)
    row.inner:SetSize(14, 14)
    row.inner:SetPoint("CENTER", row.box, "CENTER", 0, 0)
    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetSize(22, 22)
    row.check:SetPoint("CENTER", row.box, "CENTER", 0, 0)
    row.label = text(row, "GameFontHighlight")
    row.label:SetPoint("LEFT", row.box, "RIGHT", 8, 0)
    row.label:SetPoint("RIGHT", -6, 0)
    row:SetScript("OnEnter", function(self)
        if self.index and W.focus ~= self.index then
            W.focus = self.index
            W:Render()
        end
    end)
    row:SetScript("OnClick", function(self) W:Act(self.index) end)
    return row
end

local function pagerButton(f, label, delta)
    local b = CreateFrame("Button", nil, f)
    b:SetSize(24, 18)
    b.label = text(b, "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetJustifyH("CENTER")
    b.label:SetText(label)
    b:SetScript("OnClick", function() W:StepPage(delta) end)
    return b
end

function W:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(WIDTH, 200)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:Hide()
    self.frame = f
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.06, 0.94)
    rim(f)

    f.title = text(f, "GameFontNormal")
    f.title:SetPoint("TOPLEFT", PAD, -10)
    f.title:SetText(SRH.TITLE)
    local close = CreateFrame("Button", nil, f)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    close:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up", "ADD")
    close:SetScript("OnClick", function() W:Close() end)
    f.close = close

    f.header = text(f, "GameFontHighlight")
    f.info = text(f, "GameFontHighlightSmall", { 1, 0.6, 0.3 })
    f.tip = text(f, "GameFontHighlightSmall", GREY)
    for _, t in ipairs({ f.header, f.info, f.tip }) do
        t:SetWidth(WIDTH - 2 * PAD)
        t:SetWordWrap(true)
    end
    f.rows = {}
    for i = 1, PER_PAGE do f.rows[i] = newRow(f) end
    f.pager = text(f, "GameFontHighlightSmall")
    f.pager:SetJustifyH("CENTER")
    f.prev = pagerButton(f, "<", -1)
    f.next = pagerButton(f, ">", 1)
    f.help = text(f, "GameFontHighlightSmall", GREY)
    f.help:SetWidth(WIDTH - 2 * PAD)

    f:SetScript("OnMouseWheel", function(_, delta) W:StepPage(delta > 0 and -1 or 1) end)
    f:SetScript("OnUpdate", function() W:OnUpdate() end)
    -- The pad follows the window: taken when it shows, let go when it hides
    -- (closed, or the whole interface hidden)
    f:SetScript("OnShow", function() W:BindPad() end)
    f:SetScript("OnHide", function()
        W:UnbindPad()
        W.repeatName = nil
    end)
end

-- Each part under the one before; the window as tall as what it shows
function W:Render()
    local f = self.frame
    if not f then return end
    local checks = self.checks or {}
    local n, pages = #checks, self:Pages()
    if n > 0 then self.focus = clamp(self.focus or 1, 1, n) end
    local page = self:Page()
    local focused = checks[self.focus]
    local y = -34

    local function place(t, value, gap)
        t:SetShown(value ~= nil)
        if value == nil then return end
        t:SetText(value)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, y)
        y = y - (t:GetStringHeight() or 14) - gap
    end
    place(f.header, self.header, 6)
    place(f.info, #self.infos > 0 and table.concat(self.infos, "\n") or nil, 6)
    place(f.tip, focused and focused.tip or nil, 8)

    for i, row in ipairs(f.rows) do
        local index = (page - 1) * PER_PAGE + i
        local c = checks[index]
        row.index = c and index or nil
        row:SetShown(c ~= nil)
        if c then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, y)
            y = y - ROW_H
            row.label:SetText(c.label)
            row.check:SetShown(c.get() and true or false)
            row.hl:SetShown(index == self.focus)
            row.bar:SetShown(index == self.focus)
        end
    end
    if n > 0 then y = y - 6 end

    -- The page, when there are more than one
    local paged = pages > 1
    for _, part in ipairs({ f.pager, f.prev, f.next }) do part:SetShown(paged) end
    if paged then
        f.pager:SetText(format("%s %d / %d", L.V_PAGE, page, pages))
        f.pager:ClearAllPoints()
        f.pager:SetPoint("TOP", f, "TOP", 0, y)
        f.prev:ClearAllPoints()
        f.prev:SetPoint("RIGHT", f.pager, "LEFT", -8, 0)
        f.next:ClearAllPoints()
        f.next:SetPoint("LEFT", f.pager, "RIGHT", 8, 0)
        local first, last = page == 1, page == pages
        f.prev.label:SetTextColor(first and GREY[1] or GOLD[1], first and GREY[2] or GOLD[2], first and GREY[3] or GOLD[3])
        f.next.label:SetTextColor(last and GREY[1] or GOLD[1], last and GREY[2] or GOLD[2], last and GREY[3] or GOLD[3])
        y = y - 22
    end

    -- What the pad does here
    local hints = {}
    if focused then
        hints[#hints + 1] = glyph("A") .. " " .. (focused.get() and L.V_UNCHECK or L.V_CHECK)
    end
    hints[#hints + 1] = glyph("B") .. " " .. L.V_CLOSE
    if paged then hints[#hints + 1] = glyph("LB") .. glyph("RB") .. " " .. L.V_PAGE end
    f.help:SetText(table.concat(hints, "    "))
    f.help:ClearAllPoints()
    f.help:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, y)
    y = y - (f.help:GetStringHeight() or 14) - 12
    f:SetHeight(-y)
end

---------------------------------------------------------------------------
-- The pad's hidden buttons. A press acts at once (D-pad up / down repeat
-- while held); B acts on release: closing the window on the press would
-- leave the release to the game alone
---------------------------------------------------------------------------
function W:CreateInput()
    if self.input then return end
    self.input = true
    for key, name in pairs(NAV) do
        local b = CreateFrame("Button", BUTTON .. key)
        b:SetSize(1, 1)
        b:RegisterForClicks("AnyDown", "AnyUp")
        b:SetScript("OnClick", function(_, _, down)
            if name == "B" then
                if down == false then W:Press(name) end
                return
            end
            if down == false then
                if W.repeatName == name then W.repeatName = nil end
                return
            end
            if REPEAT[name] then
                W.repeatName, W.repeatKey, W.repeatAt = name, key, GetTime() + 0.35
            end
            W:Press(name)
        end)
    end
end

local function bindKey(f, key)
    local name = BUTTON .. key
    if key == "ESCAPE" then
        SetOverrideBindingClick(f, true, key, name)
    else
        for _, prefix in ipairs(PREFIXES) do SetOverrideBindingClick(f, true, prefix .. key, name) end
    end
end

-- A button still held (the one of the key binding that opened the
-- window...) is taken only once released: its release belongs to the game,
-- which saw it pressed
function W:BindPad()
    if InCombatLockdown() or not self.frame then return end
    local f = self.frame
    ClearOverrideBindings(f)
    self.heldKeys = {}
    for key in pairs(NAV) do
        if key ~= "ESCAPE" and IsKeyDown and IsKeyDown(key) then
            self.heldKeys[key] = true
        else
            bindKey(f, key)
        end
    end
end

function W:BindReleasedKeys()
    if not self.heldKeys or not next(self.heldKeys) or InCombatLockdown() then return end
    for key in pairs(self.heldKeys) do
        if not IsKeyDown(key) then
            self.heldKeys[key] = nil
            bindKey(self.frame, key)
        end
    end
end

function W:UnbindPad()
    self.heldKeys = nil
    if self.frame and not InCombatLockdown() then ClearOverrideBindings(self.frame) end
end

function W:OnUpdate()
    self:BindReleasedKeys()
    -- Its release went elsewhere (the game rebound the pad): over
    if self.repeatName and IsKeyDown and self.repeatKey and not IsKeyDown(self.repeatKey) then
        self.repeatName = nil
    end
    if self.repeatName and GetTime() >= self.repeatAt then
        self.repeatAt = GetTime() + 0.08
        self:Press(self.repeatName)
    end
end

---------------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------------
function W:IsOpen()
    return (self.frame and self.frame:IsShown()) or false
end

function W:Open()
    if SRH:BlockedByCombat() then return end
    self:Build()
    self:Refresh()
    if not self.frame:IsShown() then self.frame:Show() end
    self:Render()
end

function W:Close()
    if not self:IsOpen() then return end
    self.frame:Hide()
end

-- Nothing of the game's has the pad: no settings, game menu, chat or other
-- gamepad window. overChat: /srh typed in the chat, the chat that sent it
-- doesn't count
local function activeChat()
    local get = ChatFrameUtil and ChatFrameUtil.GetActiveWindow or ChatEdit_GetActiveWindow
    return get and get()
end

local function isChatWindow(active)
    local chat = activeChat()
    return chat ~= nil and chat:HasFocus() and (active == nil or active.editBox == chat)
end

function W:GameIsFree(overChat)
    if SettingsPanel and SettingsPanel:IsShown() then return false end
    if GameMenuFrame and GameMenuFrame:IsShown() then return false end
    local manager = GamepadMode and GamepadMode.FrameControlsManager
    local focused = manager and manager.isUIFocused
    if focused == nil then focused = true end
    local active = focused and manager and manager.GetActiveFrame and manager:GetActiveFrame()
    if overChat and isChatWindow(active or nil) then return true end
    if active then return false end
    local chat = activeChat()
    return not (chat and chat:HasFocus())
end

-- From the game's options or the chat: those have the pad, and closing the
-- options brings back the game menu, whose B would close the window too.
-- Open once the player is back in the game
function W:OpenWhenFree(overChat)
    if self:GameIsFree() then
        self:Open()
        return
    end
    -- Typed in the chat: once the game is done with the send (it would set
    -- its chat's buttons again after ours)
    if overChat and self:GameIsFree(true) then
        C_Timer.After(0.15, function()
            if InCombatLockdown() or self:IsOpen() then return end
            if self:GameIsFree(true) then self:Open() else self:OpenWhenFree() end
        end)
        return
    end
    self.openLater = true
    if SettingsPanel and SettingsPanel:IsShown() then SRH:Print(L.OPEN_LATER) end
    if self.laterTicker then return end
    local tries = 0
    self.laterTicker = C_Timer.NewTicker(0.25, function(ticker)
        tries = tries + 1
        if W.openLater and W:GameIsFree() and not InCombatLockdown() then
            W.openLater = nil
            W:Open()
        end
        -- Given up after two minutes
        if not W.openLater or tries > 480 then
            ticker:Cancel()
            W.laterTicker, W.openLater = nil, nil
        end
    end)
end

-- /srh and the key binding: open, or closed if it is
function W:Toggle(overChat)
    if self:IsOpen() then return self:Close() end
    if SRH:BlockedByCombat() then return end
    self:OpenWhenFree(overChat)
end

---------------------------------------------------------------------------
-- The game's settings panel (Escape > Options > AddOns > SimpleRogueHelper
-- - Forever) only points to the window. A plain button: no dropdowns or
-- StaticPopups, which go through WoW Forever's gamepad UI
---------------------------------------------------------------------------
function W:RegisterOptions()
    if self.optionsPanel then return end
    local panel = CreateFrame("Frame")
    panel.name = SRH.TITLE
    panel:Hide()
    self.optionsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(SRH.TITLE)
    local section = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    section:SetText(L.SEC_MARKS)
    local about = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    about:SetPoint("TOPLEFT", section, "BOTTOMLEFT", 0, -8)
    about:SetWidth(560)
    about:SetJustifyH("LEFT")
    about:SetText(L.TIP_SEC_MARKS)
    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -12)
    hint:SetWidth(560)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.SETTINGS_HINT)
    local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    open:SetSize(240, 26)
    open:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -14)
    open:SetText(L.OPEN)
    open:SetScript("OnClick", function() W:OpenWhenFree() end)
    panel.open = open

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

---------------------------------------------------------------------------
-- At load (Core.lua, ADDON_LOADED)
---------------------------------------------------------------------------
function W:Init()
    self:CreateInput()
    self:RegisterOptions()
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED", "PLAYER_TALENT_UPDATE",
        "CHARACTER_POINTS_CHANGED", "TRAIT_CONFIG_UPDATED", "LEARNED_SPELL_IN_SKILL_LINE" }) do
        pcall(events.RegisterEvent, events, event)
    end
    events:SetScript("OnEvent", function(_, event)
        -- A fight: closed while the pad can still be let go
        if event == "PLAYER_REGEN_DISABLED" then return W:Close() end
        -- The spell book or the talents changed: the list again
        if W:IsOpen() then
            W:Refresh()
            W:Render()
        end
    end)
    -- A game window opened meanwhile (Start menu...) rebinds the pad when it
    -- closes: take the window's keys back
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("Gamepad.RefreshFrameFocus", function()
            C_Timer.After(0, function()
                local manager = GamepadMode and GamepadMode.FrameControlsManager
                local focused = manager and manager.GetActiveFrame and manager:GetActiveFrame()
                if W:IsOpen() and (not focused or isChatWindow(focused)) and not InCombatLockdown() then W:BindPad() end
            end)
        end, W)
    end
end

SLASH_SIMPLEROGUEHELPER1 = "/srh"
-- The chat edit box is still sending this command: opened once it is done
SlashCmdList.SIMPLEROGUEHELPER = function() W:Toggle(true) end

-- The key binding (Bindings.xml)
function SimpleRogueHelper_ToggleWindow() W:Toggle() end
