# Development Setup

## Overview

This project uses Godot 4 with GDScript. There is no package manager, no build step, and no CLI — Godot is a GUI editor. Setup is: download, open project, run.

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| [Godot 4](https://godotengine.org/download/) | 4.3+ stable | Engine and editor |
| Xcode | 15+ | iOS export only (macOS required) |
| Android Studio | Latest | Android export only |

Download Godot from [godotengine.org](https://godotengine.org/download/). No installation needed — unzip and run the binary.

---

## Opening the Project

1. Launch the Godot 4 editor
2. Click **Import** on the Project Manager screen
3. Navigate to this repository root and select `project.godot`
4. Click **Import & Edit**

> `project.godot` does not exist yet — it will be created when you set up the Godot project for the first time. Use **New Project** instead, point it at this repo root, and the file will be generated.

---

## Project Structure

```
game/
├── project.godot          ← Godot project file — open this in the editor
├── scenes/                ← .tscn scene files (visual + node tree)
├── scripts/               ← .gd GDScript files (logic)
│   ├── autoloads/         ← GameState.gd, DataStore.gd — register in Project Settings
│   ├── world/             ← hex grid, world map, fog of war
│   ├── systems/           ← turn manager, event manager, combat resolver
│   └── ui/                ← HUD, event panel
├── themes/                ← theme packs (fantasy/, sci_fi/, etc.)
│   └── fantasy/
│       ├── theme.json
│       ├── tile_overrides.json
│       ├── hero_overrides.json
│       ├── event_text.json
│       └── assets/
└── docs/                  ← all documentation (you are here)
```

---

## Registering Autoloads

Autoloads are global singletons. They must be registered manually after creating the scripts:

1. Open **Project → Project Settings → Autoload**
2. Add `scripts/autoloads/data_store.gd` — name it `DataStore`
3. Add `scripts/autoloads/game_state.gd` — name it `GameState`
4. Order matters: `DataStore` must load before `GameState`

Once registered, any script can access them as `DataStore.tiles` or `GameState.turn`.

---

## Setting Up the Hex TileMap

The world map uses Godot's built-in `TileMapLayer` nodes with hexagonal tiles, but **nothing is painted in the editor**. At startup, `scripts/world/world_map.gd`:

1. Builds a `TileSet` at runtime (Tile Shape = Hexagon, Layout = Stacked, Offset Axis = Horizontal, tile size 120×140) with one atlas tile per entry in `DataStore.tiles`, using the `sprite` path from the active theme's `tile_overrides.json`. Each tile gets a `tile_id` custom data layer.
2. Places cells from `docs/content/world-map.json` (a hand-crafted list of `{ "pos": [x, y], "tile": "<tile_id>" }` entries — the v1 map).
3. Covers every placed cell with a fog tile (`themes/fantasy/assets/fog_hex.png`) on a second `TileMapLayer`; fog cells are erased as the team explores.

To change the map, edit `world-map.json`. To change how a tile looks, edit `tile_overrides.json`.

---

## Running the Game

In the editor: press **F5** (or the Play button) to run the main scene.

For mobile testing, see [Mobile Export](../technical/mobile-export.md).

---

## Environment Variables

This project has no environment variables — all configuration is in `project.godot` and the JSON data files under `docs/content/`.

---

## Common Workflows

### Adding a new script
Create `.gd` files under `scripts/` in the appropriate subfolder. Attach scripts to nodes by dragging or via the Inspector.

### Modifying game content
Edit JSON files in `docs/content/` directly. The engine reads these at startup via `DataStore`. No hot-reload — restart the game to see changes.

### Adding a theme override
Edit the relevant override file in `themes/fantasy/` (or your theme folder). See [Theme System](../game-design/theme-system.md) for the full format.

---

## Gotchas

- **GDScript is not Python** — similar syntax, but no pip, no imports from external packages. All code is self-contained within the project.
- **Godot editor = IDE** — write scripts in the built-in editor or connect an external editor (VS Code works well with the Godot Tools extension).
- **Save often** — Godot auto-saves scenes but not scripts. `Ctrl+S` saves the current script.
- **DataStore is read-only at runtime** — load data once in `_ready()`, never write to it during gameplay.
