// Wave spawning, progression, and win/lose state.

class WaveManager {
  final PApplet p;
  final GameContext ctx;
  final WorldScene world;
  final AudioManager audio;

  WaveManager(PApplet p, GameContext ctx, WorldScene world, AudioManager audio) {
    this.p = p;
    this.ctx = ctx;
    this.world = world;
    this.audio = audio;
  }

  void initGame() {
    audio.stopMusic();
    ctx.endlessMode = (ctx.selectedGameMode == GAME_MODE_ENDLESS);
    ctx.maxWaves = STORY_MAX_WAVES;
    ctx.gamePaused = false;
    ctx.gamePauseAccumMs = 0;
    ctx.gamePauseStartMs = 0;
    ctx.weaponUnlockBannerTimer = 0;
    ctx.weaponUnlockBannerText = "";
    ctx.player = new Player(0, 0);
    ctx.player.resetWeaponsForMode(ctx.endlessMode);
    ctx.bullets.clear();
    ctx.enemyBullets.clear();
    ctx.bandits.clear();
    ctx.pendingBanditSpawns.clear();
    ctx.previewSpawnMarkers.clear();
    ctx.waveSpawning = false;
    ctx.wavePreviewTimer = 0;
    ctx.waveBannerTimer = 0;
    ctx.shellCasings.clear();
    ctx.camShakeAmp = 0;
    ctx.camShakePx = 0;
    ctx.muzzleFlashes.clear();
    ctx.hitSparks.clear();
    ctx.lootPickups.clear();
    ctx.pickupPlusFx.clear();
    ctx.gibChunks.clear();
    ctx.bloodParticles.clear();
    ctx.sprintTrailPuffs.clear();
    ctx.sprintTrailScreenDots.clear();
    ctx.sprintTrailEmitAccum = 0;
    ctx.ammoGainFx.clear();
    ctx.playerGoreSpawned = false;
    ctx.kills = 0;
    ctx.score = 0;
    ctx.extraTimeSec = 0;
    ctx.finished = false;
    ctx.gameStateText = "";
    ctx.runStatsPersisted = false;
    ctx.waveState = WAVE_STATE_FIGHT;
    ctx.waveBreakTimer = 0;
    ctx.currentWave = 1;
    ctx.hurtShakePx = 0;
    ctx.hurtRing = 0;
    ctx.lastHp = 100;
    ctx.sprintHeld = false;
    ctx.sprintBarFocus = 0;
    spawnWave(1);
    audio.startMusicIfAny();
  }

  void updateWaveTimers(float dt) {
    if (ctx.waveState != WAVE_STATE_BREAK) return;
    ctx.waveBreakTimer -= dt;
    if (ctx.waveBreakTimer > 0) return;
    ctx.currentWave++;
    if (!ctx.endlessMode && ctx.currentWave > ctx.maxWaves) {
      ctx.finished = true;
      ctx.gameStateText = "YOU WIN";
      audio.playWavSafe("win.wav");
      ctx.waveState = WAVE_STATE_FIGHT;
      return;
    }
    spawnWave(ctx.currentWave);
    ctx.waveState = WAVE_STATE_FIGHT;
  }

  void updateWaveIntro(float dt) {
    if (ctx.waveBannerTimer > 0) ctx.waveBannerTimer -= dt;
    if (ctx.wavePreviewTimer <= 0) return;
    ctx.wavePreviewTimer -= dt;
    if (ctx.wavePreviewTimer <= 0) beginStaggeredSpawnsFromPending();
  }

  void beginStaggeredSpawnsFromPending() {
    if (ctx.pendingBanditSpawns.size() == 0) {
      ctx.waveSpawning = false;
      return;
    }
    PendingBandit first = ctx.pendingBanditSpawns.remove(0);
    ctx.bandits.add(new Bandit(first.x, first.z, first.outfit, first.spdMul, first.hpMul, first.wave, first.weaponType));
    ctx.waveSpawning = ctx.pendingBanditSpawns.size() > 0;
    ctx.staggerSpawnTimer = STAGGER_SPAWN_INTERVAL;
  }

  void applyWeaponUnlocksForWave(int w) {
    if (ctx.endlessMode || ctx.player == null) return;
    if (w >= UNLOCK_SHOTGUN_WAVE && !ctx.player.isWeaponUnlocked(1)) {
      ctx.player.unlockWeaponSlot(1);
      ctx.weaponUnlockBannerText = "SHOTGUN UNLOCKED";
      ctx.weaponUnlockBannerTimer = 3.5f;
    }
    if (w >= UNLOCK_REPEATER_WAVE && !ctx.player.isWeaponUnlocked(2)) {
      ctx.player.unlockWeaponSlot(2);
      ctx.weaponUnlockBannerText = "REPEATER UNLOCKED";
      ctx.weaponUnlockBannerTimer = 3.5f;
    }
  }

  int banditCountForWave(int w) {
    if (ctx.endlessMode && w > STORY_MAX_WAVES) {
      return min(8, 5 + (w - STORY_MAX_WAVES) / 2);
    }
    return max(2, min(6, 2 + (w - 1) / 2));
  }

  void spawnWave(int w) {
    applyWeaponUnlocksForWave(w);
    ctx.bandits.clear();
    ctx.enemyBullets.clear();
    ctx.bullets.clear();
    ctx.pendingBanditSpawns.clear();
    ctx.previewSpawnMarkers.clear();
    int n = banditCountForWave(w);
    int[] outfits = {
      p.color(180, 60, 50), p.color(160, 100, 50), p.color(130, 60, 90),
      p.color(80, 120, 145), p.color(100, 80, 60)
    };
    ArrayList<PVector> usedSpawns = new ArrayList<PVector>();
    float hpMul = 1 + 0.05f * (w - 1);
    float spdMul = 1 + 0.03f * (w - 1);
    if (ctx.endlessMode && w > STORY_MAX_WAVES) {
      hpMul += 0.035f * (w - STORY_MAX_WAVES);
      spdMul += 0.018f * (w - STORY_MAX_WAVES);
    }
    for (int i = 0; i < n; i++) {
      PVector sp = randomBanditSpawnForWave(i, n, w, usedSpawns);
      if (world.circleOverlapsColliderXZ(sp.x, sp.z, 20)) world.nudgeToClearPosition(sp, 20);
      usedSpawns.add(sp.copy());
      ctx.previewSpawnMarkers.add(sp.copy());
      int wpn = rollBanditWeaponForWave(w);
      ctx.pendingBanditSpawns.add(new PendingBandit(
        sp.x, sp.z, outfits[i % outfits.length], spdMul, hpMul, w, wpn
      ));
    }
    ctx.wavePreviewTimer = WAVE_PREVIEW_DURATION;
    ctx.waveBannerTimer = WAVE_BANNER_DURATION;
    ctx.waveBannerNumber = w;
    ctx.waveSpawning = false;
    ctx.staggerSpawnTimer = STAGGER_SPAWN_INTERVAL;
  }

  int rollBanditWeaponForWave(int w) {
    float r = p.random(1);
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

  PVector randomBanditSpawnForWave(int index, int total, int wave, ArrayList<PVector> used) {
    float spawnR = 22;
    float minFromPlayer = 600 + wave * 45;
    float maxFromPlayer = min(ctx.arenaHalfW, ctx.arenaHalfH) * 0.78f;
    float minSep = 190;
    for (int attempt = 0; attempt < 140; attempt++) {
      float sector = (index + 0.5f) / max(1, total);
      float a = sector * TWO_PI + p.random(-0.42f, 0.42f);
      float ring = p.random(minFromPlayer, maxFromPlayer);
      float rx = ctx.player.pos.x + cos(a) * ring;
      float rz = ctx.player.pos.z + sin(a) * ring;
      if (!world.isInArenaXZ(rx, rz, 90)) continue;
      float dx = rx - ctx.player.pos.x, dz = rz - ctx.player.pos.z;
      if (dx * dx + dz * dz < minFromPlayer * minFromPlayer) continue;
      if (!farEnoughFromOthers(rx, rz, used, minSep)) continue;
      if (!world.isWalkableSpawnXZ(rx, rz, spawnR)) continue;
      return new PVector(rx, 0, rz);
    }
    for (int attempt = 0; attempt < 80; attempt++) {
      float a = p.random(TWO_PI);
      float ring = p.random(minFromPlayer, maxFromPlayer);
      float rx = ctx.player.pos.x + cos(a) * ring;
      float rz = ctx.player.pos.z + sin(a) * ring;
      if (!world.isInArenaXZ(rx, rz, 90)) continue;
      float dx = rx - ctx.player.pos.x, dz = rz - ctx.player.pos.z;
      if (dx * dx + dz * dz < minFromPlayer * minFromPlayer) continue;
      if (!farEnoughFromOthers(rx, rz, used, minSep * 0.85f)) continue;
      if (!world.isWalkableSpawnXZ(rx, rz, spawnR)) continue;
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
      ctx.player.pos.x + cos(fallbackAng) * minFromPlayer,
      0,
      ctx.player.pos.z + sin(fallbackAng) * minFromPlayer
    );
  }

  PVector tryBanditSpawnPoint(float x, float z, float spawnR) {
    PVector pos = new PVector(x, 0, z);
    if (world.circleOverlapsColliderXZ(pos.x, pos.z, spawnR)) world.nudgeToClearPosition(pos, spawnR);
    if (world.isWalkableSpawnXZ(pos.x, pos.z, spawnR)) return pos;
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

  void updateGameState(float t) {
    if (ctx.finished) return;
    float remaining = max(0, ctx.gameDurationSec + ctx.extraTimeSec - t);
    if (remaining <= 0) {
      ctx.finished = true;
      ctx.gameStateText = "TIME OVER";
      audio.playWavSafe("lose.wav");
      return;
    }
    if (ctx.player.hp <= 0) {
      ctx.finished = true;
      ctx.gameStateText = "YOU LOST";
      audio.playWavSafe("lose.wav");
      return;
    }
    if (ctx.waveState != WAVE_STATE_FIGHT) return;
    if (ctx.wavePreviewTimer > 0) return;
    if (ctx.waveSpawning || ctx.pendingBanditSpawns.size() > 0) return;
    int aliveCount = 0;
    for (Bandit b : ctx.bandits) {
      if (b.alive) aliveCount++;
    }
    if (aliveCount == 0 && ctx.bandits.size() > 0) {
      if (!ctx.endlessMode && ctx.currentWave >= STORY_MAX_WAVES) {
        ctx.finished = true;
        ctx.gameStateText = "YOU WIN";
        audio.playWavSafe("win.wav");
      } else {
        ctx.waveState = WAVE_STATE_BREAK;
        ctx.waveBreakTimer = WAVE_BREAK_DURATION;
        ctx.extraTimeSec += 18;
        ctx.addScore(50 * ctx.currentWave);
        audio.playWavSafe("wave_clear.wav");
      }
    }
  }

  void forceCompleteCurrentWave() {
    if (ctx.finished || ctx.gameFlow != FLOW_PLAY || ctx.waveState != WAVE_STATE_FIGHT) return;
    ctx.pendingBanditSpawns.clear();
    ctx.waveSpawning = false;
    ctx.wavePreviewTimer = 0;
    ctx.staggerSpawnTimer = 0;
    for (Bandit b : ctx.bandits) {
      b.alive = false;
      b.hp = 0;
    }
    if (!ctx.endlessMode && ctx.currentWave >= STORY_MAX_WAVES) {
      ctx.finished = true;
      ctx.gameStateText = "YOU WIN";
      audio.playWavSafe("win.wav");
      return;
    }
    ctx.waveState = WAVE_STATE_BREAK;
    ctx.waveBreakTimer = WAVE_BREAK_DURATION;
    ctx.extraTimeSec += 18;
    ctx.addScore(50 * ctx.currentWave);
    audio.playWavSafe("wave_clear.wav");
  }

  void registerBanditLootDrop(float x, float z) {
    int lk = p.random(1) < 0.45 ? LootPickup.LOOT_HEALTH : LootPickup.LOOT_AMMO;
    ctx.lootPickups.add(new LootPickup(x + p.random(-6, 6), z + p.random(-6, 6), lk));
  }
}
