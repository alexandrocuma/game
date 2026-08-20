# Mobile Export — Godot 4

## Overview

Godot 4 exports natively to iOS and Android. No wrapping or third-party tools needed.

---

## Android Export

### Requirements
- Android SDK (via Android Studio)
- Java Development Kit (JDK 17+)
- A debug or release keystore

### Steps
1. Install [Android Studio](https://developer.android.com/studio)
2. In Godot: **Editor → Export → Add → Android**
3. Set package name (e.g. `com.yourstudio.theuncharted`)
4. Connect a device via USB with USB debugging enabled
5. Click **Export Project** → select your device

### Release Build
Generate a keystore:
```bash
keytool -genkey -v -keystore release.keystore -alias mykey -keyalg RSA -keysize 2048 -validity 10000
```
Add keystore path and credentials in the Godot Android export settings.

---

## iOS Export

### Requirements
- macOS with Xcode 15+
- Apple Developer account (paid, $99/year)
- iOS Export Templates installed in Godot

### Steps
1. Install Xcode from the Mac App Store
2. In Godot: **Editor → Export → Add → iOS**
3. Set bundle ID (e.g. `com.yourstudio.theuncharted`)
4. Click **Export Project** → generates an `.xcodeproj`
5. Open in Xcode → sign with your Apple Developer account → run on device

### Simulator Testing
You can test in the iOS Simulator without a paid account:
- In Xcode, select a simulator target instead of a real device

---

## Touch Input in Godot 4

Replace mouse input with touch input in all scripts:

```gdscript
func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        var world_pos = get_global_mouse_position()
        var hex_coords = tile_map.local_to_map(world_pos)
        # handle tap on hex_coords
```

Use `InputEventScreenTouch` (tap) and `InputEventScreenDrag` (scroll/pan).

---

## Performance Notes

- Keep tile count per layer under 10,000 for smooth mobile performance
- Disable physics for tiles that don't need collision
- Use compressed textures (`.webp` or `.basis`) for sprites
- Target 60fps on mid-range devices (iPhone 12 / Pixel 5 class)
