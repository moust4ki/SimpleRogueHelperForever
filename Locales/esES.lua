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
    V_CHANGE = "Cambiar",
    -- Energy marks (EnergyMarks.lua)
    SEC_MARKS = "Marcas",
    TIP_SEC_MARKS = "Pícaros: en la barra de recursos personal del juego (actívala en el modo de edición), hasta cinco marcas finas en la barra de energía, cada una a la energía que elijas, tenue por debajo, encendida en cuanto la tienes. Ajustado por personaje.",
    MARKS_NAME = "Marcas en la barra de energía",
    MARKS_ROGUE_ONLY = "Solo pícaros.",
    MARKS_NO_DISPLAY = "La barra de recursos personal del juego no está: actívala en el modo de edición.",
    MARK_N = "Marca %d",
    MARK_NONE = "Ninguna",
    TIP_MARK = "Una marca en la barra de energía a esta energía, encendida en cuanto la tienes (Ninguna: sin marca). Mantenida, la cruceta sigue.",
    -- On the target's health bar (TargetHud.lua)
    HUD_OPTION = "En la barra de salud del objetivo: puntos de combo, energía y marcas",
    TIP_HUD = "Tus puntos de combo y tu energía, con sus marcas, en la barra de salud de tu objetivo (su placa de nombre), encima o debajo según elijas: todo en el mismo sitio. Se muestra para un enemigo seleccionado cuya placa de nombre es visible.",
    HUD_NO_NAMEPLATES = "Las placas de nombre de los enemigos están ocultas: actívalas en las opciones del juego (%s).",
    HUD_POSITION = "Lugar",
    TIP_HUD_POSITION = "Encima de la barra de salud del objetivo (los puntos de combo arriba) o debajo (primero la energía). Debajo también aparece la barra de lanzamiento del enemigo: aumenta el espaciado para no perderla de vista.",
    HUD_ABOVE = "Encima",
    HUD_BELOW = "Debajo",
    HUD_GAP = "Espaciado",
    TIP_HUD_GAP = "El espacio entre la barra de salud del objetivo y tu energía.",
    HUD_SCALE = "Tamaño",
    TIP_HUD_SCALE = "El tamaño de los puntos de combo y el grosor de la barra de energía (tan ancha como la barra de salud, sea cual sea el tamaño).",
    HUD_TEXT = "Valor de energía",
    TIP_HUD_TEXT = "Tu energía en número, en el centro de la barra de energía (también en combate).",
}

-- Latin American Spanish: the same
SRH.LOCALES.esMX = SRH.LOCALES.esES
