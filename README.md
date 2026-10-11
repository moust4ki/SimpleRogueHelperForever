# SimpleRogueHelper - Forever

**Energy marks for rogues on WoW Forever.** On the game's own personal resource display, a thin
mark on the energy bar at the energy each spell you choose costs: dim below it, lit (gold) once you
have enough energy to cast it.

- **The game's cost**: read from the game (`C_Spell.GetSpellPowerCost`, its energy entry), so a
  talent that lowers a spell's cost moves its mark.
- **Your spells**: the window lists the spells of your spell book that cost energy, the cheapest
  first. Tick the ones you want marked. They are kept by name (a new rank keeps its mark) and per
  character.
- **On the bar itself**: the marks belong to the game's energy bar, so they show, hide and scale with
  it. They are placed again when your maximum energy changes, when your spell book or talents
  change, and when the bar is resized in Edit Mode.
- **In combat**, the game may hide power values from addons. The marks then stay where they were
  (placed again after the fight) and are lit by the game itself, through `UnitPowerPercent` and a
  step colour curve; if that isn't available, from the energy, else they stay dim.

The addon stands alone: it works with or without Easy Controller - Forever, where it started as a
test.

## Installation

1. Download the repository (*Code > Download ZIP*) and extract it.
2. Name the folder **`SimpleRogueHelperForever`** (exact name) and put it in
   `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. **Fully restart the game** after installing it or after an update that adds files (`/reload` does
   not load new files).

## Getting started

1. **Turn on the personal resource display**: Edit Mode, *Personal Resource Display*. The marks are
   drawn on its energy bar.
2. **Open the window** and tick your spells:
   - type `/srh`;
   - or *Escape > Options > AddOns > SimpleRogueHelper - Forever > Open the configuration* (the window
     opens once the options and the game menu are closed);
   - or give it a key: *Escape > Options > Key Bindings > AddOns > SimpleRogueHelper - Forever* (no
     key by default).

## The window

| Gamepad | Mouse | |
| --- | --- | --- |
| D-pad up / down | hover | Move (held: repeats) |
| A | click a row | Check / uncheck the spell |
| B, Escape | the × button | Close |
| LB / RB, D-pad left / right | wheel, `<` `>` | Previous / next page (8 spells a page) |

While the window is open, these gamepad buttons are the window's; they go back to the game as soon
as it closes. A button already held when it opens (the one of its key binding, say) is taken only
once released. The window closes when a fight starts, and `/srh` is refused in combat ("Not possible
in combat").

## Languages

English, French, German, Spanish (Spain and Latin America) and Italian, following the game client's
language. Spell names are the game's.

## Saved variables

`SimpleRogueHelperCharDB`, per character: `{ marks = { ["Spell name"] = true } }`. A file edited by
hand that holds anything else is cleaned at load.

## Development

- `SimpleRogueHelperForever.toc`, `Bindings.xml`
- `Locales/*.lua`: the texts (English first, each language over it), loaded before `Core.lua`
- `Core.lua`: languages, saved variables, the combat message
- `EnergyMarks.lua`: the marks
- `Window.lua`: the settings window, its gamepad bindings, its page in the game's options, `/srh`
- `tools/`: the release zip and the CurseForge upload (see *Releases*); `docs/curseforge.md`: the
  CurseForge page

### Tests

The tests run the addon's files in a small simulation of the game (Lua 5.1 through
[lupa](https://pypi.org/project/lupa/)):

```
D:\Dev\ControllerKeyboard-tests\venv\Scripts\python.exe tests\run_all.py
```

- `t01_energy_marks.py`: the marks (cost, lit / dim, placed again, combat, per character)
- `t02_window.py`: the window (D-pad, A, B, pages, held buttons, combat, mouse, options, chat,
  `Bindings.xml`)
- `t03_locales.py`: the same keys and codes in every language, the TOC
- `t04_globals.py`: no global beyond the game's needs, none of the game's replaced, nothing of Easy
  Controller - Forever's

Each test's output is written to `tests/out/`.

### Releases

Every version tag pushed to GitHub (`v1.0.0`, `v1.1.0-beta1`...) runs
[.github/workflows/release.yml](.github/workflows/release.yml): it checks that the tag matches the
TOC's `## Version`, runs the tests, builds the zip (`tools/package.py`), creates the GitHub release
and uploads the file to CurseForge (`tools/release.py`), with that version's section of
`CHANGELOG.md` as its notes. A version with a `-` (`1.1.0-beta1`) goes out as a beta.

It needs the `CF_API_KEY` repository secret (a CurseForge API token) and the CurseForge project's ID
in the TOC (`## X-Curse-Project-ID`). The game version is `1.60.1` (WoW Forever) unless the
`CF_GAME_VERSION` (or `CF_GAME_VERSION_ID`) repository variable says otherwise.

To release a version:

1. Set `## Version: x.y.z` in `SimpleRogueHelperForever.toc`, and add a `## x.y.z` section at the top
   of `CHANGELOG.md`.
2. Commit, then tag and push: `git tag vx.y.z` and `git push origin main vx.y.z`.

`docs/curseforge.md` is the CurseForge project's description.

### Trying it in the game

A directory junction makes the game load the repository itself (game closed, then a full restart):

```
mklink /J "D:\Games\Battle.net\World of Warcraft\_classic_beta_\Interface\AddOns\SimpleRogueHelperForever" "D:\Dev\SimpleRogueHelperForever"
```

**Never update the addon from the CurseForge app on an installation that uses a junction**: the app
writes through it, straight into the repository.

## License

MIT, see [LICENSE](LICENSE).
