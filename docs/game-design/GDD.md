# Game Design Document — Hex Exploration RPG
**Working Title:** The Uncharted
**Platform:** Mobile (iOS + Android)
**Engine:** Godot 4
**Mode:** Single-player, turn-based

---

## One-Line Pitch

A turn-based mobile game where a small team of heroes explores an unknown hex world — each tile is a land that hides events, danger, resources, or opportunity.

---

## Design Principles

### 1. Content is Data, Not Code
Every piece of game content — heroes, tiles, events, abilities, themes, upgrades — is defined in a **data file (JSON)**. The engine reads these files and runs the rules.

- Adding a new hero role = write a new JSON entry, no code change
- Adding a new event type = add to the event table JSON
- Swapping themes = swap the data + assets folder

This is called **data-driven design**. It is the core architectural principle.

### 2. Systems are Agnostic
Each system (combat, events, tiles, progression) operates on **interfaces**, not concrete types. A combat system doesn't know if it's resolving a knight vs. an orc or a marine vs. an alien — it just reads attack/defense values from whichever data it's given.

### 3. Expand by Addition, Not Modification
v2, v3 content should be added by dropping in new data files. The codebase should rarely need changes to add new content.

---

## Core Design Pillars

| Pillar | Description |
|---|---|
| **Tile as world** | Every hex is a container of possibility. Stepping on it triggers the world. |
| **Gradual revelation** | The world is hidden. You earn the map tile by tile. Nothing is handed to you. |
| **Team, not lone hero** | 2–4 heroes move together. Each has a role. Losing one matters. |
| **Camp as anchor** | One safe hub in a dangerous world. Always somewhere to return to. |
| **Theme-agnostic engine** | Mechanics decouple from lore. Swap any theme without changing a single rule. |

---

## The Turn Loop

```
Each turn:
  1. Player chooses adjacent hex to move to (or stays)
  2. Team moves → fog of war recedes around them
  3. Tile event triggers (if first visit)
  4. Player resolves event (choice, combat, gather, etc.)
  5. Resources / XP updated
  6. Next turn begins
```

Movement costs 1 turn. Rough terrain tiles cost 2 turns.
The camp tile is always free to return to — no event, just safety.

---

## v1 Scope

1. Hex world with fog of war (~50–80 tiles, hand-crafted)
2. 2 hero roles: fighter + healer
3. 3 tile types: wilderness, camp, resource node
4. 3 event types: combat, gather, quiet
5. HP + leveling (levels 1–3 only)
6. Camp with 2 upgrades: healer's tent, storage
7. 1 theme (fantasy)
8. Win condition: reach the destination hex

---

## What's NOT in v1

- More than 2 hero roles
- Towns / NPC interactions
- Crafting
- Online multiplayer
- Multiple themes
- Procedural map generation
- Specialist role
- Complex skill trees
