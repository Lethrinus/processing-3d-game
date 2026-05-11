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
  sounds/
    gun_player.wav
    gun_enemy.wav
    hit_player.wav
    hit_enemy.wav
    reload.wav
    wave_clear.wav
    win.wav
    lose.wav
    music_loop.wav       (optional loop)

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

4) textures/sky_stars.png (optional)
   - Dark sky + stars; if missing, starfield is drawn procedurally.

--------------------------------------------------------------------------------
AUDIO — format and tips
--------------------------------------------------------------------------------
Format: WAV (PCM), 44.1 kHz, mono or stereo — no extra libraries.
Keep clips short (gun 0.1–0.4 s, hits 0.1–0.2 s) for memory.

- gun_player.wav   : revolver crack (short, sharp)
- gun_enemy.wav    : thinner / distant shot
- hit_player.wav   : thud or impact
- hit_enemy.wav    : body hit
- reload.wav       : magazine / lever
- wave_clear.wav   : short fanfare
- win.wav          : win sting (1–2 s)
- lose.wav         : low defeat tone
- music_loop.wav   : western ambient (optional, 30–60 s loop)

Free examples: freesound.org (check license), OpenGameArt, Kenney.nl (CC0).

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
