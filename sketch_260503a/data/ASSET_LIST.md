# Asset checklist

All files live under **`sketch_260503a/data/`**.

---

## Audio (`data/sounds/`)

| File | When it plays |
|------|---------------|
| `gun_player.wav` | Player revolver/repeater fire |
| `enemy_gunshot.wav` | Enemy gunfire |
| `shotgun-firing.wav` | Player shotgun fire |
| `gun_reload.wav` | Revolver / repeater reload |
| `shotgun-reload-sfx.wav` | Shotgun reload |
| `health_pickup.wav` | Health loot collected |
| `bullet_pickup.wav` | Ammo loot collected |
| `wave_clear.wav` | Wave cleared (intermission starts) |
| `ui_click.wav` | Menu / settings click |
| `western_soundtrack.wav` | Title, controls, settings menu loop |
| `ingame_theme.wav` | In-game background music loop |

**Format:** WAV (PCM), 44.1 kHz.

---

## Textures (`data/textures/`)

| File | Used for |
|------|----------|
| `barrel_wood.jpg` | Barrel cylinder |
| `ground_dirt.jpg` | Arena floor |
| `cactus.png` | Cactus cylinders |
| `wood1.jpg`, `wood2.jpg`, `wood3.jpg` | Building walls |
| `fence.jpg` | Fence posts |
| `sky_cubemap/cubemap.png` | Sky cubemap (cross layout) |

Missing roof / building / flat-sky files fall back to procedural textures in code.

---

## Fonts (`data/fonts/`)

| File | Usage |
|------|-------|
| `RioGrande.ttf` | Titles, large HUD text |
| `Sancreek-Regular.ttf` | Body text, controls panel |

---

## UI (`data/ui/`)

| File | Usage |
|------|-------|
| `western_bg.png` | Title + controls background |
| `hat.png` | Menu decoration |
| `revolver.png`, `tumbleweed.png` | Decoration |

---

## Control icons (`data/controls/`)

`keyboard_*.png`, `mouse_*.png` — controls overlay grid.

---

## Auto-generated

| File | Description |
|------|-------------|
| `progression.txt` | `highScore`, `totalKills`, volume, fullscreen |

---

## Folder tree

```
sketch_260503a/data/
├── fonts/
│   ├── RioGrande.ttf
│   └── Sancreek-Regular.ttf
├── sounds/
│   ├── gun_player.wav
│   ├── enemy_gunshot.wav
│   ├── shotgun-firing.wav
│   ├── gun_reload.wav
│   ├── shotgun-reload-sfx.wav
│   ├── health_pickup.wav
│   ├── bullet_pickup.wav
│   ├── wave_clear.wav
│   ├── ui_click.wav
│   ├── western_soundtrack.wav
│   └── ingame_theme.wav
├── textures/
│   ├── barrel_wood.jpg
│   ├── ground_dirt.jpg
│   ├── cactus.png
│   ├── wood1.jpg, wood2.jpg, wood3.jpg
│   ├── fence.jpg
│   └── sky_cubemap/cubemap.png
├── controls/
├── ui/
│   ├── western_bg.png
│   ├── hat.png
│   ├── revolver.png
│   └── tumbleweed.png
└── progression.txt
```
