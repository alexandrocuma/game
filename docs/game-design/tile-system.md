# Tile System

## Overview

The hex grid is the world. Each tile has a **type** defined in data, which controls what can happen there — movement cost, possible events, resources, and how it looks per theme.

The engine reads tile data; it never hardcodes tile behavior. New tile types are added by writing new JSON entries.

---

## Tile Categories

| Category | Description |
|---|---|
| `wilderness` | Unexplored land. Event fires on first entry. |
| `structure_enemy` | Hostile-controlled location. Higher combat chance. |
| `structure_neutral` | Towns, outposts. Trade and quests (v2+). |
| `resource_node` | Dedicated gather tile. Repeatable on later visits. |
| `dungeon` | High-risk, high-reward area. Optional challenge. |
| `camp_player` | Player's base. Safe zone, no events. |
| `discovery` | Unique, one-time tile. Lore + special reward. |

---

## Tile Data Schema

```json
{
  "id": "wilderness_forest",
  "category": "wilderness",
  "movement_cost": 1,
  "event_table": "wilderness_standard",
  "encounter_chance": 0.6,
  "resource_types": ["food", "wood"],
  "buildable": false,
  "theme_variants": {
    "fantasy": {
      "label": "Dense Forest",
      "sprite": "forest.png"
    },
    "sci_fi": {
      "label": "Alien Jungle",
      "sprite": "jungle_alien.png"
    }
  }
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `category` | string | One of the tile categories above |
| `movement_cost` | int | Turns required to enter (1 = normal, 2 = rough) |
| `event_table` | string | ID of the event table to roll from on entry |
| `encounter_chance` | float | 0.0–1.0 base chance an event fires on entry |
| `resource_types` | array | Resource types gatherable here |
| `buildable` | bool | Whether the player can place a camp/outpost here |
| `theme_variants` | object | Per-theme label and sprite overrides |

---

## Fog of War

- All tiles start hidden
- Tiles are revealed when the team moves adjacent to them (1-hex sight radius)
- The camp tile always starts revealed
- The `watchtower` camp upgrade extends reveal radius to 2 hexes from camp

---

## Agnostic Design Notes

- The engine only reads `category`, `movement_cost`, `event_table`, and `encounter_chance` for logic
- Visual data (`label`, `sprite`) is pulled from the active theme variant at render time
- The engine never references a tile by name — always by `id`
