local _, SRH = ...

-- Français (over English, Locales/enUS.lua)
SRH.LOCALES = SRH.LOCALES or {}
SRH.LOCALES.frFR = {
    COMBAT_UNAVAILABLE = "Impossible en combat",
    BINDING_TOGGLE = "Ouvrir / fermer la fenêtre de réglage",
    OPEN = "Ouvrir la configuration",
    OPEN_LATER = "La fenêtre SimpleRogueHelper - Forever s'ouvrira quand vous serez revenu en jeu (options et menu du jeu fermés).",
    SETTINGS_HINT = "Tous les réglages sont dans la fenêtre de l'addon, à la manette ou à la souris : /srh ou son raccourci.",
    -- The window's help bar
    V_CHECK = "Cocher",
    V_UNCHECK = "Décocher",
    V_CLOSE = "Fermer",
    V_PAGE = "Page",
    V_CHANGE = "Changer",
    -- Energy marks (EnergyMarks.lua)
    SEC_MARKS = "Marqueurs",
    TIP_SEC_MARKS = "Voleurs : sur la barre de ressources personnelle du jeu (à activer dans le mode Édition), un trait sur la barre d'énergie au coût de chaque sort choisi (le coût du jeu : un talent qui le réduit le déplace), discret en dessous, allumé dès que vous avez assez d'énergie pour le lancer. Choisi par personnage.",
    MARKS_NAME = "Traits sur la barre d'énergie",
    MARKS_ROGUE_ONLY = "Voleurs seulement.",
    MARKS_NO_DISPLAY = "La barre de ressources personnelle du jeu n'est pas là : activez-la dans le mode Édition.",
    MARKS_NO_SPELL = "Aucun de vos sorts ne coûte d'énergie.",
    TIP_MARKS_SPELL = "Un trait sur la barre d'énergie au coût de ce sort, allumé dès que vous avez assez d'énergie.",
    -- On the target's health bar (TargetHud.lua)
    HUD_OPTION = "Sur la barre de vie de la cible : points de combo, énergie et traits",
    TIP_HUD = "Vos points de combo et votre énergie, avec ses traits, sur la barre de vie de votre cible (sa barre de nom), au-dessus ou en dessous selon votre choix : tout au même endroit. Affiché pour un ennemi ciblé dont la barre de nom est visible.",
    HUD_NO_NAMEPLATES = "Les barres de nom des ennemis sont masquées : activez-les dans les options du jeu (%s).",
    HUD_POSITION = "Place",
    TIP_HUD_POSITION = "Au-dessus de la barre de vie de la cible (les points de combo en haut), ou en dessous (l'énergie d'abord). En dessous s'affiche aussi la barre d'incantation de l'ennemi : augmentez l'espacement pour la garder en vue.",
    HUD_ABOVE = "Au-dessus",
    HUD_BELOW = "En dessous",
    HUD_GAP = "Espacement",
    TIP_HUD_GAP = "L'espace entre la barre de vie de la cible et votre énergie.",
    HUD_SCALE = "Taille",
    TIP_HUD_SCALE = "La taille des points de combo et l'épaisseur de la barre d'énergie (aussi large que la barre de vie, quelle que soit la taille).",
}
