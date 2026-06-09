# A Man with No Name — Game Rules

SEN3301 semester project documentation (Upload #2 / #3).

## Objective

Survive waves of bandits in a 3D western arena. Protect your score and remaining time; win by clearing all story waves or lose when time runs out or your health reaches zero.

## Game Modes


| Mode        | Description                                                                               |
| ----------- | ----------------------------------------------------------------------------------------- |
| **Story**   | 9 waves. Shotgun unlocks on wave 3; Repeater on wave 6. Clear wave 9 to win.              |
| **Endless** | All weapons unlocked from the start. Unlimited waves; compete on score and survival time. |


Select a mode on the title screen, then click to continue.

## Controls


| Input                  | Action                                        |
| ---------------------- | --------------------------------------------- |
| **W A S D**            | Move                                          |
| **Left mouse (LMB)**   | Shoot (toward the ground aim marker)          |
| **1 / 2 / 3**          | Weapon: Revolver / Shotgun / Repeater         |
| **Shift**              | Sprint (uses stamina bar)                     |
| **R**                  | Reload (or restart after game over)           |
| **Right mouse + drag** | Rotate camera                                 |
| **Mouse wheel**        | Zoom                                          |
| **ESC**                | Pause / resume                                |
| **SPACE**              | Skip wave break                               |
| **H**                  | Controls overlay (in-game)                    |
| **Q**                  | Quit run                                      |
| **T**                  | *(debug)* Instantly complete the current wave |


## Scoring

- **Kill:** `100 × current_wave + 15` points
- **Wave clear bonus:** `50 × current_wave` points
- High score is saved in `data/progression.txt` as `highScore`.

## Time Limit

- Starting time: **240 seconds**
- Each completed wave break: **+18 seconds** bonus
- When time reaches **0** → **TIME OVER** (loss)
- Remaining time is shown on the HUD.

## Weapons


| Slot | Weapon   | Story unlock |
| ---- | -------- | ------------ |
| 1    | Revolver | From start   |
| 2    | Shotgun  | Wave 3       |
| 3    | Repeater | Wave 6       |


Press **R** to reload when empty. Pick up ground loot for health or ammo.

## Waves

1. Short **spawn preview markers** appear before each wave.
2. Enemies **spawn gradually** (not all at once).
3. When all enemies are defeated, an **intermission** starts (default 8 s); press SPACE to skip.
4. In Story mode, finishing wave 9 shows **YOU WIN**.

## Win / Lose Conditions


| Condition             | Result        |
| --------------------- | ------------- |
| Story wave 9 cleared  | **YOU WIN**   |
| Health reaches 0      | **YOU LOST**  |
| Time reaches 0        | **TIME OVER** |
| **Q** pressed         | **QUIT**      |
| **R** after game over | New run       |


## Enemies (Bandits)

- Pathfind with A* around buildings and obstacles.
- Shoot or melee depending on distance.
- Speed and health scale with wave number (and further in Endless mode).

## Settings

Title → **SETTINGS**: SFX / music volume and fullscreen toggle. Values are saved to `progression.txt`.

## Technical Notes (SEN3301)

- 3D scene: P3D renderer; texture mapping on cylinders (barrels, cacti) and cones (fence caps).
- Camera: mouse rotate and wheel zoom.
- Score and time tracked continuously on the HUD.
- Code uses OOP structure: `GameSession`, entity classes, separate renderers and managers (see root `README.md`).