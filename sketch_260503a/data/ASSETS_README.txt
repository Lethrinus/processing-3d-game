================================================================================
SEN3301 Western 3D — Required image and audio files
================================================================================
Place everything under this sketch’s `data` folder (Processing loads it
automatically). If files are missing, the game still runs (procedural placeholder
textures are generated).

--------------------------------------------------------------------------------
FOLDER LAYOUT
--------------------------------------------------------------------------------
data/
  textures/
    barrel_wood.jpg      (or .png)
    roof_rust.jpg
    ground_dirt.jpg      (optional; procedural noise if absent)
    sky_stars.png        (optional; black background still OK for specs)
  ui/                    (optional — button images for HUD / menu)
    btn_controls.png     (~108×30, normal)
    btn_controls_hot.png (optional hover state)
    western_bg.png       (title + controls fullscreen background)
    hat_cowboy.png       (tilted hat on title text — transparent PNG)
    hat_pixel.png        (alternate name for hat sprite)
    hat.png              (fallback name)
  sounds/
    gun_player.wav / gun_player.mp3
    gun_reload.mp3 / reload.wav
    gun_enemy.wav
    hit_player.wav
    hit_enemy.wav
    wave_clear.wav
    win.wav
    lose.wav
    western_soundtrack.mp3   (title + controls menu loop)
    music_loop.wav           (optional in-game loop)

--------------------------------------------------------------------------------
IMAGES — suggested use
--------------------------------------------------------------------------------
1) textures/barrel_wood.jpg
   - Side wrap for vertical barrel cylinder.
   - Suggestion: 512x1024 or 1024x1024 wood / barrel (seamless if possible).
   - Sources: textures.com, ambientCG, Poly Haven (CC0), OpenGameArt.

2) textures/roof_rust.jpg
   - Rusty metal / shingles for cone fence caps.
   - Suggestion: 512x512 tileable rust or sheet metal.

3) textures/ground_dirt.jpg (optional)
   - Ground plane. Suggestion: 1024x1024 desert / dirt seamless.
   - If missing: short noise pattern is generated in code.

4) ui/western_bg.png
   - Full-screen menu background (title + controls).

--------------------------------------------------------------------------------
AUDIO — format and tips
--------------------------------------------------------------------------------
Format: WAV (PCM) or MP3. MP3 needs code/jlayer-1.0.1.jar (included in sketch).
Keep clips short (gun 0.1–0.4 s, hits 0.1–0.2 s) for memory.

- gun_player.wav / gun_player.mp3 : revolver crack (short, sharp)
- gun_reload.mp3 / reload.wav     : magazine / lever
- western_soundtrack.mp3          : menu music (loops on title + controls)
- gun_enemy.wav    : thinner / distant shot
- hit_player.wav   : thud or impact
- hit_enemy.wav    : body hit
- wave_clear.wav   : short fanfare
- win.wav          : win sting (1–2 s)
- lose.wav         : low defeat tone
- music_loop.wav   : western ambient (optional, 30–60 s loop)

Free examples: freesound.org (check license), OpenGameArt, Kenney.nl (CC0).

--------------------------------------------------------------------------------
OPTIONAL UI BUTTON IMAGES
--------------------------------------------------------------------------------
Place PNGs under data/ui/. If btn_controls.png exists, the in-game CONTROLS
button uses the image instead of a drawn rectangle. Hover uses btn_controls_hot.png
when provided.

Suggested size: about 108×30 px (or 2× for retina — Processing scales to fit).

Menu hats: use a side-view or 3/4 cowboy hat PNG with transparent background
(32–128 px pixel art works well). The game drifts several copies across the
title and controls screens. See also ASSET_LIST_TR.md for a full file checklist.

You can add more images later (title logo, per-control icons) and load them
with tryLoadImage("ui/your_file.png") the same way as textures.

--------------------------------------------------------------------------------
HOW TO ADD OR CHANGE TEXTURES (Processing)
--------------------------------------------------------------------------------
1) Put image files under this sketch folder:
      sketch_260503a/data/textures/your_name.jpg   (or .png)

2) Load once in setup — see loadTextureAssets() in sketch_260503a.pde:
      PImage texMine = tryLoadImage("textures/your_name.jpg");

   tryLoadImage returns null if the file is missing (game keeps running).

3) Draw with texture mapping in P3D:
   - Before filling a shape: textureMode(NORMAL); then vertex(u,v, ...) with u,v in 0..1
   - Or wrap an existing helper: drawTexturedCylinder(texMine, radius, height, detail, false);

4) Tips:
   - Prefer seamless/tileable images for cylinders and ground so seams are hidden.
   - Size: 512x512 or 1024x1024 is enough; huge images waste memory.
   - PNG with alpha works if you need transparency (not used on cylinders here).

5) Loot randomness: do NOT call randomSeed() every frame inside draw loops —
   it breaks random() for gameplay (e.g. loot drops). Ambient effects should use
   noise() or deterministic animation instead.

--------------------------------------------------------------------------------
NOTE
--------------------------------------------------------------------------------
The play screen uses background(0). Cylinder (barrel) and cone (fence cap)
geometry use texture mapping as required by the course brief.
