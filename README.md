# dice.koplugin

A **Dice** plugin for [KOReader](https://github.com/koreader/koreader) — roll one or more virtual dice, with a real dice look, right from the Tools menu.

## Concept

Open the plugin, pick a number of faces and a number of dice from the menu (top-left), then tap **Roll**. Six-sided dice are drawn with real pips, just like a physical die; any other face count shows the rolled number instead. Rolling more than one die also shows the total.

Your last roll and settings are remembered between sessions.

## Features

- **Real d6 pips** — classic dot pattern (1–6), not just digits
- **Configurable faces** — presets d4/d6/d8/d10/d12/d20, or any custom value from 2 to 100
- **Configurable dice count** — 1 to 12 dice at once, auto-arranged in a grid
- **Running total** — shown below the roll whenever more than one die is used
- **Persistent** — remembers the last roll and settings across sessions
- **FR + EN UI**

## Controls

| Action | Effect |
|--------|--------|
| **🎲 Roll** | Roll all dice again |
| **☰ menu → Number of faces…** | Choose faces (presets or custom) |
| **☰ menu → Number of dice…** | Choose how many dice to roll (1–12) |
| **☰ menu → Rules** | Show a quick reminder |
| **✕** | Close |

## Installation

### Via KOReader Plugin Manager

```
dice.koplugin/  → KOReader plugins/ folder
game-common/    → alongside plugins/ (shared library)
```

### Manual

1. Download `dice.zip` from [Releases](../../releases).
2. Extract to your KOReader `plugins/` directory.
3. Restart KOReader — **Dice** appears in the Tools menu.

## Development

`dice.koplugin/` lives inside the
[koreader-plugins](https://github.com/t2ym5u/koreader-plugins) monorepo.

## License

GPL-3.0
