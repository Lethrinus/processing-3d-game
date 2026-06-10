// Main game orchestration — setup, draw loop, play session.

class GameSession {
  final PApplet p;
  final GameContext ctx = new GameContext();
  AudioManager audio;
  WorldScene world;
  WaveManager waves;
  InputHandler input;
  SceneRenderer scene;
  UIRenderer ui;
  EntityRenderer entities;
  AssetLoader assets;

  PFont uiFontHud;
  PFont uiFontBody;
  int lastSfxPreviewMs = 0;

  GameSession(PApplet p) {
    this.p = p;
    audio = new AudioManager(p, ctx);
    world = new WorldScene(p, ctx);
    waves = new WaveManager(p, ctx, world, audio);
    scene = new SceneRenderer(p, ctx);
    ui = new UIRenderer(p, ctx, this);
    entities = new EntityRenderer(p, ctx, scene);
    assets = new AssetLoader(p, ctx);
    input = new InputHandler(p, ctx, this);
  }

  void settings() {
    if (readFullscreenPref()) p.fullScreen(P3D, 1);
    else p.size(WINDOWED_W, WINDOWED_H, P3D);
  }

  boolean readFullscreenPref() {
    String[] raw = p.loadStrings("progression.txt");
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
    ctx.sceneStartMs = p.millis();
    uiFontHud = createWesternHudFont();
    uiFontBody = createUiBodyFont();
    textFontBody();
    p.sphereDetail(18);
    world.buildSceneColliders();
    assets.loadTextureAssets();
    assets.loadUiAssets();
    assets.loadControlPanelAssets();
    loadProgression();
    audio.applyVolumes();
    surface.setResizable(true);
    syncDisplayModeToPreference();
    ctx.gameFlow = FLOW_TITLE;
  }

  void draw() {
    processPendingDisplayMode();
    audio.ensureMenuMusic();
    if (ctx.gameFlow == FLOW_TITLE) {
      ui.drawTitleScreen();
      return;
    }
    if (ctx.gameFlow == FLOW_SETTINGS) {
      ui.drawSettingsScreen();
      return;
    }
    if (ctx.gameFlow == FLOW_CONTROLS) {
      ui.drawControlsIntroScreen();
      return;
    }
    updatePauseClock();
    drawPlay(gameElapsedSec());
  }

  void drawPlay(float t) {
    p.background(92, 62, 48);
    p.hint(ENABLE_DEPTH_TEST);
    float fr = max(p.frameRate, 30);
    float dt = 1.0f / fr;
    boolean gameplayActive = !ctx.showControlsOverlay && !ctx.finished && !ctx.gamePaused;
    if (ctx.weaponUnlockBannerTimer > 0) ctx.weaponUnlockBannerTimer -= dt;
    if (gameplayActive) {
      waves.updateWaveTimers(dt);
      waves.updateWaveIntro(dt);
      updateMovement(dt);
      world.updateStaggeredSpawns(dt);
    }
    updateDamageFlash(dt);
    persistRunIfEnded();
    updatePickupPlusFx(dt);
    updateAmmoGainFx(dt);
    audio.syncPlayMusic();

    setAngledCamera();
    reset3DDrawState();
    scene.drawWesternEnvironment(t);

    ctx.aimPoint = groundFromMouse(p.mouseX, p.mouseY);
    ctx.player.updateAim(ctx.aimPoint);
    if (gameplayActive) {
      ctx.player.update(t, dt, ctx);
      updateSprintTrail(t, dt);
      updateSprintBarFocus(dt);
    }

    if (gameplayActive && ctx.shooting && ctx.waveState == WAVE_STATE_FIGHT && ctx.wavePreviewTimer <= 0) {
      ArrayList<Bullet> volley = ctx.player.tryShootVolley(ctx.aimPoint, ctx, audio);
      if (volley != null && volley.size() > 0) {
        ctx.bullets.addAll(volley);
        PVector tip = ctx.player.gunTip();
        ctx.muzzleFlashes.add(new MuzzleFlash(tip, ctx.player.facing, ctx.player.weaponSlot));
        if (ctx.player.weaponSlot == 0) addCamShake(2.8f);
        else if (ctx.player.weaponSlot == 1) {
          addCamShake(11f);
          emitShotgunShells(tip, ctx.player.facing);
        } else addCamShake(4.5f);
      }
    }

    if (ctx.player.hp > 0) entities.drawPlayer(ctx.player, t);

    if (gameplayActive) {
      updateAndDrawBandits(t, dt);
      for (int li = ctx.lootPickups.size() - 1; li >= 0; li--) {
        LootPickup lp = ctx.lootPickups.get(li);
        lp.update(ctx.player, this);
        if (lp.gone) ctx.lootPickups.remove(li);
      }
    } else {
      for (Bandit b : ctx.bandits) entities.drawBandit(b, t);
    }
    for (LootPickup lp : ctx.lootPickups) entities.drawLoot(lp, t);

    if (gameplayActive) {
      updateAndDrawBullets(dt);
      updateAndDrawEnemyBullets(dt);
      updateAndDrawMuzzleFlashes(dt);
      updateAndDrawShellCasings(dt);
      updateAndDrawHitSparks(dt);
    } else {
      for (Bullet b : ctx.bullets)       b.display();
      for (EnemyBullet eb : ctx.enemyBullets) eb.display();
      for (MuzzleFlash m : ctx.muzzleFlashes) m.display();
      for (ShellCasing sc : ctx.shellCasings) sc.display();
      for (HitSpark s : ctx.hitSparks) s.display();
    }

    scene.drawAimMarker(ctx.aimPoint, t);

    ArrayList<float[]> healthPositions = new ArrayList<float[]>();
    for (Bandit b : ctx.bandits) {
      if (!b.alive) continue;
      float sx = p.screenX(b.pos.x, -90, b.pos.z);
      float sy = p.screenY(b.pos.x, -90, b.pos.z);
      healthPositions.add(new float[]{sx, sy, b.hp / b.maxHp});
    }

    if (gameplayActive) waves.updateGameState(t);

    if (gameplayActive) updateAndDrawGore(dt);
    else {
      for (GibChunk g : ctx.gibChunks) g.display();
      for (BloodParticle bp : ctx.bloodParticles) bp.display();
    }

    ctx.playerScreenFootX = p.screenX(ctx.player.pos.x, GROUND_Y, ctx.player.pos.z);
    ctx.playerScreenFootY = p.screenY(ctx.player.pos.x, GROUND_Y, ctx.player.pos.z);
    ctx.playerSprintHudX = p.screenX(ctx.player.pos.x, -86, ctx.player.pos.z);
    ctx.playerSprintHudY = p.screenY(ctx.player.pos.x, -86, ctx.player.pos.z);
    rebuildSprintTrailScreen(t);

    p.hint(DISABLE_DEPTH_TEST);
    p.noTexture();
    p.camera();
    p.perspective();
    p.noLights();
    textFontBody();
    float shakeX = (p.random(-1, 1) + p.random(-1, 1)) * 0.5f * (ctx.hurtShakePx + ctx.camShakePx);
    float shakeY = (p.random(-1, 1) + p.random(-1, 1)) * 0.5f * (ctx.hurtShakePx + ctx.camShakePx * 0.85f);
    drawSprintTrail2D();
    drawPlayerSprintBar2D();
    p.pushMatrix();
    p.translate(shakeX, shakeY);
    ui.drawHealthBars(healthPositions);
    ui.drawHudDistributed(t);
    ui.drawControlsHudButton();
    ui.drawPlayerReloadBarScreen();
    ui.drawReloadNeededFeedback(t);
    ui.drawWaveIntermissionOverlay(t);
    ui.drawWaveBanner2D();
    ui.drawSpawnPreview2D(t);
    p.popMatrix();
    ui.drawHurtFeedbackOverlay();
    drawPickupPlusFx2D();
    drawAmmoGainFx2D();
    ui.drawWeaponUnlockBanner2D();
    reset2DDrawState();
    if (ctx.gamePaused && !ctx.finished) ui.drawPauseOverlay();
    if (ctx.showControlsOverlay) {
      ui.drawControlsOverlayPanel("Click anywhere or press H to close", false);
    }
    p.hint(ENABLE_DEPTH_TEST);
  }

  // --- Combat & FX updaters ---

  void updateAndDrawBullets(float dt) {
    for (int i = ctx.bullets.size() - 1; i >= 0; i--) {
      Bullet b = ctx.bullets.get(i);
      b.update(dt, ctx);
      if (b.alive && world.circleOverlapsColliderXZ(b.pos.x, b.pos.z, 6)) b.alive = false;
      for (Bandit bandit : ctx.bandits) {
        if (!bandit.alive) continue;
        float dx = b.pos.x - bandit.pos.x;
        float dz = b.pos.z - bandit.pos.z;
        if (dx * dx + dz * dz < 30 * 30) {
          if (bandit.takeHit(b.dmg, ctx, audio, this)) {
            waves.registerBanditLootDrop(bandit.pos.x, bandit.pos.z);
          }
          b.alive = false;
          break;
        }
      }
      b.display();
      if (!b.alive) ctx.bullets.remove(i);
    }
  }

  void updateAndDrawEnemyBullets(float dt) {
    float pr = 36;
    for (int i = ctx.enemyBullets.size() - 1; i >= 0; i--) {
      EnemyBullet eb = ctx.enemyBullets.get(i);
      eb.update(dt, ctx);
      if (eb.alive && world.circleOverlapsColliderXZ(eb.pos.x, eb.pos.z, 9)) eb.alive = false;
      if (eb.alive && !ctx.finished) {
        float dx = eb.pos.x - ctx.player.pos.x;
        float dz = eb.pos.z - ctx.player.pos.z;
        if (dx * dx + dz * dz < pr * pr) {
          ctx.player.hp -= eb.dmg;
          eb.alive = false;
          audio.playWavSafe("hit_player.wav");
          for (int k = 0; k < 6; k++) {
            float a = p.random(TWO_PI);
            ctx.hitSparks.add(new HitSpark(ctx.player.pos.x, -40, ctx.player.pos.z,
              cos(a) * 90, -p.random(40, 120), sin(a) * 90));
          }
        }
      }
      eb.display();
      if (!eb.alive) ctx.enemyBullets.remove(i);
    }
  }

  void updateAndDrawBandits(float t, float dt) {
    for (Bandit b : ctx.bandits) {
      b.update(ctx.player, ctx, world, audio, t, dt);
      entities.drawBandit(b, t);
    }
  }

  void updateAndDrawMuzzleFlashes(float dt) {
    for (int i = ctx.muzzleFlashes.size() - 1; i >= 0; i--) {
      MuzzleFlash m = ctx.muzzleFlashes.get(i);
      m.update(dt);
      m.display();
      if (!m.isAlive()) ctx.muzzleFlashes.remove(i);
    }
  }

  void updateAndDrawShellCasings(float dt) {
    for (int i = ctx.shellCasings.size() - 1; i >= 0; i--) {
      ShellCasing sc = ctx.shellCasings.get(i);
      sc.update(dt);
      sc.display();
      if (!sc.isAlive()) ctx.shellCasings.remove(i);
    }
  }

  void updateAndDrawHitSparks(float dt) {
    for (int i = ctx.hitSparks.size() - 1; i >= 0; i--) {
      HitSpark s = ctx.hitSparks.get(i);
      s.update(dt);
      s.display();
      if (!s.isAlive()) ctx.hitSparks.remove(i);
    }
  }

  void updateAndDrawGore(float dt) {
    for (int i = ctx.gibChunks.size() - 1; i >= 0; i--) {
      GibChunk g = ctx.gibChunks.get(i);
      g.update(dt);
      g.display();
      if (!g.isAlive()) ctx.gibChunks.remove(i);
    }
    for (int i = ctx.bloodParticles.size() - 1; i >= 0; i--) {
      BloodParticle bp = ctx.bloodParticles.get(i);
      bp.update(dt);
      bp.display();
      if (!bp.isAlive()) ctx.bloodParticles.remove(i);
    }
  }

  void spawnBanditGore(float x, float z, int outfitC) {
    for (int i = 0; i < 11; i++) {
      float a = p.random(TWO_PI);
      float pv = p.random(0.35f, 0.85f);
      PVector v = new PVector(cos(a) * pv * 165, -p.random(70, 195), sin(a) * pv * 165);
      int mix = p.lerpColor(outfitC, p.color(72, 42, 38), p.random(0.1f, 0.32f));
      ctx.gibChunks.add(new GibChunk(x + p.random(-5, 5), p.random(-50, -28), z + p.random(-5, 5), v, mix));
    }
    for (int i = 0; i < 28; i++) {
      float a = p.random(TWO_PI);
      float e = p.random(0.15f, 0.72f);
      PVector v = new PVector(cos(a) * e * p.random(45, 130), -p.random(45, 155), sin(a) * e * p.random(45, 130));
      ctx.bloodParticles.add(new BloodParticle(x + p.random(-9, 9), p.random(-48, -22), z + p.random(-9, 9), v));
    }
  }

  void spawnPlayerGore(float x, float z) {
    if (ctx.playerGoreSpawned) return;
    ctx.playerGoreSpawned = true;
    spawnBanditGore(x, z, p.color(58, 96, 145));
  }

  // --- Movement & camera ---

  void updateMovement(float dt) {
    PVector input = new PVector();
    if (ctx.moveW) input.z -= 1;
    if (ctx.moveS) input.z += 1;
    if (ctx.moveA) input.x -= 1;
    if (ctx.moveD) input.x += 1;
    if (input.magSq() > 0) {
      input.normalize();
      float ca = cos(ctx.camYaw);
      float sa = sin(ctx.camYaw);
      float rx = input.x * ca + input.z * sa;
      float rz = -input.x * sa + input.z * ca;
      PVector move = new PVector(rx, 0, rz);
      float spd = ctx.player.speed;
      if (ctx.sprintHeld && ctx.player.stamina > 0.035f && !ctx.finished && ctx.waveState == WAVE_STATE_FIGHT) {
        spd *= 1.55f;
      }
      move.mult(spd * dt);
      ctx.player.pos.add(move);
      ctx.player.moving = true;
    } else {
      ctx.player.moving = false;
    }
    ctx.player.pos.x = constrain(ctx.player.pos.x, -ctx.arenaHalfW + 80, ctx.arenaHalfW - 80);
    ctx.player.pos.z = constrain(ctx.player.pos.z, -ctx.arenaHalfH + 80, ctx.arenaHalfH - 80);
    world.resolveCircleColliders(ctx.player.pos, 26);
  }

  void setAngledCamera() {
    float horizDist = ctx.camDist * cos(ctx.camPitch);
    float vertDist = ctx.camDist * sin(ctx.camPitch);
    ctx.camPosX = ctx.player.pos.x + horizDist * sin(ctx.camYaw);
    ctx.camPosY = -vertDist;
    ctx.camPosZ = ctx.player.pos.z + horizDist * cos(ctx.camYaw);
    ctx.camTargetX = ctx.player.pos.x;
    ctx.camTargetY = -8;
    ctx.camTargetZ = ctx.player.pos.z;
    float shX = (p.random(-1, 1) + p.random(-1, 1)) * 0.5f * (ctx.camShakePx + ctx.hurtShakePx * 0.75f);
    float shY = (p.random(-1, 1) + p.random(-1, 1)) * 0.5f * (ctx.camShakePx * 0.55f + ctx.hurtShakePx * 0.45f);
    float shZ = (p.random(-1, 1) + p.random(-1, 1)) * 0.5f * ctx.camShakePx * 0.4f;
    p.camera(ctx.camPosX + shX, ctx.camPosY + shY, ctx.camPosZ + shZ,
      ctx.camTargetX + shX * 0.35f, ctx.camTargetY, ctx.camTargetZ + shZ * 0.35f, 0, 1, 0);
    p.perspective(PI / 3.0, (float) p.width / (float) p.height, 1, 6000);
    ctx.camForward.set(ctx.camTargetX - ctx.camPosX, ctx.camTargetY - ctx.camPosY, ctx.camTargetZ - ctx.camPosZ);
    ctx.camForward.normalize();
    PVector worldUp = new PVector(0, 1, 0);
    ctx.camRight = ctx.camForward.cross(worldUp);
    ctx.camRight.normalize();
    ctx.camUp = ctx.camRight.cross(ctx.camForward);
    ctx.camUp.normalize();
    p.ambientLight(80, 70, 60);
    p.directionalLight(255, 220, 175, -0.4f, 0.85f, -0.25f);
    p.pointLight(255, 165, 95, ctx.player.pos.x, -200, ctx.player.pos.z + 200);
  }

  PVector groundFromMouse(float mx, float my) {
    float fov = PI / 3.0f;
    float aspect = (float) p.width / p.height;
    float tFov = tan(fov / 2.0f);
    float ndcX = (2.0f * mx / p.width - 1.0f) * aspect * tFov;
    float ndcY = (2.0f * my / p.height - 1.0f) * tFov;
    PVector rayDir = ctx.camForward.copy();
    rayDir.add(PVector.mult(ctx.camRight, ndcX));
    rayDir.add(PVector.mult(ctx.camUp, ndcY));
    rayDir.normalize();
    float planeY = GROUND_Y;
    if (abs(rayDir.y) < 1e-5f) return new PVector(ctx.player.pos.x, planeY, ctx.player.pos.z);
    float t = (planeY - ctx.camPosY) / rayDir.y;
    if (t < 0) t = 1500;
    return new PVector(ctx.camPosX + rayDir.x * t, planeY, ctx.camPosZ + rayDir.z * t);
  }

  // --- Session flow ---

  void beginPlaySession() {
    audio.stopMusic();
    waves.initGame();
    ctx.sceneStartMs = p.millis();
    ctx.gameFlow = FLOW_PLAY;
    ctx.showControlsOverlay = false;
    ctx.gamePaused = false;
    ctx.shooting = false;
  }

  void returnToTitleFromPause() {
    ctx.gamePaused = false;
    ctx.shooting = false;
    saveProgression();
    audio.stopMusic();
    ctx.gameFlow = FLOW_TITLE;
    audio.startMenuMusic();
  }

  void quitToTitle() {
    if (!ctx.finished) {
      ctx.finished = true;
      ctx.gameStateText = "QUIT";
    }
    persistRunIfEnded();
    ctx.gamePaused = false;
    ctx.showControlsOverlay = false;
    ctx.shooting = false;
    saveProgression();
    audio.stopMusic();
    ctx.gameFlow = FLOW_TITLE;
    audio.startMenuMusic();
  }

  void setGamePaused(boolean paused) {
    if (paused == ctx.gamePaused) return;
    updatePauseClock();
    ctx.gamePaused = paused;
    updatePauseClock();
    if (ctx.gamePaused) ctx.shooting = false;
  }

  void updatePauseClock() {
    if (ctx.gamePaused && ctx.gamePauseStartMs == 0) ctx.gamePauseStartMs = p.millis();
    if (!ctx.gamePaused && ctx.gamePauseStartMs > 0) {
      ctx.gamePauseAccumMs += p.millis() - ctx.gamePauseStartMs;
      ctx.gamePauseStartMs = 0;
    }
  }

  float gameElapsedSec() {
    long paused = ctx.gamePauseAccumMs;
    if (ctx.gamePaused && ctx.gamePauseStartMs > 0) paused += p.millis() - ctx.gamePauseStartMs;
    return max(0, (p.millis() - ctx.sceneStartMs - paused) / 1000.0f);
  }

  // --- Fonts & draw state ---

  String resolveFontPath(String fileName) {
    String inFonts = "fonts/" + fileName;
    if (new File(p.dataPath(inFonts)).exists()) return inFonts;
    if (new File(p.dataPath(fileName)).exists()) return fileName;
    return null;
  }

  PFont createWesternHudFont() {
    String path = resolveFontPath("RioGrande.ttf");
    if (path != null) return p.createFont(path, 72, true);
    return p.createFont("Serif", 72, true);
  }

  PFont createUiBodyFont() {
    String[] dataFiles = {"Sancreek-Regular.ttf", "sancreek-regular.ttf"};
    for (String name : dataFiles) {
      String path = resolveFontPath(name);
      if (path != null) return p.createFont(path, 14, true);
    }
    return p.createFont("SansSerif", 48, true);
  }

  void textFontDisplay() {
    p.textFont(uiFontHud);
  }

  void textFontBody() {
    p.textFont(uiFontBody);
  }

  void reset3DDrawState() {
    p.noTint();
    p.blendMode(BLEND);
    p.emissive(0, 0, 0);
    p.strokeWeight(1);
  }

  void reset2DDrawState() {
    p.hint(ENABLE_DEPTH_TEST);
    p.blendMode(BLEND);
    p.rectMode(CORNER);
    p.textAlign(LEFT, BASELINE);
    textFontBody();
  }

  // --- Progression & display mode ---

  float sanitizeVolume(float v, float fallback) {
    if (Float.isNaN(v) || Float.isInfinite(v)) return fallback;
    return constrain(v, 0, 1);
  }

  float parseVolumeSetting(String v, float fallback) {
    if (v == null || v.length() == 0) return fallback;
    String s = v.trim().replace(',', '.');
    return sanitizeVolume(parseFloat(s), fallback);
  }

  String formatVolumeFile(float v) {
    return String.format(Locale.US, "%.3f", sanitizeVolume(v, 0.22f));
  }

  void loadProgression() {
    ctx.progressionHighScore = 0;
    ctx.progressionTotalKills = 0;
    ctx.settingsSfxVol = GAME_SFX_VOLUME_DEFAULT;
    ctx.settingsMusicVol = GAME_MUSIC_VOLUME_DEFAULT;
    String[] raw = p.loadStrings("progression.txt");
    if (raw == null) return;
    for (int i = 0; i < raw.length; i++) {
      if (raw[i] == null) continue;
      String line = raw[i].trim();
      int eq = line.indexOf('=');
      if (eq < 1) continue;
      String k = line.substring(0, eq).trim();
      String v = line.substring(eq + 1).trim();
      if (k.equals("highScore")) ctx.progressionHighScore = parseInt(v);
      else if (k.equals("totalKills")) ctx.progressionTotalKills = parseInt(v);
      else if (k.equals("sfxVolume")) ctx.settingsSfxVol = parseVolumeSetting(v, GAME_SFX_VOLUME_DEFAULT);
      else if (k.equals("musicVolume")) ctx.settingsMusicVol = parseVolumeSetting(v, GAME_MUSIC_VOLUME_DEFAULT);
      else if (k.equals("fullscreen")) {
        String lv = v.toLowerCase(Locale.ROOT);
        ctx.settingsFullscreen = lv.equals("1") || lv.equals("true") || lv.equals("yes");
      }
    }
  }

  void saveProgression() {
    String[] lines = {
      "highScore=" + ctx.progressionHighScore,
      "totalKills=" + ctx.progressionTotalKills,
      "sfxVolume=" + formatVolumeFile(ctx.settingsSfxVol),
      "musicVolume=" + formatVolumeFile(ctx.settingsMusicVol),
      "fullscreen=" + (ctx.settingsFullscreen ? "1" : "0")
    };
    p.saveStrings("progression.txt", lines);
  }

  void syncDisplayModeToPreference() {
    if (ctx.settingsFullscreen) {
      if (p.width < p.displayWidth - 8 || p.height < p.displayHeight - 8) ctx.pendingDisplayMode = 1;
    } else if (p.width > WINDOWED_W + 8 || p.height > WINDOWED_H + 8) {
      ctx.pendingDisplayMode = 0;
    }
  }

  void processPendingDisplayMode() {
    if (ctx.pendingDisplayMode < 0) return;
    int mode = ctx.pendingDisplayMode;
    ctx.pendingDisplayMode = -1;
    if (mode == 1) surface.setSize(p.displayWidth, p.displayHeight);
    else surface.setSize(WINDOWED_W, WINDOWED_H);
  }

  void applyDisplayMode(boolean fullscreen) {
    ctx.settingsFullscreen = fullscreen;
    ctx.pendingDisplayMode = fullscreen ? 1 : 0;
    saveProgression();
  }

  boolean displayModeButtonHit(float mx, float my) {
    return mx >= ctx.settingsDisplayBtnX && mx <= ctx.settingsDisplayBtnX + ctx.settingsDisplayBtnW
      && my >= ctx.settingsDisplayBtnY && my <= ctx.settingsDisplayBtnY + ctx.settingsDisplayBtnH;
  }

  void persistRunIfEnded() {
    if (ctx.runStatsPersisted || !ctx.finished) return;
    ctx.runStatsPersisted = true;
    if (ctx.score > ctx.progressionHighScore) ctx.progressionHighScore = ctx.score;
    ctx.progressionTotalKills += ctx.kills;
    saveProgression();
    if (ctx.player != null && ctx.player.hp <= 0) spawnPlayerGore(ctx.player.pos.x, ctx.player.pos.z);
  }

  void updateDamageFlash(float dt) {
    if (ctx.player != null && ctx.player.hp < ctx.lastHp) {
      float lost = max(0, ctx.lastHp - ctx.player.hp);
      ctx.hurtRing = min(1, ctx.hurtRing + 0.95f + lost * 0.012f);
      ctx.hurtShakePx = min(18, ctx.hurtShakePx + 4.2f + lost * 0.06f);
      addCamShake(3.5f + lost * 0.08f);
    }
    if (ctx.player != null) ctx.lastHp = ctx.player.hp;
    ctx.hurtShakePx *= exp(-dt * 11);
    ctx.hurtRing = max(0, ctx.hurtRing - dt * 2.85f);
    updateCamShake(dt);
  }

  void addCamShake(float amp) {
    ctx.camShakeAmp = min(24, ctx.camShakeAmp + amp);
  }

  void updateCamShake(float dt) {
    ctx.camShakeAmp *= exp(-dt * 13.5f);
    ctx.camShakePx = (p.random(-1, 1) + p.random(-1, 1)) * 0.5f * ctx.camShakeAmp;
  }

  void emitShotgunShells(PVector tip, float facing) {
    for (int i = 0; i < 2; i++) {
      ctx.shellCasings.add(new ShellCasing(tip, facing + p.random(-0.12f, 0.12f)));
    }
  }

  void spawnPickupPlusBurst(float sx, float sy, int kind) {
    for (int i = 0; i < 12; i++) {
      ctx.pickupPlusFx.add(new PickupPlusFx(
        sx + p.random(-48, 48), sy + p.random(-38, 12), kind,
        p.random(-140, 140), p.random(54, 108)));
    }
  }

  void updatePickupPlusFx(float dt) {
    for (int i = ctx.pickupPlusFx.size() - 1; i >= 0; i--) {
      PickupPlusFx fx = ctx.pickupPlusFx.get(i);
      fx.update(dt);
      if (fx.dead()) ctx.pickupPlusFx.remove(i);
    }
  }

  void drawPickupPlusFx2D() {
    for (PickupPlusFx fx : ctx.pickupPlusFx) fx.draw2D(p);
  }

  void spawnAmmoGainFloat(float sx, float sy, int amount) {
    if (amount <= 0) return;
    ctx.ammoGainFx.add(new AmmoGainFx(sx, sy, "+" + amount));
  }

  void updateAmmoGainFx(float dt) {
    for (int i = ctx.ammoGainFx.size() - 1; i >= 0; i--) {
      AmmoGainFx a = ctx.ammoGainFx.get(i);
      a.update(dt);
      if (a.dead()) ctx.ammoGainFx.remove(i);
    }
  }

  void drawAmmoGainFx2D() {
    for (AmmoGainFx a : ctx.ammoGainFx) a.draw2D(p);
  }

  void updateSprintTrail(float gameT, float dt) {
    boolean sprinting = ctx.sprintHeld && ctx.player.moving && ctx.player.stamina > 0.02f
      && !ctx.finished && ctx.waveState == WAVE_STATE_FIGHT;
    if (sprinting) {
      ctx.sprintTrailEmitAccum += dt;
      final float step = 0.52f;
      while (ctx.sprintTrailEmitAccum >= step) {
        ctx.sprintTrailEmitAccum -= step;
        float bf = ctx.player.facing;
        float backX = -sin(bf), backZ = -cos(bf);
        float sideX = cos(bf), sideZ = -sin(bf);
        float dist = 24, spread = 11;
        ctx.sprintTrailPuffs.add(new SprintTrailPuff(
          ctx.player.pos.x + backX * dist - sideX * spread,
          ctx.player.pos.z + backZ * dist - sideZ * spread, gameT, 1));
        ctx.sprintTrailPuffs.add(new SprintTrailPuff(
          ctx.player.pos.x + backX * dist + sideX * spread,
          ctx.player.pos.z + backZ * dist + sideZ * spread, gameT, 1));
      }
    } else ctx.sprintTrailEmitAccum = 0;
    final float maxAge = 0.45f;
    for (int i = ctx.sprintTrailPuffs.size() - 1; i >= 0; i--) {
      if (gameT - ctx.sprintTrailPuffs.get(i).t0 > maxAge) ctx.sprintTrailPuffs.remove(i);
    }
  }

  void rebuildSprintTrailScreen(float gameT) {
    ctx.sprintTrailScreenDots.clear();
    for (SprintTrailPuff puff : ctx.sprintTrailPuffs) {
      float age = gameT - puff.t0;
      float life = 0.42f;
      if (age <= 0 || age >= life) continue;
      float u = age / life;
      float a = (1 - u) * (1 - u);
      float diam = (32 + u * 28) * puff.scMul;
      ctx.sprintTrailScreenDots.add(new float[]{
        p.screenX(puff.x, 0, puff.z), p.screenY(puff.x, 0, puff.z), diam, a});
    }
  }

  void drawSprintTrail2D() {
    if (ctx.sprintTrailScreenDots.isEmpty()) return;
    p.pushStyle();
    p.rectMode(CENTER);
    p.noStroke();
    p.blendMode(BLEND);
    for (float[] d : ctx.sprintTrailScreenDots) {
      float op = constrain(d[3] * 120, 14, 62);
      p.fill(195, 160, 118, op);
      p.ellipse(d[0], d[1] + 1, d[2] * 1.08f, d[2] * 0.62f);
      p.fill(235, 215, 175, op * 0.45f);
      p.ellipse(d[0], d[1] - d[2] * 0.04f, d[2] * 0.42f, d[2] * 0.28f);
    }
    p.rectMode(CORNER);
    p.popStyle();
  }

  void updateSprintBarFocus(float dt) {
    if (ctx.finished || ctx.waveState != WAVE_STATE_FIGHT || ctx.player == null || ctx.player.hp <= 0) {
      ctx.sprintBarFocus = 0;
      return;
    }
    if (ctx.sprintHeld) ctx.sprintBarFocus = min(1, ctx.sprintBarFocus + dt * 8.5f);
    else ctx.sprintBarFocus = max(0, ctx.sprintBarFocus - dt * 1.6f);
  }

  void maybePreviewSfxVolume() {
    if (SoundHelper.sfxVolume <= 0.0001f) return;
    int now = p.millis();
    if (now - lastSfxPreviewMs < 140) return;
    lastSfxPreviewMs = now;
    audio.playSoundSafe("ui_click.wav");
  }

  void drawPlayerSprintBar2D() {
    if (ctx.finished || ctx.waveState != WAVE_STATE_FIGHT || ctx.player.hp <= 0) return;
    if (ctx.sprintBarFocus < 0.02f) return;
    int op = (int) constrain(ctx.sprintBarFocus * 255, 0, 255);
    float cx = ctx.playerSprintHudX;
    float barTop = ctx.playerSprintHudY - 44;
    float bw = 142, bh = 11;
    float lx = constrain(cx - bw * 0.5f, 18, p.width - bw - 18);
    p.rectMode(CORNER);
    p.noStroke();
    p.fill(18, 12, 9, op);
    p.rect(lx, barTop, bw, bh, 5);
    float fw = (bw - 5) * constrain(ctx.player.stamina, 0, 1);
    if (fw > 0.5f) {
      p.fill(72, 210, 125, op);
      p.rect(lx + 2.5f, barTop + 2.5f, fw, bh - 5, 3);
    }
    p.textAlign(CENTER, BOTTOM);
    p.textSize(10);
    p.fill(235, 225, 205, op);
    p.text("SPRINT", cx, barTop - 3);
  }
}
