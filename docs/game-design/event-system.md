# Event System

## Overview

When the team enters a new tile for the first time, the game selects an event from that tile's **event table** and resolves it. Events are the primary source of gameplay: combat, discovery, resources, narrative choices, and hazards.

All event content lives in data files. The engine dispatches to a handler based on the event's `type` field.

---

## Event Types

| Type | What happens |
|---|---|
| `combat` | A fight is triggered. Uses the combat system to resolve. |
| `gather` | Resources are added to the team's inventory. |
| `encounter` | A branching choice is presented (2–3 options). Each has an outcome. |
| `discovery` | A lore entry is added to the log. Optional reward attached. |
| `hazard` | A negative effect is applied (damage, resource loss, debuff). |
| `quiet` | Nothing happens. Used as a tension device — not every tile is dangerous. |

---

## Event Data Schema

```json
{
  "id": "ambush_bandits",
  "type": "combat",
  "title": "Ambush!",
  "weight": 0.3,
  "triggers": {
    "tile_categories": ["wilderness", "dungeon"]
  },
  "scout_reduces_chance": true,
  "enemy_group": "bandits_small",
  "theme_variants": {
    "fantasy": {
      "title": "Ambush!",
      "description": "Bandits leap from the trees."
    },
    "sci_fi": {
      "title": "Ambush!",
      "description": "Raiders jam your comms and attack."
    }
  }
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `type` | string | Determines which handler resolves this event |
| `weight` | float | Relative probability in the event table (higher = more likely) |
| `triggers.tile_categories` | array | Which tile categories this event can appear on |
| `scout_reduces_chance` | bool | If true, a scout hero reduces this event's weight |
| `enemy_group` | string | (combat only) ID of the enemy group data |
| `theme_variants` | object | Per-theme title and description text |

---

## Event Tables

A named list of events with weights. The resolver picks one using weighted random selection.

```json
{
  "id": "wilderness_standard",
  "events": [
    { "event_id": "ambush_bandits",   "weight": 0.3 },
    { "event_id": "find_berries",     "weight": 0.4 },
    { "event_id": "abandoned_camp",   "weight": 0.2 },
    { "event_id": "quiet_wind",       "weight": 0.1 }
  ]
}
```

---

## Event Frequency by Depth

| Distance from camp | Event profile |
|---|---|
| Close (1–3 tiles) | Mostly gather, quiet. Low combat. |
| Mid (4–7 tiles) | Mix of encounters, discoveries, some combat. |
| Far (8+ tiles) | More hazards, ambushes, dungeon entrances. |

Implemented by assigning different event tables to tiles placed further from camp on the map.

---

## Encounter Events (branching choices)

```json
{
  "id": "lost_traveler",
  "type": "encounter",
  "choices": [
    {
      "label": "Help them",
      "outcome": { "type": "resource_gain", "gold": 5, "xp": 10 }
    },
    {
      "label": "Ignore them",
      "outcome": { "type": "nothing" }
    },
    {
      "label": "Rob them",
      "outcome": { "type": "resource_gain", "gold": 15, "team_morale": -1 }
    }
  ]
}
```

Outcomes are resolved by the event system based on the `type` key — no hardcoded logic per event.

---

## World Events (turn-scheduled)

Separate from tile-triggered events: `world-events.json` defines events that fire on a **turn schedule**, processed by `WorldEvents` (`scripts/systems/world_events.gd`) during every WORLD_TICK phase — not on tile entry.

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

Three schedule kinds via `event_type`:

| `event_type` | Behavior |
|---|---|
| `immediate` | Fires once on the first world tick |
| `scheduled` | Fires once when `turn >= trigger_turn` |
| `periodic` | Fires every `interval_turns` starting at `trigger_turn`; missed intervals catch up (effect applied once per missed cycle) |

Handlers dispatch on the `type` string, same pattern as tile events. Implemented types:

| `type` | Behavior |
|---|---|
| `hazard_regrowth` | Re-arms one random explored tile per cycle (per `payload.categories`) so its event fires again on the next visit |

The queue is rebuilt from the catalog on run start/resume (it is not part of the save file); `trigger_turn` is an absolute run turn, so periodic events catch up after loading a save.

---

## Agnostic Design Notes

- The resolver dispatches purely on `type` — it has no knowledge of any specific event
- All flavor text lives in theme variant data
- New event type = define a handler for that `type` key + write data entries
- Scout passive is applied as a weight modifier before selection, not inside event logic
