# Technical Architecture

## Engine: Godot 4 + GDScript

GDScript is syntactically similar to Python. As a software developer, you'll feel at home immediately.

---

## Do You Need a Backend Server?

**No — not for single-player.**

| Web development | Game development |
|---|---|
| Browser (frontend) | Rendering / UI layer |
| Server (backend) | Game logic layer |
| Database | Save file (disk) |

The game logic layer IS your "backend" — pure code handling rules, state, and data. No HTTP server, no REST API. All of it lives inside the engine.

A real backend server is only needed for **online multiplayer** (to sync state and prevent cheating).

---

## Data-Driven Design

All game content is defined in JSON files under `docs/content/`. The engine reads these at startup and merges the active theme overrides. No content is hardcoded in scripts.

```
Game start
  └── Load base data files (heroes, tiles, events, enemies, upgrades)
  └── Load active theme overrides
  └── Merge → single data store
  └── All systems read from merged data store
```

---

## Scene / Node Structure

```
Main (Node2D)
├── WorldMap (TileMapLayer)        ← hex tiles, terrain rendering
├── FogOfWar (TileMapLayer)        ← second layer, tiles removed as explored
├── HeroUnit (Node2D)              ← team position + sprite
├── TurnManager (Node)             ← turn state machine
├── EventManager (Node)            ← event selection + resolution
├── DataStore (Node, Autoload)     ← merged data, global access
├── GameState (Node, Autoload)     ← runtime state (HP, XP, inventory, position)
└── UI (CanvasLayer)
    ├── HUD                        ← turn counter, HP bars, movement points
    └── EventPanel                 ← popup for event resolution
```

---

## Autoloads (Global Singletons)

Two autoloads registered in Project Settings:

### `GameState`
Runtime state — changes every turn.
```gdscript
var turn: int
var team: Array[HeroState]
var resources: Dictionary          # { "food": 12, "gold": 5, "materials": 8 }
var team_position: Vector2i        # current hex coordinates
var explored_tiles: Dictionary     # Vector2i → bool
var camp_upgrades: Array[String]   # list of built upgrade IDs
```

### `DataStore`
Loaded once at startup, read-only during play.
```gdscript
var tiles: Dictionary              # id → tile data
var events: Dictionary             # id → event data
var heroes: Dictionary             # id → hero definition
var enemies: Dictionary            # id → enemy group data
var event_tables: Dictionary       # id → event table
var upgrades: Dictionary           # id → upgrade data
var combat_rules: Dictionary       # combat formula constants (single object)
var world_events: Dictionary       # id → turn-scheduled world event
```

---

## Turn State Machine

Managed by `TurnManager`. States:

```
PLAYER_INPUT  →  ANIMATING  →  EVENT  →  WORLD_TICK  →  PLAYER_INPUT
```

| State | What happens |
|---|---|
| `PLAYER_INPUT` | Highlight reachable tiles, wait for player tap |
| `ANIMATING` | Play movement animation |
| `EVENT` | Fire tile event, show EventPanel, wait for resolution |
| `WORLD_TICK` | Apply food drain, process scheduled world events, check win/lose conditions |

---

## Hex Grid

Godot's `TileMapLayer` with tile shape set to `Hexagon` in the inspector handles coordinate math.

Key built-in methods used:
- `local_to_map(Vector2)` — pixel → hex grid coords
- `map_to_local(Vector2i)` — hex grid coords → pixel
- `get_surrounding_cells(Vector2i)` — 6 hex neighbors
- `get_used_cells()` — all placed tiles

Custom helper (`hex_grid.gd`, all static, offset `Vector2i` in/out with cube conversion internally):
- `get_cells_in_range(tilemap, origin, steps)` — BFS over neighbors, returns reachable set for movement highlighting
- `distance(a, b)` — hex distance via cube coordinates
- `get_movement_cost(tilemap, pos)` — terrain cost from the tile's catalog entry
- `ring(center, radius)` — cells at exactly `radius` distance (fog reveal, AoE, spawn placement)
- `line(a, b)` — straight cell line via cube lerp + round (line-of-sight, previews)
- `find_path(tilemap, from, to)` — A* lowest-cost path; `get_movement_cost` as terrain cost, `distance` as heuristic, empty cells impassable, `[]` if unreachable
- `path_cost(tilemap, path)` — summed movement cost of a path, excluding the start

---

## World Events

`WorldEvents` (`scripts/systems/world_events.gd`, a plain RefCounted owned by `TurnManager`) is a turn-scheduled event queue processed during `WORLD_TICK`. Entries come from `docs/content/world-events.json` (`immediate` / `scheduled` / `periodic`); periodic events apply catch-up cycles for missed intervals. Handlers dispatch on the entry's `type` string, mirroring `EventManager`. The queue is rebuilt from the catalog on `TurnManager.start()` — it is not serialized into the save file.

---

## Save System

No database. Godot's `FileAccess` writes JSON to the user data directory.

```gdscript
func save():
    var f = FileAccess.open("user://save.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(GameState.to_dict()))

func load_save():
    var f = FileAccess.open("user://save.json", FileAccess.READ)
    GameState.from_dict(JSON.parse_string(f.get_as_text()))
```

Auto-saves on every rest at camp. Manual save also available.

---

## Mobile Export

Godot 4 exports natively to iOS and Android.
- iOS: requires Xcode and an Apple Developer account
- Android: requires Android SDK and a keystore

See `docs/technical/mobile-export.md` for setup steps.

---

## File Structure

```
game/
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── world_map.tscn
│   └── ui/
│       ├── hud.tscn
│       └── event_panel.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── game_state.gd
│   │   └── data_store.gd
│   ├── world/
│   │   ├── hex_grid.gd
│   │   └── world_map.gd
│   ├── systems/
│   │   ├── turn_manager.gd
│   │   ├── event_manager.gd
│   │   ├── combat_resolver.gd
│   │   └── world_events.gd
│   └── ui/
│       ├── hud.gd
│       └── event_panel.gd
├── themes/
│   └── fantasy/
│       ├── theme.json
│       ├── tile_overrides.json
│       ├── hero_overrides.json
│       ├── event_text.json
│       └── assets/
└── docs/
    ├── game-design/
    ├── technical/
    └── content/
```
