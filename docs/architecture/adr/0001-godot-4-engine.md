# ADR 0001 — Godot 4 as the Game Engine

**Status**: Accepted
**Date**: 2026-05-09

---

## Context

The project is a mobile hex exploration RPG targeting iOS and Android. The developer is an experienced software developer with no prior game development experience. We evaluated four options:

| Option | Mobile export | Hex grid support | Learning curve (softdev) | License |
|---|---|---|---|---|
| Godot 4 + GDScript | Native iOS + Android | Built-in (TileMapLayer Hexagon mode) | Low — GDScript ≈ Python | MIT, free forever |
| Unity + C# | Native iOS + Android | Needs plugin | Medium — C# + Unity quirks | Runtime fee above threshold |
| Phaser.js + Capacitor | Wrapped WebView | Manual math | Low — TypeScript | MIT |
| Python + Pygame | Not viable for mobile | Manual math | Low | MIT |

---

## Decision

**Use Godot 4 with GDScript.**

---

## Rationale

- **Mobile export**: Godot 4 exports natively to iOS and Android without wrapping. No third-party tools required.
- **Hex grid built-in**: `TileMapLayer` supports hexagonal tile shapes natively — `local_to_map()`, `map_to_local()`, and `get_surrounding_cells()` handle all coordinate math. No hex library needed.
- **GDScript syntax**: Nearly identical to Python — the developer can read and write it from day one without learning a new paradigm.
- **No licensing risk**: MIT license. No royalties, no runtime fees regardless of revenue.
- **Navigation built-in**: `NavigationAgent2D` provides pathfinding on the tile map without a third-party library.

---

## Consequences

- Requires Xcode on macOS for iOS export (Apple Developer account, $99/year)
- Requires Android Studio for Android export
- GDScript is Godot-specific — not transferable to other engines, but acceptable for a dedicated mobile game project
- The Godot editor is the primary IDE — external editor support exists (VS Code + Godot Tools extension)

---

## Alternatives Considered

**Unity**: Rejected due to steeper learning curve (C# + Unity-specific patterns), licensing concerns for a commercial release, and no meaningful advantage for a 2D hex game.

**Phaser.js + Capacitor**: Rejected because Capacitor wraps the game in a WebView — not native mobile. Performance acceptable for simple games but introduces friction (web deployment model, native feature limitations).

**Pygame**: Rejected. No viable path to iOS; Android requires heavy tooling (Buildozer). Not suitable for mobile-first development.
