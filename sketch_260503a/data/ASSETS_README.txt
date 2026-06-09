================================================================================
SEN3301 Western 3D — Asset files
================================================================================
Place everything under this sketch's data folder. Missing optional paths use
procedural placeholder textures in AssetLoader.

--------------------------------------------------------------------------------
FOLDER LAYOUT
--------------------------------------------------------------------------------
data/
  fonts/
    RioGrande.ttf
    Sancreek-Regular.ttf
  textures/
    barrel_wood.jpg
    ground_dirt.jpg
    cactus.png
    wood1.jpg, wood2.jpg, wood3.jpg
    fence.jpg
    sky_cubemap/cubemap.png
  controls/
    keyboard_*.png, mouse_*.png
  ui/
    western_bg.png
    hat.png
    revolver.png, tumbleweed.png
  sounds/
    gun_player.wav
    enemy_gunshot.wav
    shotgun-firing.wav
    gun_reload.wav
    shotgun-reload-sfx.wav
    health_pickup.wav
    bullet_pickup.wav
    wave_clear.wav
    ui_click.wav
    western_soundtrack.wav  — menu loop
    ingame_theme.wav        — in-game loop

--------------------------------------------------------------------------------
TEXTURE MAPPING (course requirement)
--------------------------------------------------------------------------------
- Cylinder: barrels and cacti (barrel_wood, cactus).
- Cone: fence post caps (procedural rust if no roof texture file).
- Ground: tiled ground_dirt on the arena plane.

Load in AssetLoader.loadTextureAssets(); draw via SceneRenderer helpers.

--------------------------------------------------------------------------------
AUDIO
--------------------------------------------------------------------------------
Format: WAV (PCM). AudioManager plays via SoundHelper.java.

Menu music: western_soundtrack.wav
In-game music: ingame_theme.wav (starts when a run begins)

Do NOT call randomSeed() every frame in draw loops — it breaks gameplay RNG.

--------------------------------------------------------------------------------
SEE ALSO
--------------------------------------------------------------------------------
ASSET_LIST.md — full checklist
README.md (project root) — run instructions and SEN3301 compliance
