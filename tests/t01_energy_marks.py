# Energy marks (ported from Easy Controller - Forever's t41_energy_marks.py):
# on the game's personal resource display, the rogue's energy bar gets up
# to five marks, each at the energy the player sets (the addon's window,
# per character), dim below, lit once there is that much. Fixed values:
# nothing read of the spells' costs, save once to make 1.1's marks by spell
# values (their regular cost: kept, or read when Poised can't lower it). In
# combat the game may hide power from addons: the marks stay where they were
# placed (placed again after the fight), lit through the game's
# UnitPowerPercent with step curves; without them, from the energy.
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env import new_game, done

lua = new_game()
lua.execute(r'''
local EM, W, L = NS.EnergyMarks, NS.Window, NS.L
local function values() return table.concat(EM:Values(), " ") end
local function right(n) for _ = 1, n do tap("PADDRIGHT") end end
local function left(n) for _ = 1, n do tap("PADDLEFT") end end

section("A  five marks, none set yet")
check("A none", values(), "0 0 0 0 0")
check("A saved for this character", #SimpleRogueHelperCharDB.values, 5)
check("A no mark on the bar", marks(), "")
W:Open()
local ids = {} for i, c in ipairs(W.checks) do ids[i] = c.id end
check("A the window: the option of the target's health bar, then the five marks", table.concat(ids, " "), "hud mark1 mark2 mark3 mark4 mark5")
local rows = W.frame.rows
check("A each a value: none", rows[2].label.text .. " " .. rows[2].value.text .. " | " .. rows[6].label.text .. " " .. rows[6].value.text,
  format(L.MARK_N, 1) .. " < " .. L.MARK_NONE .. " > | " .. format(L.MARK_N, 5) .. " < " .. L.MARK_NONE .. " >")
check("A (no box on them)", tostring(rows[2].box.shown), "false")

section("B  set with the D-pad, the mouse; lit once there is that much")
tap("PADDDOWN")
check("B on mark 1: its tip, the help bar says D-pad left / right change it",
  tostring(W.frame.tip.text == L.TIP_MARK) .. " " .. tostring(W.frame.help.text:find(L.V_CHANGE, 1, true) ~= nil), "true true")
right(25)
check("B D-pad right x25: 25", values() .. " | " .. rows[2].value.text, "25 0 0 0 0 | < 25 >")
check("B its mark at 25 (of 100, 200 wide); 40 energy: lit", marks(), "25@50.0 lit")
check("B lit by the game's curves", curveCalls > 0, true)
check("B on the bar, its child", tostring(EM.prd.frame.shown) .. " " .. tostring(EM.prd.frame:GetParent() == bar), "true true")
left(1)
check("B D-pad left: 24", values(), "24 0 0 0 0")
right(1)
check("B (the D-pad didn't turn the page)", W:Page(), 1)
print("-- B2 held: on and on")
tap("PADDDOWN")
press("PADDRIGHT")
check("B2 pressed: 1", EM:Values()[2], 1)
advance(0.2)
check("B2 0.2 s: still", EM:Values()[2], 1)
advance(0.2) advance(0.1) advance(0.1)
check("B2 then every 0.08 s", EM:Values()[2], 4)
release("PADDRIGHT")
advance(0.5)
check("B2 released: stops", EM:Values()[2], 4)
right(31)
tap("PADDDOWN") right(45)
check("B 25, 35, 45", values(), "25 35 45 0 0")
check("B their marks; 40 energy: the first two lit", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
tap("PADDDOWN") right(10)
check("B a 4th at 10: the marks in the order of their values", marks(), "10@20.0 lit 25@50.0 lit 35@70.0 lit 45@90.0 dim")
left(15)
check("B D-pad left down to none, no further", values() .. " | " .. rows[5].value.text, "25 35 45 0 0 | < " .. L.MARK_NONE .. " >")
check("B (its mark gone)", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
tap("PADDDOWN")
SimpleRogueHelperCharDB.values[5] = 98
right(3)
check("B up to the maximum less one (99 of 100), no further: no mark at the full bar", EM:Values()[5], 99)
tap("PAD1")
check("B A: the next one; past the highest, none", EM:Values()[5], 0)
tap("PAD1")
check("B A again: 1", EM:Values()[5], 1)
rows[6].scripts.OnClick(rows[6], "LeftButton")
check("B a click: the next one", EM:Values()[5], 2)
rows[6].scripts.OnClick(rows[6], "RightButton")
check("B a right click: the one before", EM:Values()[5], 1)
rows[6].scripts.OnMouseWheel(rows[6], 1)
check("B the wheel over it: up", EM:Values()[5], 2)
rows[6].scripts.OnMouseWheel(rows[6], -1) rows[6].scripts.OnMouseWheel(rows[6], -1) rows[6].scripts.OnMouseWheel(rows[6], -1)
check("B down to none", EM:Values()[5], 0)
tap("PAD2")
check("B closed (B), the game got none of it", tostring(W:IsOpen()) .. " " .. #gameActions, "false 0")
ENERGY.now = 45 fire("UNIT_POWER_FREQUENT", "player")
check("B 45 energy: all lit", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 lit")
ENERGY.now = 24 fire("UNIT_POWER_FREQUENT", "player")
check("B 24: none", marks(), "25@50.0 dim 35@70.0 dim 45@90.0 dim")
ENERGY.now = 35 fire("UNIT_POWER_FREQUENT", "player")
check("B exactly 35: the first two lit", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
ENERGY.now = 40
fire("UNIT_POWER_FREQUENT", "target")
check("B another unit's power: nothing changed", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
fire("UNIT_POWER_FREQUENT", "player")

section("C  placed again when it changes")
ENERGY.max = 120 fire("UNIT_MAXPOWER", "player")
check("C 120 energy: further left", marks(), "25@41.7 lit 35@58.3 lit 45@75.0 dim")
bar.w = 300 bar.hooks.OnSizeChanged(bar)
check("C the bar wider (Edit Mode): placed on it", marks(), "25@62.5 lit 35@87.5 lit 45@112.5 dim")
bar.w = 200 ENERGY.max = 100 fire("UNIT_MAXPOWER", "player")
check("C back to 100, 200 wide", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
ENERGY.max = 30 fire("UNIT_MAXPOWER", "player")
check("C 30 energy at most: no mark at it or beyond", marks(), "25@166.7 lit")
check("C (the values kept)", values(), "25 35 45 0 0")
ENERGY.max = 35 fire("UNIT_MAXPOWER", "player")
check("C 35 at most: the mark at 35 hidden too (it would only light at full)", marks(), "25@142.9 lit")
ENERGY.max = 30 fire("UNIT_MAXPOWER", "player")
W:Open() tap("PADDDOWN") tap("PADDDOWN") tap("PADDDOWN") tap("PADDDOWN") tap("PADDDOWN") right(40) tap("PAD2")
check("C set there: 29 at most", EM:Values()[5], 29)
SimpleRogueHelperCharDB.values[5] = 0
ENERGY.max = 100 fire("UNIT_MAXPOWER", "player")
check("C back to 100", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")

section("D  in combat, power hidden from addons")
UnitPowerMax = function() error("attempt to compare a secret value") end
UnitPower = UnitPowerMax
fire("UNIT_MAXPOWER", "player")
check("D the marks where they were", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
check("D placed again later", EM.pending, true)
ENERGY.now = 50 fire("UNIT_POWER_FREQUENT", "player")
check("D still lit by the game's curves", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 lit")
UnitPowerMax = function() return secret(ENERGY.max) end
UnitPower = function() return secret(ENERGY.now) end
ENERGY.now = 30 fire("UNIT_POWER_FREQUENT", "player") fire("UNIT_MAXPOWER", "player")
check("D (secret values: the same, no error)", marks() .. " " .. #errors, "25@50.0 lit 35@70.0 dim 45@90.0 dim 0")
UnitPowerMax = function() return ENERGY.max end
UnitPower = function() return ENERGY.now end
fire("PLAYER_REGEN_ENABLED")
check("D after the fight: placed again", EM.pending, nil)
print("-- D2 no curves from the game: lit from the energy")
local keepPct = UnitPowerPercent
UnitPowerPercent = function() error("no") end
ENERGY.now = 36 fire("UNIT_POWER_FREQUENT", "player")
check("D2 36: the first two lit", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
print("-- D3 neither: dim")
UnitPower = function() error("secret") end
fire("UNIT_POWER_FREQUENT", "player")
check("D3 all dim", marks(), "25@50.0 dim 35@70.0 dim 45@90.0 dim")
UnitPower = function() return ENERGY.now end
UnitPowerPercent = keepPct
ENERGY.now = 40 fire("UNIT_POWER_FREQUENT", "player")

section("E  another class, no display")
CLASS = "MAGE" fire("PLAYER_ENTERING_WORLD")
check("E a mage: hidden", EM.prd.frame.shown, false)
W:Open()
check("E the window: rogues only, no row", W.infos[1] .. " / " .. #W.checks, L.MARKS_ROGUE_ONLY .. " / 0")
W:Close()
CLASS = "ROGUE" fire("PLAYER_ENTERING_WORLD")
check("E a rogue again: back", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
local keepPrd = PersonalResourceDisplayFrame
PersonalResourceDisplayFrame = nil fire("PLAYER_ENTERING_WORLD")
check("E no personal resource display: nothing, no error", #errors, 0)
W:Open()
check("E (the window tells, the marks still there)", W.infos[1] .. " / " .. #W.checks, L.MARKS_NO_DISPLAY .. " / 6")
W:Close()
PersonalResourceDisplayFrame = keepPrd fire("PLAYER_ENTERING_WORLD")

section("F  nothing read of the spells' costs")
COSTS[2098] = 30 fire("SPELLS_CHANGED")
check("F a talent lowers Eviscerate: the marks stay", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 dim")
ENERGY.now = 100 POISED = 10 fire("UNIT_POWER_FREQUENT", "player")
check("F full energy, Poised: the same", marks(), "25@50.0 lit 35@70.0 lit 45@90.0 lit")
check("F (no cost asked of the game)", spellCostReads, 0)
ENERGY.now = 40 POISED = 0 COSTS[2098] = 35 fire("UNIT_POWER_FREQUENT", "player")

section("G  values edited by hand: what isn't a whole energy, none")
SimpleRogueHelperCharDB.values = { 30, "40", -5, 2.5, 50, [9] = 7, x = 1 }
check("G five kept, the wrong ones none", values(), "30 0 0 0 50")
check("G (nothing else)", tostring(SimpleRogueHelperCharDB.values[9]) .. " " .. tostring(SimpleRogueHelperCharDB.values.x), "nil nil")
SimpleRogueHelperCharDB.values = "broken"
check("G not a table: started again", values(), "0 0 0 0 0")
''')

# Another character: its own saved variables (the game swaps the file at
# login), none of the first one's marks; back on the first: its marks
other = new_game(pre="SimpleRogueHelperCharDB = nil")
other.execute('section("H  per character: the game\'s file of each")')
other.execute('check("H another character: none (theirs)", marks() .. "|" .. table.concat(SimpleRogueHelperCharDB.values, " "), "|0 0 0 0 0")')
back = new_game(pre='SimpleRogueHelperCharDB = { values = { 45, 35, 0, 0, 0 }, version = 2 }')
back.execute('check("H back: 35 and 45", marks(), "35@70.0 lit 45@90.0 dim")')
broken = new_game(pre='SimpleRogueHelperCharDB = "edited by hand"')
broken.execute('check("H a broken file: started again, no error", table.concat(SimpleRogueHelperCharDB.values, " ") .. " " .. #errors, "0 0 0 0 0 0")')

# 1.1's marks by spell, made values once
kept = new_game(pre='''
SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true, ["Attaque pernicieuse"] = true },
  costs = { ["Éviscération"] = 32, ["Attaque pernicieuse"] = 40 }, version = 1 }
ENERGY.now = 100 POISED = 10
''')
kept.execute(r'''
section("M  1.1's marks by spell: made values, once")
local db = SimpleRogueHelperCharDB
check("M their regular costs kept (1.1.1's test builds): the values at once, even at full energy",
  table.concat(db.values, " ") .. " | " .. marks(), "32 40 0 0 0 | 32@64.0 lit 40@80.0 lit")
check("M the spells forgotten, no cost asked of the game", tostring(db.marks) .. " " .. tostring(db.costs) .. " " .. spellCostReads, "nil nil 0")
check("M (the file's new version)", db.version, 2)
''')
waits = new_game(pre='''
SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true, ["Attaque pernicieuse"] = true }, version = 1 }
ENERGY.now = 100 POISED = 10
''')
waits.execute(r'''
local db = SimpleRogueHelperCharDB
check("M2 1.1.0 (none kept), full energy, Poised (the game says 25 and 35): not yet, no mark", table.concat(db.values, " ") .. " | " .. marks() .. " | " .. tostring(db.marks ~= nil), "0 0 0 0 0 |  | true")
combat = true fire("PLAYER_REGEN_DISABLED")
ENERGY.now = 70 fire("UNIT_POWER_FREQUENT", "player")
check("M2 a fight, the energy below full: not in it (no cost read in a fight)", table.concat(db.values, " ") .. " " .. spellCostReads, "0 0 0 0 0 0")
UnitPower = function() return secret(ENERGY.now) end
UnitPowerMax = function() return secret(ENERGY.max) end
ENERGY.now = 55 POISED = 0 fire("UNIT_POWER_FREQUENT", "player")
check("M2 a fight, the energy hidden: not yet, no error", table.concat(db.values, " ") .. " " .. #errors, "0 0 0 0 0 0")
combat = false
UnitPower = function() return ENERGY.now end UnitPowerMax = function() return ENERGY.max end
fire("PLAYER_REGEN_ENABLED")
check("M2 after it, below full energy: the regular costs, the values", table.concat(db.values, " ") .. " | " .. marks(), "35 45 0 0 0 | 35@70.0 lit 45@90.0 lit")
check("M2 (the spells forgotten)", db.marks, nil)
ENERGY.now = 30 COSTS[2098] = 30 fire("SPELLS_CHANGED") fire("UNIT_POWER_FREQUENT", "player")
check("M2 then fixed: a talent changes nothing", marks(), "35@70.0 dim 45@90.0 dim")
''')
book = new_game(pre='''
SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true, ["Sprint énergique"] = true, ["Attaque pernicieuse"] = false, [3] = true } }
ENERGY.now = 100 POISED = 10
keepLines = C_SpellBook.GetNumSpellBookSkillLines
C_SpellBook.GetNumSpellBookSkillLines = function() return 0 end
''')
book.execute(r'''
local db = SimpleRogueHelperCharDB
ENERGY.now = 70 POISED = 0 fire("UNIT_POWER_FREQUENT", "player")
check("M3 the energy below full, out of a fight, but no spell book yet: not yet", tostring(db.marks ~= nil) .. " " .. table.concat(db.values, " "), "true 0 0 0 0 0")
C_SpellBook.GetNumSpellBookSkillLines = keepLines fire("SPELLS_CHANGED")
check("M3 the spell book there: Eviscerate's; a spell not in it, one unticked, a wrong one: none", table.concat(db.values, " ") .. " | " .. marks(), "35 0 0 0 0 | 35@70.0 lit")
''')
falls = new_game(pre='''
SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true } }
ENERGY.now = 100 POISED = 10
''')
falls.execute(r'''
ENERGY.now = 65 POISED = 0 fire("UNIT_POWER_FREQUENT", "player")
check("M3 out of a fight, the energy falls (Sap...): made a value then", table.concat(SimpleRogueHelperCharDB.values, " ") .. " | " .. marks(), "35 0 0 0 0 | 35@70.0 lit")
''')
many = new_game(pre='''
SimpleRogueHelperCharDB = { marks = { A = true, B = true, C = true, D = true, E = true, F = true },
  costs = { A = 60, B = 20, C = 50, D = 10, E = 40, F = 30 } }
''')
many.execute('check("M4 six spells: the five cheapest", table.concat(SimpleRogueHelperCharDB.values, " "), "10 20 30 40 50")')
first = new_game(pre='''
SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true } }
ENERGY.now = 100 POISED = 10
''')
first.execute(r'''
local db = SimpleRogueHelperCharDB
db.values[2] = 50 NS.EnergyMarks:Layout()
ENERGY.now = 60 POISED = 0 fire("UNIT_POWER_FREQUENT", "player")
check("M5 a value set meanwhile: kept, the spells forgotten", table.concat(db.values, " ") .. " " .. tostring(db.marks), "0 50 0 0 0 nil")
''')
mage = new_game(pre='CLASS = "MAGE" SimpleRogueHelperCharDB = { marks = {}, version = 1 }')
mage.execute('check("M6 another class, 1.1\'s empty list: forgotten", tostring(SimpleRogueHelperCharDB.marks) .. " " .. table.concat(SimpleRogueHelperCharDB.values, " "), "nil 0 0 0 0 0")')
odd = new_game(pre='SimpleRogueHelperCharDB = { marks = "yes", costs = 4 }')
odd.execute('check("M7 a list edited by hand: forgotten, no error", tostring(SimpleRogueHelperCharDB.marks) .. " " .. tostring(SimpleRogueHelperCharDB.costs) .. " " .. #errors, "nil nil 0")')

# Their fails and errors counted with the first session's
for g in (other, back, broken, kept, waits, book, falls, many, first, mage, odd):
    g.execute("for _, e in ipairs(errors) do print('  ERR ' .. e) end")
    lua.execute("fails = fails + %d for i = 1, %d do errors[#errors + 1] = 'in another session (above)' end"
                % (g.eval("fails"), g.eval("#errors")))
done(lua)
