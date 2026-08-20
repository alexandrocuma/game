# ADR 0002 — Data-Driven Design for All Game Content

**Status**: Accepted
**Date**: 2026-05-09

---

## Context

The game needs to support multiple content types (tiles, heroes, events, enemies, upgrades) and multiple themes (fantasy, sci-fi, mythological) without requiring code changes for each addition. The developer wants the ability to expand the game — new heroes, new events, new tile types — without touching engine scripts.

Two approaches were considered:

**Option A — Hardcoded content**: Define tiles, heroes, and events directly in GDScript. Each new tile type or hero role requires editing scripts.

**Option B — Data-driven design**: Define all content in JSON files. Engine scripts read data at startup and dispatch on type keys. New content = new JSON entry.

---

## Decision

**Use data-driven design (Option B).** All game content is defined in JSON files under `docs/content/`. Engine scripts operate on data objects — they never reference content by name.

---

## Rationale

- **Expand by addition**: adding a new hero, tile, or event never requires modifying existing scripts — only adding a new JSON entry. This eliminates the risk of regressions when expanding content.
- **Theme modularity**: because content is data, visual/textual overrides (themes) can be layered on top at startup. The same combat system resolves a knight vs. orc and a marine vs. alien identically — it only reads stat values.
- **Clear separation of concerns**: the `DataStore` autoload is a read-only content registry; `GameState` is mutable runtime state. Nothing else owns content.
- **Future-proof**: if the game is expanded to support user-generated content or modding, JSON files are the natural format. No engine changes required.

---

## Consequences

- All content authors (including the developer writing design notes) work in JSON — no GDScript knowledge required to add content
- Schemas must be maintained in [`docs/technical/data-schemas.md`](../../technical/data-schemas.md) — if a schema changes, all catalog entries using it must be updated
- New mechanic types (new event `type` keys, new passive effect keys) still require a handler branch in the relevant system script — data-driven does not eliminate all code changes, only content additions
- `DataStore` loads all catalogs at startup — for a game of this scale, startup cost is negligible

---

## Alternatives Considered

**Hardcoded content (Option A)**: Rejected. Every new hero or event type requires touching a script, increasing the chance of breaking existing behavior. Theme swapping would require extensive conditional logic throughout the codebase. Does not scale beyond a small fixed content set.

**GDScript Resources (`.tres` files)**: Godot has a built-in resource system that could serve a similar purpose. Rejected in favor of plain JSON because: JSON is readable outside the Godot editor, easier to version control and diff, and allows the design docs folder (`docs/content/`) to serve as both documentation and source data simultaneously.
