# Theme System

## Overview

The theme system decouples all visual and textual presentation from game mechanics. Every system operates on pure data (IDs, stats, effect keys). The active theme provides the labels, sprites, and flavor text layered on top at render time.

Swapping a theme requires zero code changes.

---

## How It Works

At game startup, the engine:
1. Loads all base data files (heroes, tiles, events, enemies, upgrades)
2. Loads the active theme's override files
3. Merges them: theme overrides win on label/sprite fields; all mechanic fields stay from base data
4. All systems read from the merged result

No system ever checks which theme is active. They only read the merged data.

---

## Theme Pack Structure

```
themes/
  fantasy/
    theme.json            ← theme metadata (name, version, author)
    tile_overrides.json   ← label + sprite per tile id
    hero_overrides.json   ← name + sprite per hero id
    enemy_overrides.json  ← name + sprite per enemy id
    event_text.json       ← title + description per event id
    upgrade_overrides.json← label + sprite per upgrade id
    assets/
      sprites/
      music/
      sfx/
  sci_fi/
    ...
```

---

## Theme Metadata Schema

```json
{
  "id": "fantasy",
  "name": "Swords & Sorcery",
  "version": "1.0",
  "base_game_version": "1.0",
  "author": "Studio Name"
}
```

---

## Override File Schemas

### tile_overrides.json
```json
{
  "wilderness_forest": { "label": "Dense Forest",   "sprite": "forest.png" },
  "resource_mine":     { "label": "Ancient Mine",   "sprite": "mine.png" }
}
```

### hero_overrides.json
```json
{
  "fighter":   { "name": "Knight",  "sprite": "knight.png" },
  "healer":    { "name": "Cleric",  "sprite": "cleric.png" },
  "scout":     { "name": "Ranger",  "sprite": "ranger.png" }
}
```

### event_text.json
```json
{
  "ambush_bandits": {
    "title": "Ambush!",
    "description": "Bandits leap from the trees."
  },
  "lost_traveler": {
    "title": "A Stranger",
    "description": "A weary traveler blocks your path."
  }
}
```

---

## Adding a New Theme

1. Create a folder under `themes/` with the theme ID
2. Write override files for tiles, heroes, enemies, events, upgrades
3. Add assets to `themes/<id>/assets/`
4. Set the active theme ID in game settings

No engine code changes required.

---

## What Themes Cannot Change

Themes are purely cosmetic. They cannot:
- Change stats (HP, attack, defense)
- Change movement costs or encounter chances
- Add new tile categories or event types
- Modify game rules

Any mechanical change requires editing the base data files, not the theme.

---

## Agnostic Design Notes

- The merge step at startup is the only place theme data touches base data
- Systems receive merged data objects — they have no concept of "current theme"
- New override field types can be added to the merge step without touching any system logic
