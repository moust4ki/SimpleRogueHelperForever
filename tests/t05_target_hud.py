# Above the target's health bar (an option, off at first): on the enemy's
# nameplate, from the top, the combo points centered, then the energy with
# its marks, right on the health bar. Shown for an enemy targeted whose
# nameplate is there, hidden otherwise; in combat the values the game hides
# go straight to the bars (no arithmetic or comparison on them, no size
# read).
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env import new_game, done

lua = new_game()
lua.execute(r'''
local W, EM, HUD, L = NS.Window, NS.EnergyMarks, NS.TargetHud, NS.L
EM:SetMarked("Éviscération", true)
EM:SetMarked("Attaque pernicieuse", true)
TARGET, COMBO = { enemy = true }, 2
PLATES.target = newPlate("plate1")
fire("PLAYER_TARGET_CHANGED")

section("A  off at first")
check("A saved off", SimpleRogueHelperCharDB.hud, false)
check("A an enemy targeted, its nameplate there: nothing on it", hud(), "hidden")
check("A (no mark there)", hudMarks(), "")
check("A the personal resource display's marks as before", marks(), "35@70.0 lit 45@90.0 dim")
W:Open()
check("A the window: the option first, unticked", W.checks[1].id .. " " .. tostring(W.checks[1].get()), "hud false")
check("A its tip", W.frame.tip.text, L.TIP_HUD)

section("B  on (the window, A): above the target's health bar")
tap("PAD1")
check("B saved on", SimpleRogueHelperCharDB.hud, true)
check("B the row ticked", W.frame.rows[1].check.shown, true)
tap("PAD2")
check("B on the target's nameplate: energy 40 of 100, 2 combo points", hud(), "on plate1, energy 40/100, combo 2")
local f, health = HUD.frame, PLATES.target.UnitFrame.HealthBarsContainer
local p1, p2 = { f:GetPoint(1) }, { f:GetPoint(2) }
check("B on its health bar (clear of the character under it), as wide", p1[1] .. ">" .. p1[3] .. " " .. p2[1] .. ">" .. p2[3] .. " " .. tostring(p1[2] == health and p2[2] == health) .. " " .. p1[5],
  "BOTTOMLEFT>TOPLEFT BOTTOMRIGHT>TOPRIGHT true 6")
local e1 = { HUD.energy:GetPoint(1) }
check("B the energy at its bottom, on the health bar", e1[1] .. " " .. e1[3], "BOTTOMLEFT BOTTOMLEFT")
check("B the marks on its energy bar, where each spell's cost is", hudMarks(), "35@0.35 lit 45@0.45 dim")
local m = HUD.host.marks[1]
local _, rel, relPoint = m.tex:GetPoint(1)
check("B (a mark at the end of its own hidden bar)", tostring(rel == m.at:GetStatusBarTexture()) .. " " .. relPoint, "true RIGHT")
check("B the personal resource display's marks too", marks(), "35@70.0 lit 45@90.0 dim")
local point, over, at, x = HUD.pips[1]:GetParent():GetPoint(1)
check("B the combo points centered over the energy", point .. " " .. tostring(over == HUD.energy) .. " " .. at .. " " .. x, "BOTTOM true TOP 0")
check("B at the game's scale for them on a nameplate", HUD.pips[1]:GetParent():GetScale(), 0.7)
check("B five of them", #HUD.pips, 5)
print("-- B2 the game's own look (the personal resource display's)")
local e = HUD.energy
local a, b = { e.bg:GetPoint(1) }, { e.bg:GetPoint(2) }
check("B2 its energy bar and frame", e.barTexture .. " | " .. e.bg.atlas .. " " .. a[1] .. a[4] .. "," .. a[5] .. " " .. b[1] .. b[4] .. "," .. b[5],
  "UI-HUD-CoolDownManager-Bar | UI-HUD-CoolDownManager-Bar-BG TOPLEFT-2,3 BOTTOMRIGHT6,-7")
check("B2 energy yellow", table.concat(e.barColor, ","), "1,1,0,1")
local pip = HUD.pips[2]
local _, _, _, px = pip:GetPoint(1)
local _, _, _, sx, sy = pip.shadow:GetPoint(1)
check("B2 a combo point: 20 x 20, 4 apart", pip.w .. "x" .. pip.h .. " at " .. px, "20x20 at 24")
check("B2 its shadow and dark orb", pip.shadow.atlas .. " " .. sx .. "," .. sy .. " | " .. pip.off.atlas, "uf-roguecp-bg-shadow 0,-4 | uf-roguecp-bg-dis")
check("B2 lit: its orb, its red gem over it, each its own size", pip.on.barTexture .. " " .. pip.on.w .. " | " .. pip.gem.barTexture .. " " .. pip.gem.w .. " " .. tostring(pip.gem:GetParent() == pip.on),
  "uf-roguecp-bg 21 | uf-roguecp-icon-red 13 true")
check("B2 the 2nd lit (2 points), the 3rd not, every layer", filled(HUD.pips[2].on) .. filled(HUD.pips[2].gem) .. filled(HUD.pips[3].on) .. filled(HUD.pips[3].gem), "1100")
ENERGY.now = 45 fire("UNIT_POWER_FREQUENT", "player")
check("B 45 energy: both marks lit", hud() .. " | " .. hudMarks(), "on plate1, energy 45/100, combo 2 | 35@0.35 lit 45@0.45 lit")
COMBO = 5 fire("UNIT_POWER_FREQUENT", "player")
check("B 5 combo points", hud(), "on plate1, energy 45/100, combo 5")
COMBO = 0 fire("COMBO_TARGET_CHANGED")
check("B none (moved to another target)", hud(), "on plate1, energy 45/100, combo 0")
ENERGY.now, COMBO = 40, 2 fire("UNIT_POWER_FREQUENT", "player")

section("C  the target changes")
TARGET = nil fire("PLAYER_TARGET_CHANGED")
check("C no target: hidden", hud(), "hidden")
TARGET = { enemy = false } fire("PLAYER_TARGET_CHANGED")
check("C a friend targeted: hidden", hud(), "hidden")
TARGET, PLATES.target = { enemy = true }, nil fire("PLAYER_TARGET_CHANGED")
check("C an enemy without its nameplate (far, off screen): hidden", hud(), "hidden")
PLATES.target = newPlate("plate2") fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check("C its nameplate shown: on it", hud(), "on plate2, energy 40/100, combo 2")
PLATES.target = nil fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
check("C its nameplate gone: hidden", hud(), "hidden")
PLATES.target = newPlate("plate3") fire("PLAYER_TARGET_CHANGED")
check("C another enemy: on its nameplate", hud(), "on plate3, energy 40/100, combo 2")
ENERGY.max = 120 fire("UNIT_MAXPOWER", "player")
check("C 120 energy at most: the bar and the marks", hud() .. " | " .. hudMarks(), "on plate3, energy 40/120, combo 2 | 35@0.29 lit 45@0.38 dim")
ENERGY.max = 100 fire("UNIT_MAXPOWER", "player")

section("D  in combat: the values hidden from addons")
fire("PLAYER_REGEN_DISABLED") combat = true
UnitPower = function() return secret(ENERGY.now) end
UnitPowerMax = function() return secret(ENERGY.max) end
GetComboPoints = function() return secret(COMBO) end
ENERGY.now, COMBO = 50, 3 fire("UNIT_POWER_FREQUENT", "player")
check("D shown as the game gives them, no error", hud() .. " " .. #errors, "on plate3, energy 50/100, combo 3 0")
check("D (handed on hidden)", tostring(issecretvalue(HUD.energy.value)) .. " " .. tostring(issecretvalue(HUD.pips[1].on.value)), "true true")
fire("UNIT_MAXPOWER", "player")
check("D the marks where they were, placed again later", hudMarks() .. " " .. tostring(EM.pending), "35@0.35 lit 45@0.45 lit true")
PLATES.target = newPlate("plate4") COMBO = 1 fire("PLAYER_TARGET_CHANGED")
check("D a new target in the fight: on its nameplate", hud(), "on plate4, energy 50/100, combo 1")
check("D (nothing read of the nameplate's sizes, no error)", #errors, 0)
UnitPower = function() return ENERGY.now end
UnitPowerMax = function() return ENERGY.max end
GetComboPoints = function() return COMBO end
combat = false fire("PLAYER_REGEN_ENABLED")
check("D after the fight: placed again", EM.pending, nil)

section("E  not a rogue, the option off again")
CLASS = "MAGE" fire("PLAYER_ENTERING_WORLD") fire("PLAYER_TARGET_CHANGED")
check("E a mage: hidden", hud(), "hidden")
W:Open()
check("E (no option in the window)", #W.checks, 0)
W:Close()
CLASS = "ROGUE" fire("PLAYER_ENTERING_WORLD")
check("E a rogue again: back", hud(), "on plate4, energy 50/100, combo 1")
W:Open() tap("PAD1") tap("PAD2")
check("E off (the window): hidden", hud() .. " " .. tostring(SimpleRogueHelperCharDB.hud), "hidden false")
check("E (its marks hidden)", HUD.host.frame.shown, false)
check("E the personal resource display's marks still there", marks(), "35@70.0 lit 45@90.0 lit")

section("F  the window's notes")
cvars.nameplateShowEnemies = "0"
NAMEPLATE_OPTIONS_LABEL = "Barres de noms"
W:Open() tap("PAD1")
check("F on, the enemy nameplates hidden: told where to show them", W.infos[1], format(L.HUD_NO_NAMEPLATES, "Barres de noms"))
cvars.nameplateShowEnemies = "1"
local keepPrd = PersonalResourceDisplayFrame
PersonalResourceDisplayFrame = nil
W:Refresh()
check("F on, no personal resource display: not needed, not told", #W.infos, 0)
tap("PAD1")
check("F off: told again", W.infos[1], L.MARKS_NO_DISPLAY)
PersonalResourceDisplayFrame = keepPrd
tap("PAD2")
''')

# Saved per character: on at the next login, an enemy already targeted
on = new_game(pre='SimpleRogueHelperCharDB = { marks = { ["Éviscération"] = true }, hud = true } '
                  'TARGET, PLATES.target = { enemy = true }, newPlate("plate1")')
on.execute('section("G  saved per character")')
on.execute('check("G on at login: under the target", hud() .. " | " .. hudMarks(), "on plate1, energy 40/100, combo 0 | 35@0.35 lit")')
broken = new_game(pre='SimpleRogueHelperCharDB = { hud = "yes" }')
broken.execute('check("G a value edited by hand: off, no error", tostring(SimpleRogueHelperCharDB.hud) .. " " .. #errors, "false 0")')
plain = new_game(pre='C_Texture = nil SimpleRogueHelperCharDB = { hud = true } '
                     'TARGET, PLATES.target, COMBO = { enemy = true }, newPlate("plate1"), 3')
plain.execute(r'''check("G a client without the game's art: plain bars, the same",
  hud() .. " | " .. tostring(NS.TargetHud.art) .. " " .. tostring(NS.TargetHud.energy.barTexture:find("WHITE8X8", 1, true) ~= nil),
  "on plate1, energy 40/100, combo 3 | false true")''')
for g in (on, broken, plain):
    g.execute("for _, e in ipairs(errors) do print('  ERR ' .. e) end")
    lua.execute("fails = fails + %d for i = 1, %d do errors[#errors + 1] = 'in another session (above)' end"
                % (g.eval("fails"), g.eval("#errors")))
done(lua)
