# The settings window: /srh, the key binding (Bindings.xml) and the game's
# options open it; the pad is bound to its hidden buttons while it is shown
# (D-pad up / down move, A checks, B closes on release, LB / RB and D-pad
# left / right page), a button held when it opens taken once released, all
# let go when it closes; a fight closes it, /srh is refused in one; the
# mouse does the same.
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env import new_game, done, read, ROOT

lua = new_game()
# Bindings.xml: its binding's name, header and code
xml = read(os.path.join(ROOT, "Bindings.xml"))
found = re.findall(r'<Binding name="([A-Z_]+)" header="([A-Z_]+)" category="ADDONS">\s*(.*?)\s*</Binding>', xml, re.S)
lua.globals().BINDINGS_XML = lua.table_from([lua.table_from(b) for b in found])
lua.execute(r'''
local W, EM, L = NS.Window, NS.EnergyMarks, NS.L
local PAD = "CLICK SimpleRogueHelperPad"
local function ours(key) return binding(key):sub(1, #PAD) == PAD end
-- Eleven energy spells (two pages of 8), 25 to 75 energy
BOOK, COSTS = {}, {}
for i, n in ipairs({ "Coup bas", "Suriner", "Attaque sournoise", "Éviscération", "Attaque pernicieuse", "Débiter",
  "Exposer l'armure", "Garrot", "Rupture", "Embuscade", "Aiguillon perfide" }) do
  BOOK[i] = { name = n, spellID = 100 + i, iconID = i, itemType = 1 }
  COSTS[100 + i] = 20 + 5 * i
end
fire("SPELLS_CHANGED")
local function shownRows()
  local t = {}
  for _, r in ipairs(W.frame.rows) do if r.shown then t[#t + 1] = r.index end end
  return table.concat(t, ",")
end

section("A  /srh: open, the pad bound to the window")
check("A closed at first", W:IsOpen(), false)
check("A nothing bound", numBindings(), 0)
slash("/srh")
check("A open", W:IsOpen(), true)
check("A D-pad up: the window's", binding("PADDUP"), PAD .. "PADDUP:LeftButton")
check("A A, B, LB, RB, D-pad: the window's", ours("PAD1") and ours("PAD2") and ours("PADLSHOULDER") and ours("PADRSHOULDER")
  and ours("PADDDOWN") and ours("PADDLEFT") and ours("PADDRIGHT"), true)
check("A with a trigger held (a modifier) too", ours("CTRL-PADDDOWN") and ours("ALT-SHIFT-PAD1"), true)
check("A Escape: the window's", binding("ESCAPE"), PAD .. "ESCAPE:LeftButton")
check("A X and Y stay the game's", binding("PAD3") .. " " .. binding("PAD4"), "GAME_PAD3 GAME_PAD4")
check("A 8 keys x 8 modifiers, and Escape", numBindings(), 65)
check("A the first spell focused, page 1", W.focus .. " " .. shownRows(), "1 1,2,3,4,5,6,7,8")
check("A the page shown", W.frame.pager.text, L.V_PAGE .. " 1 / 2")
check("A the help bar: the game's icons", W.frame.help.text:find("|A:Gamepad_Ltr_A_64:16:16|a " .. L.V_CHECK, 1, true) ~= nil, true)

section("B  D-pad up / down, A")
tap("PADDDOWN") tap("PADDDOWN") tap("PADDDOWN")
check("B down x3: the 4th", W.focus, 4)
tap("PADDUP")
check("B up: the 3rd", W.focus, 3)
for _ = 1, 5 do tap("PADDUP") end
check("B up past the top: the first", W.focus, 1)
tap("PAD1")
check("B A: Cheap Shot marked", EM:Marked()["Coup bas"], true)
check("B its mark", marks(), "25@50.0 lit")
check("B the row ticked", W.frame.rows[1].check.shown, true)
check("B the help bar: A unchecks now", W.frame.help.text:find(L.V_UNCHECK, 1, true) ~= nil, true)
tap("PAD1")
check("B A again: unmarked", EM:Marked()["Coup bas"], nil)
check("B (no mark)", marks(), "")
check("B the game got none of it", #gameActions, 0)
print("-- B2 held: repeats")
press("PADDDOWN")
check("B2 pressed: the 2nd", W.focus, 2)
advance(0.2)
check("B2 0.2 s: still", W.focus, 2)
advance(0.2) advance(0.1) advance(0.1)
check("B2 then every 0.08 s", W.focus, 5)
release("PADDDOWN")
advance(0.5)
check("B2 released: stops", W.focus, 5)

section("C  LB / RB, D-pad left / right: the pages")
tap("PADRSHOULDER")
check("C RB: page 2, its last spell (no 5th line there)", W.focus .. " " .. shownRows(), "11 9,10,11")
check("C the page shown", W.frame.pager.text, L.V_PAGE .. " 2 / 2")
tap("PADRSHOULDER")
check("C RB on the last page: nothing", W.focus, 11)
tap("PADLSHOULDER")
check("C LB: page 1, on the same line", W.focus .. " " .. shownRows(), "3 1,2,3,4,5,6,7,8")
tap("PADDRIGHT")
check("C D-pad right: page 2", shownRows(), "9,10,11")
tap("PADDLEFT")
check("C D-pad left: page 1", shownRows(), "1,2,3,4,5,6,7,8")
for _ = 1, 20 do tap("PADDDOWN") end
check("C down from page 1 goes on to page 2, the last spell at most", W.focus .. " " .. shownRows(), "11 9,10,11")
tap("PAD1")
check("C A there: the 11th marked", EM:Marked()["Aiguillon perfide"], true)
tap("PAD1")

section("D  B closes on its release, the pad let go")
press("PAD2")
check("D B pressed: still open", W:IsOpen(), true)
release("PAD2")
check("D B released: closed", W:IsOpen(), false)
check("D nothing bound any more", numBindings(), 0)
check("D the game got neither", #gameActions, 0)
slash("/srh")
check("D open again: back on the spell focused", W.focus, 11)
tap("ESCAPE")
check("D Escape: closed", W:IsOpen(), false)
check("D (the game menu didn't open)", #gameActions, 0)

section("E  a button held when it opens: taken once released")
keysDown.PADRSHOULDER = true
SimpleRogueHelper_ToggleWindow()
check("E open (the key binding)", W:IsOpen(), true)
check("E RB still the game's", binding("PADRSHOULDER"), "GAME_PADRSHOULDER")
check("E the others the window's", ours("PADDUP") and ours("PAD1"), true)
tick()
check("E still held: still the game's", binding("PADRSHOULDER"), "GAME_PADRSHOULDER")
release("PADRSHOULDER")
check("E its release went to the game", gameActions[#gameActions], "GAME_PADRSHOULDER up")
tick()
check("E released: the window's", ours("PADRSHOULDER") and ours("CTRL-PADRSHOULDER"), true)
SimpleRogueHelper_ToggleWindow()
check("E the key binding again: closed", W:IsOpen(), false)
check("E (all let go)", numBindings(), 0)
gameActions = {}

section("F  a fight: closed; /srh and the key binding refused")
slash("/srh")
fire("PLAYER_REGEN_DISABLED") combat = true
check("F closed as it starts", W:IsOpen(), false)
check("F the pad let go before the lockdown", numBindings(), 0)
slash("/srh")
check("F /srh in combat: refused", W:IsOpen(), false)
check("F (told, in red)", uiErrors[#uiErrors], L.COMBAT_UNAVAILABLE)
SimpleRogueHelper_ToggleWindow()
check("F the key binding: refused too", tostring(W:IsOpen()) .. " " .. #uiErrors, "false 2")
W:Open()
check("F (opened by any other way: refused)", W:IsOpen(), false)
fire("PLAYER_REGEN_ENABLED") combat = false
slash("/srh")
check("F after the fight: open", W:IsOpen(), true)
slash("/srh")
check("F /srh again: closed", W:IsOpen(), false)

section("G  the mouse")
W:Open()
W.frame.scripts.OnMouseWheel(W.frame, 1)
check("G wheel up: page 1", shownRows(), "1,2,3,4,5,6,7,8")
local rows = W.frame.rows
rows[2].scripts.OnEnter(rows[2])
check("G over the 2nd row: focused", W.focus, 2)
rows[2].scripts.OnClick(rows[2], "LeftButton")
check("G clicked: Backstab marked", EM:Marked()["Suriner"], true)
rows[2].scripts.OnClick(rows[2], "LeftButton")
check("G clicked again: unmarked", EM:Marked()["Suriner"], nil)
W.frame.scripts.OnMouseWheel(W.frame, -1)
check("G wheel down: page 2", shownRows(), "9,10,11")
W.frame.prev.scripts.OnClick(W.frame.prev)
check("G the < button: page 1", shownRows(), "1,2,3,4,5,6,7,8")
W.frame.close.scripts.OnClick(W.frame.close)
check("G the close button", tostring(W:IsOpen()) .. " " .. numBindings(), "false 0")

section("H  from the game's options: once they and the game menu are closed")
local cat = categories[1]
check("H Escape > Options > AddOns: its page", cat and cat.name, "SimpleRogueHelper - Forever")
SettingsPanel.shown = true
cat.panel.open.scripts.OnClick(cat.panel.open)
check("H the button: not over the options", W:IsOpen(), false)
check("H (told)", chatlog[#chatlog]:find(L.OPEN_LATER, 1, true) ~= nil, true)
advance(1)
check("H still not", W:IsOpen(), false)
SettingsPanel.shown = false GameMenuFrame.shown = true
advance(1)
check("H the game menu back: still not", W:IsOpen(), false)
GameMenuFrame.shown = false
advance(0.3)
check("H back in the game: open", W:IsOpen(), true)
W:Close()

section("I  from the chat, or another game window having the pad")
activeChat = mock("EditBox") activeChat.focus = true
gamepadFocus = { editBox = activeChat }
slash("/srh")
check("I typed in the chat: not yet (the game ends the send)", W:IsOpen(), false)
activeChat.focus = false gamepadFocus = nil
advance(0.2)
check("I then: open", W:IsOpen(), true)
W:Close()
gamepadFocus = mock("Frame", "BagsWindow")
slash("/srh")
advance(1)
check("I a game window has the pad: waits", W:IsOpen(), false)
gamepadFocus = nil
advance(0.3)
check("I closed: open", W:IsOpen(), true)

section("J  the pad taken back after a game window")
local other = {}
SetOverrideBindingClick(other, true, "PAD1", "GameButton")
check("J a game window took A", binding("PAD1"), "CLICK GameButton:LeftButton")
callback("Gamepad.RefreshFrameFocus")
advance(0)
check("J the game's focus refreshed: the window's again", ours("PAD1"), true)
ClearOverrideBindings(other)

section("K  the spell book changes while it is open")
W.frame.rows[3].scripts.OnEnter(W.frame.rows[3])
check("K on Sneak Attack", W.checks[W.focus].id, "em_Attaque sournoise")
table.insert(BOOK, 1, { name = "Sprint énergique", spellID = 200, iconID = 9, itemType = 1 })
COSTS[200] = 10
fire("SPELLS_CHANGED")
check("K a new spell: listed first", #W.checks .. " " .. W.checks[1].id, "12 em_Sprint énergique")
check("K still on Sneak Attack", W.checks[W.focus].id, "em_Attaque sournoise")
W:Close()

section("L  not a rogue: told, B closes")
CLASS = "MAGE"
slash("/srh")
check("L rogues only", W.infos[1], L.MARKS_ROGUE_ONLY)
check("L no row, no page", shownRows() .. "|" .. tostring(W.frame.pager.shown), "|false")
check("L the help bar: B only", W.frame.help.text, "|A:Gamepad_Ltr_B_64:16:16|a " .. L.V_CLOSE)
tap("PAD1") tap("PADDDOWN")
check("L A, down: nothing, no error", #errors, 0)
tap("PAD2")
check("L B: closed", W:IsOpen(), false)
CLASS = "ROGUE"

section("M  Bindings.xml")
local b = BINDINGS_XML[1]
check("M one binding", #BINDINGS_XML, 1)
check("M its name and header", b[1] .. " " .. b[2], "SIMPLEROGUEHELPER_TOGGLE SIMPLEROGUEHELPER")
check("M named in the game's key bindings", BINDING_NAME_SIMPLEROGUEHELPER_TOGGLE, L.BINDING_TOGGLE)
check("M under the addon's name", BINDING_HEADER_SIMPLEROGUEHELPER, "SimpleRogueHelper - Forever")
local run = loadstring(b[3])
run()
check("M its code opens the window", W:IsOpen(), true)
run()
check("M and closes it", W:IsOpen(), false)
''')
done(lua)
