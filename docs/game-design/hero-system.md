# Hero System

## Overview

The team is a fixed group of 2–4 heroes chosen at the start. They move as one unit across the hex map. Each hero has a **role** that passively affects how events play out, plus one active ability usable during events.

All hero definitions live in data files. The engine reads stats, roles, and abilities — it never hardcodes hero behavior.

---

## Hero Roles

| Role | Passive Effect |
|---|---|
| `scout` | Reduces ambush event weight by 40%; reveals 1 extra hex ring on move |
| `fighter` | Absorbs 30% more damage before other heroes take hits; highest base HP |
| `healer` | Restores team HP after every event resolution; reduces stamina drain |
| `specialist` | Wildcard — defined per theme (mage / engineer / shaman). Effect defined in data. |

Passive effects are applied by the relevant systems (event resolver, combat resolver) by reading the team's role composition — not by calling hero-specific code.

---

## Hero Data Schema

```json
{
  "id": "fighter",
  "role": "fighter",
  "base_stats": {
    "hp": 120,
    "stamina": 80,
    "attack": 15,
    "defense": 10
  },
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
    "fantasy": { "name": "Knight",   "sprite": "knight.png" },
    "sci_fi":  { "name": "Soldier",  "sprite": "soldier.png" }
  }
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `role` | string | Determines which passive system effects apply |
| `base_stats` | object | Starting HP, stamina, attack, defense |
| `passive` | string | Key used by systems to apply role behavior |
| `ability` | object | Single active ability: stamina cost + effect key |
| `level_perks` | object | Per-level perk options (pick 1 of 2 on level up) |
| `theme_variants` | object | Per-theme name and sprite |

---

## Stats

| Stat | Description |
|---|---|
| `hp` | Health. Reaches 0 = hero is incapacitated for this run. |
| `stamina` | Used to activate the hero's ability. Recovers fully at camp. |
| `attack` | Base damage output in combat. |
| `defense` | Damage reduction in combat. |

---

## Leveling

- XP is earned by the team, shared equally
- Level thresholds are defined in `docs/game-design/progression.md`
- On level up, the player picks 1 of 2 perk options from the hero's `level_perks` data
- Max level: 5 in v1

### Perk Keys (v1)

| Key | Effect |
|---|---|
| `hp+N` | Increase max HP by N |
| `attack+N` | Increase attack by N |
| `defense+N` | Increase defense by N |
| `stamina+N` | Increase stamina by N |
| `ability_upgrade` | Enhances the hero's active ability (defined per ability in data) |
| `legendary_passive` | Level 5 only — a major passive defined per hero in data |

---

## Team Composition Rules (v1)

- Team size: 2 heroes minimum, 4 maximum
- Chosen at game start from available hero data
- No mid-run recruitment in v1
- If all heroes reach 0 HP: game over

---

## Agnostic Design Notes

- Role passives are string keys (`"frontline"`, `"scout_vision"`, etc.) that systems look up — no hero-specific code paths
- A new hero = a new JSON file in `docs/content/hero-catalog.json` with any `role` value
- A new role = define the passive behavior under that key in the relevant systems
- The combat and event systems never import hero classes — they receive hero stat objects
