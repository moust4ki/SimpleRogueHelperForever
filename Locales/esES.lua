local _, SRH = ...

-- Español (over English, Locales/enUS.lua)
SRH.LOCALES = SRH.LOCALES or {}
SRH.LOCALES.esES = {
    COMBAT_UNAVAILABLE = "No es posible en combate",
    BINDING_TOGGLE = "Abrir / cerrar la ventana de ajustes",
    OPEN = "Abrir la configuración",
    OPEN_LATER = "La ventana de SimpleRogueHelper - Forever se abrirá cuando vuelvas al juego (opciones y menú del juego cerrados).",
    SETTINGS_HINT = "Todos los ajustes están en la ventana del addon, con el mando o el ratón: /srh o su atajo.",
    -- The window's help bar
    V_CHECK = "Marcar",
    V_UNCHECK = "Desmarcar",
    V_CLOSE = "Cerrar",
    V_PAGE = "Página",
    -- Energy marks (EnergyMarks.lua)
    SEC_MARKS = "Marcas",
    TIP_SEC_MARKS = "Pícaros: en la barra de recursos personal del juego (actívala en el modo de edición), una marca fina en la barra de energía al coste de cada hechizo elegido (el coste del juego: un talento que lo reduce la mueve), tenue por debajo, encendida en cuanto tienes energía para lanzarlo. Elegido por personaje.",
    MARKS_NAME = "Marcas en la barra de energía",
    MARKS_ROGUE_ONLY = "Solo pícaros.",
    MARKS_NO_DISPLAY = "La barra de recursos personal del juego no está: actívala en el modo de edición.",
    MARKS_NO_SPELL = "Ninguno de tus hechizos cuesta energía.",
    TIP_MARKS_SPELL = "Una marca en la barra de energía al coste de este hechizo, encendida en cuanto tienes energía suficiente.",
}

-- Latin American Spanish: the same
SRH.LOCALES.esMX = SRH.LOCALES.esES
