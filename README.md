# The Uncharted — Hex Exploration RPG

A turn-based mobile game where a small team of heroes explores an unknown hex world. Every tile is a land that hides events, danger, resources, or opportunity.

**Engine:** Godot 4 | **Platform:** iOS + Android | **Mode:** Single-player

---

## Documentation

### Game Design
| Doc | Description |
|---|---|
| [GDD](docs/game-design/GDD.md) | Game Design Document — overview, pillars, v1 scope |
| [Tile System](docs/game-design/tile-system.md) | Hex tile types, categories, fog of war |
| [Event System](docs/game-design/event-system.md) | Events, tables, encounter choices |
| [Hero System](docs/game-design/hero-system.md) | Roles, stats, leveling, abilities |
| [Combat System](docs/game-design/combat-system.md) | Combat flow, enemies, loot |
| [Camp System](docs/game-design/camp-system.md) | Base upgrades, rest mechanics |
| [Theme System](docs/game-design/theme-system.md) | Swappable themes, override format |
| [Progression](docs/game-design/progression.md) | XP, leveling, resources, economy |

### Technical
| Doc | Description |
|---|---|
| [Architecture](docs/technical/architecture.md) | Engine structure, data-driven design, scene tree |
| [Data Schemas](docs/technical/data-schemas.md) | All JSON schema definitions |
| [Mobile Export](docs/technical/mobile-export.md) | iOS and Android export setup |

### Content Catalogs
| File | Description |
|---|---|
| [tile-catalog.json](docs/content/tile-catalog.json) | All tile definitions |
| [hero-catalog.json](docs/content/hero-catalog.json) | All hero definitions |
| [event-catalog.json](docs/content/event-catalog.json) | All event definitions |
| [enemy-catalog.json](docs/content/enemy-catalog.json) | All enemy group definitions |

---

## Core Design Principle

**Content is data, not code.** Every tile, hero, event, enemy, upgrade, and theme is defined in JSON. Adding new content means writing new data entries — not changing engine code. See [Architecture](docs/technical/architecture.md) for details.

---

## v1 Scope

- 2 hero roles (fighter + healer)
- ~60 tile hand-crafted map with fog of war
- 3 event types (combat, gather, quiet)
- Camp with 2 upgrades
- 1 theme (fantasy)
- Win condition: reach the destination hex
