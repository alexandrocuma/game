# Documentation

Navigation index for all project documentation.

---

## Game Design

Rules, systems, and mechanics. Start here before touching any code or data.

- [GDD — Game Design Document](game-design/GDD.md) — overview, design pillars, v1 scope
- [Tile System](game-design/tile-system.md) — hex tile types, categories, fog of war
- [Event System](game-design/event-system.md) — events, tables, encounter choices, resolution
- [Hero System](game-design/hero-system.md) — roles, stats, leveling, abilities
- [Combat System](game-design/combat-system.md) — combat flow, enemies, loot tables
- [Camp System](game-design/camp-system.md) — base upgrades, rest mechanics
- [Theme System](game-design/theme-system.md) — swappable theme packs, override format
- [Progression](game-design/progression.md) — XP, leveling, resources, food economy

## Content Catalogs

Source data for all in-game content. Edit these to add tiles, heroes, events, and enemies.

- [tile-catalog.json](content/tile-catalog.json)
- [hero-catalog.json](content/hero-catalog.json)
- [event-catalog.json](content/event-catalog.json)
- [enemy-catalog.json](content/enemy-catalog.json)

## Guides

Step-by-step workflows for common tasks.

- [Adding Content](guides/adding-content.md) — add tiles, events, heroes, enemies without touching engine code

## Architecture

- [ADR Index](architecture/adr/) — all architecture decision records
  - [0001 — Godot 4 Engine](architecture/adr/0001-godot-4-engine.md)
  - [0002 — Data-Driven Design](architecture/adr/0002-data-driven-design.md)

## Technical

Implementation reference for developers.

- [Architecture](technical/architecture.md) — engine structure, scene tree, autoloads, save system
- [Data Schemas](technical/data-schemas.md) — all JSON schema definitions
- [Mobile Export](technical/mobile-export.md) — iOS and Android export setup

## Development

- [Setup](development/setup.md) — install Godot 4, open the project, run on device
