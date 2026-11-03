# Changelog

All notable changes to this project will be documented in this file.

Reconstructed from this repository's git history: each release lists the
feature and fix commits it carried. Version bumps, screenshot additions
and CI syncs are left out.

## [1.1.2] - 2026-11-02

### Changed
- Picks up game-common 1.10.0: the shared Tools → Games menu also lists
  the games' new "· multiplayer" entries under Party & quiz.

## [1.1.1] - 2026-11-02

### Changed
- Listed under **Tools → Games**, grouped by category, instead of its own
  entry in the Tools menu (game-common 1.9.1).

## [1.1.0] - 2026-10-30

### Changed
- Redesigned play screen: the dice fill the room left by the status and a
  full-width Roll bar, and landscape puts the controls beside the dice.
- Title-bar menu entries show the current values, "Faces: d6" and "Dice: 2",
  instead of "Number of faces…" / "Number of dice…".
- The status line reads "2 dice · d6".

### Fixed
- The Roll button started with a 🎲 emoji the UI fonts have no glyph for, so it
  showed as a box.
- The rolled numbers and the total were scaled by DPI twice and could overflow
  the die on high-DPI screens; they are now fitted and centred.

## [1.0.13] - 2026-10-07

### Fixed
- The Tools menu entry is translated again. `main.lua` took `_` from
  KOReader's `gettext`, which knows nothing of this plugin's strings, so the
  menu label stayed English while the game's own screen, which goes through
  `i18n`, was translated. `_` now comes from `i18n` here too.


## [1.0.12] - 2026-10-01

### Fixed
- Picks up game-common v1.5.0. Play statistics were recorded under a key no
  tool could match: `ReaderUI`/`FileManager:registerModule()` rewrite a plugin
  instance's `name` to `reader<id>` / `filemanager<id>` right after it is
  built, so this game's sessions were split across two rows and neither
  carried its plugin id. Rows written under the old keys are merged back on
  first read. The same release brings the `stopPlugin()` /
  `deletePluginSettings()` hooks KOReader 2026.07 calls when a plugin is
  deleted from the device (PR #15240).

  No change to this plugin's own code -- it inherits all of it from the
  shared library.

## [1.0.11] - 2026-08-05

### Added
- Add ES and DE translations

## [1.0.10] - 2026-08-05

### Changed
- Add issue/PR templates and CONTRIBUTING.md

### Fixed
- Correct Total-line vertical metrics and add tap-anywhere-to-roll

## [1.0.7] - 2026-07-29

### Fixed
- Drop deprecated name field from _meta.lua

## [1.0.4] - 2026-07-28

### Changed
- Add GPL-3.0 LICENSE

## [1.0.1] - 2026-07-21

### Added
- Own translations locally instead of via game-common
