# Camp System

## Overview

The camp is the player's only guaranteed safe tile. No events fire here. It's where the team rests, heals, manages inventory, and spends resources on upgrades.

Upgrades are light — a small set of meaningful improvements, not a full base-builder.

---

## Camp Actions

| Action | Description |
|---|---|
| **Rest** | Restore team HP. Amount depends on upgrades. Base: 50% of max HP. |
| **Manage inventory** | View and equip items (v2). In v1: view resources only. |
| **Build upgrade** | Spend resources to add a camp upgrade. |
| **Save game** | Explicit save. Auto-save also triggers on rest. |

Resting costs 1 turn. Building an upgrade costs 1 turn + resources.

---

## Camp Upgrade Schema

```json
{
  "id": "healers_tent",
  "cost": { "materials": 10, "gold": 5 },
  "effect": "rest_hp_multiplier: 1.5",
  "max_level": 1,
  "theme_variants": {
    "fantasy": { "label": "Healer's Tent", "sprite": "tent.png" },
    "sci_fi":  { "label": "Med Bay",        "sprite": "medbay.png" }
  }
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `cost` | object | Resource cost to build |
| `effect` | string | Effect key applied when upgrade is active |
| `max_level` | int | How many times this can be built (1 = once only) |
| `theme_variants` | object | Per-theme label and sprite |

---

## Available Upgrades (v1)

| ID | Cost | Effect |
|---|---|---|
| `healers_tent` | 10 materials, 5 gold | Restore 50% more HP on rest |
| `storage_unit` | 8 materials | Carry 25% more resources |
| `training_ground` | 12 materials, 8 gold | Heroes gain 20% more XP |
| `watchtower` | 15 materials | Reveals 2 extra hex rings from camp |

Maximum 4 upgrades total in v1 — one of each.

---

## Effect Keys

Camp effects use the same key-dispatch pattern as the rest of the game:

| Key | Behavior |
|---|---|
| `rest_hp_multiplier: N` | Multiply HP restored on rest by N |
| `carry_capacity_multiplier: N` | Multiply max resource carry by N |
| `xp_multiplier: N` | Multiply XP earned by N |
| `vision_radius: N` | Set camp fog-reveal radius to N hexes |

---

## Agnostic Design Notes

- Camp upgrades are loaded from data at startup; the camp system reads effect keys and applies them
- New upgrade = new JSON entry, no code change required
- Theme labels/sprites are only read at render time
