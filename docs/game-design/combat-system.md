# Combat System

## Overview

Combat is fast and simple. No separate combat screen in v1 — it resolves as a sequence using hero and enemy stats from data. The goal is tension without complexity: a few meaningful decisions, a clear outcome.

---

## Combat Flow

```
1. Combat event fires → enemy group loaded from data
2. Enemy instances spawn with stat variation (±variance per instance, see below)
3. Initiative: heroes always act first (v1 keeps it simple)
4. Each hero attacks one enemy (sequential, left to right in party order)
   - Base damage = attacker.attack - target.defense
   - Per-attack roll: 10% miss (0 damage), 5% critical (×2), otherwise ±10% variance; minimum damage 1 on a successful hit
   - Hero may spend stamina to use their active ability instead
5. Surviving enemies attack the team
   - Damage split across heroes (fighter absorbs 30% more via passive)
   - Stunned enemies skip their attack
   - Active shields reduce incoming damage
6. Repeat until one side reaches 0 HP
7. Outcome resolved:
   - Victory → loot table rolled, XP awarded
   - Defeat → team retreats to last safe tile, all heroes at 10% HP
```

---

## Combat Rules (tunable data)

All combat constants live in [`docs/content/combat-rules.json`](../content/combat-rules.json), loaded into `DataStore.combat_rules` — never hardcoded. Missing fields fall back to engine defaults.

| Rule | Default | Effect |
|---|---|---|
| `miss_chance` | 0.10 | Chance a hero attack deals 0 damage |
| `crit_chance` | 0.05 | Chance a hero attack crits |
| `crit_multiplier` | 2.0 | Damage multiplier on crit |
| `variance` | 0.10 | ± random variance on normal hits |
| `enemy_stat_variance` | 0.20 | Default spawn variation for enemy stats |

Every attack log entry carries an `outcome` field: `"hit"`, `"miss"`, `"critical"`, or `"heal"` (heal abilities). Enemy-side attacks always log `"hit"`.

---

## Enemy Stat Variation

Each enemy instance spawned from a group rolls its hp/attack/defense within ±`variance` of the catalog value (optional per-entry field, defaulting to `enemy_stat_variance`). Two bandits from the same group are no longer identical.

---

## Enemy Group Schema

```json
{
  "id": "bandits_small",
  "enemies": [
    {
      "id": "bandit",
      "count": 3,
      "hp": 30,
      "attack": 8,
      "defense": 4,
      "variance": 0.2
    }
  ],
  "loot_table": "bandit_drops",
  "xp_reward": 25,
  "theme_variants": {
    "fantasy": { "name": "Bandits",  "sprite": "bandit.png" },
    "sci_fi":  { "name": "Raiders",  "sprite": "raider.png" }
  }
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique group identifier |
| `enemies` | array | List of enemy types with count, stats, and optional `variance` |
| `loot_table` | string | ID of loot table to roll on victory |
| `xp_reward` | int | XP granted to the team on victory |
| `theme_variants` | object | Per-theme name and sprite |

---

## Loot Tables

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

`rolls` = how many entries are drawn. `amount` = [min, max] range.

---

## Abilities in Combat

Each hero has one active ability. Spending stamina to use it replaces the normal attack.

```json
{
  "id": "power_strike",
  "stamina_cost": 20,
  "effect": "attack_multiplier: 2.0"
}
```

Effect keys are resolved by the combat system:

| Key | Behavior |
|---|---|
| `attack_multiplier: N` | Multiply hero's attack by N for this hit |
| `heal_team: N` | Restore N HP to all living heroes instead of attacking |
| `stun_enemy: N` | Target enemy skips its next N rounds (status on the enemy instance) |
| `shield: N` | Team-wide damage reduction of N for the next N rounds (status on each hero) |

Stun and shield are status dictionaries on the unit copies the resolver works on (`stun_rounds` int on the enemy, `{"amount", "rounds"}` on each living hero). They tick down inside the combat and are discarded when combat ends.

---

## Retreat Condition

If all heroes reach 0 HP before enemies are defeated:
- Team retreats to the last tile they were on before entering this tile
- All heroes restored to 10% of max HP
- No XP or loot awarded
- The tile's event resets (can be re-entered and fought again)

---

## Agnostic Design Notes

- The combat resolver takes arrays of stat objects — no hero or enemy classes are imported
- Enemy group definitions are fully in data; new enemies require zero code changes
- Ability effects are string keys dispatched to effect handlers — adding a new effect = add a handler + use the key in ability data
- Theme info is only read at render time, never during resolution
