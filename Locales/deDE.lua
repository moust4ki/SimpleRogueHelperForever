local _, SRH = ...

-- Deutsch (over English, Locales/enUS.lua)
SRH.LOCALES = SRH.LOCALES or {}
SRH.LOCALES.deDE = {
    COMBAT_UNAVAILABLE = "Im Kampf nicht möglich",
    BINDING_TOGGLE = "Einstellungsfenster öffnen / schließen",
    OPEN = "Konfiguration öffnen",
    OPEN_LATER = "Das Fenster von SimpleRogueHelper - Forever öffnet sich, sobald du wieder im Spiel bist (Optionen und Spielmenü geschlossen).",
    SETTINGS_HINT = "Alle Einstellungen sind im eigenen Fenster des Addons, per Gamepad oder Maus: /srh oder seine Tastenbelegung.",
    -- The window's help bar
    V_CHECK = "Ankreuzen",
    V_UNCHECK = "Abwählen",
    V_CLOSE = "Schließen",
    V_PAGE = "Seite",
    V_CHANGE = "Ändern",
    -- Energy marks (EnergyMarks.lua)
    SEC_MARKS = "Marken",
    TIP_SEC_MARKS = "Schurken: auf der persönlichen Ressourcenanzeige des Spiels (im Bearbeitungsmodus einschalten) bis zu fünf feine Marken auf dem Energiebalken, jede bei der Energie, die du einstellst, schwach darunter, hell, sobald du so viel hast. Pro Charakter eingestellt.",
    MARKS_NAME = "Marken auf dem Energiebalken",
    MARKS_ROGUE_ONLY = "Nur Schurken.",
    MARKS_NO_DISPLAY = "Die persönliche Ressourcenanzeige des Spiels ist nicht da: Schalte sie im Bearbeitungsmodus ein.",
    MARK_N = "Marke %d",
    MARK_NONE = "Keine",
    TIP_MARK = "Eine Marke auf dem Energiebalken bei dieser Energie, hell, sobald du so viel hast (Keine: keine Marke). Gehalten läuft das Steuerkreuz weiter.",
    -- On the target's health bar (TargetHud.lua)
    HUD_OPTION = "Am Lebensbalken des Ziels: Combopunkte, Energie und Marken",
    TIP_HUD = "Deine Combopunkte und deine Energie mit ihren Marken direkt am Lebensbalken deines Ziels (seiner Namensplakette), darüber oder darunter nach deiner Wahl: alles an einem Ort. Angezeigt für einen anvisierten Feind, dessen Namensplakette sichtbar ist.",
    HUD_NO_NAMEPLATES = "Die Namensplaketten der Feinde sind ausgeblendet: Schalte sie in den Optionen des Spiels ein (%s).",
    HUD_POSITION = "Platz",
    TIP_HUD_POSITION = "Über dem Lebensbalken des Ziels (die Combopunkte oben) oder darunter (zuerst die Energie). Darunter erscheint auch der Zauberbalken des Feindes: Vergrößere den Abstand, um ihn im Blick zu behalten.",
    HUD_ABOVE = "Darüber",
    HUD_BELOW = "Darunter",
    HUD_GAP = "Abstand",
    TIP_HUD_GAP = "Der Abstand zwischen dem Lebensbalken des Ziels und deiner Energie.",
    HUD_SCALE = "Größe",
    TIP_HUD_SCALE = "Die Größe der Combopunkte und die Dicke des Energiebalkens (so breit wie der Lebensbalken, egal welche Größe).",
    HUD_TEXT = "Energiewert",
    TIP_HUD_TEXT = "Deine Energie als Zahl, in der Mitte des Energiebalkens (auch im Kampf).",
}
