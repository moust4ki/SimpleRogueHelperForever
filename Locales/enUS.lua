local _, SRH = ...

-- English: the base of every language, a key another language leaves out
-- stays English. Each other language is a file of its own here, named by
-- the game's locale (GetLocale()), listed in SimpleRogueHelperForever.toc
-- before Core.lua, which puts the client's language over this one. To add
-- one: copy Locales/frFR.lua as Locales/<locale>.lua, change the locale in
-- SRH.LOCALES.<locale>, translate the values (keep the %s, %d... and the
-- |c...|r codes as they are), and list the file in the TOC.
SRH.L = {
    COMBAT_UNAVAILABLE = "Not possible in combat",
    BINDING_TOGGLE = "Open / close the settings window",
    OPEN = "Open the configuration",
    OPEN_LATER = "The SimpleRogueHelper - Forever window opens once you are back in the game (options and game menu closed).",
    SETTINGS_HINT = "Every setting is in the addon's own window, driven with the gamepad or the mouse: /srh, or its key binding.",
    -- The window's help bar
    V_CHECK = "Check",
    V_UNCHECK = "Uncheck",
    V_CLOSE = "Close",
    V_PAGE = "Page",
    V_CHANGE = "Change",
    -- Energy marks (EnergyMarks.lua)
    SEC_MARKS = "Energy marks",
    TIP_SEC_MARKS = "Rogues: on the game's personal resource display (turn it on in Edit Mode), a thin mark on the energy bar at the energy each chosen spell costs (the game's cost: a talent that lowers it moves it), dim below it, lit once you have enough energy to cast it. Chosen per character.",
    MARKS_NAME = "Marks on the energy bar",
    MARKS_ROGUE_ONLY = "Rogues only.",
    MARKS_NO_DISPLAY = "The game's personal resource display isn't there: turn it on in Edit Mode.",
    MARKS_NO_SPELL = "No spell of yours costs energy.",
    TIP_MARKS_SPELL = "A mark on the energy bar at this spell's cost, lit once you have enough energy.",
    -- On the target's health bar (TargetHud.lua)
    HUD_OPTION = "On the target's health bar: combo points, energy and marks",
    TIP_HUD = "Your combo points and your energy, with its marks, right on the health bar of your target (its nameplate), above or below it as you choose: everything in one place. Shown for an enemy you target whose nameplate is shown.",
    HUD_NO_NAMEPLATES = "The enemy nameplates are hidden: turn them on in the game's options (%s).",
    HUD_POSITION = "Place",
    TIP_HUD_POSITION = "Above the target's health bar (the combo points on top), or below it (the energy first). Below, the enemy's cast bar shows there too: widen the spacing to keep it in sight.",
    HUD_ABOVE = "Above",
    HUD_BELOW = "Below",
    HUD_GAP = "Spacing",
    TIP_HUD_GAP = "The space between the target's health bar and your energy.",
    HUD_SCALE = "Size",
    TIP_HUD_SCALE = "The size of the combo points and the thickness of the energy bar (as wide as the health bar whatever the size).",
}
