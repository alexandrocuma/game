# Data Schemas Reference

All game content lives in JSON files under `docs/content/`. This document is the single source of truth for every schema.

---

## Tile

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
    "fantasy": { "label": "Dense Forest", "sprite": "forest.png" }
  }
}
```

---

## Event

```json
{
  "id": "ambush_bandits",
  "type": "combat",
  "weight": 0.3,
  "triggers": { "tile_categories": ["wilderness", "dungeon"] },
  "scout_reduces_chance": true,
  "enemy_group": "bandits_small",
  "theme_variants": {
    "fantasy": { "title": "Ambush!", "description": "Bandits leap from the trees." }
  }
}
```

---

## Encounter Event (with choices)

```json
{
  "id": "lost_traveler",
  "type": "encounter",
  "weight": 0.2,
  "triggers": { "tile_categories": ["wilderness"] },
  "choices": [
    { "label": "Help them",  "outcome": { "type": "resource_gain", "gold": 5, "xp": 10 } },
    { "label": "Ignore",     "outcome": { "type": "nothing" } },
    { "label": "Rob them",   "outcome": { "type": "resource_gain", "gold": 15, "team_morale": -1 } }
  ],
  "theme_variants": {
    "fantasy": { "title": "A Stranger", "description": "A weary traveler blocks your path." }
  }
}
```

---

## Event Table

```json
{
  "id": "wilderness_standard",
  "events": [
    { "event_id": "ambush_bandits",  "weight": 0.3 },
    { "event_id": "find_berries",    "weight": 0.4 },
    { "event_id": "abandoned_camp",  "weight": 0.2 },
    { "event_id": "quiet_wind",      "weight": 0.1 }
  ]
}
```

---

## Hero

```json
{
  "id": "fighter",
  "role": "fighter",
  "base_stats": { "hp": 120, "stamina": 80, "attack": 15, "defense": 10 },
  "passive": "frontline",
  "ability": {
    "id": "power_strike",
    "stamina_cost": 20,
    "effect": "attack_multiplier: 2.0"
  },
  "level_perks": {
    "2": ["hp+20", "attack+3"],
    "3": ["defense+5", "ability_upgrade"],
    "4": ["hp+30", "stamina+10"],
    "5": ["legendary_passive"]
  },
  "theme_variants": {
    "fantasy": { "name": "Knight", "sprite": "knight.png" }
  }
}
```

---

## Enemy Group

```json
{
  "id": "bandits_small",
  "enemies": [
    { "id": "bandit", "count": 3, "hp": 30, "attack": 8, "defense": 4, "variance": 0.2 }
  ],
  "loot_table": "bandit_drops",
  "xp_reward": 25,
  "theme_variants": {
    "fantasy": { "name": "Bandits", "sprite": "bandit.png" }
  }
}
```

`variance` (optional, per enemy entry): each spawned instance rolls hp/attack/defense within ±variance of the listed value. Defaults to `enemy_stat_variance` in `combat-rules.json` when omitted.

---

## Combat Rules

`combat-rules.json` is a single object (not an array of entries) loaded into `DataStore.combat_rules`. All fields optional — missing fields fall back to the defaults in `combat_resolver.gd`.

```json
{
  "miss_chance": 0.10,
  "crit_chance": 0.05,
  "crit_multiplier": 2.0,
  "variance": 0.10,
  "enemy_stat_variance": 0.20
}
```

| Field | Type | Description |
|---|---|---|
| `miss_chance` | float | Probability a hero attack misses (0 damage, outcome `"miss"`) |
| `crit_chance` | float | Probability a hero attack crits (outcome `"critical"`) |
| `crit_multiplier` | float | Damage multiplier on a critical hit |
| `variance` | float | ± random damage variance on normal hits |
| `enemy_stat_variance` | float | Default ± stat variation when spawning enemy instances |

---

## World Event

`world-events.json` holds turn-scheduled events processed by `WorldEvents` during the WORLD_TICK phase (distinct from tile-triggered events in `event-catalog.json`).

```json
{
  "id": "hazard_regrowth_wilds",
  "event_type": "periodic",
  "type": "hazard_regrowth",
  "trigger_turn": 15,
  "interval_turns": 15,
  "payload": { "categories": ["wilderness"] }
}
```

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `event_type` | string | `immediate` (first tick), `scheduled` (once at `trigger_turn`), or `periodic` (every `interval_turns`) |
| `type` | string | Handler key dispatched in `world_events.gd` |
| `trigger_turn` | int | Absolute run turn of first trigger |
| `interval_turns` | int | (periodic only) Turns between triggers |
| `payload` | object | Handler-specific parameters |

---

## Loot Table

```json
{
  "id": "bandit_drops",
  "rolls": 2,
  "entries": [
    { "resource": "gold",      "amount": [5, 15],  "weight": 0.5 },
    { "resource": "food",      "amount": [3, 8],   "weight": 0.3 },
    { "resource": "materials", "amount": [2, 5],   "weight": 0.2 }
  ]
}
```

---

## Camp Upgrade

```json
{
  "id": "healers_tent",
  "cost": { "materials": 10, "gold": 5 },
  "effect": "rest_hp_multiplier: 1.5",
  "max_level": 1,
  "theme_variants": {
    "fantasy": { "label": "Healer's Tent", "sprite": "tent.png" }
  }
}
```

---

## Theme Metadata

```json
{
  "id": "fantasy",
  "name": "Swords & Sorcery",
  "version": "1.0",
  "base_game_version": "1.0"
}
```
