# The addon's globals: only the ones the game needs (its saved variables,
# the slash command, the key binding and its names, the pad's hidden
# buttons), all named after it; none of the game's replaced; nothing read
# that the game may not have, past a known few; and nothing of Easy
# Controller - Forever's (the addon stands alone, it on or off).
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env import new_game, done, read, toc_files, ROOT

EXPECTED = {
    "SimpleRogueHelperCharDB",
    "SLASH_SIMPLEROGUEHELPER1",
    "BINDING_HEADER_SIMPLEROGUEHELPER",
    "BINDING_NAME_SIMPLEROGUEHELPER_TOGGLE",
    "SimpleRogueHelper_ToggleWindow",
} | {"SimpleRogueHelperPad" + k for k in ("PADDUP", "PADDDOWN", "PADDLEFT", "PADDRIGHT", "PAD1", "PAD2",
                                          "PADLSHOULDER", "PADRSHOULDER", "ESCAPE")}
# Read though they may not be there: the saved variables before their first
# save, and the game's that differ between clients (each one checked first)
OPTIONAL = {"SimpleRogueHelperCharDB", "PersonalResourceDisplayFrame", "ChatFrameUtil", "ChatEdit_GetActiveWindow",
            "GameMenuFrame", "SettingsPanel", "GamepadMode", "InterfaceOptions_AddCategory", "Settings",
            "EventRegistry", "C_CurveUtil", "UnitPowerPercent", "CreateColor", "C_Texture", "C_Spell", "C_SpellBook",
            "UnitPowerType", "Enum", "UIErrorsFrame"}


def names(lua, table):
    return sorted(k for k, v in lua.eval(table).items() if v)


def everything(lua):
    # All the addon does in a session: marks, the window (pad and mouse),
    # the options, a fight, the key binding, the bar resized
    lua.execute(r'''
    local W, EM = NS.Window, NS.EnergyMarks
    EM:SetMarked("Éviscération", true)
    ENERGY.now = 50 fire("UNIT_POWER_FREQUENT", "player")
    bar.w = 300 if bar.hooks then bar.hooks.OnSizeChanged(bar) end
    fire("SPELLS_CHANGED") fire("PLAYER_TALENT_UPDATE") fire("CHARACTER_POINTS_CHANGED") fire("LEARNED_SPELL_IN_SKILL_LINE")
    slash("/srh") advance(0.2)
    tap("PADDDOWN") tap("PAD1") tap("PADRSHOULDER") tap("PADLSHOULDER") tap("PADDLEFT") tap("PADDRIGHT")
    press("PADDUP") advance(0.5) release("PADDUP") tick()
    callback("Gamepad.RefreshFrameFocus") advance(0)
    W.frame.rows[1].scripts.OnEnter(W.frame.rows[1]) W.frame.rows[1].scripts.OnClick(W.frame.rows[1])
    W.frame.scripts.OnMouseWheel(W.frame, -1) W.frame.next.scripts.OnClick(W.frame.next)
    tap("PAD2")
    SimpleRogueHelper_ToggleWindow() advance(0.2)
    fire("PLAYER_REGEN_DISABLED") combat = true
    UnitPowerMax = function() error("secret") end fire("UNIT_MAXPOWER", "player")
    slash("/srh") SimpleRogueHelper_ToggleWindow()
    UnitPowerMax = function() return ENERGY.max end
    combat = false fire("PLAYER_REGEN_ENABLED")
    local cat = categories[1]
    if cat then
      SettingsPanel.shown = true
      cat.panel.open.scripts.OnClick(cat.panel.open)
      SettingsPanel.shown = false advance(0.5)
    end
    W:Close()
    CLASS = "MAGE" fire("PLAYER_ENTERING_WORLD") slash("/srh") advance(0.2) tap("PAD2") CLASS = "ROGUE"
    PersonalResourceDisplayFrame = nil fire("PLAYER_ENTERING_WORLD") slash("/srh") advance(0.2) tap("PAD2")
    ''')


lua = new_game()
everything(lua)
check = lua.eval("check")
lua.execute('section("A  the globals it makes: the game\'s needs only, named after it")')
made = set(names(lua, "addonGlobals"))
check("none beyond these", ", ".join(sorted(made - EXPECTED)), "")
check("all of these", ", ".join(sorted(EXPECTED - made)), "")
check("each named after the addon", ", ".join(n for n in made if "SimpleRogueHelper" not in n and "SIMPLEROGUEHELPER" not in n), "")
check("none of the game's replaced", ", ".join(names(lua, "addonOverwrites")), "")
check("SlashCmdList: its own entry only", ",".join(k for k in lua.eval("SlashCmdList").keys()), "SIMPLEROGUEHELPER")
check("the namespace's own: the game's untouched", lua.eval("_G.SRH == nil and _G.L == nil and _G.EM == nil and _G.W == nil"), True)

lua.execute('section("B  what it reads: the game\'s, the few that may be missing checked first")')
check("read though missing, past the known ones", ", ".join(n for n in names(lua, "addonMissing") if n not in OPTIONAL), "")
check("(its saved variables, before their first save)", "SimpleRogueHelperCharDB" in names(lua, "addonMissing"), True)

lua.execute('section("C  a client without the optional parts: still no error")')
bare = new_game(pre='''
ChatFrameUtil = nil GameMenuFrame = nil SettingsPanel = nil GamepadMode = nil
Settings = nil EventRegistry = nil C_CurveUtil = nil UnitPowerPercent = nil C_Texture = nil
UNKNOWN_EVENTS = { TRAIT_CONFIG_UPDATED = true, PLAYER_TALENT_UPDATE = true, CHARACTER_POINTS_CHANGED = true,
  LEARNED_SPELL_IN_SKILL_LINE = true }
''')
everything(bare)
bare.execute('check("C everything done again, no error", #errors, 0)')
bare.execute('check("C the marks lit from the energy (no curves)", marks(), "45@135.0 lit")')
bare.execute('check("C the help bar\'s buttons as letters", NS.Window.frame.help.text:find("B|r", 1, true) ~= nil, true)')
lua.execute("fails = fails + %d" % bare.eval("fails"))
lua.execute("for i = 1, %d do errors[#errors + 1] = 'in the session without the optional parts (above)' end" % bare.eval("#errors"))

lua.execute('section("D  nothing of Easy Controller - Forever\'s")')
sources = {name: read(os.path.join(ROOT, name)) for name in toc_files()}
sources["Bindings.xml"] = read(os.path.join(ROOT, "Bindings.xml"))
sources["SimpleRogueHelperForever.toc"] = read(os.path.join(ROOT, "SimpleRogueHelperForever.toc"))
pattern = re.compile(r"ControllerKeyboard|CONTROLLERKEYBOARD|\bCK\b|EasyController\b|\bEC\b")
hits = []
for name, src in sources.items():
    for i, line in enumerate(src.splitlines(), 1):
        # (comments may say where the code comes from)
        code = line.split("--", 1)[0] if name.endswith(".lua") else line
        if pattern.search(code):
            hits.append("%s:%d" % (name, i))
check("no reference to it, its globals or its folder", ", ".join(hits), "")
with_ec = new_game(pre='''
ControllerKeyboard = {} ControllerKeyboardDB = { settings = {} }
SLASH_CONTROLLERKEYBOARD1 = "/ec" SlashCmdList.CONTROLLERKEYBOARD = function() end
BINDING_HEADER_CONTROLLERKEYBOARD = "Easy Controller - Forever"
''')
everything(with_ec)
with_ec.execute('check("D loaded with it on: the same, no error", #errors .. " " .. tostring(ControllerKeyboardDB.settings.energyMarks), "0 nil")')
with_ec.execute('check("D its slash command kept", SLASH_CONTROLLERKEYBOARD1 .. " " .. type(SlashCmdList.CONTROLLERKEYBOARD), "/ec function")')
lua.execute("fails = fails + %d" % with_ec.eval("fails"))
lua.execute("for i = 1, %d do errors[#errors + 1] = 'in the session with Easy Controller (above)' end" % with_ec.eval("#errors"))
done(lua)
