-- The least of the game the tests need (run by lupa, Lua 5.1, from env.py):
-- frames that remember what is done to them, events, timers, override
-- bindings resolved like the game's, the pad's buttons, a rogue with a
-- spell book and an energy bar on the personal resource display, and the
-- globals the addon reads and writes, watched.
ADDON = "SimpleRogueHelperForever"
NS = {}
LOCALE = LOCALE or "frFR"
function GetLocale() return LOCALE end
format = string.format

---------------------------------------------------------------------------
-- Checks and errors
---------------------------------------------------------------------------
fails, errors = 0, {}
function check(name, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print((ok and "  ok    " or "  FAIL  ") .. name .. "  -> " .. tostring(got) .. (ok and "" or ("   (want " .. tostring(want) .. ")")))
end
function section(title) print("== " .. title) end
function safecall(fn, ...)
  if not fn then return end
  local ok, err = pcall(fn, ...)
  if not ok then errors[#errors + 1] = tostring(err) print("  LUA ERROR> " .. tostring(err)) end
end
function finish()
  print("fails: " .. fails)
  print("errors: " .. #errors)
  for _, e in ipairs(errors) do print("  ERR " .. e) end
end
function geterrorhandler() return function(e) errors[#errors + 1] = tostring(e) end end

---------------------------------------------------------------------------
-- Time: GetTime, C_Timer, and each frame's OnUpdate
---------------------------------------------------------------------------
now = 100
function GetTime() return now end
local timers = {}
C_Timer = {
  After = function(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end,
  NewTicker = function(every, fn)
    local t = { at = now + every, every = every, fn = fn }
    t.handle = { Cancel = function() t.done = true end }
    timers[#timers + 1] = t
    return t.handle
  end,
}
allFrames = {}
local function visible(f)
  while f do
    if not f.shown then return false end
    f = f.parent
  end
  return true
end
function tick(elapsed)
  for _, f in ipairs(allFrames) do
    if f.scripts.OnUpdate and visible(f) then safecall(f.scripts.OnUpdate, f, elapsed or 0.016) end
  end
end
-- The timers due meanwhile, in their order, then one frame drawn
function advance(seconds)
  local target = now + seconds
  while true do
    local due
    for _, t in ipairs(timers) do
      if not t.done and t.at <= target and (not due or t.at < due.at) then due = t end
    end
    if not due then break end
    now = due.at
    if due.every then
      due.at = due.at + due.every
      safecall(due.fn, due.handle)
    else
      due.done = true
      safecall(due.fn)
    end
  end
  now = target
  tick(seconds)
end

---------------------------------------------------------------------------
-- Frames, textures, font strings
---------------------------------------------------------------------------
UNKNOWN_EVENTS = { TRAIT_CONFIG_UPDATED = true }
local function normPoint(point, a, b, c, d)
  local rel, relPoint, x, y
  if a == nil then rel, relPoint, x, y = nil, point, 0, 0
  elseif type(a) == "number" then rel, relPoint, x, y = nil, point, a, b
  elseif type(b) == "string" then rel, relPoint, x, y = a, b, c or 0, d or 0
  elseif type(b) == "number" then rel, relPoint, x, y = a, point, b, c or 0
  else rel, relPoint, x, y = a, point, 0, 0 end
  return { point, rel, relPoint, x, y }
end
local NOOP = function() end
local M = {}
local MT = { __index = function(self, k)
  if M[k] then return M[k] end
  -- Any other widget method: does nothing
  if type(k) == "string" and k:find("^%u") then return NOOP end
  return nil
end }
function mock(kind, name, parent)
  return setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, shown = true, level = 1,
    text = "", points = {} }, MT)
end
function M.SetScript(s, n, f) s.scripts[n] = f end
function M.GetScript(s, n) return s.scripts[n] end
function M.HookScript(s, n, f)
  local h = rawget(s, "hooks") or {}
  rawset(s, "hooks", h)
  local prev = h[n]
  h[n] = prev and function(...) prev(...) f(...) end or f
end
function M.RegisterEvent(s, ev)
  if UNKNOWN_EVENTS[ev] then error("Attempt to register unknown event \"" .. ev .. "\"") end
  local e = rawget(s, "events") or {}
  rawset(s, "events", e)
  e[ev] = true
end
function M.UnregisterEvent(s, ev) local e = rawget(s, "events") if e then e[ev] = nil end end
function M.UnregisterAllEvents(s) rawset(s, "events", {}) end
function M.CreateTexture(s) return mock("Texture", nil, s) end
function M.CreateFontString(s) return mock("FontString", nil, s) end
function M.SetParent(s, p) s.parent = p end
function M.GetParent(s) return s.parent end
function M.IsShown(s) return s.shown end
function M.IsVisible(s) return visible(s) end
function M.Show(s)
  local was = visible(s)
  s.shown = true
  if not was and visible(s) and s.scripts.OnShow then safecall(s.scripts.OnShow, s) end
end
function M.Hide(s)
  local was = visible(s)
  s.shown = false
  if was and s.scripts.OnHide then safecall(s.scripts.OnHide, s) end
end
function M.SetShown(s, v) if v then s:Show() else s:Hide() end end
function M.SetPoint(s, ...)
  local n = normPoint(...)
  for i, q in ipairs(s.points) do if q[1] == n[1] then s.points[i] = n return end end
  s.points[#s.points + 1] = n
end
function M.ClearAllPoints(s) s.points = {} end
function M.GetPoint(s, i)
  local q = s.points[i or 1]
  if q then return q[1], q[2], q[3], q[4], q[5] end
end
function M.GetNumPoints(s) return #s.points end
function M.SetAllPoints(s, r) s.allPoints = r or "parent" end
function M.SetSize(s, w, h) s.w, s.h = w, h end
function M.SetWidth(s, w) s.w = w end
function M.SetHeight(s, h) s.h = h end
function M.GetWidth(s) return s.w or 0 end
function M.GetHeight(s) return s.h or 0 end
function M.GetName(s) return s.name end
function M.SetFrameLevel(s, l) s.level = l end
function M.GetFrameLevel(s) return s.level end
function M.SetText(s, v) s.text = v end
function M.GetText(s) return s.text end
function M.GetStringHeight(s)
  local _, lines = tostring(s.text or ""):gsub("\n", "")
  return 14 * (lines + 1)
end
function M.SetTextColor(s, r, g, b) s.textColor = { r, g, b } end
function M.SetVertexColor(s, r, g, b, a) s.color = { r, g, b, a } end
function M.SetColorTexture(s, r, g, b, a) s.colorTexture = { r, g, b, a } end
function M.SetTexture(s, v) s.texture = v end
function M.RegisterForClicks(s, ...) s.clicks = { ... } end
function M.HasFocus(s) return s.focus == true end

-- Frames made by the addon: each name a global (watched, see below), each
-- one's events fired
function CreateFrame(kind, name, parent, template)
  local f = mock(kind, name, parent)
  f.template = template
  allFrames[#allFrames + 1] = f
  if name then
    if fromAddon and fromAddon(2) then addonGlobals[name] = true end
    _G[name] = f
  end
  return f
end
function fire(event, ...)
  for _, f in ipairs(allFrames) do
    local e = rawget(f, "events")
    if e and e[event] and f.scripts.OnEvent then safecall(f.scripts.OnEvent, f, event, ...) end
  end
end

UIParent = mock("Frame", "UIParent")
UIParent.w, UIParent.h = 1920, 1080
chatlog, uiErrors = {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chatlog[#chatlog + 1] = m print("  chat> " .. m) end }
UIErrorsFrame = { AddMessage = function(_, m) uiErrors[#uiErrors + 1] = m print("  UIErrors> " .. m) end }
SlashCmdList = {}
-- A command typed in the chat, as the game finds it (SLASH_<NAME><n>)
function slash(text)
  local cmd, msg = text:match("^(%S+)%s*(.-)$")
  for k, v in pairs(G0 or _G) do
    local name = type(k) == "string" and k:match("^SLASH_(.-)%d+$")
    if name and v == cmd and SlashCmdList[name] then return safecall(SlashCmdList[name], msg) end
  end
  print("  unknown command " .. cmd)
end
categories = {}
Settings = {
  RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name } end,
  RegisterAddOnCategory = function(category) categories[#categories + 1] = category end,
}
local listeners = {}
EventRegistry = { RegisterCallback = function(_, ev, fn, owner)
  listeners[ev] = listeners[ev] or {}
  table.insert(listeners[ev], function(...) fn(owner, ...) end)
end }
function callback(ev, ...) for _, fn in ipairs(listeners[ev] or {}) do safecall(fn, ...) end end
C_Texture = { GetAtlasInfo = function(n) if n:find("^Gamepad_") then return {} end end }
-- The game's windows that may have the pad
SettingsPanel = mock("Frame", "SettingsPanel") SettingsPanel.shown = false
GameMenuFrame = mock("Frame", "GameMenuFrame") GameMenuFrame.shown = false
gamepadFocus = nil
GamepadMode = { FrameControlsManager = { GetActiveFrame = function() return gamepadFocus end } }
activeChat = nil
ChatFrameUtil = { GetActiveWindow = function() return activeChat end }

---------------------------------------------------------------------------
-- Combat, keys held, override bindings (priority first, the latest set
-- wins, then the game's own)
---------------------------------------------------------------------------
combat = false
function InCombatLockdown() return combat end
keysDown = {}
function IsKeyDown(k) return keysDown[k] or false end
overrides, bindSeq = {}, 0
native = { ESCAPE = "TOGGLEGAMEMENU" }
for _, k in ipairs({ "PAD1", "PAD2", "PAD3", "PAD4", "PADDUP", "PADDDOWN", "PADDLEFT", "PADDRIGHT",
  "PADLSHOULDER", "PADRSHOULDER" }) do native[k] = "GAME_" .. k end
function SetOverrideBindingClick(owner, prio, key, name, mouse)
  if combat then error("SetOverrideBindingClick in combat") end
  bindSeq = bindSeq + 1
  overrides[owner] = overrides[owner] or {}
  overrides[owner][key] = { "CLICK " .. name .. ":" .. (mouse or "LeftButton"), prio, bindSeq }
end
function ClearOverrideBindings(owner)
  if combat then error("ClearOverrideBindings in combat") end
  overrides[owner] = nil
end
function binding(key)
  local best
  for _, o in pairs(overrides) do local b = o[key] if b and b[2] and (not best or b[3] > best[3]) then best = b end end
  if best then return best[1] end
  if native[key] then return native[key] end
  for _, o in pairs(overrides) do local b = o[key] if b and (not best or b[3] > best[3]) then best = b end end
  return best and best[1] or ""
end
function numBindings()
  local n = 0
  for _, o in pairs(overrides) do for _ in pairs(o) do n = n + 1 end end
  return n
end
-- A pad button pressed and released: the binding it has then (a CLICK one
-- clicks that button, down then up); the game's own are only noted
gameActions = {}
local function dispatch(key, down)
  local action = binding(key)
  local name, button = action:match("^CLICK ([^:]+):(.+)$")
  if name and _G[name] then return safecall(_G[name].scripts.OnClick, _G[name], button, down) end
  gameActions[#gameActions + 1] = action .. (down and " down" or " up")
end
function press(key, mods) keysDown[key] = true dispatch((mods or "") .. key, true) end
function release(key, mods) keysDown[key] = false dispatch((mods or "") .. key, false) end
function tap(key, mods) press(key, mods) release(key, mods) end

---------------------------------------------------------------------------
-- A rogue: 100 energy (40 now), the personal resource display's power bar
-- 200 wide, a spell book (BOOK, COSTS: tests change them)
---------------------------------------------------------------------------
CLASS = "ROGUE"
UnitClass = function() return "Voleur", CLASS end
UnitPowerType = function() return CLASS == "ROGUE" and 3 or 0, "ENERGY" end
ENERGY = { now = 40, max = 100 }
UnitPower = function() return ENERGY.now end
UnitPowerMax = function() return ENERGY.max end
PersonalResourceDisplayFrame = mock("Frame", "PersonalResourceDisplayFrame")
bar = mock("StatusBar")
bar.w, bar.h, bar.level = 200, 10, 3
bar.parent = PersonalResourceDisplayFrame
PersonalResourceDisplayFrame.PowerBar = bar
Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1 }, PowerType = { Energy = 3 },
  LuaCurveType = { Linear = 0, Step = 1 } }
-- Two energy spells, a free one, a passive one
COSTS = { [2098] = 35, [1752] = 45, [1784] = 0 }
BOOK = {
  { name = "Éviscération", spellID = 2098, iconID = 1, itemType = 1 },
  { name = "Attaque pernicieuse", spellID = 1752, iconID = 2, itemType = 1 },
  { name = "Camouflage", spellID = 1784, iconID = 3, itemType = 1 },
  { name = "Ambidextrie", spellID = 999, isPassive = true, itemType = 1 },
}
C_SpellBook = {
  GetNumSpellBookSkillLines = function() return 1 end,
  GetSpellBookSkillLineInfo = function() return { name = "Combat", itemIndexOffset = 0, numSpellBookItems = #BOOK } end,
  GetSpellBookItemInfo = function(i) return BOOK[i] end,
}
C_Spell = { GetSpellPowerCost = function(id)
  local c = COSTS[id]
  if c == nil then return nil end
  return { { type = 3, cost = c } }
end }
-- The game's step colour curves, and its power percentage through them
CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a, GetRGBA = function(c) return c.r, c.g, c.b, c.a end } end
local function stepCurve()
  local c = { points = {} }
  function c:SetType(t) self.type = t end
  function c:AddPoint(x, y) self.points[#self.points + 1] = { x, y } table.sort(self.points, function(p, q) return p[1] < q[1] end) end
  function c:Evaluate(x)
    local v = self.points[1][2]
    for _, p in ipairs(self.points) do if x >= p[1] then v = p[2] end end
    return v
  end
  return c
end
C_CurveUtil = { CreateColorCurve = stepCurve }
curveCalls = 0
UnitPowerPercent = function(unit, power, unmodified, curve)
  curveCalls = curveCalls + 1
  return curve:Evaluate(ENERGY.now / ENERGY.max)
end

-- The marks on the bar as drawn: "cost@x lit" (or dim) each
function marks()
  local t = {}
  local EM = NS.EnergyMarks
  for _, m in ipairs(EM and EM.marks or {}) do
    if m.cost and m.tex.shown ~= false then
      local _, _, _, x = m.tex:GetPoint(1)
      local lit = m.tex.color and m.tex.color[3] < 0.5
      t[#t + 1] = string.format("%d@%.1f%s", m.cost, x or -1, lit and " lit" or " dim")
    end
  end
  return table.concat(t, " ")
end

---------------------------------------------------------------------------
-- The globals, watched once the addon loads: every global moves to G0 and
-- _G stays empty, so that each read and write goes through here. What the
-- addon's own files (their chunk names) write, and read without it being
-- there, is noted
---------------------------------------------------------------------------
addonGlobals, addonOverwrites, addonMissing = {}, {}, {}
local getinfo, prefix = debug.getinfo, "@" .. ADDON .. "/"
-- The function `level` calls up (1: the one asking) is one of the addon's
local function isAddon(level)
  local info = getinfo(level + 1, "S")
  return info ~= nil and info.source:sub(1, #prefix) == prefix
end
function fromAddon(level)
  local yes = isAddon(level + 1)
  return yes
end
-- (only locals in the metamethods: a global read there would come back here)
function watchGlobals()
  local G, store, setmetatable, pairs = _G, {}, setmetatable, pairs
  local globals, overwrites, missing = addonGlobals, addonOverwrites, addonMissing
  for k, v in pairs(G) do store[k] = v end
  for k in pairs(store) do G[k] = nil end
  store.G0 = store
  setmetatable(G, {
    __index = function(_, k)
      local v = store[k]
      if v == nil and isAddon(2) then missing[k] = true end
      return v
    end,
    __newindex = function(_, k, v)
      if isAddon(2) then
        if store[k] ~= nil and not globals[k] then overwrites[k] = true else globals[k] = true end
      end
      store[k] = v
    end,
  })
end
