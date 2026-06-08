/*
Ozan Halis Demiralp -2203046
Yavuzhan Özbek 2201927

##RULES##
   1) WASD — move
   2) Left click — shoot (aim with mouse)
   3) Right drag — camera
   4) Mouse wheel — zoom
   5) R — reload; 1/2/3 — weapons; Shift — sprint
   6) During wave break [SPACE] — skip wait
   7) Clear all waves or outlast the timer
   8) Q — quit (progress saves)
   Assets: data/ASSETS_README.txt
*/

import java.util.ArrayList;
import java.util.Locale;
import java.io.File;
import javax.sound.sampled.Clip;

/** Rio Grande — titles, banners, ALL CAPS labels. */
PFont uiFontHud;
/** Mixed-case UI — data/fonts/Sancreek-Regular.ttf (small text). */
PFont uiFontBody;

/** Resolves a font under data/fonts/ with legacy data/ root fallback. */
String resolveFontPath(String fileName) {
  String inFonts = "fonts/" + fileName;
  if (new File(dataPath(inFonts)).exists()) return inFonts;
  if (new File(dataPath(fileName)).exists()) return fileName;
  return null;
}

PFont createWesternHudFont() {
  String path = resolveFontPath("RioGrande.ttf");
  if (path != null) return createFont(path, 72, true);
  return createFont("Serif", 72, true);
}

PFont createUiBodyFont() {
  String[] dataFiles = {
    "Sancreek-Regular.ttf", "sancreek-regular.ttf",
    "Sancreek-Regular.otf", "sancreek-regular.otf",
    "ui-body.ttf", "UI-Body.ttf"
  };
  for (String name : dataFiles) {
    String path = resolveFontPath(name);
    if (path != null) return createFont(path, 14, true);
  }
  String[] preferred = {"Arial", "Helvetica Neue", "Helvetica", "Verdana", "SansSerif", "Dialog"};
  String[] avail = PFont.list();
  for (String w : preferred) {
    for (String f : avail) {
      if (f.equalsIgnoreCase(w)) return createFont(f, 48, true);
    }
  }
  return createFont("SansSerif", 48, true);
}

void textFontDisplay() {
  textFont(uiFontHud);
}

void textFontBody() {
  textFont(uiFontBody);
}

int sceneStartMs;
/** Arena size (scaled from legacy 900×620 coordinates). */
float arenaHalfW = 1120;
float arenaHalfH = 800;
final float LEGACY_ARENA_W = 900;
final float LEGACY_ARENA_H = 620;

float worldX(float legacyX) {
  return legacyX * arenaHalfW / LEGACY_ARENA_W;
}

float worldZ(float legacyZ) {
  return legacyZ * arenaHalfH / LEGACY_ARENA_H;
}

Player player;
ArrayList<Bandit> bandits;
ArrayList<Bullet> bullets;
ArrayList<EnemyBullet> enemyBullets;
ArrayList<MuzzleFlash> muzzleFlashes;
ArrayList<HitSpark> hitSparks;
ArrayList<LootPickup> lootPickups;
ArrayList<PickupPlusFx> pickupPlusFx = new ArrayList<PickupPlusFx>();
ArrayList<GibChunk> gibChunks = new ArrayList<GibChunk>();
ArrayList<BloodParticle> bloodParticles = new ArrayList<BloodParticle>();
ArrayList<SprintTrailPuff> sprintTrailPuffs = new ArrayList<SprintTrailPuff>();
/** Built each frame in 3D (screenX/Y): sx, sy, diam, alpha */
ArrayList<float[]> sprintTrailScreenDots = new ArrayList<float[]>();
float sprintTrailEmitAccum = 0;
ArrayList<AmmoGainFx> ammoGainFx = new ArrayList<AmmoGainFx>();
boolean playerGoreSpawned = false;
boolean sprintHeld = false;
float hurtShakePx = 0;
float hurtRing = 0;
float lastHp = 100;
int progressionHighScore = 0;
int progressionTotalKills = 0;
boolean runStatsPersisted = false;

int kills;
int score;
float gameDurationSec = 240.0;
/** Bonus time earned between waves. */
float extraTimeSec = 0;

final int WAVE_STATE_FIGHT = 0;
final int WAVE_STATE_BREAK = 1;
int waveState = WAVE_STATE_FIGHT;
float waveBreakTimer = 0;
final float WAVE_BREAK_DURATION = 8.0;
int currentWave = 1;
int maxWaves = 9;

final int GAME_MODE_STORY = 0;
final int GAME_MODE_ENDLESS = 1;
final int STORY_MAX_WAVES = 9;
final int UNLOCK_SHOTGUN_WAVE = 3;
final int UNLOCK_REPEATER_WAVE = 6;

final int BANDIT_WPN_REVOLVER = 0;
final int BANDIT_WPN_SHOTGUN = 1;
final int BANDIT_WPN_REPEATER = 2;

int selectedGameMode = GAME_MODE_STORY;
boolean endlessMode = false;
boolean gamePaused = false;
long gamePauseAccumMs = 0;
int gamePauseStartMs = 0;
boolean menuMusicStarted = false;

float storyBtnX, storyBtnY, storyBtnW = 300, storyBtnH = 50;
float endlessBtnX, endlessBtnY;
float pauseContinueBtnX, pauseContinueBtnY, pauseMenuBtnX, pauseMenuBtnY;
final float pauseBtnW = 260, pauseBtnH = 46;

float weaponUnlockBannerTimer = 0;
String weaponUnlockBannerText = "";

/** Staggered wave spawns — one bandit every STAGGER_SPAWN_INTERVAL sec. */
final float STAGGER_SPAWN_INTERVAL = 0.82f;
ArrayList<PendingBandit> pendingBanditSpawns = new ArrayList<PendingBandit>();
boolean waveSpawning = false;
float staggerSpawnTimer = 0;

/** Spawn önizlemesi — düşmanlar gelmeden önce işaretler. */
final float WAVE_PREVIEW_DURATION = 2.85f;
final float WAVE_BANNER_DURATION = 3.75f;
float wavePreviewTimer = 0;
float waveBannerTimer = 0;
int waveBannerNumber = 1;
ArrayList<PVector> previewSpawnMarkers = new ArrayList<PVector>();

ArrayList<ShellCasing> shellCasings = new ArrayList<ShellCasing>();
float camShakeAmp = 0;
float camShakePx = 0;

/** Coarse grid A* for bandit pathfinding around buildings. */
final float PATH_CELL = 100f;
int pathCols, pathRows;
boolean[] pathBlocked;
int[] pathDirDx = {1, -1, 0, 0, 1, 1, -1, -1};
int[] pathDirDz = {0, 0, 1, -1, 1, -1, 1, -1};
float[] pathDirCost = {1, 1, 1, 1, 1.414f, 1.414f, 1.414f, 1.414f};

PImage texBarrel, texRoof, texGround, texCactus, texSky;
PImage texBuildingWood, texBuildingRoof;
PImage texWood1, texWood2, texWood3, texFence;
/** Cubemap faces: 0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z (OpenGL / Poly Haven order). */
PImage[] skyCubemap = new PImage[6];
boolean skyCubemapReady;
/** Optional UI sprites in data/ui/ — game draws text buttons if missing. */
PImage uiBtnControls, uiBtnControlsHot;
/** Controls overlay — key/mouse icons in data/controls/ (or data/ui/controls/). */
ControlPanelRow[] controlPanelRows;
final int CTRL_LAYOUT_ROW = 0;
final int CTRL_LAYOUT_WASD = 1;
final int CTRL_GRID_COLS = 4;

class ControlPanelRow {
  String title;
  /** Drawn with Sancreek (uiFontBody). */
  String[] keyLabels;
  /** mouse_*.png only */
  PImage[] mouseIcons;
  int layout = CTRL_LAYOUT_ROW;
}
/** Menu UI — data/ui/ */
PImage uiWesternBg;
Clip musicClip;

/** Varsayılan ses (ayarlar menüsünden değişir; progression.txt’e kaydedilir). */
final float GAME_SFX_VOLUME_DEFAULT = 0.22f;
final float GAME_MUSIC_VOLUME_DEFAULT = 0.16f;
float settingsSfxVol = GAME_SFX_VOLUME_DEFAULT;
float settingsMusicVol = GAME_MUSIC_VOLUME_DEFAULT;
final int WINDOWED_W = 1280;
final int WINDOWED_H = 720;
boolean settingsFullscreen = true;
/** -1 none, 0 windowed resize, 1 borderless fill — next frame (no native setFullscreen). */
int pendingDisplayMode = -1;
float settingsDisplayBtnX, settingsDisplayBtnY, settingsDisplayBtnW = 300, settingsDisplayBtnH = 40;

/** WESTERN BOUNTY — harflerden geçen dalga */
final int TITLE_FONT_SIZE = 62;
final float TITLE_WAVE_SPEED = 0.0015f;
final float TITLE_WAVE_SPACING = 0.4f;
final float TITLE_WAVE_AMP = 6f;

final int MENU_SUBTITLE_SIZE = 24;
final int MENU_SCORE_SIZE = 20;
final int MENU_CREDITS_SIZE = 16;
final int MENU_CLICK_SIZE = 28;

/** Click to play — sadece alpha yanıp sönme (boyut sabit) */
final float CLICK_BLINK_SPEED = 0.004f;
final int CLICK_ALPHA_MIN = 100;
final int CLICK_ALPHA_MAX = 255;

/** Player feet in screen space (for reload bar). */
float playerScreenFootX, playerScreenFootY;
/** ~Chest height — sprint bar anchored above character in screen space. */
float playerSprintHudX, playerSprintHudY;
/** 0..1: visible while Shift held, fades out after release. */
float sprintBarFocus = 0;

final int FLOW_TITLE = 0;
final int FLOW_CONTROLS = 1;
final int FLOW_PLAY = 2;
final int FLOW_SETTINGS = 3;
int gameFlow = FLOW_TITLE;
float settingsBtnX, settingsBtnY, settingsBtnW = 200, settingsBtnH = 44;
float settingsSfxBarY, settingsMusicBarY, settingsBarW = 320, settingsBarH = 22;
boolean settingsDraggingSfx = false;
boolean settingsDraggingMusic = false;
boolean showControlsOverlay = false;
final float HUD_LEFT_PANEL_W = 310;
float controlsBtnX = 340, controlsBtnY = 12, controlsBtnW = 96, controlsBtnH = 26;

String gameStateText = "";
boolean finished = false;

boolean moveW, moveA, moveS, moveD;
boolean shooting = false;

float camYaw = -PI / 6.0;
/** Lower pitch = less top-down “floating platform” look (was 1.05). */
float camPitch = 0.82f;
float camDist = 720;
/** World Y of walkable floor (Processing: +Y is down). */
final float GROUND_Y = 0;
/** Character meshes are authored with feet ~1 unit below their root; pull root up so feet sit on GROUND_Y. */
final float CHARACTER_GROUND_OFFSET = -1f;
/** Cubemap face images: UV height where the horizon line sits (0=top, 1=bottom of face). */
final float SKYBOX_HORIZON_UV = 0.54f;
float camDistMin = 360;
float camDistMax = 1750;

float camPosX, camPosY, camPosZ;
float camTargetX, camTargetY, camTargetZ;
PVector camForward = new PVector();
PVector camRight = new PVector();
PVector camUp = new PVector();

PVector aimPoint = new PVector(0, 0, 0);

/** Axis-aligned colliders in XZ: minX, maxX, minZ, maxZ (world space, y ignored). */
ArrayList<float[]> sceneColliders = new ArrayList<float[]>();

void settings() {
  if (readFullscreenPref()) fullScreen(P3D, 1);
  else size(WINDOWED_W, WINDOWED_H, P3D);
}

boolean readFullscreenPref() {
  String[] raw = loadStrings("progression.txt");
  if (raw == null) return true;
  for (int i = 0; i < raw.length; i++) {
    if (raw[i] == null) continue;
    String line = raw[i].trim();
    int eq = line.indexOf('=');
    if (eq < 1) continue;
    if (!line.substring(0, eq).trim().equals("fullscreen")) continue;
    String v = line.substring(eq + 1).trim().toLowerCase(Locale.ROOT);
    return v.equals("1") || v.equals("true") || v.equals("yes");
  }
  return true;
}

void setup() {
  sceneStartMs = millis();
  uiFontHud = createWesternHudFont();
  uiFontBody = createUiBodyFont();
  textFontBody();
  sphereDetail(18);
  buildSceneColliders();
  loadTextureAssets();
  loadUiAssets();
  loadControlPanelAssets();
  loadProgression();
  applyAudioVolumes();
  surface.setResizable(true);
  syncDisplayModeToPreference();
  gameFlow = FLOW_TITLE;
}

void syncDisplayModeToPreference() {
  if (settingsFullscreen) {
    if (width < displayWidth - 8 || height < displayHeight - 8) pendingDisplayMode = 1;
  } else if (width > WINDOWED_W + 8 || height > WINDOWED_H + 8) {
    pendingDisplayMode = 0;
  }
}

PImage tryLoadImage(String relPath) {
  File f = new File(dataPath(relPath));
  if (!f.exists()) return null;
  PImage img = loadImage(relPath);
  if (img == null || img.width < 2) return null;
  return img;
}

PImage makeNoiseGroundTexture() {
  PImage g = createImage(128, 128, ARGB);
  g.loadPixels();
  for (int y = 0; y < g.height; y++) {
    for (int x = 0; x < g.width; x++) {
      float n = noise(x * 0.12f, y * 0.12f);
      g.pixels[y * g.width + x] = color(120 + n * 55, 80 + n * 40, 45 + n * 35);
    }
  }
  g.updatePixels();
  return g;
}

PImage makeWoodStripes() {
  PImage g = createImage(64, 128, ARGB);
  g.loadPixels();
  for (int y = 0; y < g.height; y++) {
    for (int x = 0; x < g.width; x++) {
      float n = noise(x * 0.2f, y * 0.08f);
      g.pixels[y * g.width + x] = color(95 + n * 50, 58 + n * 35, 32 + n * 25);
    }
  }
  g.updatePixels();
  return g;
}

PImage makeRustTexture() {
  PImage g = createImage(64, 64, ARGB);
  g.loadPixels();
  for (int y = 0; y < g.height; y++) {
    for (int x = 0; x < g.width; x++) {
      float n = noise(x * 0.25f, y * 0.25f);
      g.pixels[y * g.width + x] = color(110 + n * 60, 55 + n * 30, 35 + n * 25);
    }
  }
  g.updatePixels();
  return g;
}

void loadTextureAssets() {
  texBarrel = tryLoadImage("textures/barrel_wood.jpg");
  if (texBarrel == null) texBarrel = tryLoadImage("textures/barrel_wood.png");
  if (texBarrel == null) texBarrel = makeWoodStripes();

  texRoof = tryLoadImage("textures/roof_rust.jpg");
  if (texRoof == null) texRoof = tryLoadImage("textures/roof_rust.png");
  if (texRoof == null) texRoof = makeRustTexture();

  texGround = tryLoadImage("textures/ground_dirt.jpg");
  if (texGround == null) texGround = tryLoadImage("textures/ground_dirt.png");
  if (texGround == null) texGround = makeNoiseGroundTexture();

  texCactus = tryLoadImage("textures/cactus.png");

  texWood1 = tryLoadImage("textures/wood1.jpg");
  if (texWood1 == null) texWood1 = tryLoadImage("textures/wood1.png");
  texWood2 = tryLoadImage("textures/wood2.jpg");
  if (texWood2 == null) texWood2 = tryLoadImage("textures/wood2.png");
  texWood3 = tryLoadImage("textures/wood3.jpg");
  if (texWood3 == null) texWood3 = tryLoadImage("textures/wood3.png");
  texFence = tryLoadImage("textures/fence.jpg");
  if (texFence == null) texFence = tryLoadImage("textures/fence.png");

  texBuildingWood = tryLoadImage("textures/building_wood.jpg");
  if (texBuildingWood == null) texBuildingWood = tryLoadImage("textures/building_wood.png");
  if (texBuildingWood == null) texBuildingWood = texWood1;

  texBuildingRoof = tryLoadImage("textures/building_roof.jpg");
  if (texBuildingRoof == null) texBuildingRoof = tryLoadImage("textures/building_roof.png");
  if (texBuildingRoof == null) texBuildingRoof = texRoof;

  texSky = tryLoadImage("textures/sky_horizon.jpg");
  if (texSky == null) texSky = tryLoadImage("textures/sky_horizon.png");
  if (texSky == null) texSky = tryLoadImage("textures/sky_panorama.jpg");
  if (texSky == null) texSky = tryLoadImage("textures/sky_panorama.png");
  if (texSky == null) texSky = tryLoadImage("textures/sky_stars.png");

  loadSkyCubemapAssets();
}

void loadSkyCubemapAssets() {
  skyCubemapReady = false;
  for (int i = 0; i < 6; i++) skyCubemap[i] = null;

  String[][] faceNames = {
    {"px", "posx"},
    {"nx", "negx"},
    {"py", "posy"},
    {"ny", "negy"},
    {"pz", "posz"},
    {"nz", "negz"}
  };
  boolean separateOk = true;
  for (int i = 0; i < 6; i++) {
    for (int j = 0; j < faceNames[i].length; j++) {
      skyCubemap[i] = tryLoadImage("textures/sky_cubemap/" + faceNames[i][j] + ".jpg");
      if (skyCubemap[i] == null) {
        skyCubemap[i] = tryLoadImage("textures/sky_cubemap/" + faceNames[i][j] + ".png");
      }
      if (skyCubemap[i] != null) break;
    }
    if (skyCubemap[i] == null) separateOk = false;
  }
  if (separateOk) {
    skyCubemapReady = true;
    return;
  }
  for (int i = 0; i < 6; i++) skyCubemap[i] = null;

  PImage cross = tryLoadImage("textures/sky_cubemap/cubemap.png");
  if (cross == null) cross = tryLoadImage("textures/sky_cubemap/sky_cubemap.png");
  if (cross == null) cross = tryLoadImage("textures/sky_cubemap.png");
  if (cross != null) skyCubemapReady = loadCubemapFromCrossLayout(cross);
}

/**
 * Horizontal-cross cubemap sheet (4 wide x 3 tall):
 *       [ny]
 * [nx]  [pz]  [px]  [nz]
 *       [py]
 */
boolean loadCubemapFromCrossLayout(PImage cross) {
  int face = cross.width / 4;
  if (face < 2 || face * 3 != cross.height) return false;

  int[][] colsRows = {
    {2, 1}, // 0 +X px
    {0, 1}, // 1 -X nx
    {1, 2}, // 2 +Y py (down)
    {1, 0}, // 3 -Y ny (up)
    {1, 1}, // 4 +Z pz (front)
    {3, 1}  // 5 -Z nz (back)
  };
  for (int i = 0; i < 6; i++) {
    int col = colsRows[i][0];
    int row = colsRows[i][1];
    skyCubemap[i] = cross.get(col * face, row * face, face, face);
    if (skyCubemap[i] == null) return false;
  }
  return true;
}

boolean hasCustomSky() {
  return skyCubemapReady || texSky != null;
}

void loadUiAssets() {
  uiWesternBg = tryLoadImage("ui/western_bg.png");
  uiBtnControls = tryLoadImage("ui/btn_controls.png");
  uiBtnControlsHot = tryLoadImage("ui/btn_controls_hot.png");
  if (uiBtnControlsHot == null) uiBtnControlsHot = uiBtnControls;
}

PImage tryLoadControlMouseIcon(String fileName) {
  PImage img = tryLoadImage("controls/" + fileName);
  if (img != null) return img;
  return tryLoadImage("ui/controls/" + fileName);
}

PImage[] loadControlMouseIcons(String[] files) {
  if (files == null || files.length == 0) return new PImage[0];
  ArrayList<PImage> list = new ArrayList<PImage>();
  for (String f : files) {
    if (f == null || f.length() == 0) continue;
    PImage img = tryLoadControlMouseIcon(f);
    if (img != null) list.add(img);
  }
  return list.toArray(new PImage[0]);
}

void loadControlPanelAssets() {
  Object[][] defs = {
    {CTRL_LAYOUT_WASD, "Move", new String[] {"W", "A", "S", "D"}, null},
    {CTRL_LAYOUT_ROW, "Shoot", null, new String[] {"mouse_left.png"}},
    {CTRL_LAYOUT_ROW, "Camera", null, new String[] {"mouse_right.png"}},
    {CTRL_LAYOUT_ROW, "Zoom", null, new String[] {"mouse_scroll.png"}},
    {CTRL_LAYOUT_ROW, "Weapons", new String[] {"1", "2", "3"}, null},
    {CTRL_LAYOUT_ROW, "Reload", new String[] {"R"}, null},
    {CTRL_LAYOUT_ROW, "Sprint", new String[] {"Shift"}, null},
    {CTRL_LAYOUT_ROW, "Wave skip", new String[] {"Space"}, null},
    {CTRL_LAYOUT_ROW, "Pause", new String[] {"Esc"}, null},
    {CTRL_LAYOUT_ROW, "Test", new String[] {"T"}, null},
    {CTRL_LAYOUT_ROW, "Quit", new String[] {"Q"}, null}
  };
  controlPanelRows = new ControlPanelRow[defs.length];
  for (int i = 0; i < defs.length; i++) {
    ControlPanelRow row = new ControlPanelRow();
    row.layout = (Integer) defs[i][0];
    row.title = (String) defs[i][1];
    row.keyLabels = (String[]) defs[i][2];
    row.mouseIcons = loadControlMouseIcons((String[]) defs[i][3]);
    controlPanelRows[i] = row;
  }
}

float controlKeyWidth(String label, float baseSize) {
  if (label == null || label.length() == 0) return baseSize;
  if (label.length() == 1) return baseSize;
  if (label.equals("Shift")) return baseSize * 1.75f;
  if (label.equals("Space")) return baseSize * 2.35f;
  if (label.equals("Esc")) return baseSize * 1.2f;
  return baseSize * max(1.15f, 0.45f * label.length() + 0.55f);
}

float controlCellIconBlockW(ControlPanelRow row, float keySize, float mouseSize, float iconGap) {
  if (row.layout == CTRL_LAYOUT_WASD && row.keyLabels != null && row.keyLabels.length >= 4) {
    return keySize * 3 + iconGap * 2;
  }
  if (row.keyLabels != null && row.keyLabels.length > 0) {
    float w = 0;
    for (int i = 0; i < row.keyLabels.length; i++) {
      w += controlKeyWidth(row.keyLabels[i], keySize);
      if (i > 0) w += iconGap;
    }
    return w;
  }
  if (row.mouseIcons != null && row.mouseIcons.length > 0) {
    return row.mouseIcons.length * mouseSize + max(0, row.mouseIcons.length - 1) * iconGap;
  }
  return 0;
}

float controlCellIconBlockH(ControlPanelRow row, float keySize, float mouseSize, float iconGap) {
  if (row.layout == CTRL_LAYOUT_WASD && row.keyLabels != null && row.keyLabels.length >= 4) {
    return keySize * 2 + iconGap;
  }
  if (row.mouseIcons != null && row.mouseIcons.length > 0) return mouseSize;
  return keySize;
}

/** Draw a UI button image or a simple western-style fallback rect. */
void drawUiButton(PImage img, PImage imgHot, float x, float y, float w, float h, boolean hot) {
  rectMode(CORNER);
  PImage use = hot && imgHot != null ? imgHot : img;
  if (use != null) {
    imageMode(CORNER);
    image(use, x, y, w, h);
    imageMode(CORNER);
    return;
  }
  noStroke();
  fill(hot ? 72 : 48, 32, 18, 240);
  rect(x, y, w, h, 6);
  stroke(200, 155, 75, hot ? 255 : 200);
  strokeWeight(1.5);
  noFill();
  rect(x + 1, y + 1, w - 2, h - 2, 5);
  noStroke();
}

/** Tries each filename under data/sounds/ (WAV and MP3). */
void playSoundSafe(String... names) {
  if (SoundHelper.sfxVolume <= 0.0001f) return;
  for (String name : names) {
    File f = new File(dataPath("sounds/" + name));
    if (f.exists()) {
      SoundHelper.playSoundFile(f.getAbsolutePath(), SoundHelper.sfxVolume);
      return;
    }
  }
}

void playWavSafe(String name) {
  if (name.equals("gun_player.wav")) {
    playSoundSafe("gun_player.wav");
    return;
  }
  if (name.equals("reload.wav")) {
    playSoundSafe("gun_reload.wav", "reload.wav");
    return;
  }
  playSoundSafe(name);
}

/** Loot pickup — reload sesi değil; data/sounds/pickup.wav varsa onu çalar. */
void playPickupSound() {
  playSoundSafe("pickup.wav", "loot.wav");
}

void playUiClick() {
  playSoundSafe("ui_click.wav");
}

String firstSoundPath(String... names) {
  for (String name : names) {
    File f = new File(dataPath("sounds/" + name));
    if (f.exists()) return f.getAbsolutePath();
  }
  return null;
}

float sanitizeVolume(float v, float fallback) {
  if (Float.isNaN(v) || Float.isInfinite(v)) return fallback;
  return constrain(v, 0, 1);
}

/** progression.txt — locale bağımsız (nokta ondalık). */
float parseVolumeSetting(String v, float fallback) {
  if (v == null || v.length() == 0) return fallback;
  String s = v.trim();
  if (s.equalsIgnoreCase("nan") || s.equalsIgnoreCase("null")) return fallback;
  s = s.replace(',', '.');
  float f = parseFloat(s);
  return sanitizeVolume(f, fallback);
}

String formatVolumeFile(float v) {
  return String.format(Locale.US, "%.3f", sanitizeVolume(v, 0.22f));
}

void loadProgression() {
  progressionHighScore = 0;
  progressionTotalKills = 0;
  settingsSfxVol = GAME_SFX_VOLUME_DEFAULT;
  settingsMusicVol = GAME_MUSIC_VOLUME_DEFAULT;
  boolean repairVolumes = false;
  String[] raw = loadStrings("progression.txt");
  if (raw == null) return;
  for (int i = 0; i < raw.length; i++) {
    if (raw[i] == null) continue;
    String line = raw[i].trim();
    int eq = line.indexOf('=');
    if (eq < 1) continue;
    String k = line.substring(0, eq).trim();
    String v = line.substring(eq + 1).trim();
    if (k.equals("highScore")) progressionHighScore = max(0, parseInt(v));
    if (k.equals("totalKills")) progressionTotalKills = max(0, parseInt(v));
    if (k.equals("sfxVolume")) {
      if (v.equalsIgnoreCase("nan") || v.indexOf(',') >= 0) repairVolumes = true;
      settingsSfxVol = parseVolumeSetting(v, GAME_SFX_VOLUME_DEFAULT);
    }
    if (k.equals("musicVolume")) {
      if (v.equalsIgnoreCase("nan") || v.indexOf(',') >= 0) repairVolumes = true;
      settingsMusicVol = parseVolumeSetting(v, GAME_MUSIC_VOLUME_DEFAULT);
    }
    if (k.equals("fullscreen")) {
      String vl = v.toLowerCase(Locale.ROOT);
      settingsFullscreen = vl.equals("1") || vl.equals("true") || vl.equals("yes");
    }
  }
  settingsSfxVol = sanitizeVolume(settingsSfxVol, GAME_SFX_VOLUME_DEFAULT);
  settingsMusicVol = sanitizeVolume(settingsMusicVol, GAME_MUSIC_VOLUME_DEFAULT);
  if (repairVolumes) saveProgression();
}

void saveProgression() {
  settingsSfxVol = sanitizeVolume(settingsSfxVol, GAME_SFX_VOLUME_DEFAULT);
  settingsMusicVol = sanitizeVolume(settingsMusicVol, GAME_MUSIC_VOLUME_DEFAULT);
  saveStrings(dataPath("progression.txt"), new String[] {
    "highScore=" + progressionHighScore,
    "totalKills=" + progressionTotalKills,
    "sfxVolume=" + formatVolumeFile(settingsSfxVol),
    "musicVolume=" + formatVolumeFile(settingsMusicVol),
    "fullscreen=" + (settingsFullscreen ? "1" : "0")
  });
}

void centerSketchWindow() {
  surface.setLocation(max(0, (displayWidth - WINDOWED_W) / 2), max(0, (displayHeight - WINDOWED_H) / 2));
}

void processPendingDisplayMode() {
  if (pendingDisplayMode < 0) return;
  boolean wantFs = pendingDisplayMode == 1;
  pendingDisplayMode = -1;
  if (wantFs) {
    surface.setSize(displayWidth, displayHeight);
    surface.setLocation(0, 0);
  } else {
    surface.setSize(WINDOWED_W, WINDOWED_H);
    centerSketchWindow();
  }
}

void applyDisplayMode(boolean fullscreen) {
  settingsFullscreen = fullscreen;
  pendingDisplayMode = fullscreen ? 1 : 0;
  saveProgression();
}

boolean displayModeButtonHit(float mx, float my) {
  return mx >= settingsDisplayBtnX && mx <= settingsDisplayBtnX + settingsDisplayBtnW
    && my >= settingsDisplayBtnY && my <= settingsDisplayBtnY + settingsDisplayBtnH;
}

int lastSfxPreviewMs = 0;

void applyAudioVolumes() {
  settingsSfxVol = sanitizeVolume(settingsSfxVol, GAME_SFX_VOLUME_DEFAULT);
  settingsMusicVol = sanitizeVolume(settingsMusicVol, GAME_MUSIC_VOLUME_DEFAULT);
  SoundHelper.sfxVolume = settingsSfxVol;
  SoundHelper.musicVolume = settingsMusicVol;
  if (musicClip != null) {
    if (settingsMusicVol <= 0.0001f) stopMusic();
    else SoundHelper.setClipVolume(musicClip, settingsMusicVol);
  } else if (settingsMusicVol > 0.0001f && menuMusicStarted
      && (gameFlow == FLOW_TITLE || gameFlow == FLOW_CONTROLS || gameFlow == FLOW_SETTINGS)) {
    startMenuMusic();
  }
}

void ensureMenuMusic() {
  if (menuMusicStarted) return;
  menuMusicStarted = true;
  applyAudioVolumes();
  if (settingsMusicVol > 0.0001f
      && (gameFlow == FLOW_TITLE || gameFlow == FLOW_CONTROLS || gameFlow == FLOW_SETTINGS)) {
    startMenuMusic();
  }
}

void maybePreviewSfxVolume() {
  if (SoundHelper.sfxVolume <= 0.0001f) return;
  int now = millis();
  if (now - lastSfxPreviewMs < 140) return;
  lastSfxPreviewMs = now;
  playSoundSafe("pickup.wav", "gun_player.wav");
}

void persistRunIfEnded() {
  if (runStatsPersisted || !finished) return;
  runStatsPersisted = true;
  if (score > progressionHighScore) progressionHighScore = score;
  progressionTotalKills += kills;
  saveProgression();
}

void updateDamageFlash(float dt) {
  if (player != null && player.hp < lastHp) {
    float lost = max(0, lastHp - player.hp);
    hurtRing = min(1, hurtRing + 0.95 + lost * 0.012);
    hurtShakePx = min(18, hurtShakePx + 4.2 + lost * 0.06);
    addCamShake(3.5f + lost * 0.08f);
  }
  if (player != null) lastHp = player.hp;
  hurtShakePx *= exp(-dt * 11);
  hurtRing = max(0, hurtRing - dt * 2.85);
  updateCamShake(dt);
}

void addCamShake(float amp) {
  camShakeAmp = min(24, camShakeAmp + amp);
}

void updateCamShake(float dt) {
  camShakeAmp *= exp(-dt * 13.5);
  camShakePx = (random(-1, 1) + random(-1, 1)) * 0.5f * camShakeAmp;
}

void emitShotgunShells(PVector tip, float facing) {
  for (int i = 0; i < 2; i++) {
    shellCasings.add(new ShellCasing(tip, facing + random(-0.12f, 0.12f)));
  }
}

void updateWaveIntro(float dt) {
  if (waveBannerTimer > 0) waveBannerTimer -= dt;
  if (wavePreviewTimer <= 0) return;
  wavePreviewTimer -= dt;
  if (wavePreviewTimer <= 0) beginStaggeredSpawnsFromPending();
}

void beginStaggeredSpawnsFromPending() {
  if (pendingBanditSpawns.size() == 0) {
    waveSpawning = false;
    return;
  }
  PendingBandit first = pendingBanditSpawns.remove(0);
  bandits.add(new Bandit(first.x, first.z, first.outfit, first.spdMul, first.hpMul, first.wave, first.weaponType));
  waveSpawning = pendingBanditSpawns.size() > 0;
  staggerSpawnTimer = STAGGER_SPAWN_INTERVAL;
}

/** Spawn ground loot after a kill (called from sketch bullet loop only). */
void registerBanditLootDrop(float x, float z) {
  if (lootPickups == null) lootPickups = new ArrayList<LootPickup>();
  int lk = random(1) < 0.45 ? LootPickup.LOOT_HEALTH : LootPickup.LOOT_AMMO;
  lootPickups.add(new LootPickup(x + random(-6, 6), z + random(-6, 6), lk));
}

void spawnPickupPlusBurst(float sx, float sy, int kind) {
  int n = 12;
  for (int i = 0; i < n; i++) {
    pickupPlusFx.add(new PickupPlusFx(
      sx + random(-48, 48),
      sy + random(-38, 12),
      kind,
      random(-140, 140),
      random(54, 108)
    ));
  }
}

void updatePickupPlusFx(float dt) {
  for (int i = pickupPlusFx.size() - 1; i >= 0; i--) {
    PickupPlusFx p = pickupPlusFx.get(i);
    p.update(dt);
    if (p.dead()) pickupPlusFx.remove(i);
  }
}

void drawPickupPlusFx2D() {
  for (PickupPlusFx p : pickupPlusFx) p.draw2D();
}

void spawnAmmoGainFloat(float sx, float sy, int amount) {
  if (amount <= 0) return;
  ammoGainFx.add(new AmmoGainFx(sx, sy, "+" + amount));
}

void updateAmmoGainFx(float dt) {
  for (int i = ammoGainFx.size() - 1; i >= 0; i--) {
    AmmoGainFx a = ammoGainFx.get(i);
    a.update(dt);
    if (a.dead()) ammoGainFx.remove(i);
  }
}

void drawAmmoGainFx2D() {
  for (AmmoGainFx a : ammoGainFx) a.draw2D();
}

/** Green +N float when ammo loot is picked up. */
class AmmoGainFx {
  float sx, sy, age = 0;
  String label;
  float driftX;

  AmmoGainFx(float sx, float sy, String label) {
    this.sx = sx;
    this.sy = sy;
    this.label = label;
    this.driftX = random(-40, 40);
  }

  void update(float dt) {
    age += dt;
    sy -= dt * 88;
    sx += driftX * dt * 0.4;
    driftX *= exp(-dt * 2.2);
  }

  boolean dead() {
    return age > 1.08;
  }

  void draw2D() {
    float u = age / 1.08;
    float a = 255 * (1 - u * u);
    if (a < 5) return;
    pushStyle();
    blendMode(BLEND);
    float pulse = age < 0.14 ? (0.72 + 0.28 * sin(age * 55)) : 1;
    float ts = (34 + 12 * pulse) * (1 - u * 0.22);
    textAlign(CENTER, CENTER);
    textSize(ts);
    int core = color(70, 255, 130);
    fill(0, a * 0.6);
    text(label, sx + 2.5, sy + 2.5);
    fill(red(core), green(core), blue(core), a);
    text(label, sx, sy - 1);
    popStyle();
  }
}

/** Dust puffs left on the ground while sprinting. */
class SprintTrailPuff {
  float x, z, t0, scMul, ang;

  SprintTrailPuff(float x, float z, float t0, float scMul) {
    this.x = x;
    this.z = z;
    this.t0 = t0;
    this.scMul = scMul;
    this.ang = random(TWO_PI);
  }
}

class PickupPlusFx {
  float sx, sy;
  float age = 0;
  int kind;
  float driftVx;
  float riseSpd;

  PickupPlusFx(float sx, float sy, int kind, float driftVx, float riseSpd) {
    this.sx = sx;
    this.sy = sy;
    this.kind = kind;
    this.driftVx = driftVx;
    this.riseSpd = riseSpd;
  }

  void update(float dt) {
    age += dt;
    sy -= dt * riseSpd;
    sx += dt * driftVx;
  }

  boolean dead() {
    return age > 0.82;
  }

  void draw2D() {
    float a = 255 * constrain(1 - age / 0.82, 0, 1);
    if (a < 6) return;
    pushStyle();
    blendMode(BLEND);
    textAlign(CENTER, CENTER);
    int c = color(115, 255, 155);
    if (kind == LootPickup.LOOT_AMMO) c = color(255, 175, 85);
    float pulse = 1 + 0.14 * sin(age * 26 + sx * 0.05);
    textSize(24 * pulse);
    fill(0, a * 0.5);
    text("+", sx + 1.5, sy + 2);
    fill(red(c), green(c), blue(c), a);
    text("+", sx, sy);
    noStroke();
    popStyle();
  }
}

void spawnBanditGore(float x, float z, int outfitC) {
  for (int i = 0; i < 11; i++) {
    float a = random(TWO_PI);
    float p = random(0.35, 0.85);
    PVector v = new PVector(cos(a) * p * 165, -random(70, 195), sin(a) * p * 165);
    int mix = lerpColor(outfitC, color(72, 42, 38), random(0.1, 0.32));
    gibChunks.add(new GibChunk(x + random(-5, 5), random(-50, -28), z + random(-5, 5), v, mix));
  }
  for (int i = 0; i < 28; i++) {
    float a = random(TWO_PI);
    float e = random(0.15, 0.72);
    PVector v = new PVector(cos(a) * e * random(45, 130), -random(45, 155), sin(a) * e * random(45, 130));
    bloodParticles.add(new BloodParticle(x + random(-9, 9), random(-48, -22), z + random(-9, 9), v));
  }
}

void spawnPlayerGore(float x, float z) {
  color vest = color(58, 96, 145);
  color skin = color(238, 208, 170);
  color jeans = color(40, 50, 90);
  for (int i = 0; i < 14; i++) {
    float r = random(1);
    int c = r < 0.36 ? vest : (r < 0.68 ? jeans : skin);
    float a = random(TWO_PI);
    float p = random(0.32, 0.78);
    PVector v = new PVector(cos(a) * p * 150, -random(65, 190), sin(a) * p * 150);
    gibChunks.add(new GibChunk(x + random(-5, 5), random(-50, -28), z + random(-5, 5), v, c));
  }
  for (int i = 0; i < 32; i++) {
    float a = random(TWO_PI);
    float e = random(0.12, 0.65);
    PVector v = new PVector(cos(a) * e * random(42, 125), -random(40, 145), sin(a) * e * random(42, 125));
    bloodParticles.add(new BloodParticle(x + random(-9, 9), random(-48, -20), z + random(-9, 9), v));
  }
}

void updateAndDrawGore(float dt) {
  for (int i = gibChunks.size() - 1; i >= 0; i--) {
    GibChunk g = gibChunks.get(i);
    g.update(dt);
    g.display();
    if (g.life <= 0) gibChunks.remove(i);
  }
  for (int i = bloodParticles.size() - 1; i >= 0; i--) {
    BloodParticle bp = bloodParticles.get(i);
    bp.update(dt);
    bp.display();
    if (bp.life <= 0) bloodParticles.remove(i);
  }
}

void stopMusic() {
  SoundHelper.stopMusicLoop();
  SoundHelper.disposeClip(musicClip);
  musicClip = null;
}

void startMenuMusic() {
  if (gameFlow != FLOW_TITLE && gameFlow != FLOW_CONTROLS) return;
  stopMusic();
  String path = firstSoundPath("western_soundtrack.wav", "music_menu.wav");
  if (path == null) return;
  musicClip = SoundHelper.openMusicLoop(path, SoundHelper.musicVolume);
}

void startMusicIfAny() {
  stopMusic();
  String path = firstSoundPath("music_loop.wav", "music_loop.mp3");
  if (path == null) return;
  musicClip = SoundHelper.openMusicLoop(path, SoundHelper.musicVolume * 0.85f);
}

void drawWesternMenuBgImage() {
  noStroke();
  if (uiWesternBg != null) {
    imageMode(CORNER);
    image(uiWesternBg, 0, 0, width, height);
  } else {
    background(32, 20, 14);
  }
}

/** Title letters with a traveling Mexican-wave bounce. */
void drawTitleMexicanWave(String title, float cx, float cy, int fontSize) {
  pushStyle();
  textSize(fontSize);
  textAlign(LEFT, CENTER);
  float totalW = textWidth(title);
  float x = cx - totalW * 0.5f;
  float t = millis() * TITLE_WAVE_SPEED;
  for (int i = 0; i < title.length(); i++) {
    char ch = title.charAt(i);
    float lift = sin(t - i * TITLE_WAVE_SPACING) * TITLE_WAVE_AMP;
    float y = cy + lift;
    fill(0, 0, 0, 200);
    text(ch, x + 2, y + 2);
    fill(255, 242, 175);
    text(ch, x, y);
    x += textWidth(ch);
  }
  popStyle();
}

/** High score + credits on title / controls menus. */
void drawMenuExtras(float centerX) {
  textFontBody();
  textAlign(CENTER, CENTER);
  if (progressionHighScore > 0 || progressionTotalKills > 0) {
    textSize(MENU_SCORE_SIZE);
    fill(255, 248, 210);
    text("★ Best score: " + progressionHighScore + "   Lifetime kills: " + progressionTotalKills,
      centerX, height * 0.52f);
  }
  textSize(MENU_CREDITS_SIZE);
  fill(245, 235, 210);
  text("Ozan Halis Demiralp · Yavuzhan Özbek", centerX, height * 0.91f);
}

void addCollider(float minX, float maxX, float minZ, float maxZ) {
  sceneColliders.add(new float[]{minX, maxX, minZ, maxZ});
}

void addCircleCollider(float cx, float cz, float radius) {
  addCollider(cx - radius, cx + radius, cz - radius, cz + radius);
}

void buildSceneColliders() {
  sceneColliders.clear();

  addCollider(worldX(-666), worldX(-454), worldZ(-292), worldZ(-112));
  addCollider(worldX(470), worldX(650), worldZ(-266), worldZ(-116));
  addCollider(worldX(-640), worldX(-440), worldZ(176), worldZ(324));
  addCollider(worldX(450), worldX(590), worldZ(178), worldZ(320));
  addCircleCollider(worldX(-148), worldZ(58), worldX(44));
  addCollider(worldX(632), worldX(808), worldZ(-10), worldZ(70));
  addCircleCollider(worldX(520), worldZ(250), worldX(62));

  float cR = (worldX(26) + worldZ(26)) * 0.5;
  addCircleCollider(worldX(-130), worldZ(-380), cR);
  addCircleCollider(worldX(160), worldZ(-310), cR);
  addCircleCollider(worldX(180), worldZ(350), cR);
  addCircleCollider(worldX(-220), worldZ(320), cR);
  addCircleCollider(worldX(-680), worldZ(50), cR);
  addCircleCollider(worldX(680), worldZ(-50), cR);

  float bR = (worldX(14) + worldZ(14)) * 0.5;
  addCircleCollider(worldX(-30), worldZ(-130), bR);
  addCircleCollider(worldX(30), worldZ(-150), bR);
  addCircleCollider(worldX(70), worldZ(120), bR);
  addCircleCollider(worldX(-380), worldZ(0), bR);
  rebuildPathGrid();
}

int pathIndex(int gx, int gz) {
  return gx + gz * pathCols;
}

float pathCellCenterX(int gx) {
  return -arenaHalfW + (gx + 0.5f) * PATH_CELL;
}

float pathCellCenterZ(int gz) {
  return -arenaHalfH + (gz + 0.5f) * PATH_CELL;
}

int worldToGx(float x) {
  return constrain((int)floor((x + arenaHalfW) / PATH_CELL), 0, pathCols - 1);
}

int worldToGz(float z) {
  return constrain((int)floor((z + arenaHalfH) / PATH_CELL), 0, pathRows - 1);
}

void rebuildPathGrid() {
  pathCols = max(10, (int)ceil((arenaHalfW * 2f) / PATH_CELL));
  pathRows = max(10, (int)ceil((arenaHalfH * 2f) / PATH_CELL));
  pathBlocked = new boolean[pathCols * pathRows];
  for (int gz = 0; gz < pathRows; gz++) {
    for (int gx = 0; gx < pathCols; gx++) {
      float wx = pathCellCenterX(gx);
      float wz = pathCellCenterZ(gz);
      pathBlocked[pathIndex(gx, gz)] =
        !isInArenaXZ(wx, wz, 50) || circleOverlapsColliderXZ(wx, wz, 40);
    }
  }
}

int nearestFreePathCell(int gx, int gz) {
  if (!pathBlocked[pathIndex(gx, gz)]) return pathIndex(gx, gz);
  for (int ring = 1; ring < max(pathCols, pathRows); ring++) {
    for (int dz = -ring; dz <= ring; dz++) {
      for (int dx = -ring; dx <= ring; dx++) {
        if (abs(dx) != ring && abs(dz) != ring) continue;
        int nx = gx + dx, nz = gz + dz;
        if (nx < 0 || nz < 0 || nx >= pathCols || nz >= pathRows) continue;
        int idx = pathIndex(nx, nz);
        if (!pathBlocked[idx]) return idx;
      }
    }
  }
  return pathIndex(gx, gz);
}

/** A* path as world waypoints (cell centers); empty if unreachable. */
ArrayList<PVector> findPathWorld(float sx, float sz, float ex, float ez) {
  ArrayList<PVector> out = new ArrayList<PVector>();
  if (pathBlocked == null || pathBlocked.length == 0) rebuildPathGrid();
  int sgx = worldToGx(sx), sgz = worldToGz(sz);
  int egx = worldToGx(ex), egz = worldToGz(ez);
  int start = nearestFreePathCell(sgx, sgz);
  int goal = nearestFreePathCell(egx, egz);
  if (start == goal) {
    out.add(new PVector(ex, 0, ez));
    return out;
  }
  int n = pathCols * pathRows;
  float[] gScore = new float[n];
  int[] cameFrom = new int[n];
  boolean[] closed = new boolean[n];
  for (int i = 0; i < n; i++) {
    gScore[i] = 1e9f;
    cameFrom[i] = -1;
  }
  gScore[start] = 0;
  int[] openSet = new int[n];
  int openCount = 0;
  openSet[openCount++] = start;
  while (openCount > 0) {
    int bestI = 0;
    float bestF = 1e9f;
    for (int oi = 0; oi < openCount; oi++) {
      int idx = openSet[oi];
      int gx = idx % pathCols, gz = idx / pathCols;
      float h = dist(gx, gz, egx, egz);
      float f = gScore[idx] + h;
      if (f < bestF) {
        bestF = f;
        bestI = oi;
      }
    }
    int current = openSet[bestI];
    openSet[bestI] = openSet[--openCount];
    if (closed[current]) continue;
    closed[current] = true;
    if (current == goal) {
      int c = goal;
      while (c != -1) {
        int gx = c % pathCols, gz = c / pathCols;
        out.add(0, new PVector(pathCellCenterX(gx), 0, pathCellCenterZ(gz)));
        c = cameFrom[c];
      }
      if (out.size() > 0) {
        PVector last = out.get(out.size() - 1);
        last.x = ex;
        last.z = ez;
      }
      return out;
    }
    int cgx = current % pathCols, cgz = current / pathCols;
    for (int d = 0; d < pathDirDx.length; d++) {
      int ngx = cgx + pathDirDx[d], ngz = cgz + pathDirDz[d];
      if (ngx < 0 || ngz < 0 || ngx >= pathCols || ngz >= pathRows) continue;
      int ni = pathIndex(ngx, ngz);
      if (pathBlocked[ni] || closed[ni]) continue;
      float tentative = gScore[current] + PATH_CELL * pathDirCost[d];
      if (tentative < gScore[ni]) {
        cameFrom[ni] = current;
        gScore[ni] = tentative;
        boolean inOpen = false;
        for (int oi = 0; oi < openCount; oi++) {
          if (openSet[oi] == ni) {
            inOpen = true;
            break;
          }
        }
        if (!inOpen && openCount < n) openSet[openCount++] = ni;
      }
    }
  }
  return out;
}

void updateStaggeredSpawns(float dt) {
  if (!waveSpawning || pendingBanditSpawns.size() == 0) {
    waveSpawning = false;
    return;
  }
  staggerSpawnTimer -= dt;
  if (staggerSpawnTimer > 0) return;
  staggerSpawnTimer = STAGGER_SPAWN_INTERVAL;
  PendingBandit e = pendingBanditSpawns.remove(0);
  bandits.add(new Bandit(e.x, e.z, e.outfit, e.spdMul, e.hpMul, e.wave, e.weaponType));
  if (pendingBanditSpawns.size() == 0) waveSpawning = false;
}

/** Push a circle (px,pz,r) out of all axis-aligned XZ boxes. */
void resolveCircleColliders(PVector pos, float r) {
  resolveCircleColliders(pos, r, 6);
}

void resolveCircleColliders(PVector pos, float r, int maxPass) {
  for (int pass = 0; pass < maxPass; pass++) {
    for (float[] b : sceneColliders) {
      float px = pos.x;
      float pz = pos.z;
      float cx = constrain(px, b[0], b[1]);
      float cz = constrain(pz, b[2], b[3]);
      float dx = px - cx;
      float dz = pz - cz;
      float d2 = dx * dx + dz * dz;
      if (d2 < r * r) {
        float d = sqrt(max(d2, 1e-8f));
        float push = r - d;
        pos.x += (dx / d) * push;
        pos.z += (dz / d) * push;
      }
    }
  }
}

boolean circleOverlapsColliderXZ(float px, float pz, float r) {
  for (float[] b : sceneColliders) {
    float cx = constrain(px, b[0], b[1]);
    float cz = constrain(pz, b[2], b[3]);
    float dx = px - cx;
    float dz = pz - cz;
    if (dx * dx + dz * dz < r * r) return true;
  }
  return false;
}

boolean isInArenaXZ(float x, float z, float margin) {
  return x > -arenaHalfW + margin && x < arenaHalfW - margin
    && z > -arenaHalfH + margin && z < arenaHalfH - margin;
}

/** True if a bandit-sized circle can stand here. */
boolean isWalkableSpawnXZ(float x, float z, float r) {
  return isInArenaXZ(x, z, 80) && !circleOverlapsColliderXZ(x, z, r);
}

/** Push position out of buildings; spiral search if still inside. */
void nudgeToClearPosition(PVector pos, float r) {
  resolveCircleColliders(pos, r, 16);
  if (!circleOverlapsColliderXZ(pos.x, pos.z, r * 0.9f)) return;
  float ox = pos.x, oz = pos.z;
  for (float ring = 35; ring < 320; ring += 32) {
    for (int i = 0; i < 16; i++) {
      float a = i * TWO_PI / 16.0f;
      float tx = ox + cos(a) * ring;
      float tz = oz + sin(a) * ring;
      if (isWalkableSpawnXZ(tx, tz, r)) {
        pos.x = tx;
        pos.z = tz;
        return;
      }
    }
  }
}

/** Steering away from building colliders (smooth avoidance, not only collision). */
PVector colliderSteerForce(float px, float pz, float radius) {
  PVector acc = new PVector(0, 0, 0);
  float pad = radius + 42;
  for (float[] b : sceneColliders) {
    if (px > b[0] && px < b[1] && pz > b[2] && pz < b[3]) {
      float dl = px - b[0], dr = b[1] - px, db = pz - b[2], df = b[3] - pz;
      float m = min(dl, min(dr, min(db, df)));
      if (m == dl) acc.x -= 1.4f;
      else if (m == dr) acc.x += 1.4f;
      else if (m == db) acc.z -= 1.4f;
      else acc.z += 1.4f;
    }
    float cx = constrain(px, b[0], b[1]);
    float cz = constrain(pz, b[2], b[3]);
    float dx = px - cx, dz = pz - cz;
    float d2 = dx * dx + dz * dz;
    if (d2 < pad * pad && d2 > 1e-6f) {
      float d = sqrt(d2);
      float w = (pad - d) / pad;
      acc.x += (dx / d) * w * 1.2f;
      acc.z += (dz / d) * w * 1.2f;
    }
  }
  if (acc.magSq() > 1e-4f) {
    acc.normalize();
    acc.mult(0.85f);
  }
  return acc;
}

void unstuckBandit(Bandit b, Player player) {
  float r = 18;
  PVector best = null;
  float bestScore = -1e9f;
  for (int i = 0; i < 16; i++) {
    float a = i * TWO_PI / 16.0f + b.phase;
    for (float dist = 40; dist <= 140; dist += 35) {
      float tx = b.pos.x + cos(a) * dist;
      float tz = b.pos.z + sin(a) * dist;
      if (!isWalkableSpawnXZ(tx, tz, r)) continue;
      float dPlayer = dist(tx, tz, player.pos.x, player.pos.z);
      float score = -dPlayer + dist * 0.15f;
      if (score > bestScore) {
        bestScore = score;
        best = new PVector(tx, 0, tz);
      }
    }
  }
  if (best != null) {
    b.pos.x = best.x;
    b.pos.z = best.z;
  } else {
    nudgeToClearPosition(b.pos, r);
  }
  b.stuckSec = 0;
}

void draw() {
  processPendingDisplayMode();
  ensureMenuMusic();
  if (gameFlow == FLOW_TITLE) {
    drawTitleScreen();
    return;
  }
  if (gameFlow == FLOW_SETTINGS) {
    drawSettingsScreen();
    return;
  }
  if (gameFlow == FLOW_CONTROLS) {
    drawControlsIntroScreen();
    return;
  }
  updatePauseClock();
  drawSecondScreen(gameElapsedSec());
}

void updatePauseClock() {
  if (gamePaused && gamePauseStartMs == 0) gamePauseStartMs = millis();
  if (!gamePaused && gamePauseStartMs > 0) {
    gamePauseAccumMs += millis() - gamePauseStartMs;
    gamePauseStartMs = 0;
  }
}

float gameElapsedSec() {
  long paused = gamePauseAccumMs;
  if (gamePaused && gamePauseStartMs > 0) paused += millis() - gamePauseStartMs;
  return max(0, (millis() - sceneStartMs - paused) / 1000.0f);
}

void setGamePaused(boolean paused) {
  if (paused == gamePaused) return;
  updatePauseClock();
  gamePaused = paused;
  updatePauseClock();
  if (gamePaused) shooting = false;
}

void beginPlaySession() {
  stopMusic();
  initGame();
  sceneStartMs = millis();
  gameFlow = FLOW_PLAY;
  showControlsOverlay = false;
  gamePaused = false;
  shooting = false;
}

/** Reset fill/tint so 2D HUD colors do not tint the next frame's 3D draws. */
void reset3DDrawState() {
  blendMode(BLEND);
  noTint();
  fill(255);
  stroke(255);
  emissive(0, 0, 0);
  noStroke();
}

void reset2DDrawState() {
  blendMode(BLEND);
  noTint();
  noTexture();
  fill(255);
  stroke(255);
  noStroke();
}

void drawTitleScreen() {
  if (musicClip == null) startMenuMusic();
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  drawWesternMenuBgImage();
  hint(ENABLE_DEPTH_TEST);

  float centerX = width * 0.5f;
  textFontDisplay();
  textAlign(CENTER, CENTER);
  String title = "MAN WITH NO NAME";
  float titleY = height * 0.38f;
  drawTitleMexicanWave(title, centerX, titleY, TITLE_FONT_SIZE);

  textFontBody();
  textAlign(CENTER, CENTER);
  textSize(MENU_SUBTITLE_SIZE);
  fill(255, 248, 225);
  text("SEN3301 — 3D Arena Shootout", centerX, height * 0.46);
  drawMenuExtras(centerX);

  storyBtnX = centerX - storyBtnW * 0.5f;
  storyBtnY = height * 0.56f;
  endlessBtnX = storyBtnX;
  endlessBtnY = height * 0.64f;
  boolean storyHot = titleModeButtonHit(mouseX, mouseY, storyBtnX, storyBtnY);
  boolean endlessHot = titleModeButtonHit(mouseX, mouseY, endlessBtnX, endlessBtnY);
  drawTitleModeButton(storyBtnX, storyBtnY, storyBtnW, storyBtnH, "BOUNTY RUN", "9 waves · win the frontier", storyHot);
  drawTitleModeButton(endlessBtnX, endlessBtnY, storyBtnW, storyBtnH, "ENDLESS", "Rising difficulty · no final wave", endlessHot);

  settingsBtnX = centerX - settingsBtnW * 0.5f;
  settingsBtnY = height * 0.74f;
  boolean settingsHot = settingsButtonHit(mouseX, mouseY);
  noStroke();
  fill(32, 18, 10, settingsHot ? 210 : 175);
  rect(settingsBtnX, settingsBtnY, settingsBtnW, settingsBtnH, 8);
  stroke(200, 145, 70, settingsHot ? 255 : 200);
  strokeWeight(2);
  noFill();
  rect(settingsBtnX + 1, settingsBtnY + 1, settingsBtnW - 2, settingsBtnH - 2, 7);
  noStroke();
  textFontDisplay();
  textSize(20);
  fill(255, 248, 220, settingsHot ? 255 : 230);
  text("SETTINGS", centerX, settingsBtnY + settingsBtnH * 0.52f);
  reset2DDrawState();
}

boolean settingsButtonHit(float mx, float my) {
  return mx >= settingsBtnX && mx <= settingsBtnX + settingsBtnW
    && my >= settingsBtnY && my <= settingsBtnY + settingsBtnH;
}

boolean titleModeButtonHit(float mx, float my, float bx, float by) {
  return mx >= bx && mx <= bx + storyBtnW && my >= by && my <= by + storyBtnH;
}

void drawTitleModeButton(float bx, float by, float bw, float bh, String title, String sub, boolean hot) {
  noStroke();
  fill(32, 18, 10, hot ? 225 : 185);
  rect(bx, by, bw, bh, 10);
  stroke(200, 145, 70, hot ? 255 : 200);
  strokeWeight(2);
  noFill();
  rect(bx + 1, by + 1, bw - 2, bh - 2, 9);
  noStroke();
  textAlign(CENTER, CENTER);
  textFontDisplay();
  textSize(24);
  fill(255, 248, 220, hot ? 255 : 235);
  text(title, bx + bw * 0.5f, by + bh * 0.38f);
  textFontBody();
  textSize(14);
  fill(210, 195, 170, hot ? 255 : 220);
  text(sub, bx + bw * 0.5f, by + bh * 0.72f);
}

void drawSettingsScreen() {
  if (musicClip == null) startMenuMusic();
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  drawWesternMenuBgImage();
  float cx = width * 0.5f;
  float panelW = min(width - 48, 560);
  float panelH = min(height - 100, 420);
  float px = (width - panelW) * 0.5f;
  float py = (height - panelH) * 0.5f;
  drawWesternPanel(px, py, panelW, panelH, 14);
  textAlign(CENTER, TOP);
  textFontDisplay();
  fill(255, 242, 175);
  textSize(40);
  text("SETTINGS", cx, py + 22);
  textFontBody();
  textSize(17);
  fill(235, 220, 195);
  text("Drag sliders", cx, py + 68);

  float barX = cx - settingsBarW * 0.5f;
  settingsSfxBarY = py + 118;
  settingsMusicBarY = py + 188;
  drawVolumeSlider("SFX", settingsSfxVol, barX, settingsSfxBarY);
  drawVolumeSlider("MUSIC", settingsMusicVol, barX, settingsMusicBarY);

  settingsDisplayBtnX = cx - settingsDisplayBtnW * 0.5f;
  settingsDisplayBtnY = py + 258;
  boolean displayHot = displayModeButtonHit(mouseX, mouseY);
  noStroke();
  fill(32, 18, 10, displayHot ? 225 : 185);
  rect(settingsDisplayBtnX, settingsDisplayBtnY, settingsDisplayBtnW, settingsDisplayBtnH, 8);
  stroke(200, 145, 70, displayHot ? 255 : 200);
  strokeWeight(2);
  noFill();
  rect(settingsDisplayBtnX + 1, settingsDisplayBtnY + 1, settingsDisplayBtnW - 2, settingsDisplayBtnH - 2, 7);
  noStroke();
  textFontBody();
  textAlign(CENTER, CENTER);
  textSize(17);
  fill(255, 248, 220, displayHot ? 255 : 230);
  String modeLabel = settingsFullscreen ? "FULLSCREEN" : "WINDOWED 1280×720";
  text(modeLabel, cx, settingsDisplayBtnY + settingsDisplayBtnH * 0.5f);
  textAlign(CENTER, TOP);

  textSize(15);
  fill(210, 195, 170);
  text("ESC — back to title", cx, py + panelH - 36);
  reset2DDrawState();
}

void drawVolumeSlider(String label, float val, float x, float y) {
  textFontBody();
  float safe = sanitizeVolume(val, label.equals("SFX") ? GAME_SFX_VOLUME_DEFAULT : GAME_MUSIC_VOLUME_DEFAULT);
  textAlign(LEFT, CENTER);
  textSize(18);
  fill(255, 245, 220);
  text(label, x, y - 22);
  textAlign(RIGHT, CENTER);
  text((int)(safe * 100 + 0.5f) + "%", x + settingsBarW, y - 22);
  noStroke();
  fill(28, 16, 10, 220);
  rect(x, y, settingsBarW, settingsBarH, 6);
  float fillW = settingsBarW * safe;
  fill(200, 120, 45, 240);
  rect(x, y, max(4, fillW), settingsBarH, 6);
  stroke(220, 170, 90);
  strokeWeight(2);
  float knobX = x + fillW;
  line(knobX, y - 2, knobX, y + settingsBarH + 2);
  noStroke();
}

float volumeFromBarX(float mx, float barX) {
  return constrain((mx - barX) / settingsBarW, 0, 1);
}

void updateSettingsFromMouse(float mx, float my) {
  float barX = width * 0.5f - settingsBarW * 0.5f;
  if (settingsDraggingSfx || (mx >= barX && mx <= barX + settingsBarW
      && my >= settingsSfxBarY - 8 && my <= settingsSfxBarY + settingsBarH + 8)) {
    settingsSfxVol = volumeFromBarX(mx, barX);
    applyAudioVolumes();
    if (settingsDraggingSfx) maybePreviewSfxVolume();
  }
  if (settingsDraggingMusic || (mx >= barX && mx <= barX + settingsBarW
      && my >= settingsMusicBarY - 8 && my <= settingsMusicBarY + settingsBarH + 8)) {
    settingsMusicVol = volumeFromBarX(mx, barX);
    applyAudioVolumes();
  }
}

void drawControlsIntroScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  drawWesternMenuBgImage();
  drawMenuExtras(width * 0.5f);
  drawControlsOverlayPanel("Click anywhere to start", true);
  reset2DDrawState();
}

void drawControlsOverlayPanel(String footer, boolean fullBackdrop) {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  rectMode(CORNER);
  if (fullBackdrop) {
    noStroke();
    fill(0, 90);
    rect(0, 0, width, height);
  } else {
    noStroke();
    fill(0, 165);
    rect(0, 0, width, height);
  }

  int count = controlPanelRows != null ? controlPanelRows.length : 0;
  int cols = CTRL_GRID_COLS;
  int gridRows = count > 0 ? (count + cols - 1) / cols : 0;

  final float keySize = 40;
  final float mouseSize = 54;
  final float iconGap = 5;
  final float cellPad = 10;
  final float gridGap = 10;
  final float labelH = 36;
  float iconAreaH = max(keySize * 2 + iconGap + 4, mouseSize + 4);
  float cellW = 168;
  float cellH = iconAreaH + labelH + cellPad * 2;
  float gridW = cols * cellW + (cols - 1) * gridGap;
  float gridH = gridRows * cellH + max(0, gridRows - 1) * gridGap;

  float titleBlockH = 48;
  float footerBlockH = 58;
  float panelW = min(width - 28, gridW + 44);
  float panelH = min(height - 36, titleBlockH + gridH + footerBlockH + 24);
  float px = (width - panelW) * 0.5f;
  float py = (height - panelH) * 0.5f;
  drawWesternPanel(px, py, panelW, panelH, 12);

  textAlign(CENTER, TOP);
  textFontDisplay();
  fill(255, 242, 175);
  textSize(32);
  text("CONTROLS", width * 0.5f, py + 12);

  float gridX = px + (panelW - gridW) * 0.5f;
  float gridY = py + titleBlockH;
  if (controlPanelRows != null) {
    for (int i = 0; i < controlPanelRows.length; i++) {
      int col = i % cols;
      int row = i / cols;
      float cx = gridX + col * (cellW + gridGap);
      float cy = gridY + row * (cellH + gridGap);
      drawControlGridCell(cx, cy, cellW, cellH, controlPanelRows[i], keySize, mouseSize, iconGap, iconAreaH, labelH);
    }
  }

  String modeLine = endlessMode || selectedGameMode == GAME_MODE_ENDLESS
    ? "Endless — difficulty rises each wave · survive the timer"
    : STORY_MAX_WAVES + " waves · clear all bandits or survive the timer";
  textSize(13);
  textLeading(17);
  fill(245, 235, 210);
  text(modeLine, width * 0.5f, py + panelH - footerBlockH + 4);
  textSize(17);
  textLeading(20);
  fill(255, 252, 240);
  text(footer, width * 0.5f, py + panelH - 26);
  reset2DDrawState();
}

void drawControlKeyButton(String label, float x, float y, float w, float h) {
  noStroke();
  fill(0, 50);
  rect(x + 1.5f, y + 2.5f, w, h, 6);
  fill(252, 246, 232);
  rect(x, y, w, h, 6);
  stroke(145, 95, 48, 200);
  strokeWeight(1.2f);
  noFill();
  rect(x + 0.5f, y + 0.5f, w - 1, h - 1, 5);
  noStroke();
  textFontBody();
  textAlign(CENTER, CENTER);
  float ts = min(h * 0.5f, w * 0.78f);
  if (label.length() > 4) ts *= 0.68f;
  else if (label.length() > 1) ts *= 0.82f;
  textSize(ts);
  fill(32, 20, 12);
  text(label, x + w * 0.5f, y + h * 0.52f);
}

void drawControlMouseIcon(PImage img, float x, float y, float size) {
  if (img == null) return;
  imageMode(CORNER);
  noStroke();
  fill(0, 45);
  rect(x + 1, y + 2, size, size, 5);
  image(img, x, y, size, size);
}

void drawControlKeysWASD(String[] keys, float x, float y, float size, float gap) {
  if (keys == null || keys.length < 4) return;
  float midX = x + size + gap;
  drawControlKeyButton(keys[0], midX, y, size, size);
  float row2Y = y + size + gap;
  drawControlKeyButton(keys[1], x, row2Y, size, size);
  drawControlKeyButton(keys[2], midX, row2Y, size, size);
  drawControlKeyButton(keys[3], x + (size + gap) * 2, row2Y, size, size);
}

void drawControlKeysRow(String[] keys, float x, float y, float size, float gap) {
  if (keys == null) return;
  float ix = x;
  for (String k : keys) {
    float kw = controlKeyWidth(k, size);
    drawControlKeyButton(k, ix, y, kw, size);
    ix += kw + gap;
  }
}

void drawControlMouseRow(PImage[] icons, float x, float y, float size, float gap) {
  if (icons == null) return;
  float ix = x;
  for (PImage img : icons) {
    drawControlMouseIcon(img, ix, y, size);
    ix += size + gap;
  }
}

void drawControlGridCell(float cx, float cy, float cw, float ch, ControlPanelRow row,
    float keySize, float mouseSize, float iconGap, float iconAreaH, float labelH) {
  noStroke();
  fill(32, 20, 12, 215);
  rect(cx, cy, cw, ch, 7);
  stroke(150, 100, 50, 140);
  strokeWeight(1);
  noFill();
  rect(cx + 1, cy + 1, cw - 2, ch - 2, 6);
  noStroke();

  float blockW = controlCellIconBlockW(row, keySize, mouseSize, iconGap);
  float blockH = controlCellIconBlockH(row, keySize, mouseSize, iconGap);
  float iconX = cx + (cw - blockW) * 0.5f;
  float iconY = cy + 10 + (iconAreaH - blockH) * 0.5f;

  if (row.layout == CTRL_LAYOUT_WASD && row.keyLabels != null && row.keyLabels.length >= 4) {
    drawControlKeysWASD(row.keyLabels, iconX, iconY, keySize, iconGap);
  } else if (row.keyLabels != null && row.keyLabels.length > 0) {
    drawControlKeysRow(row.keyLabels, iconX, iconY, keySize, iconGap);
  } else if (row.mouseIcons != null && row.mouseIcons.length > 0) {
    drawControlMouseRow(row.mouseIcons, iconX, iconY, mouseSize, iconGap);
  }

  textFontBody();
  textAlign(CENTER, TOP);
  textSize(13);
  textLeading(16);
  fill(255, 248, 235);
  text(row.title, cx + cw * 0.5f, cy + ch - labelH + 4);
}

boolean controlsHudButtonHit(float mx, float my) {
  return mx >= controlsBtnX && mx <= controlsBtnX + controlsBtnW
    && my >= controlsBtnY && my <= controlsBtnY + controlsBtnH;
}

void drawControlsHudButton() {
  controlsBtnX = 340;
  controlsBtnY = 12;
  controlsBtnW = 96;
  controlsBtnH = 26;
  boolean hot = controlsHudButtonHit(mouseX, mouseY);
  drawUiButton(uiBtnControls, uiBtnControlsHot, controlsBtnX, controlsBtnY, controlsBtnW, controlsBtnH, hot);
  if (uiBtnControls == null) {
    textFontBody();
    textAlign(CENTER, CENTER);
    textSize(10);
    fill(248, 215, 125);
    text("Controls", controlsBtnX + controlsBtnW * 0.5, controlsBtnY + controlsBtnH * 0.5 + 1);
  }
  reset2DDrawState();
}

// Task-2+: angled top-down western shootout with proper aiming + camera control.
void drawSecondScreen(float t) {
  background(92, 62, 48);
  hint(ENABLE_DEPTH_TEST);

  float fr = max(frameRate, 30);
  float dt = 1.0 / fr;
  boolean gameplayActive = !showControlsOverlay && !finished && !gamePaused;
  if (weaponUnlockBannerTimer > 0) weaponUnlockBannerTimer -= dt;
  if (gameplayActive) {
    updateWaveTimers(dt);
    updateWaveIntro(dt);
    updateMovement(dt);
    updateStaggeredSpawns(dt);
  }
  updateDamageFlash(dt);
  persistRunIfEnded();
  updatePickupPlusFx(dt);
  updateAmmoGainFx(dt);

  setAngledCamera();
  reset3DDrawState();
  drawWesternEnvironment(t);

  aimPoint = groundFromMouse(mouseX, mouseY);
  player.updateAim(aimPoint);
  if (gameplayActive) {
    player.update(t, dt);
    updateSprintTrail(t, dt);
    updateSprintBarFocus(dt);
  }

  if (gameplayActive && shooting && waveState == WAVE_STATE_FIGHT && wavePreviewTimer <= 0) {
    ArrayList<Bullet> volley = player.tryShootVolley(aimPoint);
    if (volley != null && volley.size() > 0) {
      bullets.addAll(volley);
      PVector tip = player.gunTip();
      muzzleFlashes.add(new MuzzleFlash(tip, player.facing, player.weaponSlot));
      if (player.weaponSlot == 0) addCamShake(2.8f);
      else if (player.weaponSlot == 1) {
        addCamShake(11f);
        emitShotgunShells(tip, player.facing);
      } else addCamShake(4.5f);
    }
  }

  if (player.hp > 0) {
    player.display(t);
  }

  if (gameplayActive) {
    updateAndDrawBandits(t, dt);
    for (int li = lootPickups.size() - 1; li >= 0; li--) {
      LootPickup lp = lootPickups.get(li);
      lp.update(player);
      if (lp.gone) lootPickups.remove(li);
    }
  } else {
    for (Bandit b : bandits) b.display(t);
  }
  for (LootPickup lp : lootPickups) lp.display(t);
  if (gameplayActive) {
    updateAndDrawBullets(dt);
    updateAndDrawEnemyBullets(dt);
    updateAndDrawMuzzleFlashes(dt);
    updateAndDrawShellCasings(dt);
    updateAndDrawHitSparks(dt);
  } else {
    for (Bullet b : bullets) b.display();
    for (EnemyBullet eb : enemyBullets) eb.display();
    for (MuzzleFlash m : muzzleFlashes) m.display();
    for (ShellCasing sc : shellCasings) sc.display();
    for (HitSpark s : hitSparks) s.display();
  }

  drawAimMarker(aimPoint, t);

  ArrayList<float[]> healthPositions = new ArrayList<float[]>();
  for (Bandit b : bandits) {
    if (!b.alive) continue;
    float sx = screenX(b.pos.x, -90, b.pos.z);
    float sy = screenY(b.pos.x, -90, b.pos.z);
    healthPositions.add(new float[]{sx, sy, b.hp / b.maxHp});
  }

  if (gameplayActive) updateGameState(t);

  if (gameplayActive) updateAndDrawGore(dt);
  else {
    for (GibChunk g : gibChunks) g.display();
    for (BloodParticle bp : bloodParticles) bp.display();
  }

  playerScreenFootX = screenX(player.pos.x, GROUND_Y, player.pos.z);
  playerScreenFootY = screenY(player.pos.x, GROUND_Y, player.pos.z);
  playerSprintHudX = screenX(player.pos.x, -86, player.pos.z);
  playerSprintHudY = screenY(player.pos.x, -86, player.pos.z);
  rebuildSprintTrailScreen(t);

  hint(DISABLE_DEPTH_TEST);
  noTexture();
  camera();
  perspective();
  noLights();
  textFontBody();
  float sx = (random(-1, 1) + random(-1, 1)) * 0.5 * (hurtShakePx + camShakePx);
  float sy = (random(-1, 1) + random(-1, 1)) * 0.5 * (hurtShakePx + camShakePx * 0.85f);
  drawSprintTrail2D();
  drawPlayerSprintBar2D();
  pushMatrix();
  translate(sx, sy);
  drawHealthBars(healthPositions);
  drawHudDistributed(t);
  drawControlsHudButton();
  drawPlayerReloadBarScreen();
  drawReloadNeededFeedback(t);
  drawWaveIntermissionOverlay(t);
  drawWaveBanner2D();
  drawSpawnPreview2D(t);
  popMatrix();
  drawHurtFeedbackOverlay();
  drawPickupPlusFx2D();
  drawAmmoGainFx2D();
  drawWeaponUnlockBanner2D();
  reset2DDrawState();
  if (gamePaused && !finished) {
    drawPauseOverlay();
  }
  if (showControlsOverlay) {
    drawControlsOverlayPanel("Click anywhere or press H to close", false);
  }
  hint(ENABLE_DEPTH_TEST);
}

void updateWaveTimers(float dt) {
  if (waveState != WAVE_STATE_BREAK) return;
  waveBreakTimer -= dt;
  if (waveBreakTimer > 0) return;
  currentWave++;
  if (!endlessMode && currentWave > maxWaves) {
    finished = true;
    gameStateText = "YOU WIN";
    playWavSafe("win.wav");
    waveState = WAVE_STATE_FIGHT;
    return;
  }
  spawnWave(currentWave);
  waveState = WAVE_STATE_FIGHT;
}

PVector tryBanditSpawnPoint(float x, float z, float spawnR) {
  PVector p = new PVector(x, 0, z);
  if (circleOverlapsColliderXZ(p.x, p.z, spawnR)) nudgeToClearPosition(p, spawnR);
  if (isWalkableSpawnXZ(p.x, p.z, spawnR)) return p;
  return null;
}

boolean farEnoughFromOthers(float x, float z, ArrayList<PVector> used, float minSep) {
  float sep2 = minSep * minSep;
  for (PVector u : used) {
    float dx = x - u.x, dz = z - u.z;
    if (dx * dx + dz * dz < sep2) return false;
  }
  return true;
}

/** Sector + distance spawn so wave enemies stay far from player and spread out. */
PVector randomBanditSpawnForWave(int index, int total, int wave, ArrayList<PVector> used) {
  float spawnR = 22;
  float minFromPlayer = 600 + wave * 45;
  float maxFromPlayer = min(arenaHalfW, arenaHalfH) * 0.78f;
  float minSep = 190;

  for (int attempt = 0; attempt < 140; attempt++) {
    float sector = (index + 0.5f) / max(1, total);
    float a = sector * TWO_PI + random(-0.42f, 0.42f);
    float ring = random(minFromPlayer, maxFromPlayer);
    float rx = player.pos.x + cos(a) * ring;
    float rz = player.pos.z + sin(a) * ring;
    if (!isInArenaXZ(rx, rz, 90)) continue;
    float dx = rx - player.pos.x, dz = rz - player.pos.z;
    if (dx * dx + dz * dz < minFromPlayer * minFromPlayer) continue;
    if (!farEnoughFromOthers(rx, rz, used, minSep)) continue;
    if (!isWalkableSpawnXZ(rx, rz, spawnR)) continue;
    PVector p = new PVector(rx, 0, rz);
    return p;
  }

  for (int attempt = 0; attempt < 80; attempt++) {
    float a = random(TWO_PI);
    float ring = random(minFromPlayer, maxFromPlayer);
    float rx = player.pos.x + cos(a) * ring;
    float rz = player.pos.z + sin(a) * ring;
    if (!isInArenaXZ(rx, rz, 90)) continue;
    float dx = rx - player.pos.x, dz = rz - player.pos.z;
    if (dx * dx + dz * dz < minFromPlayer * minFromPlayer) continue;
    if (!farEnoughFromOthers(rx, rz, used, minSep * 0.85f)) continue;
    if (!isWalkableSpawnXZ(rx, rz, spawnR)) continue;
    return new PVector(rx, 0, rz);
  }

  PVector fb = tryBanditSpawnPoint(-520, -420, spawnR);
  if (fb != null && farEnoughFromOthers(fb.x, fb.z, used, minSep * 0.7f)) return fb;
  fb = tryBanditSpawnPoint(520, 420, spawnR);
  if (fb != null && farEnoughFromOthers(fb.x, fb.z, used, minSep * 0.7f)) return fb;
  fb = tryBanditSpawnPoint(-480, 480, spawnR);
  if (fb != null) return fb;
  float fallbackAng = TWO_PI * index / max(1, total);
  return new PVector(
    player.pos.x + cos(fallbackAng) * minFromPlayer,
    0,
    player.pos.z + sin(fallbackAng) * minFromPlayer
  );
}

int rollBanditWeaponForWave(int w) {
  float r = random(1);
  if (w <= 2) return BANDIT_WPN_REVOLVER;
  if (w <= 5) return r < 0.7 ? BANDIT_WPN_REVOLVER : BANDIT_WPN_SHOTGUN;
  if (w <= 8) {
    if (r < 0.35) return BANDIT_WPN_REVOLVER;
    if (r < 0.7) return BANDIT_WPN_SHOTGUN;
    return BANDIT_WPN_REPEATER;
  }
  if (r < 0.2) return BANDIT_WPN_REVOLVER;
  if (r < 0.5) return BANDIT_WPN_SHOTGUN;
  return BANDIT_WPN_REPEATER;
}

void applyWeaponUnlocksForWave(int w) {
  if (endlessMode || player == null) return;
  if (w >= UNLOCK_SHOTGUN_WAVE && !player.isWeaponUnlocked(1)) {
    player.unlockWeaponSlot(1);
    weaponUnlockBannerText = "SHOTGUN UNLOCKED";
    weaponUnlockBannerTimer = 3.5f;
  }
  if (w >= UNLOCK_REPEATER_WAVE && !player.isWeaponUnlocked(2)) {
    player.unlockWeaponSlot(2);
    weaponUnlockBannerText = "REPEATER UNLOCKED";
    weaponUnlockBannerTimer = 3.5f;
  }
}

void spawnWave(int w) {
  applyWeaponUnlocksForWave(w);
  bandits.clear();
  enemyBullets.clear();
  bullets.clear();
  pendingBanditSpawns.clear();
  previewSpawnMarkers.clear();
  int n = max(2, 2 + w + w / 2);
  color[] outfits = {
    color(180, 60, 50), color(160, 100, 50), color(130, 60, 90),
    color(80, 120, 145), color(100, 80, 60)
  };
  ArrayList<PVector> usedSpawns = new ArrayList<PVector>();
  float hpMul = 1 + 0.10f * (w - 1);
  float spdMul = 1 + 0.065f * (w - 1);
  if (endlessMode && w > STORY_MAX_WAVES) {
    hpMul += 0.055f * (w - STORY_MAX_WAVES);
    spdMul += 0.028f * (w - STORY_MAX_WAVES);
  }
  for (int i = 0; i < n; i++) {
    PVector p = randomBanditSpawnForWave(i, n, w, usedSpawns);
    if (circleOverlapsColliderXZ(p.x, p.z, 20)) nudgeToClearPosition(p, 20);
    usedSpawns.add(p.copy());
    previewSpawnMarkers.add(p.copy());
    int wpn = rollBanditWeaponForWave(w);
    pendingBanditSpawns.add(new PendingBandit(
      p.x, p.z, outfits[i % outfits.length], spdMul, hpMul, w, wpn
    ));
  }
  wavePreviewTimer = WAVE_PREVIEW_DURATION;
  waveBannerTimer = WAVE_BANNER_DURATION;
  waveBannerNumber = w;
  waveSpawning = false;
  staggerSpawnTimer = STAGGER_SPAWN_INTERVAL;
}

void initGame() {
  stopMusic();
  endlessMode = (selectedGameMode == GAME_MODE_ENDLESS);
  maxWaves = STORY_MAX_WAVES;
  gamePaused = false;
  gamePauseAccumMs = 0;
  gamePauseStartMs = 0;
  weaponUnlockBannerTimer = 0;
  weaponUnlockBannerText = "";
  player = new Player(0, 0);
  player.resetWeaponsForMode(endlessMode);
  bullets = new ArrayList<Bullet>();
  enemyBullets = new ArrayList<EnemyBullet>();
  bandits = new ArrayList<Bandit>();
  pendingBanditSpawns.clear();
  previewSpawnMarkers.clear();
  waveSpawning = false;
  wavePreviewTimer = 0;
  waveBannerTimer = 0;
  shellCasings.clear();
  camShakeAmp = 0;
  camShakePx = 0;
  muzzleFlashes = new ArrayList<MuzzleFlash>();
  hitSparks = new ArrayList<HitSpark>();
  if (lootPickups == null) lootPickups = new ArrayList<LootPickup>();
  else lootPickups.clear();
  pickupPlusFx.clear();
  gibChunks.clear();
  bloodParticles.clear();
  sprintTrailPuffs.clear();
  sprintTrailScreenDots.clear();
  sprintTrailEmitAccum = 0;
  ammoGainFx.clear();
  playerGoreSpawned = false;
  kills = 0;
  score = 0;
  extraTimeSec = 0;
  finished = false;
  gameStateText = "";
  runStatsPersisted = false;
  waveState = WAVE_STATE_FIGHT;
  waveBreakTimer = 0;
  currentWave = 1;
  hurtShakePx = 0;
  hurtRing = 0;
  lastHp = 100;
  sprintHeld = false;
  sprintBarFocus = 0;
  spawnWave(1);
  startMusicIfAny();
}

void updateMovement(float dt) {
  PVector input = new PVector();
  if (moveW) input.z -= 1;
  if (moveS) input.z += 1;
  if (moveA) input.x -= 1;
  if (moveD) input.x += 1;

  if (input.magSq() > 0) {
    input.normalize();
    float ca = cos(camYaw);
    float sa = sin(camYaw);
    float rx = input.x * ca + input.z * sa;
    float rz = -input.x * sa + input.z * ca;
    PVector move = new PVector(rx, 0, rz);
    float spd = player.speed;
    if (sprintHeld && player.stamina > 0.035 && !finished && waveState == WAVE_STATE_FIGHT) {
      spd *= 1.55;
    }
    move.mult(spd * dt);
    player.pos.add(move);
    player.moving = true;
  } else {
    player.moving = false;
  }

  player.pos.x = constrain(player.pos.x, -arenaHalfW + 80, arenaHalfW - 80);
  player.pos.z = constrain(player.pos.z, -arenaHalfH + 80, arenaHalfH - 80);
  resolveCircleColliders(player.pos, 26);
}

void updateSprintTrail(float gameT, float dt) {
  boolean sprinting = sprintHeld && player.moving && player.stamina > 0.02
    && !finished && waveState == WAVE_STATE_FIGHT;
  if (sprinting) {
    sprintTrailEmitAccum += dt;
    /** Two heel puffs, infrequent — no busy particle spam. */
    final float step = 0.52;
    while (sprintTrailEmitAccum >= step) {
      sprintTrailEmitAccum -= step;
      float bf = player.facing;
      float backX = -sin(bf);
      float backZ = -cos(bf);
      float sideX = cos(bf);
      float sideZ = -sin(bf);
      float dist = 24;
      float spread = 11;
      float pxL = player.pos.x + backX * dist - sideX * spread;
      float pzL = player.pos.z + backZ * dist - sideZ * spread;
      float pxR = player.pos.x + backX * dist + sideX * spread;
      float pzR = player.pos.z + backZ * dist + sideZ * spread;
      sprintTrailPuffs.add(new SprintTrailPuff(pxL, pzL, gameT, 1));
      sprintTrailPuffs.add(new SprintTrailPuff(pxR, pzR, gameT, 1));
    }
  } else {
    sprintTrailEmitAccum = 0;
  }
  final float maxAge = 0.45;
  for (int i = sprintTrailPuffs.size() - 1; i >= 0; i--) {
    if (gameT - sprintTrailPuffs.get(i).t0 > maxAge) sprintTrailPuffs.remove(i);
  }
}

/** Call while 3D camera is active so screenX/Y are correct. */
void rebuildSprintTrailScreen(float gameT) {
  sprintTrailScreenDots.clear();
  if (sprintTrailPuffs.isEmpty()) return;
  for (SprintTrailPuff p : sprintTrailPuffs) {
    float age = gameT - p.t0;
    float life = 0.42;
    if (age <= 0 || age >= life) continue;
    float u = age / life;
    /** Soft ground dust: low alpha, modest size — single layer per puff. */
    float a = (1 - u) * (1 - u);
    float diam = (32 + u * 28) * p.scMul;
    float sx = screenX(p.x, 0, p.z);
    float sy = screenY(p.x, 0, p.z);
    sprintTrailScreenDots.add(new float[]{sx, sy, diam, a});
  }
}

void drawSprintTrail2D() {
  if (sprintTrailScreenDots.isEmpty()) return;
  pushStyle();
  rectMode(CENTER);
  noStroke();
  blendMode(BLEND);
  for (float[] d : sprintTrailScreenDots) {
    float sx = d[0], sy = d[1], diam = d[2], a = d[3];
    float op = constrain(a * 120, 14, 62);
    fill(195, 160, 118, op);
    ellipse(sx, sy + 1, diam * 1.08, diam * 0.62);
    fill(235, 215, 175, op * 0.45);
    ellipse(sx, sy - diam * 0.04, diam * 0.42, diam * 0.28);
  }
  rectMode(CORNER);
  popStyle();
}

void updateSprintBarFocus(float dt) {
  if (finished || waveState != WAVE_STATE_FIGHT || player == null || player.hp <= 0) {
    sprintBarFocus = 0;
    return;
  }
  if (sprintHeld) {
    sprintBarFocus = min(1, sprintBarFocus + dt * 8.5f);
  } else {
    sprintBarFocus = max(0, sprintBarFocus - dt * 1.6f);
  }
}

void drawPlayerSprintBar2D() {
  if (finished || waveState != WAVE_STATE_FIGHT || player.hp <= 0) return;
  if (sprintBarFocus < 0.02) return;
  int op = (int)constrain(sprintBarFocus * 255, 0, 255);
  float cx = playerSprintHudX;
  float barTop = playerSprintHudY - 44;
  float bw = 142, bh = 11;
  float lx = constrain(cx - bw * 0.5, 18, width - bw - 18);

  rectMode(CORNER);
  noStroke();
  fill(18, 12, 9, op);
  rect(lx, barTop, bw, bh, 5);
  fill(0, min(255, (int)(80 * sprintBarFocus)));
  rect(lx + 2, barTop + 2, bw - 4, bh - 4, 4);
  float innerH = bh - 5;
  float fw = (bw - 5) * constrain(player.stamina, 0, 1);
  if (fw > 0.5) {
    fill(72, 210, 125, op);
    rect(lx + 2.5, barTop + 2.5, fw, innerH, 3);
    fill(255, min(255, (int)(58 * sprintBarFocus)));
    rect(lx + 2.5, barTop + 2.5, fw, max(2, innerH * 0.4f), 3);
    fill(0, min(255, (int)(48 * sprintBarFocus)));
    rect(lx + 2.5, barTop + 2.5 + innerH * 0.58f, fw, max(1, innerH * 0.38f), 2);
  }
  noFill();
  stroke(175, 125, 55, op);
  strokeWeight(1.5);
  rect(lx, barTop, bw, bh, 5);
  stroke(255, 248, 220, min(255, (int)(70 * sprintBarFocus)));
  strokeWeight(1);
  rect(lx + 1, barTop + 1, bw - 2, bh - 2, 4);
  noStroke();

  textAlign(CENTER, BOTTOM);
  textSize(10);
  fill(235, 225, 205, op);
  text("SPRINT", cx, barTop - 3);
}

void setAngledCamera() {
  float horizDist = camDist * cos(camPitch);
  float vertDist = camDist * sin(camPitch);
  camPosX = player.pos.x + horizDist * sin(camYaw);
  camPosY = -vertDist;
  camPosZ = player.pos.z + horizDist * cos(camYaw);
  camTargetX = player.pos.x;
  camTargetY = -8;
  camTargetZ = player.pos.z;
  float shX = (random(-1, 1) + random(-1, 1)) * 0.5f * (camShakePx + hurtShakePx * 0.75f);
  float shY = (random(-1, 1) + random(-1, 1)) * 0.5f * (camShakePx * 0.55f + hurtShakePx * 0.45f);
  float shZ = (random(-1, 1) + random(-1, 1)) * 0.5f * camShakePx * 0.4f;
  camera(camPosX + shX, camPosY + shY, camPosZ + shZ,
    camTargetX + shX * 0.35f, camTargetY, camTargetZ + shZ * 0.35f, 0, 1, 0);
  perspective(PI / 3.0, float(width) / float(height), 1, 6000);

  camForward.set(camTargetX - camPosX, camTargetY - camPosY, camTargetZ - camPosZ);
  camForward.normalize();
  PVector worldUp = new PVector(0, 1, 0);
  camRight = camForward.cross(worldUp);
  camRight.normalize();
  camUp = camRight.cross(camForward);
  camUp.normalize();

  ambientLight(80, 70, 60);
  directionalLight(255, 220, 175, -0.4, 0.85, -0.25);
  pointLight(255, 165, 95, player.pos.x, -200, player.pos.z + 200);
}

PVector groundFromMouse(float mx, float my) {
  float fov = PI / 3.0;
  float aspect = (float) width / height;
  float tFov = tan(fov / 2.0);

  float ndcX = (2.0 * mx / width - 1.0) * aspect * tFov;
  float ndcY = (2.0 * my / height - 1.0) * tFov;

  PVector rayDir = camForward.copy();
  rayDir.add(PVector.mult(camRight, ndcX));
  rayDir.add(PVector.mult(camUp, ndcY));
  rayDir.normalize();

  float planeY = GROUND_Y;
  if (abs(rayDir.y) < 1e-5) return new PVector(player.pos.x, planeY, player.pos.z);
  float t = (planeY - camPosY) / rayDir.y;
  if (t < 0) t = 1500;
  return new PVector(camPosX + rayDir.x * t, planeY, camPosZ + rayDir.z * t);
}

// === Input ===

void mousePressed() {
  if (gameFlow == FLOW_TITLE) {
    if (settingsButtonHit(mouseX, mouseY)) {
      playUiClick();
      gameFlow = FLOW_SETTINGS;
      return;
    }
    if (titleModeButtonHit(mouseX, mouseY, storyBtnX, storyBtnY)) {
      playUiClick();
      selectedGameMode = GAME_MODE_STORY;
      gameFlow = FLOW_CONTROLS;
      return;
    }
    if (titleModeButtonHit(mouseX, mouseY, endlessBtnX, endlessBtnY)) {
      playUiClick();
      selectedGameMode = GAME_MODE_ENDLESS;
      gameFlow = FLOW_CONTROLS;
      return;
    }
    return;
  }
  if (gameFlow == FLOW_SETTINGS) {
    if (displayModeButtonHit(mouseX, mouseY)) {
      playUiClick();
      applyDisplayMode(!settingsFullscreen);
      return;
    }
    float barX = width * 0.5f - settingsBarW * 0.5f;
    if (mouseY >= settingsSfxBarY - 10 && mouseY <= settingsSfxBarY + settingsBarH + 10
        && mouseX >= barX - 8 && mouseX <= barX + settingsBarW + 8) {
      playUiClick();
      settingsDraggingSfx = true;
      settingsSfxVol = volumeFromBarX(mouseX, barX);
      applyAudioVolumes();
    }
    if (mouseY >= settingsMusicBarY - 10 && mouseY <= settingsMusicBarY + settingsBarH + 10
        && mouseX >= barX - 8 && mouseX <= barX + settingsBarW + 8) {
      playUiClick();
      settingsDraggingMusic = true;
      settingsMusicVol = volumeFromBarX(mouseX, barX);
      applyAudioVolumes();
    }
    return;
  }
  if (gameFlow == FLOW_CONTROLS) {
    playUiClick();
    beginPlaySession();
    return;
  }
  if (gameFlow == FLOW_PLAY) {
    if (gamePaused && !finished) {
      if (pauseButtonHit(mouseX, mouseY, pauseContinueBtnX, pauseContinueBtnY)) {
        playUiClick();
        setGamePaused(false);
        return;
      }
      if (pauseButtonHit(mouseX, mouseY, pauseMenuBtnX, pauseMenuBtnY)) {
        playUiClick();
        returnToTitleFromPause();
        return;
      }
      return;
    }
    if (showControlsOverlay) {
      playUiClick();
      showControlsOverlay = false;
      return;
    }
    if (mouseButton == LEFT && controlsHudButtonHit(mouseX, mouseY)) {
      playUiClick();
      showControlsOverlay = true;
      shooting = false;
      return;
    }
    if (mouseButton == LEFT) shooting = true;
  }
}

void mouseReleased() {
  if (mouseButton == LEFT) shooting = false;
  if (settingsDraggingSfx || settingsDraggingMusic) {
    settingsDraggingSfx = false;
    settingsDraggingMusic = false;
    saveProgression();
  }
}

void mouseDragged() {
  if (gameFlow == FLOW_SETTINGS) {
    updateSettingsFromMouse(mouseX, mouseY);
    return;
  }
  if (mouseButton == RIGHT) {
    float dx = mouseX - pmouseX;
    float dy = mouseY - pmouseY;
    camYaw -= dx * 0.008;
    camPitch -= dy * 0.005;
    camPitch = constrain(camPitch, 0.45, 1.12);
  }
}

void mouseWheel(MouseEvent e) {
  float scroll = e.getCount();
  camDist += scroll * 60;
  camDist = constrain(camDist, camDistMin, camDistMax);
}

void returnToTitleFromPause() {
  gamePaused = false;
  shooting = false;
  saveProgression();
  stopMusic();
  gameFlow = FLOW_TITLE;
  startMenuMusic();
}

boolean pauseButtonHit(float mx, float my, float bx, float by) {
  return mx >= bx && mx <= bx + pauseBtnW && my >= by && my <= by + pauseBtnH;
}

void drawPauseOverlay() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noStroke();
  fill(0, 0, 0, 200);
  rect(0, 0, width, height);
  fill(40, 18, 8, 90);
  rect(0, 0, width, height * 0.22f);
  rect(0, height * 0.78f, width, height * 0.22f);

  float cx = width * 0.5f;
  float panelW = min(width - 56, 500);
  float panelH = 340;
  float px = (width - panelW) * 0.5f;
  float py = (height - panelH) * 0.5f;
  drawWesternPanel(px, py, panelW, panelH, 16);

  stroke(190, 140, 65, 200);
  strokeWeight(2);
  float ruleY = py + 78;
  line(px + 36, ruleY, px + panelW - 36, ruleY);
  noStroke();

  textFontDisplay();
  textAlign(CENTER, CENTER);
  fill(255, 242, 175);
  textSize(46);
  text("PAUSED", cx, py + 46);

  textFontBody();
  textSize(15);
  fill(220, 200, 168);
  if (player != null && gameFlow == FLOW_PLAY) {
    float timeLeft = max(0, gameDurationSec + extraTimeSec - gameElapsedSec());
    text("Wave " + currentWave + "  ·  Score " + score + "  ·  Kills " + kills
      + "  ·  " + nf(timeLeft, 0, 0) + "s left", cx, py + 102);
  } else {
    text("Take a breath, partner", cx, py + 102);
  }

  textSize(13);
  fill(175, 155, 130);
  text("ESC or P — resume", cx, py + 128);

  pauseContinueBtnX = cx - pauseBtnW * 0.5f;
  pauseContinueBtnY = py + 158;
  pauseMenuBtnX = pauseContinueBtnX;
  pauseMenuBtnY = py + 222;
  boolean contHot = pauseButtonHit(mouseX, mouseY, pauseContinueBtnX, pauseContinueBtnY);
  boolean menuHot = pauseButtonHit(mouseX, mouseY, pauseMenuBtnX, pauseMenuBtnY);
  drawPauseMenuButton(pauseContinueBtnX, pauseContinueBtnY, "CONTINUE", contHot);
  drawPauseMenuButton(pauseMenuBtnX, pauseMenuBtnY, "MAIN MENU", menuHot);
  reset2DDrawState();
}

void drawPauseMenuButton(float bx, float by, String label, boolean hot) {
  noStroke();
  fill(32, 18, 10, hot ? 225 : 185);
  rect(bx, by, pauseBtnW, pauseBtnH, 8);
  stroke(200, 145, 70, hot ? 255 : 200);
  strokeWeight(2);
  noFill();
  rect(bx + 1, by + 1, pauseBtnW - 2, pauseBtnH - 2, 7);
  noStroke();
  textAlign(CENTER, CENTER);
  textFontDisplay();
  textSize(20);
  fill(255, 248, 220, hot ? 255 : 235);
  text(label, bx + pauseBtnW * 0.5f, by + pauseBtnH * 0.52f);
}

void drawWeaponUnlockBanner2D() {
  if (weaponUnlockBannerTimer <= 0 || weaponUnlockBannerText.length() == 0) return;
  float u = constrain(weaponUnlockBannerTimer / 3.5f, 0, 1);
  int a = (int)(255 * min(1, u * 2.2f));
  textFontDisplay();
  textAlign(CENTER, CENTER);
  textSize(28);
  fill(0, 0, 0, a * 0.6f);
  text(weaponUnlockBannerText, width * 0.5f + 2, height * 0.2f + 2);
  fill(255, 220, 120, a);
  text(weaponUnlockBannerText, width * 0.5f, height * 0.2f);
}

void keyPressed() {
  if (gameFlow == FLOW_PLAY && !finished) {
    if (key == ESC || keyCode == ESC) {
      key = 0;
      setGamePaused(!gamePaused);
      return;
    }
    if (gamePaused) {
      if (key == 'p' || key == 'P' || key == '\n' || key == '\r') {
        setGamePaused(false);
      }
      return;
    }
  }
  if (gameFlow == FLOW_SETTINGS) {
    if (key == ESC || keyCode == ESC) {
      key = 0;
      gameFlow = FLOW_TITLE;
      saveProgression();
      return;
    }
    float step = 0.04f;
    if (keyCode == LEFT) {
      if (keyEvent.isShiftDown()) settingsMusicVol = max(0, settingsMusicVol - step);
      else settingsSfxVol = max(0, settingsSfxVol - step);
      applyAudioVolumes();
      return;
    }
    if (keyCode == RIGHT) {
      if (keyEvent.isShiftDown()) settingsMusicVol = min(1, settingsMusicVol + step);
      else settingsSfxVol = min(1, settingsSfxVol + step);
      applyAudioVolumes();
      return;
    }
  }
  if (key == 'w' || key == 'W') moveW = true;
  if (key == 'a' || key == 'A') moveA = true;
  if (key == 's' || key == 'S') moveS = true;
  if (key == 'd' || key == 'D') moveD = true;

  if (key == 'q' || key == 'Q') {
    finished = true;
    gameStateText = "QUIT";
    stopMusic();
  }
  if (key == 'r' || key == 'R') {
    if (finished) {
      beginPlaySession();
    } else if (gameFlow == FLOW_PLAY && !showControlsOverlay && !gamePaused) {
      player.startReload();
    }
  }
  if (key == 'h' || key == 'H') {
    if (gameFlow == FLOW_PLAY && !finished && !gamePaused) {
      showControlsOverlay = !showControlsOverlay;
      if (showControlsOverlay) shooting = false;
    }
  }
  if (!finished && gameFlow == FLOW_PLAY && !showControlsOverlay && !gamePaused) {
    if (key == '1') player.setWeaponSlot(0);
    if (key == '2') player.setWeaponSlot(1);
    if (key == '3') player.setWeaponSlot(2);
    if (key == ' ' && waveState == WAVE_STATE_BREAK) waveBreakTimer = 0;
    if (key == 't' || key == 'T') forceCompleteCurrentWave();
  }
  if (key == CODED && keyCode == SHIFT) sprintHeld = true;
}

void keyReleased() {
  if (key == 'w' || key == 'W') moveW = false;
  if (key == 'a' || key == 'A') moveA = false;
  if (key == 's' || key == 'S') moveS = false;
  if (key == 'd' || key == 'D') moveD = false;
  if (key == CODED && keyCode == SHIFT) sprintHeld = false;
}

// === Game state ===

/** Test key [T]: instantly end the current wave (clears spawns + living bandits). */
void forceCompleteCurrentWave() {
  if (finished || gameFlow != FLOW_PLAY || waveState != WAVE_STATE_FIGHT) return;

  pendingBanditSpawns.clear();
  waveSpawning = false;
  wavePreviewTimer = 0;
  staggerSpawnTimer = 0;

  for (Bandit b : bandits) {
    b.alive = false;
    b.hp = 0;
  }

  if (!endlessMode && currentWave >= STORY_MAX_WAVES) {
    finished = true;
    gameStateText = "YOU WIN";
    playWavSafe("win.wav");
    return;
  }

  waveState = WAVE_STATE_BREAK;
  waveBreakTimer = WAVE_BREAK_DURATION;
  extraTimeSec += 18;
  score += 50 * currentWave;
  playWavSafe("wave_clear.wav");
}

void updateGameState(float t) {
  if (finished) return;

  float remaining = max(0, gameDurationSec + extraTimeSec - t);
  if (remaining <= 0) {
    finished = true;
    gameStateText = "TIME OVER";
    playWavSafe("lose.wav");
    return;
  }

  if (player.hp <= 0) {
    if (!playerGoreSpawned) {
      playerGoreSpawned = true;
      spawnPlayerGore(player.pos.x, player.pos.z);
    }
    finished = true;
    gameStateText = "YOU LOST";
    playWavSafe("lose.wav");
    return;
  }

  if (waveState != WAVE_STATE_FIGHT) return;
  if (wavePreviewTimer > 0) return;
  if (waveSpawning || pendingBanditSpawns.size() > 0) return;

  int aliveCount = 0;
  for (Bandit b : bandits) {
    if (b.alive) aliveCount++;
  }
  if (aliveCount == 0 && bandits.size() > 0) {
    if (!endlessMode && currentWave >= STORY_MAX_WAVES) {
      finished = true;
      gameStateText = "YOU WIN";
      playWavSafe("win.wav");
    } else {
      waveState = WAVE_STATE_BREAK;
      waveBreakTimer = WAVE_BREAK_DURATION;
      extraTimeSec += 18;
      score += 50 * currentWave;
      playWavSafe("wave_clear.wav");
    }
  }
}

// === HUD / 2D overlays ===

void drawHealthBars(ArrayList<float[]> positions) {
  rectMode(CORNER);
  for (float[] p : positions) {
    float w = 58;
    float h = 8;
    float px = p[0] - w * 0.5;
    float py = p[1];
    noStroke();
    fill(0, 100);
    rect(px + 2, py + 2, w + 4, h + 4, 4);
    fill(28, 18, 12, 235);
    rect(px - 1, py - 1, w + 2, h + 2, 4);
    noFill();
    stroke(140, 95, 45, 200);
    strokeWeight(1);
    rect(px, py, w, h, 3);
    noStroke();
    fill(48, 30, 20);
    rect(px + 1, py + 1, w - 2, h - 2, 2);
    fill(220, 75, 55);
    rect(px + 2, py + 2, (w - 4) * p[2], h - 4, 2);
    fill(255, 200, 180, 90);
    rect(px + 2, py + 2, (w - 4) * p[2], max(1, (h - 4) * 0.35f), 2);
  }
}

void drawWesternPanel(float x, float y, float w, float h, float cornerR) {
  rectMode(CORNER);
  noStroke();
  fill(0, 70);
  rect(x + 5, y + 6, w, h, cornerR);
  fill(20, 12, 7, 248);
  rect(x, y, w, h, cornerR);
  fill(52, 34, 18, 115);
  rect(x, y, w, min(36, h * 0.42f), cornerR);
  fill(0, 100);
  rect(x + 4, y + h - 5, w - 8, 3, 2);
  noFill();
  stroke(85, 52, 24, 255);
  strokeWeight(1);
  rect(x + 3, y + 3, w - 6, h - 6, max(2, cornerR - 2));
  stroke(235, 195, 105, 210);
  strokeWeight(2);
  rect(x, y, w, h, cornerR);
  stroke(255, 250, 230, 55);
  strokeWeight(1);
  rect(x + 1, y + 1, w - 2, h - 2, max(1, cornerR - 1));
  noStroke();
}

void drawHudLabelShadow(String s, float x, float y, int col) {
  textFontBody();
  textAlign(LEFT, TOP);
  fill(0, 130);
  text(s, x + 1, y + 1);
  fill(col);
  text(s, x, y);
}

/** Left bounty panel — full labels, sized to Sancreek metrics. */
void drawLeftBountyHud(float lx, float ly) {
  textFontBody();
  float padX = 16;
  float padY = 12;
  float lineGap = 7;
  float pw = HUD_LEFT_PANEL_W;

  textAlign(LEFT, TOP);
  textSize(15);
  textLeading(18);
  float h0 = textAscent() + textDescent() + lineGap;
  textSize(19);
  textLeading(22);
  float h1 = textAscent() + textDescent() + lineGap;
  textSize(15);
  textLeading(18);
  float h2 = textAscent() + textDescent();
  float ph = padY * 2 + h0 + h1 * 4 + h2;

  drawWesternPanel(lx, ly, pw, ph, 9);

  String waveLine = endlessMode
    ? ("Wave  " + currentWave)
    : ("Wave  " + currentWave + " / " + STORY_MAX_WAVES);
  String modeHud = endlessMode ? "Mode  Endless" : "Mode  Bounty";
  float y = ly + padY;
  fill(200, 155, 75);
  textSize(15);
  textLeading(18);
  text("◆ BOUNTY", lx + padX, y);
  y += h0;
  textSize(19);
  textLeading(22);
  drawHudLabelShadow(waveLine, lx + padX, y, color(255, 238, 210));
  y += h1;
  drawHudLabelShadow("Score  " + score, lx + padX, y, color(235, 220, 198));
  y += h1;
  drawHudLabelShadow("Kills  " + kills, lx + padX, y, color(220, 205, 185));
  y += h1;
  drawHudLabelShadow(modeHud, lx + padX, y, color(200, 175, 130));
  y += h1;
  textSize(15);
  textLeading(18);
  fill(175, 155, 130);
  text("Best run  " + progressionHighScore, lx + padX, y);
}

/** Bottom-right weapon + ammo stack (avoids overlapping anchors). */
void drawRightWeaponAmmoHud(float hpBarY) {
  float x = width - 14;
  float y = hpBarY - 6;
  int slot = player.weaponSlot;
  textAlign(RIGHT, BOTTOM);

  if (player.reloading) {
    textFontDisplay();
    textSize(24);
    fill(120, 200, 255);
    text("RELOAD…", x, y);
    y -= textAscent() + textDescent() + 7;
    textFontDisplay();
    textSize(18);
    fill(200, 155, 75);
    text(player.weaponName().toUpperCase(), x, y);
    return;
  }

  textFontDisplay();
  textSize(50);
  String ams = str(player.wAmmo[slot]) + " / " + str(player.wMax[slot]);
  int amCol = player.wAmmo[slot] <= 0 ? color(255, 150, 110) : color(255, 245, 228);
  fill(0, 120);
  text(ams, x + 1, y + 1);
  fill(amCol);
  text(ams, x, y);
  y -= textAscent() + textDescent() + 5;

  if (!finished && player.wAmmo[slot] > 0 && player.wAmmo[slot] <= 5) {
    textFontBody();
    textSize(13);
    fill(255, 200, 70, 240);
    text("LOW AMMO", x, y);
    y -= textAscent() + textDescent() + 7;
  }

  if (!endlessMode) {
    textFontBody();
    textSize(12);
    textLeading(14);
    fill(160, 140, 120);
    if (!player.isWeaponUnlocked(1)) {
      text("[2] Shotgun — wave " + UNLOCK_SHOTGUN_WAVE, x, y);
      y -= textAscent() + textDescent() + 3;
    } else if (!player.isWeaponUnlocked(2)) {
      text("[3] Repeater — wave " + UNLOCK_REPEATER_WAVE, x, y);
      y -= textAscent() + textDescent() + 3;
    }
  }

  textFontDisplay();
  textSize(19);
  fill(200, 155, 75);
  text(player.weaponName().toUpperCase(), x, y);
}

void drawRulesPanel2D() {
  rectMode(CORNER);
  float panelW = min(width - 36, 920);
  float panelH = 82;
  float panelX = (width - panelW) * 0.5;
  float panelY = 108;

  drawWesternPanel(panelX, panelY, panelW, panelH, 8);

  stroke(160, 110, 50, 140);
  strokeWeight(1);
  int rivets = max(5, (int)(panelW / 130));
  for (int ri = 0; ri <= rivets; ri++) {
    float u = panelX + 18 + ri * (panelW - 36) / (float) rivets;
    fill(90, 62, 30, 210);
    ellipse(u, panelY + panelH * 0.5, 5, 5);
    fill(200, 165, 85, 170);
    ellipse(u - 0.5, panelY + panelH * 0.5 - 0.5, 2, 2);
  }
  noStroke();

  textAlign(CENTER, TOP);
  textFontBody();
  textSize(9);
  textLeading(12);
  String line1 =
    "WASD · shoot · 1/2/3 · Shift sprint · R reload · RMB camera · wheel zoom";
  String line2 = endlessMode
    ? "Endless · ESC pause · SPACE skip break · Q quit"
    : STORY_MAX_WAVES + " waves · ESC pause · SPACE skip · Q quit";
  float cx = panelX + panelW * 0.5;
  float ty = panelY + 10;
  fill(0, 85);
  text(line1, cx + 1, ty + 1);
  text(line2, cx + 1, ty + 1 + 13);
  fill(248, 215, 125);
  text(line1, cx, ty);
  text(line2, cx, ty + 13);
}

void drawHudBar(float x, float y, float w, float h, float ratio, int colTrack, int colFill, int colBorder) {
  ratio = constrain(ratio, 0, 1);
  rectMode(CORNER);
  noStroke();
  fill(colTrack);
  rect(x, y, w, h, 5);
  fill(0, 70);
  rect(x + 2, y + 2, w - 4, h - 4, 4);
  float innerH = h - 5;
  float fw = (w - 5) * ratio;
  if (fw > 0.5) {
    fill(colFill);
    rect(x + 2.5f, y + 2.5f, fw, innerH, 3);
    fill(255, 55);
    rect(x + 2.5f, y + 2.5f, fw, max(2, innerH * 0.4f), 3);
    fill(0, 45);
    rect(x + 2.5f, y + 2.5f + innerH * 0.58f, fw, max(1, innerH * 0.38f), 2);
  }
  noFill();
  stroke(colBorder);
  strokeWeight(1.5);
  rect(x, y, w, h, 5);
  stroke(255, 238, 200, 75);
  strokeWeight(0.9);
  rect(x + 1, y + 1, w - 2, h - 2, 4);
  noStroke();
}

/** Readable player resource bar: ticks, gloss sweep, optional low pulse. */
void drawHudResourceBar(float x, float y, float w, float h, float ratio,
  int colFill, int colTrack, int colBorder, float gameT, boolean pulseCritical, int majorTicks) {
  ratio = constrain(ratio, 0, 1);
  rectMode(CORNER);
  noStroke();
  fill(red(colTrack) * 0.45, green(colTrack) * 0.45, blue(colTrack) * 0.45);
  rect(x - 2, y - 2, w + 4, h + 4, 8);
  fill(colTrack);
  rect(x, y, w, h, 6);
  fill(0, 95);
  rect(x + 3, y + 3, w - 6, h - 6, 5);
  float inset = 5;
  float innerW = w - inset * 2;
  float innerH = h - inset * 2;
  float fw = innerW * ratio;
  if (fw > 1.2) {
    fill(colFill);
    rect(x + inset, y + inset, fw, innerH, 4);
    fill(255, 85);
    rect(x + inset, y + inset, fw, max(3, innerH * 0.36f), 4);
    fill(0, 55);
    rect(x + inset, y + inset + innerH * 0.55f, fw, max(2, innerH * 0.4f), 3);
    if (fw > 14) {
      float gw = max(5, fw * 0.13f);
      float gx = x + inset + fw * (0.55f + 0.35f * (0.5f + 0.5f * sin(gameT * 3.2f))) - gw * 0.5f;
      gx = constrain(gx, x + inset + 1, x + inset + fw - gw - 1);
      fill(255, 45);
      rect(gx, y + inset + 1, gw, innerH - 2, 2);
    }
  }
  stroke(0, 110);
  strokeWeight(1);
  for (int i = 1; i < majorTicks; i++) {
    float tx = x + inset + innerW * i / (float) majorTicks;
    line(tx, y + 4, tx, y + h - 4);
  }
  noStroke();
  stroke(colBorder);
  strokeWeight(2);
  noFill();
  rect(x, y, w, h, 6);
  stroke(255, 248, 220, 90);
  strokeWeight(1);
  rect(x + 1, y + 1, w - 2, h - 2, 5);
  noStroke();
  if (pulseCritical) {
    float e = 0.5f + 0.5f * sin(gameT * 10);
    stroke(255, 95, 75, 80 + 120 * e);
    strokeWeight(2);
    noFill();
    rect(x - 3, y - 3, w + 6, h + 6, 9);
    noStroke();
  }
}

void drawGameOverOverlay(float t) {
  boolean isWin = gameStateText.equals("YOU WIN");
  boolean isLoss = gameStateText.equals("YOU LOST") || gameStateText.equals("TIME OVER");

  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noStroke();
  fill(0, 0, 0, isLoss ? 215 : 195);
  rect(0, 0, width, height);
  if (isLoss) {
    fill(72, 16, 10, 95);
    rect(0, 0, width, height);
    fill(40, 8, 5, 80);
    rect(0, height * 0.65f, width, height * 0.35f);
  } else if (isWin) {
    fill(28, 38, 18, 70);
    rect(0, 0, width, height);
  }

  float cx = width * 0.5f;
  float panelW = min(width - 52, 560);
  float panelH = isWin ? 318 : 336;
  float px = (width - panelW) * 0.5f;
  float py = (height - panelH) * 0.5f;
  drawWesternPanel(px, py, panelW, panelH, 16);

  stroke(isLoss ? color(160, 55, 40, 220) : color(190, 140, 65, 220));
  strokeWeight(2);
  float ruleY = py + 82;
  line(px + 40, ruleY, px + panelW - 40, ruleY);
  noStroke();

  textFontDisplay();
  textAlign(CENTER, CENTER);
  textSize(isLoss ? 48 : 50);
  fill(0, 120);
  text(gameStateText, cx + 2, py + 48);
  fill(isLoss ? color(255, 118, 88) : color(255, 242, 175));
  text(gameStateText, cx, py + 46);

  textFontBody();
  textSize(16);
  fill(isLoss ? color(220, 175, 155) : color(215, 200, 175));
  String sub;
  if (gameStateText.equals("YOU LOST")) sub = "The desert got the better of you, partner.";
  else if (gameStateText.equals("TIME OVER")) sub = "Sun went down — time's up.";
  else if (isWin) sub = endlessMode ? "You outlasted the frontier." : "All " + STORY_MAX_WAVES + " waves cleared.";
  else sub = "Ride on.";
  text(sub, cx, py + 108);

  textSize(14);
  fill(200, 180, 155);
  text("Wave " + currentWave + "  ·  Score " + score + "  ·  Kills " + kills, cx, py + 136);

  stroke(140, 95, 50, 120);
  strokeWeight(1);
  line(px + 48, py + 158, px + panelW - 48, py + 158);
  noStroke();

  textSize(15);
  fill(185, 168, 145);
  text("Best run  " + progressionHighScore + "     Lifetime kills  " + progressionTotalKills, cx, py + 182);

  textSize(16);
  fill(255, 235, 200);
  text("R — play again", cx, py + 228);
  textSize(14);
  fill(175, 155, 130);
  text("Q — quit to title (saves progress)", cx, py + 254);

  reset2DDrawState();
}

void drawTimeHud(float remaining, float timeBudget, float timeRatio, float t) {
  float tw = 198;
  float th = 68;
  float rx = width - tw - 12;
  float ry = 12;
  boolean urgent = remaining <= 35 && !finished;
  float pulse = urgent ? 0.82f + 0.18f * sin(t * 7.5f) : 1;

  drawWesternPanel(rx, ry, tw, th, 10);
  textFontDisplay();
  textAlign(LEFT, TOP);
  textSize(12);
  fill(200, 155, 75);
  text("TIME", rx + 14, ry + 10);

  int totalSec = max(0, (int)ceil(remaining));
  int mm = totalSec / 60;
  int ss = totalSec % 60;
  String clock = nf(mm, 1) + ":" + nf(ss, 2);

  textAlign(RIGHT, TOP);
  textSize(36);
  fill(0, 100);
  text(clock, rx + tw - 14, ry + 7);
  fill(urgent ? color(255, 130, 95, 255 * pulse) : color(255, 248, 235));
  text(clock, rx + tw - 15, ry + 6);

  int barCol = urgent ? color(235, 95, 55) : color(95, 175, 235);
  drawHudBar(rx + 14, ry + th - 14, tw - 28, 8, timeRatio,
    color(32, 20, 14), barCol, color(175, 125, 55));
}

/** Western HUD panels. */
void drawHudDistributed(float t) {
  textFontBody();
  rectMode(CORNER);
  float remaining = max(0, gameDurationSec + extraTimeSec - t);
  float timeBudget = max(1, gameDurationSec + extraTimeSec);
  float timeRatio = remaining / timeBudget;

  drawLeftBountyHud(14, 12);
  drawTimeHud(remaining, timeBudget, timeRatio, t);

  float hpBarH = 26;
  float hpBarY = height - hpBarH;
  float hpR = max(0, player.hp / player.maxHp);
  int hpCol = lerpColor(color(210, 55, 48), color(72, 220, 118), hpR);
  boolean hpCrit = hpR <= 0.25 && player.hp > 0;
  drawHudResourceBar(0, hpBarY, width, hpBarH, hpR,
    hpCol, color(18, 10, 7), color(175, 120, 55), t, hpCrit, 24);
  textFontBody();
  textAlign(LEFT, CENTER);
  textSize(10);
  fill(255, 220, 185);
  text((int)player.hp + "/" + (int)player.maxHp, 12, hpBarY + hpBarH * 0.52);

  drawRightWeaponAmmoHud(hpBarY);

  if (finished) drawGameOverOverlay(t);
}

/** Reload progress bar at player feet (compact — no large panel). */
void drawPlayerReloadBarScreen() {
  if (!player.reloading) return;
  float rd = player.wReloadSec[player.weaponSlot];
  float prog = 1.0 - constrain(player.reloadTimer / rd, 0, 1);
  float bw = 148;
  float bh = 12;
  float cx = constrain(playerScreenFootX, bw * 0.5f + 16, width - bw * 0.5f - 16);
  float cy = constrain(playerScreenFootY + 24, 100, height - 120);
  float left = cx - bw * 0.5;
  float top = cy - 10;
  rectMode(CORNER);
  noStroke();
  fill(14, 10, 7, 210);
  rect(left - 4, top - 14, bw + 8, bh + 22, 5);
  textFontDisplay();
  textAlign(CENTER, BOTTOM);
  textSize(10);
  fill(255, 235, 200);
  text("RELOAD", cx, top - 2);
  drawHudBar(left, top + 4, bw, bh, prog, color(32, 22, 16), color(95, 205, 255), color(190, 145, 65));
  reset2DDrawState();
}

/** Empty mag reminder. */
void drawReloadNeededFeedback(float gameT) {
  if (finished || player.reloading || waveState == WAVE_STATE_BREAK) return;
  if (player.wAmmo[player.weaponSlot] > 0) return;
  float pulse = 0.5 + 0.5 * sin(gameT * 11);
  rectMode(CORNER);
  float bw = min(560, width - 48);
  float bh = 62;
  float bx = (width - bw) * 0.5;
  float by = height * 0.26;
  noStroke();
  fill(75, 28, 22, (int)(155 + 70 * pulse));
  rect(bx, by, bw, bh, 10);
  noFill();
  stroke(255, 210, 100, (int)(160 + 95 * pulse));
  strokeWeight(2.5 + pulse);
  rect(bx, by, bw, bh, 10);
  noStroke();
  textAlign(CENTER, CENTER);
  textFontDisplay();
  textSize(21);
  fill(0, 140);
  text("OUT OF AMMO  —  RELOAD [ R ]", width * 0.5 + 2, by + bh * 0.5 + 2);
  fill(255, 245, 220);
  text("OUT OF AMMO  —  RELOAD [ R ]", width * 0.5, by + bh * 0.5);
  textFontBody();
  textSize(13);
  fill(255, 220, 180, 220);
  text("You cannot fire until you reload.", width * 0.5, by + bh - 14);
}

void drawSpawnPreview2D(float t) {
  if (wavePreviewTimer <= 0) return;
  textFontDisplay();
  textAlign(CENTER, TOP);
  textSize(22);
  fill(0, 0, 0, 160);
  text("INCOMING  ·  " + str(max(1, (int)ceil(wavePreviewTimer))) + "s",
    width * 0.5f + 2, height * 0.12f + 2);
  fill(255, 220, 170, 235);
  text("INCOMING  ·  " + str(max(1, (int)ceil(wavePreviewTimer))) + "s", width * 0.5f, height * 0.12f);
}

void drawWaveBanner2D() {
  if (waveBannerTimer <= 0) return;
  float u = constrain(waveBannerTimer / WAVE_BANNER_DURATION, 0, 1);
  float enter = min(1, (1 - u) * 5.5f);
  float exitFade = u < 0.2f ? u / 0.2f : 1;
  int alpha = (int)(255 * enter * exitFade);
  if (alpha < 4) return;
  textFontDisplay();
  float cx = width * 0.5f;
  float cy = height * 0.34f;
  float scale = 1.0f + 0.12f * sin((1 - u) * PI);
  pushMatrix();
  translate(cx, cy);
  scale(scale);
  textAlign(CENTER, CENTER);
  textSize(72);
  fill(0, 0, 0, alpha / 2);
  text("WAVE " + waveBannerNumber, 4, 6);
  fill(255, 215, 120, alpha);
  text("WAVE " + waveBannerNumber, 0, 0);
  if (waveBannerTimer > WAVE_BANNER_DURATION * 0.45f) {
    textSize(36);
    fill(0, 0, 0, alpha / 2);
    text("DRAW!", 3, 58);
    fill(255, 80, 60, alpha);
    text("DRAW!", 0, 52);
  }
  popMatrix();
  noStroke();
  float barW = min(420, width * 0.55f);
  fill(120, 40, 30, alpha / 3);
  rect(cx - barW * 0.5f, cy + 72, barW, 4, 2);
}

void updateAndDrawShellCasings(float dt) {
  for (int i = shellCasings.size() - 1; i >= 0; i--) {
    ShellCasing sc = shellCasings.get(i);
    sc.update(dt);
    sc.display();
    if (sc.life <= 0) shellCasings.remove(i);
  }
}

/** Wave break — centered chip between left/right HUD (no full-width top bar). */
void drawWaveIntermissionOverlay(float gameT) {
  if (finished || waveState != WAVE_STATE_BREAK) return;
  rectMode(CORNER);
  noStroke();
  float prog = constrain(waveBreakTimer / WAVE_BREAK_DURATION, 0, 1);

  final float leftHudW = HUD_LEFT_PANEL_W;
  final float rightHudW = 198;
  final float hudPad = 14;
  float macHudDrop = PApplet.platform == PConstants.MACOS ? 22 : 10;
  float leftEnd = hudPad + leftHudW + 16;
  float rightStart = width - hudPad - rightHudW - 16;
  float chipW = rightStart - leftEnd - 20;
  float chipH = 36;
  float chipY = 14 + macHudDrop;
  if (chipW < 240) {
    chipW = min(400, width - 56);
    chipY = 118 + macHudDrop;
  } else {
    chipW = constrain(chipW, 260, 440);
  }
  float chipX = width * 0.5f - chipW * 0.5f;

  drawWesternPanel(chipX, chipY, chipW, chipH, 8);
  drawHudBar(chipX + 12, chipY + chipH - 11, chipW - 24, 6, prog,
    color(35, 22, 16), color(120, 185, 235), color(175, 125, 55));

  textFontBody();
  textAlign(CENTER, CENTER);
  textSize(13);
  String line = "Wave break  ·  " + str(max(0, (int)ceil(waveBreakTimer))) + "s  ·  [SPACE] skip";
  fill(0, 120);
  text(line, chipX + chipW * 0.5f + 1, chipY + chipH * 0.42f);
  fill(255, 238, 205);
  text(line, chipX + chipW * 0.5f, chipY + chipH * 0.41f);
}

/** Hit feedback: red vignette from screen edges (no full-screen SCREEN blend). */
void drawHurtFeedbackOverlay() {
  float ring = hurtRing;
  if (ring < 0.02) return;
  rectMode(CORNER);
  noStroke();
  blendMode(BLEND);
  float edgeW = max(48, min(width, height) * 0.14f * (0.55f + ring * 0.85f));
  int steps = 12;
  for (int i = 0; i < steps; i++) {
    float t0 = (float)i / steps;
    float t1 = (float)(i + 1) / steps;
    int a = (int)(ring * 185 * (1 - (t0 + t1) * 0.5f));
    if (a < 2) continue;
    float band = edgeW * (t1 - t0);
    fill(180, 20, 25, a);
    rect(0, edgeW * t0, width, band);
    rect(0, height - edgeW * t1, width, band);
    rect(edgeW * t0, 0, band, height);
    rect(width - edgeW * t1, 0, band, height);
  }
}

// === Environment ===

float getSkyRadius() {
  return max(arenaHalfW, arenaHalfH) * 2.9f;
}

/**
 * Arena floor — Processing P3D ground recipe: translate + rotateX(HALF_PI) + textureMode(IMAGE).
 * Direct XZ quads were back-face culled (flat background color, no texture).
 */
void drawTexturedGroundPlane(float cx, float cz, float w, float h, float y, int tilesX, int tilesZ) {
  if (texGround == null) return;

  pushMatrix();
  translate(cx, y, cz);
  rotateX(HALF_PI);

  float hw = w * 0.5f;
  float hh = h * 0.5f;
  float tileW = w / tilesX;
  float tileH = h / tilesZ;
  int tw = texGround.width;
  int th = texGround.height;

  noStroke();
  noTint();
  fill(255);
  emissive(0, 0, 0);
  textureMode(IMAGE);

  for (int ix = 0; ix < tilesX; ix++) {
    for (int iz = 0; iz < tilesZ; iz++) {
      float x0 = -hw + ix * tileW;
      float x1 = x0 + tileW;
      float y0 = -hh + iz * tileH;
      float y1 = y0 + tileH;
      beginShape(QUADS);
      texture(texGround);
      vertex(x0, y0, 0, 0, 0);
      vertex(x1, y0, 0, tw, 0);
      vertex(x1, y1, 0, tw, th);
      vertex(x0, y1, 0, 0, th);
      endShape();
    }
  }

  noTexture();
  textureMode(NORMAL);
  popMatrix();
}

/**
 * Inward-facing cubemap face. Side walls end at GROUND_Y so skybox “dirt” does not
 * sit below the arena floor (fixes floating-platform look).
 */
void drawSkyboxFace(PImage tex, float s, int face) {
  if (tex == null || face == 2) return;
  int w = tex.width;
  int h = tex.height;
  float vH = h * SKYBOX_HORIZON_UV;
  float gY = GROUND_Y;
  beginShape(QUADS);
  texture(tex);
  textureMode(IMAGE);
  switch (face) {
    case 0: // +X right
      vertex( s, -s,  s, 0, 0);
      vertex( s, -s, -s, w, 0);
      vertex( s, gY, -s, w, vH);
      vertex( s, gY,  s, 0, vH);
      break;
    case 1: // -X left
      vertex(-s, -s, -s, 0, 0);
      vertex(-s, -s,  s, w, 0);
      vertex(-s, gY,  s, w, vH);
      vertex(-s, gY, -s, 0, vH);
      break;
    case 2: // +Y down — skip (arena ground is the floor)
      break;
    case 3: // -Y up (zenith)
      vertex(-s, -s,  s, 0, 0);
      vertex(-s, -s, -s, w, 0);
      vertex( s, -s, -s, w, h);
      vertex( s, -s,  s, 0, h);
      break;
    case 4: // +Z
      vertex(-s, -s,  s, 0, 0);
      vertex( s, -s,  s, w, 0);
      vertex( s, gY,  s, w, vH);
      vertex(-s, gY,  s, 0, vH);
      break;
    case 5: // -Z
      vertex( s, -s, -s, 0, 0);
      vertex(-s, -s, -s, w, 0);
      vertex(-s, gY, -s, w, vH);
      vertex( s, gY, -s, 0, vH);
      break;
  }
  endShape();
}

/** Skybox centered on player — textures/sky_cubemap/ (6 files or one cross PNG). */
void drawSkyCubemap(float halfSize) {
  float s = halfSize;
  fill(255);
  emissive(0, 0, 0);
  drawSkyboxFace(skyCubemap[3], s, 3);
  for (int f = 0; f < 6; f++) {
    if (f == 2 || f == 3) continue;
    drawSkyboxFace(skyCubemap[f], s, f);
  }
  noTexture();
  textureMode(NORMAL);
}

/** Sky dome around the arena — panorama wraps horizontally; image top = zenith, bottom = horizon. */
void drawTexturedSkyCylinder(PImage tex, float radius, float yBot, float yTop, int segs, int bands) {
  textureMode(IMAGE);
  int tw = tex.width;
  int th = tex.height;
  fill(255);
  emissive(0, 0, 0);
  for (int b = 0; b < bands; b++) {
    float f0 = (float) b / bands;
    float f1 = (float) (b + 1) / bands;
    float y0 = lerp(yBot, yTop, f0);
    float y1 = lerp(yBot, yTop, f1);
    float imgV0 = lerp(th, 0, f0);
    float imgV1 = lerp(th, 0, f1);
    for (int i = 0; i < segs; i++) {
      float a0 = TWO_PI * i / segs;
      float a1 = TWO_PI * (i + 1) / segs;
      float imgU0 = (float) i / segs * tw;
      float imgU1 = (float) (i + 1) / segs * tw;
      beginShape(QUADS);
      texture(tex);
      vertex(cos(a0) * radius, y0, sin(a0) * radius, imgU0, imgV0);
      vertex(cos(a1) * radius, y0, sin(a1) * radius, imgU1, imgV0);
      vertex(cos(a1) * radius, y1, sin(a1) * radius, imgU1, imgV1);
      vertex(cos(a0) * radius, y1, sin(a0) * radius, imgU0, imgV1);
      endShape();
    }
  }
  noTexture();
  textureMode(NORMAL);
}

int westernSkyColorAt(float u) {
  u = constrain(u, 0, 1);
  if (u < 0.2f) return lerpColor(color(255, 228, 175), color(255, 185, 105), u / 0.2f);
  if (u < 0.45f) return lerpColor(color(255, 185, 105), color(235, 130, 80), (u - 0.2f) / 0.25f);
  if (u < 0.68f) return lerpColor(color(235, 130, 80), color(175, 105, 115), (u - 0.45f) / 0.23f);
  return lerpColor(color(175, 105, 115), color(98, 118, 148), (u - 0.68f) / 0.32f);
}

void drawWesternSky(float t) {
  if (player == null) return;
  hint(DISABLE_DEPTH_TEST);
  noStroke();
  pushMatrix();
  translate(player.pos.x, 0, player.pos.z);

  float skyR = getSkyRadius();
  float horizonY = -22;
  float zenithY = -1200;

  if (skyCubemapReady) {
    drawSkyCubemap(skyR);
    hint(ENABLE_DEPTH_TEST);
    popMatrix();
    reset3DDrawState();
    return;
  }
  if (texSky != null) {
    drawTexturedSkyCylinder(texSky, skyR, horizonY, zenithY, 36, 10);
    hint(ENABLE_DEPTH_TEST);
    popMatrix();
    reset3DDrawState();
    return;
  }

  int segs = 28;
  int bands = 9;
  for (int b = 0; b < bands; b++) {
    float u0 = b / (float) bands;
    float u1 = (b + 1) / (float) bands;
    float y0 = lerp(horizonY, zenithY, u0);
    float y1 = lerp(horizonY, zenithY, u1);
    for (int i = 0; i < segs; i++) {
      float a0 = TWO_PI * i / segs;
      float a1 = TWO_PI * (i + 1) / segs;
      beginShape(QUADS);
      fill(westernSkyColorAt(u0));
      vertex(cos(a0) * skyR, y0, sin(a0) * skyR);
      vertex(cos(a1) * skyR, y0, sin(a1) * skyR);
      fill(westernSkyColorAt(u1));
      vertex(cos(a1) * skyR, y1, sin(a1) * skyR);
      vertex(cos(a0) * skyR, y1, sin(a0) * skyR);
      endShape(CLOSE);
    }
  }

  float sunAngle = 0.55f + sin(t * 0.04f) * 0.04f;
  float sunDist = skyR * 0.78f;
  float sunX = cos(sunAngle) * sunDist;
  float sunZ = sin(sunAngle) * sunDist;
  float sunY = horizonY + 28;
  fill(255, 160, 70, 35);
  ellipse(sunX, sunY, 340, 200);
  fill(255, 195, 95, 70);
  ellipse(sunX, sunY, 200, 120);
  fill(255, 225, 155, 200);
  ellipse(sunX, sunY, 95, 55);

  for (int c = 0; c < 7; c++) {
    float ca = c * 1.15f + t * 0.015f;
    float cx = cos(ca) * skyR * (0.35f + noise(c) * 0.25f);
    float cz = sin(ca) * skyR * (0.35f + noise(c + 3) * 0.25f);
    float cy = lerp(horizonY, zenithY, 0.42f + noise(c * 0.2) * 0.2f);
    float cw = 180 + noise(c, t * 0.03f) * 120;
    float ch = 28 + noise(c + 1) * 18;
    fill(255, 210, 175, 28 + (int)(noise(c * 0.7) * 22));
    ellipse(cx, cy, cw, ch);
    fill(255, 235, 210, 18);
    ellipse(cx + cw * 0.08f, cy - ch * 0.15f, cw * 0.55f, ch * 0.65f);
  }

  for (int h = 0; h < 3; h++) {
    float hy = horizonY + 8 + h * 14;
    fill(255, 200, 140, 22 - h * 5);
    beginShape(QUAD_STRIP);
    for (int i = 0; i <= segs; i++) {
      float a = TWO_PI * i / segs;
      float r = skyR * (0.92f - h * 0.04f);
      vertex(cos(a) * r, hy, sin(a) * r);
      vertex(cos(a) * r, hy + 35, sin(a) * r);
    }
    endShape();
  }

  hint(ENABLE_DEPTH_TEST);
  popMatrix();
  reset3DDrawState();
}

void drawDistantHorizon(float t) {
  if (player == null) return;
  if (hasCustomSky()) return;
  hint(DISABLE_DEPTH_TEST);
  noStroke();
  pushMatrix();
  translate(player.pos.x, 0, player.pos.z);
  float ringR = max(arenaHalfW, arenaHalfH) * 1.52f;

  fill(118, 78, 52, 200);
  beginShape(TRIANGLE_FAN);
  vertex(0, -16, 0);
  for (int i = 0; i <= 36; i++) {
    float a = TWO_PI * i / 36;
    float mesa = noise(i * 0.35, 1.2) > 0.62 ? 1.35f : 1.0f;
    float h = (28 + noise(i * 0.42, t * 0.04) * 48) * mesa;
    vertex(cos(a) * ringR, -16 - h, sin(a) * ringR);
  }
  endShape(CLOSE);

  fill(88, 55, 38, 210);
  beginShape(TRIANGLE_FAN);
  vertex(0, -14, 0);
  for (int i = 0; i <= 36; i++) {
    float a = TWO_PI * i / 36 + 0.08f;
    float h = 14 + noise(i * 0.5 + 20, t * 0.035) * 22;
    vertex(cos(a) * ringR * 0.94f, -14 - h, sin(a) * ringR * 0.94f);
  }
  endShape(CLOSE);

  fill(255, 210, 155, 45);
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= 40; i++) {
    float a = TWO_PI * i / 40;
    vertex(cos(a) * ringR * 0.98f, -8, sin(a) * ringR * 0.98f);
    vertex(cos(a) * ringR * 0.98f, 25, sin(a) * ringR * 0.98f);
  }
  endShape();

  hint(ENABLE_DEPTH_TEST);
  popMatrix();
  reset3DDrawState();
}

void drawWesternEnvironment(float t) {
  noStroke();
  reset3DDrawState();
  drawWesternSky(t);
  drawDistantHorizon(t);

  float skyR = getSkyRadius();
  float maxPlayerDist = sqrt(arenaHalfW * arenaHalfW + arenaHalfH * arenaHalfH);
  float groundHalf = maxPlayerDist + skyR * 1.08f;
  int groundTiles = max(14, (int)(groundHalf / 260f));
  drawTexturedGroundPlane(0, 0, groundHalf * 2f, groundHalf * 2f, GROUND_Y, groundTiles, groundTiles);

  drawAmbientLife(t);
  drawMapAmbience(t);

  drawSaloon(worldX(-560), worldZ(-220), t);
  drawSheriffOffice(worldX(560), worldZ(-190));
  drawBarn(worldX(-540), worldZ(250));
  drawWaterTower(worldX(520), worldZ(250));
  drawWagon(worldX(-150), worldZ(60));
  drawTrainCar(worldX(720), worldZ(30));

  drawRockCluster(worldX(-420), worldZ(-480), t, 1.1);
  drawRockCluster(worldX(520), worldZ(420), t, 0.85);
  drawRockCluster(worldX(-820), worldZ(380), t, 0.95);

  drawCactus(worldX(-130), worldZ(-380));
  drawCactus(worldX(160), worldZ(-310));
  drawCactus(worldX(180), worldZ(350));
  drawCactus(worldX(-220), worldZ(320));
  drawCactus(worldX(-680), worldZ(50));
  drawCactus(worldX(680), worldZ(-50));

  drawBarrel(worldX(-30), worldZ(-130));
  drawBarrel(worldX(30), worldZ(-150));
  drawBarrel(worldX(70), worldZ(120));
  drawBarrel(worldX(-380), worldZ(0));

  float fenceStep = 102;
  for (float x = -arenaHalfW; x <= arenaHalfW; x += fenceStep) {
    drawFencePost(x, -arenaHalfH - worldZ(50));
    drawFencePost(x, arenaHalfH + worldZ(50));
  }
  for (float z = -arenaHalfH; z <= arenaHalfH; z += fenceStep) {
    drawFencePost(-arenaHalfW - worldX(50), z);
    drawFencePost(arenaHalfW + worldX(50), z);
  }

  noTexture();
  textureMode(NORMAL);
}

/** Dust, brush shadow, rolling tumbleweed. */
void drawAmbientLife(float t) {
  /** Do not call randomSeed here — it was resetting global RNG every frame and broke loot rolls. */
  noStroke();
  for (int i = 0; i < 32; i++) {
    float nx = noise(i * 0.41 + 2.1, t * 0.07);
    float nz = noise(i * 0.37 + 50.3, t * 0.06);
    float ax = map(nx, 0, 1, -arenaHalfW * 0.92, arenaHalfW * 0.92);
    float az = map(nz, 0, 1, -arenaHalfH * 0.92, arenaHalfH * 0.92);
    float bob = sin(t * 1.4 + i * 0.55) * 1.2;
    pushMatrix();
    translate(ax, -3 + bob, az);
    fill(210, 185, 140, 55);
    sphere(1.8 + sin(t * 2 + i) * 0.4);
    popMatrix();
  }

  float twX = worldX(320) * sin(t * 0.11 + 0.3);
  float twZ = worldZ(380) * cos(t * 0.09);
  pushMatrix();
  translate(twX, -7, twZ);
  rotateY(t * 1.8);
  rotateZ(sin(t * 3) * 0.08);
  fill(100, 72, 42);
  box(20, 9, 20);
  fill(75, 52, 30);
  for (int k = -1; k <= 1; k++) {
    pushMatrix();
    translate(k * 7, 0, 0);
    box(4, 14, 4);
    popMatrix();
  }
  popMatrix();
}

/** Extra map motion: campfire, lanterns, birds, dust, swaying sign. */
void drawMapAmbience(float t) {
  noStroke();

  float salX = worldX(-560), salZ = worldZ(-220);
  pushMatrix();
  translate(salX + worldX(55), -8, salZ + worldZ(75));
  float flicker = 0.7f + 0.3f * noise(t * 4.2);
  emissive(255, 140, 60);
  fill(255, 120 + flicker * 80, 40, 200);
  sphere(6 + flicker * 2);
  fill(255, 200, 100, 90);
  translate(0, 8, 0);
  sphere(3 + flicker);
  emissive(0, 0, 0);
  popMatrix();

  float[][] lanterns = {
    {worldX(-560), worldZ(-220), worldX(90)},
    {worldX(560), worldZ(-190), worldX(85)},
    {worldX(-540), worldZ(250), worldX(70)}
  };
  for (int i = 0; i < lanterns.length; i++) {
    pushMatrix();
    translate(lanterns[i][0], -72, lanterns[i][1] + lanterns[i][2]);
    float glow = 0.65f + 0.35f * sin(t * 3.1 + i * 1.7);
    emissive(255, 200, 120);
    fill(255, 220, 150, 180 * glow);
    sphere(4);
    emissive(0, 0, 0);
    popMatrix();
  }

  for (int b = 0; b < 5; b++) {
    float bx = map(b, 0, 4, -arenaHalfW * 0.7f, arenaHalfW * 0.7f);
    float by = -55 + sin(t * 0.9 + b * 1.3) * 8;
    float bz = map(noise(b * 0.7, t * 0.05), 0, 1, -arenaHalfH * 0.6f, arenaHalfH * 0.6f);
    pushMatrix();
    translate(bx + sin(t * 1.2 + b) * 120, by, bz + cos(t * 0.8 + b) * 80);
    rotateY(t * 0.5 + b);
    fill(40, 35, 30, 160);
    box(2, 0.4, 5);
    popMatrix();
  }

  for (int d = 0; d < 6; d++) {
    float nx = noise(d * 2.1, t * 0.03);
    float nz = noise(d * 1.3 + 40, t * 0.025);
    float dx = map(nx, 0, 1, -arenaHalfW * 0.75f, arenaHalfW * 0.75f);
    float dz = map(nz, 0, 1, -arenaHalfH * 0.75f, arenaHalfH * 0.75f);
    if (circleOverlapsColliderXZ(dx, dz, 25)) continue;
    pushMatrix();
    translate(dx, -2, dz);
    float h = 12 + sin(t * 2 + d) * 4;
    fill(200, 175, 130, 35);
    box(8, h, 8);
    fill(220, 200, 160, 25);
    translate(0, h * 0.5f, 0);
    box(5, h * 0.6f, 5);
    popMatrix();
  }

  pushMatrix();
  translate(worldX(560), -108, worldZ(-190) + worldZ(88));
  rotateY(sin(t * 0.9) * 0.12);
  fill(200, 165, 90);
  box(18, 4, 2);
  popMatrix();

  emissive(0, 0, 0);
}

void drawRockCluster(float x, float z, float t, float scl) {
  pushMatrix();
  translate(x, 0, z);
  noStroke();
  for (int i = 0; i < 4; i++) {
    pushMatrix();
    translate(sin(i * 1.7 + t * 0.05) * 8 * scl, 0, cos(i * 2.1) * 6 * scl);
    rotateY(i * 0.4 + t * 0.02);
    fill(95 + i * 8, 68 + i * 5, 48);
    box(14 * scl + i * 3, 10 * scl, 12 * scl + i * 2);
    popMatrix();
  }
  popMatrix();
}

void drawSaloon(float x, float z, float t) {
  PImage wood = pickWoodTexture(x, z);
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -46, 0);
  drawBuildingWallBox(260, 92, 190, 132, 89, 55, wood);
  popMatrix();

  pushMatrix();
  translate(0, -100, 0);
  drawBuildingRoofBox(280, 16, 200, 95, 60, 35);
  popMatrix();

  pushMatrix();
  translate(0, -120, 90);
  fill(180, 130, 75);
  box(220, 56, 6);
  popMatrix();

  pushMatrix();
  translate(0, -126, 92);
  fill(60, 30, 15);
  box(160, 22, 1.5);
  popMatrix();

  pushMatrix();
  translate(0, -76, 110);
  fill(85, 55, 30);
  box(220, 6, 50);
  popMatrix();

  for (int i = -3; i <= 3; i++) {
    pushMatrix();
    translate(i * 35, -38, 130);
    fill(105, 70, 45);
    drawCylinder(4, 76, 10);
    popMatrix();
  }

  float doorAngle = sin(t * 1.2) * 0.18;
  pushMatrix();
  translate(-16, -45, 95);
  rotateY(doorAngle);
  fill(120, 75, 40);
  box(28, 50, 2);
  popMatrix();

  pushMatrix();
  translate(16, -45, 95);
  rotateY(-doorAngle);
  fill(120, 75, 40);
  box(28, 50, 2);
  popMatrix();

  popMatrix();
}

void drawSheriffOffice(float x, float z) {
  PImage wood = pickWoodTexture(x, z);
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -44, 0);
  drawBuildingWallBox(220, 88, 170, 119, 83, 49, wood);
  popMatrix();

  pushMatrix();
  translate(0, -94, 0);
  drawBuildingRoofBox(238, 18, 186, 98, 66, 43);
  popMatrix();

  pushMatrix();
  translate(0, -110, 85);
  fill(180, 145, 92);
  box(140, 22, 4);
  popMatrix();

  pushMatrix();
  translate(0, -110, 88);
  fill(220, 180, 60);
  box(14, 14, 1);
  popMatrix();

  for (int i = -1; i <= 1; i += 2) {
    pushMatrix();
    translate(i * 90, -25, 110);
    fill(70, 45, 25);
    drawCylinder(5, 50, 10);
    popMatrix();
  }

  popMatrix();
}

void drawBarn(float x, float z) {
  PImage wood = pickWoodTexture(x, z);
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -45, 0);
  drawBuildingWallBox(250, 90, 170, 125, 50, 40, wood);
  popMatrix();

  pushMatrix();
  translate(0, -90, 0);
  if (texBuildingRoof != null || wood != null) {
    drawTexturedBarnRoof(130, 55, 90, texBuildingRoof, wood);
  } else {
    fill(82, 38, 30);
    beginShape(QUADS);
    vertex(-130, 0, -90);
    vertex(0, -55, -90);
    vertex(0, -55, 90);
    vertex(-130, 0, 90);
    vertex(0, -55, -90);
    vertex(130, 0, -90);
    vertex(130, 0, 90);
    vertex(0, -55, 90);
    endShape();
    beginShape(TRIANGLES);
    vertex(-130, 0, 90);
    vertex(0, -55, 90);
    vertex(130, 0, 90);
    vertex(-130, 0, -90);
    vertex(130, 0, -90);
    vertex(0, -55, -90);
    endShape();
  }
  popMatrix();

  pushMatrix();
  translate(0, -45, 86);
  fill(60, 30, 20);
  box(60, 80, 2);
  popMatrix();

  popMatrix();
}

void drawWaterTower(float x, float z) {
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  for (int i = 0; i < 4; i++) {
    pushMatrix();
    float sx = (i < 2) ? -32 : 32;
    float sz = (i % 2 == 0) ? -32 : 32;
    translate(sx, -55, sz);
    fill(110, 76, 52);
    drawCylinder(5, 110, 8);
    popMatrix();
  }

  pushMatrix();
  translate(0, -135, 0);
  if (texBarrel != null) {
    drawTexturedCylinder(texBarrel, 56, 70, 26, false);
  } else {
    fill(146, 104, 73);
    drawCylinder(56, 70, 24);
  }

  fill(80, 50, 30);
  for (int i = -1; i <= 1; i++) {
    pushMatrix();
    translate(0, i * 25, 0);
    drawCylinder(57, 4, 24);
    popMatrix();
  }

  fill(95, 60, 35);
  translate(0, -50, 0);
  drawCone(60, 30, 20);
  popMatrix();

  popMatrix();
}

void drawWagon(float x, float z) {
  pushMatrix();
  translate(x, 0, z);
  rotateY(-PI / 5);
  noStroke();

  pushMatrix();
  translate(0, -28, 0);
  fill(140, 92, 56);
  box(140, 28, 70);
  popMatrix();

  pushMatrix();
  translate(0, -50, -38);
  fill(110, 70, 42);
  box(140, 18, 4);
  popMatrix();

  pushMatrix();
  translate(0, -50, 38);
  fill(110, 70, 42);
  box(140, 18, 4);
  popMatrix();

  pushMatrix();
  translate(72, -50, 0);
  fill(110, 70, 42);
  box(4, 18, 76);
  popMatrix();

  pushMatrix();
  translate(-72, -50, 0);
  fill(110, 70, 42);
  box(4, 18, 76);
  popMatrix();

  for (int sx = -1; sx <= 1; sx += 2) {
    for (int sz = -1; sz <= 1; sz += 2) {
      pushMatrix();
      translate(sx * 50, -16, sz * 38);
      rotateX(HALF_PI);
      fill(45, 28, 18);
      drawCylinder(18, 8, 16);
      fill(85, 60, 35);
      drawCylinder(7, 9, 12);
      popMatrix();
    }
  }

  pushMatrix();
  translate(85, -22, 0);
  fill(95, 65, 40);
  box(80, 4, 4);
  popMatrix();

  pushMatrix();
  translate(115, -16, 0);
  fill(75, 50, 30);
  box(20, 6, 30);
  popMatrix();

  pushMatrix();
  translate(20, -50, 10);
  fill(150, 110, 70);
  box(28, 20, 22);
  popMatrix();

  pushMatrix();
  translate(-20, -45, -10);
  fill(140, 100, 60);
  box(30, 24, 22);
  popMatrix();

  popMatrix();
}

void drawTrainCar(float x, float z) {
  PImage wood = pickWoodTexture(x, z);
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -55, 0);
  drawBuildingWallBox(220, 60, 90, 60, 30, 30, wood);
  popMatrix();

  pushMatrix();
  translate(0, -95, 0);
  drawBuildingRoofBox(232, 12, 96, 40, 22, 22);
  popMatrix();

  for (int sx = -1; sx <= 1; sx += 2) {
    pushMatrix();
    translate(sx * 80, -16, 0);
    rotateX(HALF_PI);
    fill(40, 25, 15);
    drawCylinder(16, 14, 14);
    popMatrix();
  }

  popMatrix();
}

void drawCactus(float x, float z) {
  pushMatrix();
  translate(x, 0, z);
  noStroke();
  boolean useTex = texCactus != null;
  if (!useTex) fill(60, 132, 71);
  else fill(75, 140, 82);

  pushMatrix();
  translate(0, -45, 0);
  if (useTex) drawTexturedCylinder(texCactus, 12, 90, 12, false);
  else drawCylinder(12, 90, 12);
  popMatrix();

  pushMatrix();
  translate(0, -94, 0);
  if (useTex) drawTexturedSphere(texCactus, 12, 14);
  else sphere(12);
  popMatrix();

  pushMatrix();
  translate(-22, -55, 0);
  rotateZ(PI / 3);
  if (useTex) drawTexturedCylinder(texCactus, 7, 26, 10, false);
  else drawCylinder(7, 26, 10);
  popMatrix();
  pushMatrix();
  translate(-30, -68, 0);
  if (useTex) drawTexturedCylinder(texCactus, 7, 18, 10, false);
  else drawCylinder(7, 18, 10);
  popMatrix();
  pushMatrix();
  translate(-30, -77, 0);
  if (useTex) drawTexturedSphere(texCactus, 7, 12);
  else sphere(7);
  popMatrix();

  pushMatrix();
  translate(20, -45, 0);
  rotateZ(-PI / 3);
  if (useTex) drawTexturedCylinder(texCactus, 6, 22, 10, false);
  else drawCylinder(6, 22, 10);
  popMatrix();
  pushMatrix();
  translate(26, -56, 0);
  if (useTex) drawTexturedCylinder(texCactus, 6, 14, 10, false);
  else drawCylinder(6, 14, 10);
  popMatrix();
  pushMatrix();
  translate(26, -63, 0);
  if (useTex) drawTexturedSphere(texCactus, 6, 12);
  else sphere(6);
  popMatrix();

  if (useTex) noTint();
  popMatrix();
}

void drawBarrel(float x, float z) {
  pushMatrix();
  translate(x, -18, z);
  noStroke();
  if (texBarrel != null) {
    drawTexturedCylinder(texBarrel, 16, 36, 22, false);
  } else {
    fill(121, 81, 50);
    drawCylinder(16, 36, 16);
  }
  fill(64, 49, 40);
  pushMatrix();
  translate(0, -10, 0);
  drawCylinder(17.5, 4, 16);
  popMatrix();
  pushMatrix();
  translate(0, 10, 0);
  drawCylinder(17.5, 4, 16);
  popMatrix();
  popMatrix();
}

void drawFencePost(float x, float z) {
  pushMatrix();
  translate(x, -35, z);
  if (texFence != null) {
    fill(255);
    drawTexturedCylinder(texFence, 7, 70, 12, false);
  } else {
    fill(118, 82, 54);
    drawCylinder(7, 70, 10);
  }
  translate(0, -38, 0);
  if (texRoof != null) {
    drawTexturedCone(texRoof, 9, 14, 12);
  } else {
    fill(88, 62, 42);
    drawCone(9, 14, 10);
  }
  popMatrix();
}

// === Geometry helpers ===

final float BUILDING_TEX_TILE = 96f;

/** Stable per-building wood variant from world position (does not flicker each frame). */
PImage pickWoodTexture(float worldX, float worldZ) {
  PImage[] opts = {texWood1, texWood2, texWood3};
  int n = 0;
  for (int i = 0; i < opts.length; i++) {
    if (opts[i] != null) n++;
  }
  if (n == 0) {
    if (texBuildingWood != null) return texBuildingWood;
    return texBarrel;
  }
  int pick = abs((int)(worldX * 12.9898f + worldZ * 78.233f)) % n;
  int seen = 0;
  for (int i = 0; i < opts.length; i++) {
    if (opts[i] == null) continue;
    if (seen == pick) return opts[i];
    seen++;
  }
  return texWood1;
}

void drawTexQuad(PImage tex, float x0, float y0, float z0, float u0, float v0,
    float x1, float y1, float z1, float u1, float v1,
    float x2, float y2, float z2, float u2, float v2,
    float x3, float y3, float z3, float u3, float v3) {
  beginShape(QUADS);
  texture(tex);
  textureMode(NORMAL);
  textureWrap(REPEAT);
  vertex(x0, y0, z0, u0, v0);
  vertex(x1, y1, z1, u1, v1);
  vertex(x2, y2, z2, u2, v2);
  vertex(x3, y3, z3, u3, v3);
  endShape();
}

/** Box walls (4 sides) + optional top — same layout as box(w,h,d) centered at origin. */
void drawTexturedBuildingBox(float w, float h, float d, PImage wallTex, PImage roofTex, boolean roofTop) {
  if (wallTex == null) return;
  float hw = w * 0.5f;
  float hh = h * 0.5f;
  float hd = d * 0.5f;
  float uW = w / BUILDING_TEX_TILE;
  float vH = h / BUILDING_TEX_TILE;
  float uD = d / BUILDING_TEX_TILE;
  noStroke();
  noTint();
  fill(255);

  drawTexQuad(wallTex,
    -hw, -hh, hd, 0, 0,  hw, -hh, hd, uW, 0,  hw, hh, hd, uW, vH,  -hw, hh, hd, 0, vH);
  drawTexQuad(wallTex,
    hw, -hh, -hd, 0, 0,  -hw, -hh, -hd, uW, 0,  -hw, hh, -hd, uW, vH,  hw, hh, -hd, 0, vH);
  drawTexQuad(wallTex,
    hw, -hh, hd, 0, 0,  hw, -hh, -hd, uD, 0,  hw, hh, -hd, uD, vH,  hw, hh, hd, 0, vH);
  drawTexQuad(wallTex,
    -hw, -hh, -hd, 0, 0,  -hw, -hh, hd, uD, 0,  -hw, hh, hd, uD, vH,  -hw, hh, -hd, 0, vH);

  if (roofTop) {
    PImage topTex = roofTex != null ? roofTex : wallTex;
    drawTexQuad(topTex,
      -hw, -hh, -hd, 0, 0,  hw, -hh, -hd, uW, 0,  hw, -hh, hd, uW, uD,  -hw, -hh, hd, 0, uD);
  }
  noTexture();
  textureMode(NORMAL);
}

void drawBuildingWallBox(float w, float h, float d, int r, int g, int b, PImage woodTex) {
  if (woodTex != null) {
    drawTexturedBuildingBox(w, h, d, woodTex, null, false);
  } else {
    fill(r, g, b);
    box(w, h, d);
  }
}

void drawBuildingRoofBox(float w, float h, float d, int r, int g, int b) {
  if (texBuildingRoof != null || texBuildingWood != null) {
    drawTexturedBuildingBox(w, h, d, texBuildingRoof != null ? texBuildingRoof : texBuildingWood,
      texBuildingRoof, true);
  } else {
    fill(r, g, b);
    box(w, h, d);
  }
}

/** Barn gable roof — two slopes + front/back triangles. */
void drawTexturedBarnRoof(float halfW, float peakDrop, float halfD, PImage roofTex, PImage gableTex) {
  if (roofTex == null) return;
  float slopeLen = sqrt(halfW * halfW + peakDrop * peakDrop);
  float uSlope = slopeLen / BUILDING_TEX_TILE;
  float vD = (halfD * 2f) / BUILDING_TEX_TILE;
  noStroke();
  noTint();
  fill(255);

  drawTexQuad(roofTex,
    -halfW, 0, -halfD, 0, 0,  0, -peakDrop, -halfD, uSlope, 0,
    0, -peakDrop, halfD, uSlope, vD,  -halfW, 0, halfD, 0, vD);
  drawTexQuad(roofTex,
    0, -peakDrop, -halfD, 0, 0,  halfW, 0, -halfD, uSlope, 0,
    halfW, 0, halfD, uSlope, vD,  0, -peakDrop, halfD, 0, vD);

  PImage gt = gableTex != null ? gableTex : roofTex;
  beginShape(TRIANGLES);
  texture(gt);
  textureMode(NORMAL);
  vertex(-halfW, 0, halfD, 0, 0);
  vertex(0, -peakDrop, halfD, 0.5, 1);
  vertex(halfW, 0, halfD, 1, 0);
  vertex(-halfW, 0, -halfD, 0, 0);
  vertex(halfW, 0, -halfD, 1, 0);
  vertex(0, -peakDrop, -halfD, 0.5, 1);
  endShape();
  noTexture();
  textureMode(NORMAL);
}

/** Cylinder body — texture on side faces (UV). */
void drawTexturedCylinder(PImage tex, float radius, float h, int detail, boolean withCaps) {
  if (tex == null) {
    drawCylinder(radius, h, detail);
    return;
  }
  textureMode(NORMAL);
  noStroke();
  beginShape(QUAD_STRIP);
  texture(tex);
  for (int i = 0; i <= detail; i++) {
    float a = TWO_PI * i / detail;
    float xx = cos(a) * radius;
    float zz = sin(a) * radius;
    float u = (float)i / detail;
    vertex(xx, -h / 2.0, zz, u, 0);
    vertex(xx, h / 2.0, zz, u, 1);
  }
  endShape();
  if (withCaps) {
    int bc = color(90, 60, 40);
    fill(red(bc), green(bc), blue(bc));
    beginShape(TRIANGLE_FAN);
    vertex(0, -h / 2.0, 0);
    for (int i = 0; i <= detail; i++) {
      float a = TWO_PI * i / detail;
      vertex(cos(a) * radius, -h / 2.0, sin(a) * radius);
    }
    endShape();
    beginShape(TRIANGLE_FAN);
    vertex(0, h / 2.0, 0);
    for (int i = detail; i >= 0; i--) {
      float a = TWO_PI * i / detail;
      vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
    }
    endShape();
  }
  noTexture();
}

/** Sphere with lat/long UV wrap (cactus tips). Inherits fill() from caller like drawTexturedCylinder. */
void drawTexturedSphere(PImage tex, float radius, int detail) {
  if (tex == null) {
    sphere(radius);
    return;
  }
  textureMode(NORMAL);
  noStroke();
  for (int lat = 0; lat < detail; lat++) {
    float lat0 = PI * (-0.5f + (float) lat / detail);
    float lat1 = PI * (-0.5f + (float) (lat + 1) / detail);
    float y0 = sin(lat0) * radius;
    float y1 = sin(lat1) * radius;
    float r0 = cos(lat0) * radius;
    float r1 = cos(lat1) * radius;
    beginShape(QUAD_STRIP);
    texture(tex);
    for (int lon = 0; lon <= detail; lon++) {
      float lonAngle = TWO_PI * lon / detail;
      float x0 = cos(lonAngle) * r0;
      float z0 = sin(lonAngle) * r0;
      float x1 = cos(lonAngle) * r1;
      float z1 = sin(lonAngle) * r1;
      float u = (float) lon / detail;
      float v0 = (float) lat / detail;
      float v1 = (float) (lat + 1) / detail;
      vertex(x0, y0, z0, u, v0);
      vertex(x1, y1, z1, u, v1);
    }
    endShape();
  }
  noTexture();
}

/** Cone roof / fence post cap — texture mapping. */
void drawTexturedCone(PImage tex, float radius, float h, int detail) {
  if (tex == null) {
    drawCone(radius, h, detail);
    return;
  }
  textureMode(NORMAL);
  noStroke();
  float half = h * 0.5;
  for (int i = 0; i < detail; i++) {
    float a0 = TWO_PI * i / detail;
    float a1 = TWO_PI * (i + 1) / detail;
    float u0 = (float)i / detail;
    float u1 = (float)(i + 1) / detail;
    beginShape(TRIANGLES);
    texture(tex);
    vertex(0, -half, 0, 0.5, 0);
    vertex(cos(a0) * radius, half, sin(a0) * radius, u0, 1);
    vertex(cos(a1) * radius, half, sin(a1) * radius, u1, 1);
    endShape();
  }
  noTexture();
}

void drawCone(float radius, float h, int detail) {
  beginShape(TRIANGLE_FAN);
  vertex(0, -h / 2.0, 0);
  for (int i = 0; i <= detail; i++) {
    float a = TWO_PI * i / detail;
    vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
  }
  endShape();

  beginShape(TRIANGLE_FAN);
  vertex(0, h / 2.0, 0);
  for (int i = detail; i >= 0; i--) {
    float a = TWO_PI * i / detail;
    vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
  }
  endShape();
}

void drawCylinder(float radius, float h, int detail) {
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= detail; i++) {
    float a = TWO_PI * i / detail;
    float xx = cos(a) * radius;
    float zz = sin(a) * radius;
    vertex(xx, -h / 2.0, zz);
    vertex(xx, h / 2.0, zz);
  }
  endShape();

  beginShape(TRIANGLE_FAN);
  vertex(0, -h / 2.0, 0);
  for (int i = 0; i <= detail; i++) {
    float a = TWO_PI * i / detail;
    vertex(cos(a) * radius, -h / 2.0, sin(a) * radius);
  }
  endShape();

  beginShape(TRIANGLE_FAN);
  vertex(0, h / 2.0, 0);
  for (int i = detail; i >= 0; i--) {
    float a = TWO_PI * i / detail;
    vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
  }
  endShape();
}

float ease(float x) {
  return 1 - (1 - x) * (1 - x);
}

// === Aim marker ===

void drawAimMarker(PVector aim, float t) {
  pushMatrix();
  translate(aim.x, -1.5, aim.z);
  rotateX(HALF_PI);
  noFill();
  stroke(255, 220, 100, 230);
  strokeWeight(2);
  float r = 14 + sin(t * 8) * 2;
  ellipse(0, 0, r * 2, r * 2);
  line(-r - 4, 0, -r - 14, 0);
  line(r + 4, 0, r + 14, 0);
  line(0, -r - 4, 0, -r - 14);
  line(0, r + 4, 0, r + 14);
  noStroke();
  popMatrix();
}

// === Updaters ===

void updateAndDrawBullets(float dt) {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update(dt);

    if (b.alive && circleOverlapsColliderXZ(b.pos.x, b.pos.z, 6)) {
      b.alive = false;
    }

    for (Bandit bandit : bandits) {
      if (!bandit.alive) continue;
      float dx = b.pos.x - bandit.pos.x;
      float dz = b.pos.z - bandit.pos.z;
      if (dx * dx + dz * dz < 30 * 30) {
        if (bandit.takeHit(b.dmg)) {
          registerBanditLootDrop(bandit.pos.x, bandit.pos.z);
        }
        b.alive = false;
        break;
      }
    }

    b.display();

    if (!b.alive) bullets.remove(i);
  }
}

void updateAndDrawEnemyBullets(float dt) {
  float pr = 36;
  for (int i = enemyBullets.size() - 1; i >= 0; i--) {
    EnemyBullet eb = enemyBullets.get(i);
    eb.update(dt);

    if (eb.alive && circleOverlapsColliderXZ(eb.pos.x, eb.pos.z, 9)) {
      eb.alive = false;
    }

    if (eb.alive && !finished) {
      float dx = eb.pos.x - player.pos.x;
      float dz = eb.pos.z - player.pos.z;
      if (dx * dx + dz * dz < pr * pr) {
        player.hp -= eb.dmg;
        eb.alive = false;
        playWavSafe("hit_player.wav");
        for (int k = 0; k < 6; k++) {
          float a = random(TWO_PI);
          hitSparks.add(new HitSpark(player.pos.x, -40, player.pos.z,
            cos(a) * 90, -random(40, 120), sin(a) * 90));
        }
      }
    }

    eb.display();
    if (!eb.alive) enemyBullets.remove(i);
  }
}

void updateAndDrawBandits(float t, float dt) {
  for (Bandit b : bandits) {
    b.update(player, t, dt);
    b.display(t);
  }
}

void updateAndDrawMuzzleFlashes(float dt) {
  for (int i = muzzleFlashes.size() - 1; i >= 0; i--) {
    MuzzleFlash m = muzzleFlashes.get(i);
    m.update(dt);
    m.display();
    if (m.life <= 0) muzzleFlashes.remove(i);
  }
}

void updateAndDrawHitSparks(float dt) {
  for (int i = hitSparks.size() - 1; i >= 0; i--) {
    HitSpark s = hitSparks.get(i);
    s.update(dt);
    s.display();
    if (s.life <= 0) hitSparks.remove(i);
  }
}
