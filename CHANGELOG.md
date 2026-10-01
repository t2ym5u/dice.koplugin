# Changelog

All notable changes to this project will be documented in this file.

Reconstructed from this repository's git history: each release lists the
feature and fix commits it carried. Version bumps, screenshot additions
and CI syncs are left out.

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
