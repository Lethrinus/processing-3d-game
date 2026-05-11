# Western 3D Shootout (Processing / P3D)

A **third-person / angled top-down** western shooter built with **Processing** for the **SEN3301** course project. Clear waves of enemies in an arena, manage time and health, and collect loot.

**Team**

| Name | ID |
|------|-----|
| Ozan Halis Demiralp | 2203046 |
| Yavuzhan Özbek | 2201927 |

Main sketch folder: **`sketch_260503a/`**. Game logic and entity classes compile as additional tabs in the same sketch.

---

## Table of contents

1. [Requirements](#requirements)
2. [Installation and running](#installation-and-running)
3. [Controls](#controls)
4. [Gameplay](#gameplay)
5. [Weapons and economy](#weapons-and-economy)
6. [Enemies and world](#enemies-and-world)
7. [User interface (HUD)](#user-interface-hud)
8. [Audio and music](#audio-and-music)
9. [Graphics and textures](#graphics-and-textures)
10. [Source layout](#source-layout)
11. [Persistent progression](#persistent-progression)
12. [Troubleshooting](#troubleshooting)
13. [Other files](#other-files)

---

## Requirements

- **Processing 3.x or 4.x** (Java mode). Open the **`sketch_260503a`** folder as the sketch (it must contain `sketch_260503a.pde`).
- The sketch uses **fullscreen P3D**; up-to-date GPU drivers are recommended.
- No extra audio library: **`javax.sound.sampled`** plus **`SoundHelper.java`**.

---

## Installation and running

1. Clone or download this repository.
2. In the Processing IDE, use **File → Open…** and select the **`sketch_260503a`** folder.
3. Press **Run** (▶).

**Important:** In modern Processing, **`fullScreen()`** and **`size()`** must be called from **`settings()`**, not from **`setup()`**. Otherwise you get:  
`IllegalStateException: fullScreen() cannot be used here`.

By default the sketch uses **`fullScreen(P3D, 1)`** (primary display). For a second monitor, change **`1`** to **`2`** in **`settings()`** inside `sketch_260503a.pde`.

---

## Controls

| Input | Action |
|--------|--------|
| **W A S D** | Move (relative to camera facing) |
| **Left mouse** (hold) | Fire continuously (aim: mouse projects to the ground plane) |
| **Right mouse + drag** | Orbit camera (yaw) |
| **Mouse wheel** | Zoom in / out |
| **1 / 2 / 3** | Weapon slots: **Revolver** / **Shotgun** / **Repeater** |
| **R** | Reload the **current** weapon. When the match is over, **R** can also restart (see on-screen prompts). |
| **Shift** | Sprint (drains stamina; sprint bar fades after you release Shift) |
| **Space** | Skip the wait during **wave break** |
| **Q** | Quit (current run stats are saved to disk) |

The first **3 seconds** after launch show a black placeholder screen; the play scene starts afterward.

---

## Gameplay

### Objectives

- **Win** by clearing all **waves** (`maxWaves`, default **5**), or  
- **Survive** until the **timer** runs out (base time plus bonus time earned between waves).

### Waves

- Enemy count per wave: **`2 + 2 × wave_index`**.
- When every enemy in a wave is dead, a **wave break** starts (~**8 s**; press **Space** to skip).
- Clearing a wave grants time and score bonuses; after the final wave the win condition is evaluated.

### Timer and defeat

- Remaining time (base + **extra time**) is shown in the **top-right** bar.
- If time reaches **0**, the run ends with **TIME OVER**.
- If player **HP** reaches **0**, the run ends with **YOU LOST**. **Q** ends with **QUIT**.

### Loot (drops from kills)

Loot is spawned from the main sketch’s bullet hit logic when a bandit dies. Three types with **uniform random** choice:

| Type | Effect |
|------|--------|
| **Gold** | Adds `gold` and score |
| **Health** | Restores HP |
| **Ammo** | Refills ammo for **all three** weapons; a green **+N** float text appears on pickup |

Walk into a pickup to collect it. Missing sound files fail silently; **`reload.wav`** may still be requested on pickup.

### Sprint trail

While sprinting with **Shift**, a sparse **dust trail** is drawn via **2D screen projection** of world points behind the player. Intensity is intentionally low.

---

## Weapons and economy

| Slot | Weapon | Magazine | Summary |
|------|--------|----------|---------|
| **1** | Revolver | 30 | Single projectile, medium damage, fast fire |
| **2** | Shotgun | 8 | Spread (5 pellets), stronger visual recoil |
| **3** | Repeater | 40 | Fast semi-auto, single projectile |

Per-weapon **cooldown**, **reload duration**, and **bullet damage** are defined on the **`Player`** class in **`WesternGameEntities.pde`**.

**Gold** and **score** are shown in the HUD and feed into **best run score** persistence (see [Persistent progression](#persistent-progression)).

---

## Enemies and world

- **Bandit**: moves toward the player, **shoots** at range, stays inside the arena with collision helpers.
- **Enemy bullets**: gravity and motion/visual styling.
- **Arena**: scaled world coordinates; ground plane, saloon, props, barrels, fence posts, cacti, etc. — textured or procedural.
- **Combat feedback**: death effects include gibs / blood (tuned to stay readable; adjust counts in code if needed).

---

## User interface (HUD)

- **Top-left**: Wave, score, kills, gold, best run score.
- **Top-right**: Remaining **time** bar (sprint bar was moved near the character).
- **Top-center**: Short **two-line** control summary.
- **Bottom (full width)**: **Health** bar and HP label.
- **Bottom-right**: Large **ammo** readout / reload text and weapon name.
- **Damage**: HUD shake plus **center ring and slash** feedback (no full-screen white flash).
- **Reload**: Progress bar near the **player feet** screen position.

---

## Audio and music

Paths are relative to **`sketch_260503a/data/sounds/`**. If a file is missing, **`SoundHelper`** skips playback without crashing.

Recommended filenames and tips: **`sketch_260503a/data/ASSETS_README.txt`**.

---

## Graphics and textures

Default textures load from **`data/textures/`**. If a file is missing, the sketch generates **procedural placeholders**.

- **Adding textures:** follow the **“HOW TO ADD OR CHANGE TEXTURES”** section in **`ASSETS_README.txt`**: `tryLoadImage`, `textureMode(NORMAL)`, `drawTexturedCylinder`, or your own `beginShape` UVs.

**Warning:** Do **not** call **`randomSeed(...)`** every frame inside **`draw()`**; it breaks gameplay randomness (e.g. loot). Use **`noise()`** for ambient motion instead.

---

## Source layout

```
sketch_260503a/
├── sketch_260503a.pde      # Main loop: camera, arena, HUD, waves, VFX, input
├── WesternGameEntities.pde # Player, Bandit, bullets, loot, gore classes
├── SoundHelper.java        # WAV playback / music Clip (avoids Clip.open clash with Processing)
└── data/
    ├── ASSETS_README.txt   # Asset inventory and texture how-to
    ├── progression.txt     # Auto-created: highScore, totalKills (optional manual edit)
    ├── textures/           # JPG / PNG textures
    └── sounds/             # WAV SFX and optional music loop
```

- **`worldX` / `worldZ`**: Scale legacy **900×620** layout coordinates to the larger arena.
- **`sceneColliders`**: Circular / axis-aligned collision summaries for the player and bandits (defined in the main sketch).

---

## Persistent progression

File: **`data/progression.txt`**

- `highScore=...` — best score across runs.
- `totalKills=...` — cumulative kills (updated when a run ends; see **`persistRunIfEnded`** in the sketch).

Pressing **Q** to quit or finishing a run writes this file. Deleting **`progression.txt`** resets stats (it will be recreated on next launch).

---

## Troubleshooting

| Issue | What to try |
|--------|-------------|
| `fullScreen() cannot be used here` | Ensure **`fullScreen`** / **`size`** live only in **`settings()`** (this project already does). |
| “Display 3 not available” | Set Processing **Preferences → Run Sketches on Display** to **1**, or change the display index in **`settings()`**. |
| No sound | Add WAVs under **`data/sounds/`**; match names in **`ASSETS_README.txt`**. |
| Flat / procedural ground | Expected without textures; add images under **`data/textures/`**. |
| Loot always the same type | Never reset global **`random()`** with **`randomSeed()`** every frame; this sketch uses **`noise()`** for ambient dust. |

---

## Other files

- **`SEN3301_25_26_Spring_SemesterProject.pdf`**: Course / brief PDF (submission requirements, if applicable).
- **`LICENSE`**: Repository license (if present).

---

## License

The repository **`LICENSE`** file applies when present; otherwise follow your institution’s policy.

---

*This README reflects the current **`sketch_260503a`** codebase; update tables here if you rebalance weapons, waves, or timers.*
