# Changelog

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
