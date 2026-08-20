# Progression System

## Overview

Progression is intentionally light. The goal is that every tile the team explores advances something — XP, resources, or lore — without requiring grinding or farming.

---

## XP & Leveling

XP is earned by the team as a whole and shared equally across all heroes.

### XP Sources

| Source | XP Gained |
|---|---|
| Combat victory | Defined per enemy group (`xp_reward` field) |
| Discovery event | 15 XP |
| Encounter event (resolved) | 10 XP |
| Gather event | 5 XP |
| Quiet event | 0 XP |

### Level Thresholds (v1)

| Level | XP Required (cumulative) |
|---|---|
| 1 | 0 (start) |
| 2 | 50 |
| 3 | 120 |
| 4 | 220 |
| 5 | 350 |

### On Level Up

Player picks 1 of 2 perk options from the hero's `level_perks` data. Perks are permanent for the run.

---

## Resources

Three resource types in v1:

| Resource | Primary use |
|---|---|
| `food` | Team stays healthy. Running out causes HP drain each turn. |
| `gold` | Trade in towns (v2). Camp upgrades. |
| `materials` | Camp upgrades. |

### Resource Economy (v1 targets)

- A typical exploration run should exhaust food 2–3 times before reaching the destination
- Camp upgrades should require 3–5 gathering events' worth of materials
- Gold is secondary; player shouldn't be blocked without it in v1

### Carry Capacity

Base carry limit per resource type:

| Resource | Base limit |
|---|---|
| `food` | 20 |
| `gold` | 50 |
| `materials` | 30 |

`storage_unit` camp upgrade multiplies all limits by 1.25.

---

## Food & Hunger

Every turn spent moving costs 1 food.
If food reaches 0:
- Team loses 5 HP per turn until food is resupplied or they return to camp
- Camp rest restores food to full (no cost — camp has rations)

This creates a soft pressure to explore efficiently and return to camp periodically.

---

## Win Condition

Reach the **destination hex** — a unique tile placed at the far end of the map.

On arrival:
- Run complete screen shown
- Stats summarized: turns taken, tiles explored, heroes lost, events resolved
- No new game+ in v1 — just a clear ending

---

## Agnostic Design Notes

- XP thresholds and level perk options are defined in data, not code
- Resource types are string keys — adding a new resource type = add its key to the resource definitions file and reference it in relevant event/tile data
- The hunger mechanic reads `food` as a key; renaming or replacing it only requires updating data references
