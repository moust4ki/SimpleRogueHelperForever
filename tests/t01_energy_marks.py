# Energy marks (ported from Easy Controller - Forever's t41_energy_marks.py):
# on the game's personal resource display, the rogue's energy bar gets a
# mark at the cost of each chosen spell (the game's cost), dim below, lit
# once there is enough energy. Chosen per character (its own saved
# variables, the addon's window). In combat the game may hide power from
# addons: the marks stay where they were placed (placed again after the
# fight), lit through the game's UnitPowerPercent with step curves; without
# them, from the energy.
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env import new_game, done

lua = new_game()
lua.execute(r'''
local EM, W, L = NS.EnergyMarks, NS.Window, NS.L

section("A  the energy spells, the cheapest first; none marked yet")
local names = {} for _, sp in ipairs(EM:Spells()) do names[#names + 1] = sp.name .. " " .. sp.cost end
check("A Eviscerate 35, Sinister Strike 45 (no free or passive one)", table.concat(names, ", "), "Éviscération 35, Attaque pernicieuse 45")
fire("PLAYER_ENTERING_WORLD")
check("A no mark", marks(), "")

section("B  marked: at each cost, lit once there is enough")
EM:SetMarked("Éviscération", true)
EM:SetMarked("Attaque pernicieuse", true)
check("B at 35 and 45 (of 100, 200 wide); 40: the first lit", marks(), "35@70.0 lit 45@90.0 dim")
check("B lit by the game's curves", curveCalls > 0, true)
check("B on the bar", EM.frame and EM.frame.shown ~= false, true)
check("B the bar's child", EM.frame:GetParent() == bar, true)
ENERGY.now = 45 fire("UNIT_POWER_FREQUENT", "player")
check("B 45: both lit", marks(), "35@70.0 lit 45@90.0 lit")
ENERGY.now = 34 fire("UNIT_POWER_FREQUENT", "player")
check("B 34: none", marks(), "35@70.0 dim 45@90.0 dim")
ENERGY.now = 35 fire("UNIT_POWER_FREQUENT", "player")
check("B exactly 35: the first lit", marks(), "35@70.0 lit 45@90.0 dim")
ENERGY.now = 40
fire("UNIT_POWER_FREQUENT", "target")
check("B another unit's power: nothing changed", marks(), "35@70.0 lit 45@90.0 dim")

section("C  placed again when it changes")
ENERGY.max = 120 fire("UNIT_MAXPOWER", "player")
check("C 120 energy: further left", marks(), "35@58.3 lit 45@75.0 dim")
COSTS[2098] = 30 fire("SPELLS_CHANGED")
check("C a talent lowers Eviscerate to 30: moved", marks(), "30@50.0 lit 45@75.0 dim")
COSTS[2098] = 25 fire("CHARACTER_POINTS_CHANGED")
check("C a talent point spent: moved", marks(), "25@41.7 lit 45@75.0 dim")
COSTS[2098] = 35 ENERGY.max = 100
bar.w = 300 bar.hooks.OnSizeChanged(bar)
check("C the bar wider (Edit Mode): placed on it", marks(), "35@105.0 lit 45@135.0 dim")
bar.w = 200 bar.hooks.OnSizeChanged(bar)
check("C back to 200", marks(), "35@70.0 lit 45@90.0 dim")
ENERGY.max = 30 fire("UNIT_MAXPOWER", "player")
check("C 30 energy at most: no mark beyond it", marks(), "")
check("C (nothing to show)", EM.frame.shown, false)
ENERGY.max = 100 fire("UNIT_MAXPOWER", "player")

section("D  in combat, power hidden from addons")
UnitPowerMax = function() error("attempt to compare a secret value") end
UnitPower = UnitPowerMax
fire("UNIT_MAXPOWER", "player")
check("D the marks where they were", marks(), "35@70.0 lit 45@90.0 dim")
check("D placed again later", EM.pending, true)
ENERGY.now = 50 fire("UNIT_POWER_FREQUENT", "player")
check("D still lit by the game's curves", marks(), "35@70.0 lit 45@90.0 lit")
UnitPowerMax = function() return ENERGY.max end
UnitPower = function() return ENERGY.now end
fire("PLAYER_REGEN_ENABLED")
check("D after the fight: placed again", EM.pending, nil)
print("-- D2 no curves from the game: lit from the energy")
local keepPct = UnitPowerPercent
UnitPowerPercent = function() error("no") end
ENERGY.now = 36 fire("UNIT_POWER_FREQUENT", "player")
check("D2 36: the first lit", marks(), "35@70.0 lit 45@90.0 dim")
print("-- D3 neither: dim")
UnitPower = function() error("secret") end
fire("UNIT_POWER_FREQUENT", "player")
check("D3 both dim", marks(), "35@70.0 dim 45@90.0 dim")
UnitPower = function() return ENERGY.now end
UnitPowerPercent = keepPct
ENERGY.now = 40 fire("UNIT_POWER_FREQUENT", "player")

section("E  unmarked, another class, no display")
EM:SetMarked("Attaque pernicieuse", false)
check("E Sinister Strike unmarked", marks(), "35@70.0 lit")
check("E saved for this character", SimpleRogueHelperCharDB.marks["Éviscération"], true)
check("E (and only it)", SimpleRogueHelperCharDB.marks["Attaque pernicieuse"], nil)
CLASS = "MAGE" fire("PLAYER_ENTERING_WORLD")
check("E a mage: hidden", EM.frame.shown, false)
CLASS = "ROGUE" fire("PLAYER_ENTERING_WORLD")
check("E a rogue again: back", marks(), "35@70.0 lit")
local keepPrd = PersonalResourceDisplayFrame
PersonalResourceDisplayFrame = nil fire("PLAYER_ENTERING_WORLD")
check("E no personal resource display: nothing, no error", #errors, 0)
PersonalResourceDisplayFrame = keepPrd fire("PLAYER_ENTERING_WORLD")

section("F  the window: this character's energy spells")
W:Open()
check("F its header", W.header, L.MARKS_NAME)
check("F one row each energy spell", #W.checks, 2)
check("F Eviscerate ticked", W.checks[1].get(), true)
check("F Sinister Strike not", W.checks[2].get(), false)
tap("PADDDOWN") tap("PAD1")
check("F Sinister Strike ticked (D-pad down, A): its mark", marks(), "35@70.0 lit 45@90.0 dim")
tap("PAD2")
check("F closed (B)", W:IsOpen(), false)
CLASS = "MAGE"
W:Open()
check("F a mage: rogues only", W.infos[1], L.MARKS_ROGUE_ONLY)
check("F (no row)", #W.checks, 0)
W:Close()
CLASS = "ROGUE"
PersonalResourceDisplayFrame = nil
W:Open()
check("F no display: told, the spells still there", W.infos[1] .. " / " .. #W.checks, L.MARKS_NO_DISPLAY .. " / 2")
W:Close()
PersonalResourceDisplayFrame = keepPrd
local keepBook = BOOK
BOOK = { BOOK[3], BOOK[4] }
W:Open()
check("F no energy spell: told", W.infos[1], L.MARKS_NO_SPELL)
W:Close()
BOOK = keepBook
fire("PLAYER_ENTERING_WORLD")
check("F the bar as before", marks(), "35@70.0 lit 45@90.0 dim")

section("G  a saved list edited by hand: its wrong entries left out")
SimpleRogueHelperCharDB.marks = { ["Éviscération"] = true, [5] = true, Bad = "yes" }
local n = 0 for _ in pairs(EM:Marked()) do n = n + 1 end
check("G one kept", n, 1)
SimpleRogueHelperCharDB.marks = "broken"
check("G not a table: started again", type(EM:Marked()), "table")
''')

# Another character: its own saved variables (the game swaps the file at
# login), none of the first one's marks; back on the first: its marks
other = new_game(pre="SimpleRogueHelperCharDB = nil")
other.execute('section("H  per character: the game\'s file of each")')
other.execute('check("H another character: none (theirs)", marks(), "")')
other.execute('check("H (its own file, empty)", next(SimpleRogueHelperCharDB.marks), nil)')
back = new_game(pre='SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true } }')
back.execute('check("H back: Eviscerate", marks(), "35@70.0 lit")')
broken = new_game(pre='SimpleRogueHelperCharDB = "edited by hand"')
broken.execute('check("H a broken file: started again, no error", type(SimpleRogueHelperCharDB.marks) .. " " .. #errors, "table 0")')
# Their fails and errors counted with the first session's
for g in (other, back, broken):
    g.execute("for _, e in ipairs(errors) do print('  ERR ' .. e) end")
    lua.execute("fails = fails + %d for i = 1, %d do errors[#errors + 1] = 'in another session (above)' end"
                % (g.eval("fails"), g.eval("#errors")))
done(lua)
