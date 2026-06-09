// Central runtime state — replaces scattered sketch globals.

class GameContext {
  float arenaHalfW = 1120;
  float arenaHalfH = 800;

  Player player;
  ArrayList<Bandit> bandits = new ArrayList<Bandit>();
  ArrayList<Bullet> bullets = new ArrayList<Bullet>();
  ArrayList<EnemyBullet> enemyBullets = new ArrayList<EnemyBullet>();
  ArrayList<MuzzleFlash> muzzleFlashes = new ArrayList<MuzzleFlash>();
  ArrayList<HitSpark> hitSparks = new ArrayList<HitSpark>();
  ArrayList<LootPickup> lootPickups = new ArrayList<LootPickup>();
  ArrayList<PickupPlusFx> pickupPlusFx = new ArrayList<PickupPlusFx>();
  ArrayList<GibChunk> gibChunks = new ArrayList<GibChunk>();
  ArrayList<BloodParticle> bloodParticles = new ArrayList<BloodParticle>();
  ArrayList<SprintTrailPuff> sprintTrailPuffs = new ArrayList<SprintTrailPuff>();
  ArrayList<float[]> sprintTrailScreenDots = new ArrayList<float[]>();
  ArrayList<AmmoGainFx> ammoGainFx = new ArrayList<AmmoGainFx>();
  ArrayList<ShellCasing> shellCasings = new ArrayList<ShellCasing>();
  ArrayList<PendingBandit> pendingBanditSpawns = new ArrayList<PendingBandit>();
  ArrayList<PVector> previewSpawnMarkers = new ArrayList<PVector>();
  ArrayList<float[]> sceneColliders = new ArrayList<float[]>();

  int kills;
  int score;
  float gameDurationSec = 240.0f;
  float extraTimeSec = 0;

  int waveState = WAVE_STATE_FIGHT;
  float waveBreakTimer = 0;
  int currentWave = 1;
  int maxWaves = STORY_MAX_WAVES;
  boolean waveSpawning = false;
  float staggerSpawnTimer = 0;
  float wavePreviewTimer = 0;
  float waveBannerTimer = 0;
  int waveBannerNumber = 1;

  int selectedGameMode = GAME_MODE_STORY;
  boolean endlessMode = false;
  boolean gamePaused = false;
  long gamePauseAccumMs = 0;
  int gamePauseStartMs = 0;

  float weaponUnlockBannerTimer = 0;
  String weaponUnlockBannerText = "";

  boolean playerGoreSpawned = false;
  boolean sprintHeld = false;
  float hurtShakePx = 0;
  float hurtRing = 0;
  float lastHp = 100;
  float sprintTrailEmitAccum = 0;
  float camShakeAmp = 0;
  float camShakePx = 0;
  float sprintBarFocus = 0;

  boolean moveW, moveA, moveS, moveD;
  boolean shooting = false;
  boolean finished = false;
  String gameStateText = "";

  int gameFlow = FLOW_TITLE;
  boolean showControlsOverlay = false;
  boolean menuMusicStarted = false;
  boolean runStatsPersisted = false;

  float camYaw = -PI / 6.0f;
  float camPitch = 0.82f;
  float camDist = 720;
  float camDistMin = 360;
  float camDistMax = 1750;
  float camPosX, camPosY, camPosZ;
  float camTargetX, camTargetY, camTargetZ;
  PVector camForward = new PVector();
  PVector camRight = new PVector();
  PVector camUp = new PVector();
  PVector aimPoint = new PVector(0, 0, 0);

  float playerScreenFootX, playerScreenFootY;
  float playerSprintHudX, playerSprintHudY;

  int sceneStartMs;
  int progressionHighScore = 0;
  int progressionTotalKills = 0;

  float settingsSfxVol = GAME_SFX_VOLUME_DEFAULT;
  float settingsMusicVol = GAME_MUSIC_VOLUME_DEFAULT;
  boolean settingsFullscreen = true;
  int pendingDisplayMode = -1;
  boolean settingsDraggingSfx = false;
  boolean settingsDraggingMusic = false;

  PImage texBarrel, texRoof, texGround, texCactus, texSky;
  PImage texBuildingWood, texBuildingRoof;
  PImage texWood1, texWood2, texWood3, texFence;
  PImage[] skyCubemap = new PImage[6];
  boolean skyCubemapReady;
  PImage uiBtnControls, uiBtnControlsHot;
  PImage uiWesternBg;
  ControlPanelRow[] controlPanelRows;

  javax.sound.sampled.Clip musicClip;

  int pathCols, pathRows;
  boolean[] pathBlocked;

  float storyBtnX, storyBtnY, storyBtnW = 300, storyBtnH = 50;
  float endlessBtnX, endlessBtnY;
  float pauseContinueBtnX, pauseContinueBtnY, pauseMenuBtnX, pauseMenuBtnY;
  float settingsBtnX, settingsBtnY, settingsBtnW = 200, settingsBtnH = 44;
  float settingsSfxBarY, settingsMusicBarY, settingsBarW = 320, settingsBarH = 22;
  float settingsDisplayBtnX, settingsDisplayBtnY, settingsDisplayBtnW = 300, settingsDisplayBtnH = 40;
  float controlsBtnX = 340, controlsBtnY = 12, controlsBtnW = 96, controlsBtnH = 26;

  float worldX(float legacyX) {
    return legacyX * arenaHalfW / LEGACY_ARENA_W;
  }

  float worldZ(float legacyZ) {
    return legacyZ * arenaHalfH / LEGACY_ARENA_H;
  }

  boolean isFightActive() {
    return waveState == WAVE_STATE_FIGHT && !finished;
  }

  void addScore(int pts) {
    score += pts;
  }

  void addKill() {
    kills++;
  }

  void addEnemyBullet(EnemyBullet b) {
    enemyBullets.add(b);
  }
}
