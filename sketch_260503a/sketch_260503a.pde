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
import java.io.File;
import javax.sound.sampled.Clip;

PFont uiFontHud;

/** Serif / western-style UI font from installed families; falls back to Serif. */
PFont createWesternHudFont() {
  String[] preferred = {
    "Rockwell-Bold", "Rockwell Bold", "Rockwell",
    "Copperplate Gothic Bold", "Copperplate Gothic",
    "Book Antiqua", "Bookman Old Style",
    "Georgia-Bold", "Georgia Bold", "Georgia",
    "Times New Roman", "TimesNewRomanPSMT", "Palatino Linotype", "Serif"
  };
  String[] avail = PFont.list();
  for (String w : preferred) {
    for (String f : avail) {
      if (f.equalsIgnoreCase(w)) return createFont(f, 72, true);
    }
  }
  return createFont("Serif", 72, true);
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
float gameDurationSec = 200.0;
/** Bonus time earned between waves. */
float extraTimeSec = 0;

final int WAVE_STATE_FIGHT = 0;
final int WAVE_STATE_BREAK = 1;
int waveState = WAVE_STATE_FIGHT;
float waveBreakTimer = 0;
final float WAVE_BREAK_DURATION = 8.0;
int currentWave = 1;
int maxWaves = 5;

PImage texBarrel, texRoof, texGround;
Clip musicClip;
float[] starX, starY;
/** Player feet in screen space (for reload bar). */
float playerScreenFootX, playerScreenFootY;
/** ~Chest height — sprint bar anchored above character in screen space. */
float playerSprintHudX, playerSprintHudY;
/** 0..1: visible while Shift held, fades out after release. */
float sprintBarFocus = 0;

String gameStateText = "";
boolean finished = false;

boolean moveW, moveA, moveS, moveD;
boolean shooting = false;

float camYaw = -PI / 6.0;
float camPitch = 1.05;
float camDist = 720;
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

/** fullScreen/size must run here (not in setup) — see Processing fullScreen() docs. */
void settings() {
  fullScreen(P3D, 1);
}

void setup() {
  sceneStartMs = millis();
  uiFontHud = createWesternHudFont();
  textFont(uiFontHud);
  sphereDetail(18);
  buildSceneColliders();
  loadTextureAssets();
  initStarfield();
  loadProgression();
  initGame();
}

void initStarfield() {
  randomSeed(1337);
  starX = new float[140];
  starY = new float[140];
  int w = max(200, width > 0 ? width : displayWidth);
  int h = max(200, height > 0 ? height : displayHeight);
  for (int i = 0; i < starX.length; i++) {
    starX[i] = random(w * 1.05f);
    starY[i] = random(h * 1.05f);
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
}

void playWavSafe(String name) {
  SoundHelper.playWav(dataPath("sounds/" + name));
}

void loadProgression() {
  progressionHighScore = 0;
  progressionTotalKills = 0;
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
  }
}

void saveProgression() {
  saveStrings(dataPath("progression.txt"), new String[] {
    "highScore=" + progressionHighScore,
    "totalKills=" + progressionTotalKills
  });
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
  }
  if (player != null) lastHp = player.hp;
  hurtShakePx *= exp(-dt * 11);
  hurtRing = max(0, hurtRing - dt * 2.85);
}

/** Spawn ground loot after a kill (called from sketch bullet loop only). */
void registerBanditLootDrop(float x, float z) {
  if (lootPickups == null) lootPickups = new ArrayList<LootPickup>();
  int lk = (int)random(3);
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
    float pulse = age < 0.14 ? (0.72 + 0.28 * sin(age * 55)) : 1;
    float ts = (34 + 12 * pulse) * (1 - u * 0.22);
    textAlign(CENTER, CENTER);
    textSize(ts);
    int core = color(70, 255, 130);
    int rim = color(200, 255, 220);
    fill(0, a * 0.6);
    text(label, sx + 2.5, sy + 2.5);
    fill(red(rim), green(rim), blue(rim), a * 0.45);
    text(label, sx, sy);
    fill(red(core), green(core), blue(core), a);
    text(label, sx, sy - 1);
    noStroke();
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
    textAlign(CENTER, CENTER);
    int c = color(255, 224, 105);
    if (kind == 1) c = color(115, 255, 155);
    if (kind == 2) c = color(255, 175, 85);
    float pulse = 1 + 0.14 * sin(age * 26 + sx * 0.05);
    textSize(24 * pulse);
    fill(0, a * 0.5);
    text("+", sx + 1.5, sy + 2);
    fill(red(c), green(c), blue(c), a);
    text("+", sx, sy);
    stroke(red(c), green(c), blue(c), a * 0.65);
    strokeWeight(2.2);
    float r = 14 * pulse;
    line(sx - r, sy, sx + r, sy);
    line(sx, sy - r, sx, sy + r);
    noStroke();
    fill(255, 255, 250, a * 0.3);
    ellipse(sx, sy, 9, 9);
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
  SoundHelper.disposeClip(musicClip);
  musicClip = null;
}

void startMusicIfAny() {
  stopMusic();
  musicClip = SoundHelper.openMusicLoop(dataPath("sounds/music_loop.wav"));
}

void drawStarfield2D() {
  stroke(255, 70);
  strokeWeight(1.2);
  for (int i = 0; i < starX.length; i++) point(starX[i], starY[i]);
  noStroke();
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

void draw() {
  float elapsed = (millis() - sceneStartMs) / 1000.0;
  if (elapsed < 3) drawFirstScreen();
  else drawSecondScreen(elapsed - 3.0);
}

// Task-1: only canvas size + background.
void drawFirstScreen() {
  background(0);
}

// Task-2+: angled top-down western shootout with proper aiming + camera control.
void drawSecondScreen(float t) {
  background(0);
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  drawStarfield2D();
  hint(ENABLE_DEPTH_TEST);

  float fr = max(frameRate, 30);
  float dt = 1.0 / fr;
  if (!finished) {
    updateWaveTimers(dt);
    updateMovement(dt);
  }
  updateDamageFlash(dt);
  persistRunIfEnded();
  updatePickupPlusFx(dt);
  updateAmmoGainFx(dt);

  setAngledCamera();
  blendMode(BLEND);
  drawWesternEnvironment(t);

  aimPoint = groundFromMouse(mouseX, mouseY);
  player.updateAim(aimPoint);
  player.update(t, dt);
  updateSprintTrail(t, dt);
  updateSprintBarFocus(dt);

  if (shooting && !finished && waveState == WAVE_STATE_FIGHT) {
    ArrayList<Bullet> volley = player.tryShootVolley(aimPoint);
    if (volley != null && volley.size() > 0) {
      bullets.addAll(volley);
      muzzleFlashes.add(new MuzzleFlash(player.gunTip(), player.facing));
    }
  }

  if (player.hp > 0) {
    player.display(t);
  }

  updateAndDrawBandits(t, dt);
  for (int li = lootPickups.size() - 1; li >= 0; li--) {
    LootPickup lp = lootPickups.get(li);
    lp.update(player);
    if (lp.gone) lootPickups.remove(li);
  }
  for (LootPickup lp : lootPickups) lp.display(t);
  updateAndDrawBullets(dt);
  updateAndDrawEnemyBullets(dt);
  updateAndDrawMuzzleFlashes(dt);
  updateAndDrawHitSparks(dt);

  drawAimMarker(aimPoint, t);

  ArrayList<float[]> healthPositions = new ArrayList<float[]>();
  for (Bandit b : bandits) {
    if (!b.alive) continue;
    float sx = screenX(b.pos.x, -90, b.pos.z);
    float sy = screenY(b.pos.x, -90, b.pos.z);
    healthPositions.add(new float[]{sx, sy, b.hp / b.maxHp});
  }

  updateGameState(t);

  updateAndDrawGore(dt);

  playerScreenFootX = screenX(player.pos.x, 14, player.pos.z);
  playerScreenFootY = screenY(player.pos.x, 14, player.pos.z);
  playerSprintHudX = screenX(player.pos.x, -86, player.pos.z);
  playerSprintHudY = screenY(player.pos.x, -86, player.pos.z);
  rebuildSprintTrailScreen(t);

  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  textFont(uiFontHud);
  float sx = (random(-1, 1) + random(-1, 1)) * 0.5 * hurtShakePx;
  float sy = (random(-1, 1) + random(-1, 1)) * 0.5 * hurtShakePx;
  drawSprintTrail2D();
  drawPlayerSprintBar2D();
  pushMatrix();
  translate(sx, sy);
  drawHealthBars(healthPositions);
  drawRulesPanel2D();
  drawHudDistributed(t);
  drawPlayerReloadBarScreen();
  drawReloadNeededFeedback(t);
  drawWaveIntermissionOverlay(t);
  popMatrix();
  drawHurtFeedbackOverlay();
  drawPickupPlusFx2D();
  drawAmmoGainFx2D();
  hint(ENABLE_DEPTH_TEST);
}

void updateWaveTimers(float dt) {
  if (waveState != WAVE_STATE_BREAK) return;
  waveBreakTimer -= dt;
  if (waveBreakTimer > 0) return;
  currentWave++;
  if (currentWave > maxWaves) {
    finished = true;
    gameStateText = "YOU WIN";
    playWavSafe("win.wav");
    waveState = WAVE_STATE_FIGHT;
    return;
  }
  spawnWave(currentWave);
  waveState = WAVE_STATE_FIGHT;
}

PVector randomBanditSpawn() {
  for (int attempt = 0; attempt < 50; attempt++) {
    float a = random(TWO_PI);
    float rx = cos(a) * (arenaHalfW * 0.82);
    float rz = sin(a) * (arenaHalfH * 0.82);
    float dx = rx - player.pos.x;
    float dz = rz - player.pos.z;
    if (dx * dx + dz * dz > 280 * 280) return new PVector(rx, 0, rz);
  }
  return new PVector(420, 0, -380);
}

void spawnWave(int w) {
  bandits.clear();
  enemyBullets.clear();
  bullets.clear();
  int n = 2 + w * 2;
  color[] outfits = {
    color(180, 60, 50), color(160, 100, 50), color(130, 60, 90),
    color(80, 120, 145), color(100, 80, 60)
  };
  for (int i = 0; i < n; i++) {
    PVector p = randomBanditSpawn();
    float hpMul = 1 + 0.15 * (w - 1);
    float spdMul = 1 + 0.1 * (w - 1);
    bandits.add(new Bandit(p.x, p.z, outfits[i % outfits.length], spdMul, hpMul, w));
  }
}

void initGame() {
  stopMusic();
  player = new Player(0, 0);
  bullets = new ArrayList<Bullet>();
  enemyBullets = new ArrayList<EnemyBullet>();
  bandits = new ArrayList<Bandit>();
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
  camTargetY = -30;
  camTargetZ = player.pos.z;
  camera(camPosX, camPosY, camPosZ, camTargetX, camTargetY, camTargetZ, 0, 1, 0);
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

  float planeY = 0;
  if (abs(rayDir.y) < 1e-5) return new PVector(player.pos.x, planeY, player.pos.z);
  float t = (planeY - camPosY) / rayDir.y;
  if (t < 0) t = 1500;
  return new PVector(camPosX + rayDir.x * t, planeY, camPosZ + rayDir.z * t);
}

// === Input ===

void mousePressed() {
  float elapsed = (millis() - sceneStartMs) / 1000.0;
  if (elapsed < 3) return;
  if (mouseButton == LEFT) shooting = true;
}

void mouseReleased() {
  if (mouseButton == LEFT) shooting = false;
}

void mouseDragged() {
  if (mouseButton == RIGHT) {
    float dx = mouseX - pmouseX;
    float dy = mouseY - pmouseY;
    camYaw -= dx * 0.008;
    camPitch -= dy * 0.005;
    camPitch = constrain(camPitch, 0.45, 1.30);
  }
}

void mouseWheel(MouseEvent e) {
  float scroll = e.getCount();
  camDist += scroll * 60;
  camDist = constrain(camDist, camDistMin, camDistMax);
}

void keyPressed() {
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
      sceneStartMs = millis() - 3000;
      initGame();
    } else {
      player.startReload();
    }
  }
  if (!finished) {
    if (key == '1') player.setWeaponSlot(0);
    if (key == '2') player.setWeaponSlot(1);
    if (key == '3') player.setWeaponSlot(2);
    if (key == ' ' && waveState == WAVE_STATE_BREAK) waveBreakTimer = 0;
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

  int aliveCount = 0;
  for (Bandit b : bandits) {
    if (b.alive) aliveCount++;
  }
  if (bandits.size() > 0 && aliveCount == 0) {
    if (currentWave == maxWaves) {
      finished = true;
      gameStateText = "YOU WIN";
      playWavSafe("win.wav");
    } else {
      waveState = WAVE_STATE_BREAK;
      waveBreakTimer = WAVE_BREAK_DURATION;
      extraTimeSec += 14;
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
  textAlign(LEFT, TOP);
  fill(0, 130);
  text(s, x + 1.5f, y + 1.5f);
  fill(col);
  text(s, x, y);
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
  textFont(uiFontHud);
  textSize(12);
  textLeading(15);
  String line1 =
    "WASD move · Mouse shoot · 1 / 2 / 3 weapons · Shift sprint · R reload · RMB drag camera · Wheel zoom";
  String line2 =
    maxWaves + " waves · SPACE skips wave break · Q quit (saves progress)";
  float cx = panelX + panelW * 0.5;
  float ty = panelY + 14;
  fill(0, 85);
  text(line1, cx + 1, ty + 1);
  text(line2, cx + 1, ty + 1 + 17);
  fill(248, 215, 125);
  text(line1, cx, ty);
  text(line2, cx, ty + 17);
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

/** Western HUD panels. */
void drawHudDistributed(float t) {
  rectMode(CORNER);
  float remaining = max(0, gameDurationSec + extraTimeSec - t);
  float timeBudget = max(1, gameDurationSec + extraTimeSec);
  float timeRatio = remaining / timeBudget;

  float lx = 18, ly = 16;
  float pw = 246;
  float ph = 118;
  drawWesternPanel(lx, ly, pw, ph, 10);
  fill(200, 155, 75);
  textAlign(LEFT, TOP);
  textSize(11);
  text("◆ BOUNTY", lx + 14, ly + 10);
  textSize(17);
  drawHudLabelShadow("Wave  " + currentWave + " / " + maxWaves, lx + 14, ly + 28, color(255, 238, 210));
  textSize(14);
  drawHudLabelShadow("Score  " + score, lx + 14, ly + 50, color(235, 220, 198));
  drawHudLabelShadow("Kills  " + kills, lx + 14, ly + 70, color(220, 205, 185));
  drawHudLabelShadow("Gold  " + player.gold, lx + 14, ly + 90, color(230, 200, 120));
  textSize(10);
  fill(175, 155, 130);
  text("Best run  " + progressionHighScore, lx + 14, ly + 104);

  float rx = width - 258;
  float ry = 16;
  float tw = 242;
  float th = 72;
  drawWesternPanel(rx, ry, tw, th, 10);
  fill(200, 155, 75);
  textSize(11);
  textAlign(LEFT, TOP);
  text("◆ TIME", rx + 14, ry + 10);
  drawHudBar(rx + 14, ry + 28, tw - 28, 14, timeRatio,
    color(32, 20, 14), color(85, 165, 225), color(175, 125, 55));
  fill(255, 235, 210);
  textSize(13);
  textAlign(RIGHT, TOP);
  text(nf(remaining, 0, 1) + " s", rx + tw - 14, ry + 10);

  float hpBarH = 26;
  float hpBarY = height - hpBarH;
  float hpR = max(0, player.hp / player.maxHp);
  int hpCol = lerpColor(color(210, 55, 48), color(72, 220, 118), hpR);
  boolean hpCrit = hpR <= 0.25 && player.hp > 0;
  drawHudResourceBar(0, hpBarY, width, hpBarH, hpR,
    hpCol, color(18, 10, 7), color(175, 120, 55), t, hpCrit, 24);
  textAlign(LEFT, CENTER);
  textSize(12);
  fill(255, 220, 185);
  text("♥  " + (int)player.hp + " / " + (int)player.maxHp, 14, hpBarY + hpBarH * 0.52);

  int slot = player.weaponSlot;
  textAlign(RIGHT, BOTTOM);
  textSize(13);
  fill(200, 155, 75);
  text(player.weaponName().toUpperCase(), width - 18, hpBarY - 6);
  textSize(46);
  if (player.reloading) {
    textSize(22);
    fill(120, 200, 255);
    text("RELOAD…", width - 18, hpBarY - 14);
  } else {
    int amCol = color(255, 245, 228);
    if (player.wAmmo[slot] <= 0) amCol = color(255, 150, 110);
    String ams = str(player.wAmmo[slot]) + " / " + str(player.wMax[slot]);
    textAlign(RIGHT, BOTTOM);
    textSize(46);
    fill(0, 145);
    text(ams, width - 15, hpBarY - 18);
    fill(amCol);
    text(ams, width - 17, hpBarY - 20);
  }

  if (!finished && player.wAmmo[slot] > 0 && player.wAmmo[slot] <= 5 && !player.reloading) {
    textSize(12);
    fill(255, 200, 70, 240);
    textAlign(RIGHT, BOTTOM);
    text("LOW AMMO", width - 18, hpBarY - 52);
  }

  if (finished) {
    float mx = width * 0.5 - 270;
    float my = height * 0.5 - 132;
    drawWesternPanel(mx, my, 540, 268, 14);
    noFill();
    stroke(120, 75, 35, 200);
    strokeWeight(2);
    rect(mx + 10, my + 10, 520, 248, 10);
    noStroke();
    fill(255, 225, 150);
    textAlign(CENTER, CENTER);
    textSize(46);
    fill(0, 110);
    text(gameStateText, width * 0.5 + 2, height * 0.5 - 34);
    fill(255, 225, 150);
    text(gameStateText, width * 0.5, height * 0.5 - 36);
    fill(210, 190, 165);
    textSize(19);
    text("Score: " + score + "     Kills: " + kills, width * 0.5, height * 0.5 + 18);
    textSize(15);
    fill(175, 160, 140);
    text("Best score: " + progressionHighScore + "     Lifetime kills: " + progressionTotalKills,
      width * 0.5, height * 0.5 + 44);
    textSize(16);
    fill(180, 160, 140);
    text("R — restart          Q — quit", width * 0.5, height * 0.5 + 72);
  }
}

/** Reload progress bar at player feet. */
void drawPlayerReloadBarScreen() {
  if (!player.reloading) return;
  float rd = player.wReloadSec[player.weaponSlot];
  float prog = 1.0 - constrain(player.reloadTimer / rd, 0, 1);
  float bw = 168;
  float bh = 14;
  float cx = constrain(playerScreenFootX, bw * 0.5f + 16, width - bw * 0.5f - 16);
  float cy = constrain(playerScreenFootY + 28, 100, height - 120);
  float left = cx - bw * 0.5;
  float top = cy - 22;
  rectMode(CORNER);
  drawWesternPanel(left - 8, top, bw + 16, bh + 36, 8);
  textAlign(CENTER, TOP);
  textSize(11);
  fill(0, 130);
  text("RELOAD", cx + 1, top + 9);
  fill(255, 235, 200);
  text("RELOAD", cx, top + 8);
  drawHudBar(left, top + 26, bw, bh, prog, color(32, 22, 16), color(95, 205, 255), color(190, 145, 65));
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
  textSize(21);
  fill(0, 140);
  text("OUT OF AMMO  —  RELOAD [ R ]", width * 0.5 + 2, by + bh * 0.5 + 2);
  fill(255, 245, 220);
  text("OUT OF AMMO  —  RELOAD [ R ]", width * 0.5, by + bh * 0.5);
  textSize(13);
  fill(255, 220, 180, 220);
  text("You cannot fire until you reload.", width * 0.5, by + bh - 14);
}

/** Wave break: top bar + frame. */
void drawWaveIntermissionOverlay(float gameT) {
  if (finished || waveState != WAVE_STATE_BREAK) return;
  rectMode(CORNER);
  noStroke();
  float prog = constrain(waveBreakTimer / WAVE_BREAK_DURATION, 0, 1);
  float edge = 10;
  fill(42, 28, 16, 220);
  rect(0, 0, width, edge);
  rect(0, height - edge, width, edge);
  rect(0, 0, edge, height);
  rect(width - edge, 0, edge, height);
  noFill();
  stroke(210, 165, 85, 180);
  strokeWeight(2);
  rect(edge * 0.5, edge * 0.5, width - edge, height - edge);
  noStroke();

  float barH = 26;
  fill(22, 14, 9, 235);
  rect(0, 0, width, barH);
  drawHudBar(edge + 4, 6, width - (edge + 8) * 2, barH - 12, prog,
    color(35, 22, 16), color(100, 175, 240), color(185, 140, 70));

  textAlign(CENTER, CENTER);
  textSize(13);
  fill(0, 140);
  text("WAVE BREAK  ·  " + str(max(0, (int)ceil(waveBreakTimer))) + " s  ·  [SPACE] skip",
    width * 0.5 + 1, barH * 0.52 + 1);
  fill(255, 235, 200);
  text("WAVE BREAK  ·  " + str(max(0, (int)ceil(waveBreakTimer))) + " s  ·  [SPACE] skip",
    width * 0.5, barH * 0.52);
}

/** Hit feedback: shock ring + slashes (no full-screen SCREEN — whites out on black). */
void drawHurtFeedbackOverlay() {
  float ring = hurtRing;
  if (ring < 0.02) return;
  float cx = width * 0.5;
  float cy = height * 0.5;
  float dim = min(width, height);
  rectMode(CORNER);
  noStroke();
  blendMode(BLEND);
  noFill();
  stroke(255, 248, 235, ring * 220);
  strokeWeight(2 + ring * 2);
  float expand = (1 - ring * 0.88) * dim * 0.42;
  ellipse(cx, cy, expand, expand);
  stroke(200, 230, 255, ring * 110);
  strokeWeight(1);
  ellipse(cx, cy, expand * 0.92, expand * 0.92);
  noStroke();

  float sp = ring * dim * 0.34;
  for (int k = 0; k < 8; k++) {
    float a = k * TWO_PI / 8.0 + frameCount * 0.04;
    float len = sp * (0.35 + 0.65 * ring);
    stroke(255, 250, 240, ring * 140);
    strokeWeight(1.8);
    line(cx + cos(a) * (sp * 0.12), cy + sin(a) * (sp * 0.12),
      cx + cos(a) * len, cy + sin(a) * len);
  }
  noStroke();
}

// === Environment ===

void drawWesternEnvironment(float t) {
  noStroke();

  pushMatrix();
  translate(0, 0, 0);
  rotateX(HALF_PI);
  rectMode(CENTER);
  float extW = arenaHalfW * 2.4;
  float extH = arenaHalfH * 2.2;
  if (texGround != null) {
    textureMode(NORMAL);
    beginShape(QUADS);
    texture(texGround);
    float rep = 10;
    vertex(-extW / 2, -extH / 2, 0, 0, 0);
    vertex( extW / 2, -extH / 2, 0, rep, 0);
    vertex( extW / 2,  extH / 2, 0, rep, rep);
    vertex(-extW / 2,  extH / 2, 0, 0, rep);
    endShape();
  } else {
    fill(166, 123, 74);
    rect(0, 0, extW, extH);
  }
  popMatrix();

  pushMatrix();
  translate(0, -0.5, 0);
  rotateX(HALF_PI);
  fill(140, 95, 56);
  rectMode(CENTER);
  rect(0, 0, worldX(240), arenaHalfH * 1.8);
  popMatrix();

  pushMatrix();
  translate(0, -1.0, 0);
  rotateX(HALF_PI);
  fill(110, 70, 40);
  rectMode(CENTER);
  for (int i = -8; i <= 8; i++) {
    rect(0, i * worldZ(70), worldX(240), 4);
  }
  popMatrix();

  drawAmbientLife(t);

  drawSaloon(worldX(-560), worldZ(-220), t);
  drawSheriffOffice(worldX(560), worldZ(-190));
  drawBarn(worldX(-540), worldZ(250));
  drawWaterTower(worldX(520), worldZ(250), t);
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
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -46, 0);
  fill(132, 89, 55);
  box(260, 92, 190);
  popMatrix();

  pushMatrix();
  translate(0, -100, 0);
  fill(95, 60, 35);
  box(280, 16, 200);
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
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -44, 0);
  fill(119, 83, 49);
  box(220, 88, 170);
  popMatrix();

  pushMatrix();
  translate(0, -94, 0);
  fill(98, 66, 43);
  box(238, 18, 186);
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
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -45, 0);
  fill(125, 50, 40);
  box(250, 90, 170);
  popMatrix();

  pushMatrix();
  translate(0, -90, 0);
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
  popMatrix();

  pushMatrix();
  translate(0, -45, 86);
  fill(60, 30, 20);
  box(60, 80, 2);
  popMatrix();

  popMatrix();
}

void drawWaterTower(float x, float z, float t) {
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
  pushMatrix();
  translate(x, 0, z);
  noStroke();

  pushMatrix();
  translate(0, -55, 0);
  fill(60, 30, 30);
  box(220, 60, 90);
  popMatrix();

  pushMatrix();
  translate(0, -95, 0);
  fill(40, 22, 22);
  box(232, 12, 96);
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
  fill(60, 132, 71);

  pushMatrix();
  translate(0, -45, 0);
  drawCylinder(12, 90, 12);
  popMatrix();

  pushMatrix();
  translate(0, -94, 0);
  sphere(12);
  popMatrix();

  pushMatrix();
  translate(-22, -55, 0);
  rotateZ(PI / 3);
  drawCylinder(7, 26, 10);
  popMatrix();
  pushMatrix();
  translate(-30, -68, 0);
  drawCylinder(7, 18, 10);
  popMatrix();
  pushMatrix();
  translate(-30, -77, 0);
  sphere(7);
  popMatrix();

  pushMatrix();
  translate(20, -45, 0);
  rotateZ(-PI / 3);
  drawCylinder(6, 22, 10);
  popMatrix();
  pushMatrix();
  translate(26, -56, 0);
  drawCylinder(6, 14, 10);
  popMatrix();
  pushMatrix();
  translate(26, -63, 0);
  sphere(6);
  popMatrix();

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
  fill(118, 82, 54);
  drawCylinder(7, 70, 10);
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
        player.hp -= 14;
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
