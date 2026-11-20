# Changelog

## 1.1.0

**After this update, quit and restart the game**: it adds a file, which a /reload doesn't load.

- **Everything under the target's health bar** (asked, an option, off by default: the first row of the
  `/srh` window): on the nameplate of the enemy you target, a thin energy bar with the same marks, and
  your combo points centered under it. Energy, combo points and the enemy's health in one place: no
  more looking back and forth between the enemy and the personal resource display. It sits under the
  enemy's cast bar, never over it. Shown for an enemy you target whose nameplate is shown (the
  window tells you when the game's enemy nameplates are off). In combat too, where the game hides the
  values from addons.
- The window no longer asks for the personal resource display while this option is on.

## 1.0.0

The first version, from Easy Controller - Forever's energy marks test (never released there), as an
addon of its own.

- **Energy marks** (rogues): on the game's personal resource display (turn it on in Edit Mode), a
  thin mark on the energy bar at the energy each chosen spell costs, dim below it, lit once you have
  enough energy to cast it. The cost is the game's: a talent that lowers it moves the mark. The marks
  follow the bar (shown, hidden and scaled with it) and are placed again when your maximum energy,
  your spell book or your talents change, or when the bar is resized in Edit Mode. In combat, where
  the game may hide power from addons, they stay where they were placed and are lit by the game's
  own `UnitPowerPercent` through step curves.
- **The settings window**: your spells that cost energy, the cheapest first, each ticked or not.
  Gamepad (D-pad up / down, A to check, B to close, LB / RB for the pages) or mouse. Opened with
  `/srh`, from *Escape › Options › AddOns › SimpleRogueHelper - Forever*, or with its key binding
  (*Key Bindings › AddOns*, no key by default). Closed when a fight starts; `/srh` is refused in
  combat.
- **Per character**: the spells marked are kept by name (a new rank keeps its mark) in this
  character's saved variables.
- English, French, German, Spanish and Italian.
