# Adding Content

## Overview

This game uses a **data-driven design**: all tiles, heroes, events, enemies, and upgrades are defined in JSON. Adding new content means writing JSON entries — not touching engine code.

This guide covers every content type and when engine changes are actually required.

---

## The Rule

> If you are writing game content into a `.gd` script file, stop. Write a JSON entry instead.

Engine code changes are only needed when introducing a **new mechanic type** (a new event `type` key, a new passive effect key). Content that uses existing types requires zero code changes.

---

## Adding a Tile Type

**File**: [`docs/content/tile-catalog.json`](../content/tile-catalog.json)
**Schema**: [`docs/technical/data-schemas.md`](../technical/data-schemas.md#tile)
**Rules**: [`docs/game-design/tile-system.md`](../game-design/tile-system.md)

### Steps

1. Add a new object to `tile-catalog.json`:
```json
{
  "id": "swamp_cursed",
  "category": "wilderness",
  "movement_cost": 2,
  "event_table": "wilderness_harsh",
  "encounter_chance": 0.75,
  "resource_types": ["food"],
  "buildable": false,
  "theme_variants": {
    "fantasy": { "label": "Cursed Swamp", "sprite": "swamp.png" }
  }
}
```
2. Set the sprite path in `themes/fantasy/tile_overrides.json` (full `res://` path to a 120×140 hex PNG)
3. Place the tile on the map by adding `{ "pos": [x, y], "tile": "swamp_cursed" }` to `docs/content/world-map.json`

Tiles are **not** painted in the TileSet editor — `world_map.gd` builds the TileSet at runtime from the theme sprite paths and places cells from `world-map.json` at startup.

**No script changes required** — `DataStore` loads all entries in the catalog on startup.

### When engine changes ARE needed
If you introduce a new `category` value not yet handled by the event system, add a branch in `event_manager.gd`.

---

## Adding an Event

**File**: [`docs/content/event-catalog.json`](../content/event-catalog.json)
**Schema**: [`docs/technical/data-schemas.md`](../technical/data-schemas.md#event)
**Rules**: [`docs/game-design/event-system.md`](../game-design/event-system.md)

### Steps

1. Add a new object to `event-catalog.json`:
```json
{
  "id": "merchant_cart",
  "type": "encounter",
  "weight": 0.15,
  "triggers": { "tile_categories": ["wilderness"] },
  "scout_reduces_chance": false,
  "choices": [
    { "label": "Buy food",  "outcome": { "type": "resource_spend", "gold": 5, "food": 10 } },
    { "label": "Move on",   "outcome": { "type": "nothing" } }
  ],
  "theme_variants": {
    "fantasy": { "title": "Travelling Merchant", "description": "A merchant blocks the road, hawking wares." }
  }
}
```
2. Add it to the relevant event table inside the same file:
```json
{ "event_id": "merchant_cart", "weight": 0.15 }
```
3. Add flavor text to `themes/fantasy/event_text.json`

**No script changes required** if using an existing `type` (`combat`, `gather`, `encounter`, `discovery`, `hazard`, `quiet`).

### When engine changes ARE needed
If you add a new `type` value (e.g. `"type": "puzzle"`), add a handler branch in `event_manager.gd` for that type key.

---

## Adding a Hero Role

**File**: [`docs/content/hero-catalog.json`](../content/hero-catalog.json)
**Schema**: [`docs/technical/data-schemas.md`](../technical/data-schemas.md#hero)
**Rules**: [`docs/game-design/hero-system.md`](../game-design/hero-system.md)

### Steps

1. Add a new object to `hero-catalog.json`:
```json
{
  "id": "mage",
  "role": "specialist",
  "base_stats": { "hp": 70, "stamina": 140, "attack": 12, "defense": 5 },
  "passive": "spell_aura",
  "ability": {
    "id": "fireball",
    "stamina_cost": 30,
    "effect": "attack_multiplier: 3.0"
  },
  "level_perks": {
    "2": ["stamina+25", "attack+4"],
    "3": ["ability_upgrade", "hp+10"],
    "4": ["stamina+30", "attack+6"],
    "5": ["legendary_passive"]
  },
  "theme_variants": {
    "fantasy": { "name": "Mage", "sprite": "mage.png" }
  }
}
```
2. Add `mage.png` to `themes/fantasy/assets/sprites/`
3. Add an entry to `themes/fantasy/hero_overrides.json`

**No script changes required** if using an existing `passive` key and an existing ability `effect` key.

### When engine changes ARE needed
If you add a new `passive` key (e.g. `"spell_aura"`), define its effect in `event_manager.gd` and/or `combat_resolver.gd`. If you add a new ability `effect` key, add its handler in `combat_resolver.gd`.

---

## Adding an Enemy Group

**File**: [`docs/content/enemy-catalog.json`](../content/enemy-catalog.json)
**Schema**: [`docs/technical/data-schemas.md`](../technical/data-schemas.md#enemy-group)

### Steps

1. Add a new object to `enemy-catalog.json`:
```json
{
  "id": "forest_spirits",
  "enemies": [
    { "id": "spirit", "count": 2, "hp": 45, "attack": 12, "defense": 6 }
  ],
  "loot_table": "spirit_drops",
  "xp_reward": 35,
  "theme_variants": {
    "fantasy": { "name": "Forest Spirits", "sprite": "spirit.png" }
  }
}
```
2. Reference it in a `combat` event's `enemy_group` field
3. Add `spirit.png` to assets

**No script changes required.**

---

## Tuning Combat Rules

**File**: [`docs/content/combat-rules.json`](../content/combat-rules.json)
**Schema**: [`docs/technical/data-schemas.md`](../technical/data-schemas.md#combat-rules)
**Rules**: [`docs/game-design/combat-system.md`](../game-design/combat-system.md)

Miss chance, crit chance/multiplier, damage variance, and enemy stat variation are all numbers in `combat-rules.json`. Edit the value, restart the game — **no script changes required**. Omitted fields fall back to engine defaults.

Per-enemy spawn variation can be overridden with the optional `variance` field on an enemy entry in `enemy-catalog.json`.

### When engine changes ARE needed
If you add a new ability `effect` key (e.g. `"poison: 3"`), add its handler branch in `combat_resolver.gd`.

---

## Adding a World Event

**File**: [`docs/content/world-events.json`](../content/world-events.json)
**Schema**: [`docs/technical/data-schemas.md`](../technical/data-schemas.md#world-event)
**Rules**: [`docs/game-design/event-system.md`](../game-design/event-system.md#world-events-turn-scheduled)

World events fire on a turn schedule during WORLD_TICK (unlike tile events, which fire on tile entry).

### Steps

1. Add a new object to `world-events.json`:
```json
{
  "id": "hazard_regrowth_deep",
  "event_type": "periodic",
  "type": "hazard_regrowth",
  "trigger_turn": 30,
  "interval_turns": 10,
  "payload": { "categories": ["wilderness"] }
}
```

**No script changes required** if using an existing `type` handler (currently `hazard_regrowth`) and `event_type` (`immediate`, `scheduled`, `periodic`).

### When engine changes ARE needed
If you add a new `type` value, add a handler branch in `world_events.gd`'s `_dispatch()`.

---

## Adding a Theme

**Full guide**: [`docs/game-design/theme-system.md`](../game-design/theme-system.md)

### Steps

1. Create `themes/<id>/` folder
2. Write override files: `tile_overrides.json`, `hero_overrides.json`, `event_text.json`, `enemy_overrides.json`
3. Add `theme.json` metadata
4. Add assets under `themes/<id>/assets/`
5. Set the active theme ID in game settings

**Zero engine code changes.**

---

## Quick Reference

| Content type | File to edit | Engine change needed? |
|---|---|---|
| New tile type | `docs/content/tile-catalog.json` | Only if new `category` |
| New event | `docs/content/event-catalog.json` | Only if new `type` key |
| New hero | `docs/content/hero-catalog.json` | Only if new `passive` or ability `effect` |
| New enemy group | `docs/content/enemy-catalog.json` | Never |
| Combat rule tweak | `docs/content/combat-rules.json` | Never |
| New world event | `docs/content/world-events.json` | Only if new `type` key |
| New camp upgrade | *(catalog TBD)* | Only if new `effect` key |
| New theme | `themes/<id>/` folder | Never |
