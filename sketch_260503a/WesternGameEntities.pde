// Player, bandits, bullets, loot, gore VFX — compiled with the sketch.

class PendingBandit {
  float x, z, spdMul, hpMul;
  int outfit, wave, weaponType;

  PendingBandit(float x, float z, int outfit, float spdMul, float hpMul, int wave, int weaponType) {
    this.x = x;
    this.z = z;
    this.outfit = outfit;
    this.spdMul = spdMul;
    this.hpMul = hpMul;
    this.wave = wave;
    this.weaponType = weaponType;
  }
}

class Player {
  PVector pos;
  float speed = 280;
  float facing = 0;
  float hp = 100;
  float maxHp = 100;
  int lastShotMs = -9999;
  float walkPhase = 0;
  boolean moving = false;

  int weaponSlot = 0;
  int[] wMax = {30, 8, 40};
  int[] wAmmo = {30, 8, 40};
  float[] wReloadSec = {1.45, 2.25, 1.35};
  float[] wCooldown = {0.17, 0.5, 0.11};

  boolean reloading = false;
  float reloadTimer = 0;
  float recoilKick = 0;
  float knockbackVx = 0;
  float knockbackVz = 0;

  float stamina = 1;
  boolean[] weaponUnlocked = {true, false, false};

  Player(float x, float z) {
    pos = new PVector(x, 0, z);
  }

  boolean isWeaponUnlocked(int slot) {
    return slot >= 0 && slot < 3 && weaponUnlocked[slot];
  }

  void resetWeaponsForMode(boolean allUnlocked) {
    weaponSlot = 0;
    weaponUnlocked[0] = true;
    weaponUnlocked[1] = allUnlocked;
    weaponUnlocked[2] = allUnlocked;
    wAmmo[0] = wMax[0];
    wAmmo[1] = allUnlocked ? wMax[1] : 0;
    wAmmo[2] = allUnlocked ? wMax[2] : 0;
    reloading = false;
    reloadTimer = 0;
  }

  void unlockWeaponSlot(int slot) {
    if (slot < 0 || slot > 2) return;
    if (weaponUnlocked[slot]) return;
    weaponUnlocked[slot] = true;
    wAmmo[slot] = wMax[slot];
  }

  String weaponName() {
    if (weaponSlot == 0) return "Revolver";
    if (weaponSlot == 1) return "Shotgun";
    return "Repeater";
  }

  void setWeaponSlot(int s, GameContext ctx) {
    if (ctx.finished) return;
    s = constrain(s, 0, 2);
    if (!isWeaponUnlocked(s)) return;
    weaponSlot = s;
    reloading = false;
    reloadTimer = 0;
  }

  void cycleWeapon(int dir, GameContext ctx) {
    if (ctx.finished) return;
    for (int step = 0; step < 3; step++) {
      int next = (weaponSlot + dir + 3) % 3;
      if (isWeaponUnlocked(next)) {
        setWeaponSlot(next, ctx);
        return;
      }
      weaponSlot = next;
    }
  }

  void startReload(GameContext ctx, AudioManager audio) {
    if (reloading || !isWeaponUnlocked(weaponSlot)) return;
    if (wAmmo[weaponSlot] >= wMax[weaponSlot] || ctx.finished) return;
    reloading = true;
    reloadTimer = wReloadSec[weaponSlot];
    if (weaponSlot == 1) {
      audio.playSoundSafe("shotgun-reload-sfx.wav", "gun_reload.wav", "reload.wav");
    } else {
      audio.playWavSafe("reload.wav");
    }
  }

  void updateReload(float dt) {
    if (!reloading) return;
    reloadTimer -= dt;
    if (reloadTimer <= 0) {
      wAmmo[weaponSlot] = wMax[weaponSlot];
      reloading = false;
    }
  }

  void updateAim(PVector aim) {
    float dx = aim.x - pos.x;
    float dz = aim.z - pos.z;
    if (dx * dx + dz * dz > 0.001) facing = atan2(dx, dz);
  }

  void update(float t, float dt, GameContext ctx) {
    if (moving) walkPhase += dt * 9;
    else walkPhase += dt * 1.5;
    updateReload(dt);
    recoilKick = max(0, recoilKick - dt * 8.5);
    if (knockbackVx * knockbackVx + knockbackVz * knockbackVz > 1) {
      pos.x += knockbackVx * dt;
      pos.z += knockbackVz * dt;
      session.world.resolveCircleColliders(pos, 26);
      float damp = max(0, 1 - dt * 10.5f);
      knockbackVx *= damp;
      knockbackVz *= damp;
    }
    if (ctx.sprintHeld && moving && stamina > 0 && !ctx.finished && ctx.waveState == WAVE_STATE_FIGHT) {
      stamina = max(0, stamina - dt * 0.62);
    } else {
      stamina = min(1, stamina + dt * 0.38);
    }
  }

  ArrayList<Bullet> tryShootVolley(PVector aim, GameContext ctx, AudioManager audio) {
    ArrayList<Bullet> list = new ArrayList<Bullet>();
    if (reloading || ctx.finished || ctx.waveState != WAVE_STATE_FIGHT) return list;
    if (!isWeaponUnlocked(weaponSlot)) return list;
    if (wAmmo[weaponSlot] <= 0) return list;
    int now = millis();
    if ((now - lastShotMs) / 1000.0 < wCooldown[weaponSlot]) return list;
    lastShotMs = now;
    wAmmo[weaponSlot]--;
    recoilKick = weaponSlot == 1 ? 1.35 : 1.0;

    PVector tip = gunTip();
    PVector dir = new PVector(aim.x - tip.x, 0, aim.z - tip.z);
    if (dir.magSq() < 0.001) dir = new PVector(sin(facing), 0, cos(facing));
    dir.normalize();

    if (weaponSlot == 1) {
      float spd = 980;
      for (int i = -2; i <= 2; i++) {
        PVector d = session.world.rotateDirXZ(dir, i * 0.095);
        list.add(new Bullet(tip, PVector.mult(d, spd), 24, Bullet.KIND_SHOTGUN));
      }
      knockbackVx -= dir.x * 480f;
      knockbackVz -= dir.z * 480f;
    } else if (weaponSlot == 2) {
      list.add(new Bullet(tip, PVector.mult(dir, 1180), 19, Bullet.KIND_REPEATER));
    } else {
      list.add(new Bullet(tip, PVector.mult(dir, 1060), 30, Bullet.KIND_REVOLVER));
    }
    if (weaponSlot == 1) {
      audio.playSoundSafe("shotgun-firing.wav", "gun_player.wav");
    } else {
      audio.playWavSafe("gun_player.wav");
    }
    return list;
  }

  /** Muzzle tip — offset per weapon model. */
  PVector gunTip() {
    float rk = recoilKick;
    float lx = 13, ly = -50, lz = 56 - rk * 11;
    if (weaponSlot == 1) {
      lx = 14;
      ly = -48;
      lz = 44 - rk * 13;
    } else if (weaponSlot == 2) {
      lx = 12;
      ly = -50;
      lz = 78 - rk * 15;
    }
    float c = cos(facing), s = sin(facing);
    float wx = lx * c + lz * s;
    float wz = -lx * s + lz * c;
    return new PVector(pos.x + wx, ly + rk * 2.5, pos.z + wz);
  }

  void drawPlayerWeapon(float rk, float swing) {
    pushMatrix();
    translate(12, -51, 42);
    rotateX(rk * 0.55 + swing * 0.08);
    rotateZ(rk * 0.1);
    if (weaponSlot == 1) drawShotgunModel(rk);
    else if (weaponSlot == 2) drawRepeaterModel(rk);
    else drawRevolverModel(rk);
    popMatrix();
  }

  void drawRevolverModel(float rk) {
    translate(0, rk * 4, -rk * 16);
    noStroke();
    fill(42, 32, 22);
    box(5, 7, 12);
    fill(48, 48, 52);
    translate(0, -1, -9);
    box(7, 7, 5);
    fill(38, 38, 42);
    translate(0, 0, -7);
    box(3, 3, 14);
    fill(95, 70, 40);
    translate(0, -3, -5);
    box(5, 2, 3);
  }

  void drawShotgunModel(float rk) {
    translate(0, rk * 5, -rk * 18);
    noStroke();
    fill(52, 38, 24);
    box(6, 8, 18);
    fill(46, 46, 50);
    translate(0, 1, -11);
    box(9, 10, 11);
    fill(40, 40, 44);
    translate(-2.5f, 1, -12);
    box(2.5f, 2.5f, 22);
    translate(5, 0, 0);
    box(2.5f, 2.5f, 22);
    fill(72, 58, 38);
    translate(-2.5f, 4, -16);
    box(11, 3, 7);
    fill(35, 35, 38);
    translate(2.5f, -1, -20);
    box(3, 4, 4);
  }

  void drawRepeaterModel(float rk) {
    translate(0, rk * 4, -rk * 20);
    noStroke();
    fill(58, 40, 24);
    box(5, 7, 20);
    fill(50, 50, 55);
    translate(0, 0, -12);
    box(7, 8, 12);
    fill(42, 42, 48);
    translate(0, 1, -20);
    box(3, 3, 38);
    fill(130, 100, 45);
    translate(0, -5, -6);
    box(9, 2, 4);
    fill(95, 70, 40);
    translate(0, -4, -2);
    box(4, 3, 2);
  }

  void display(float t, SceneRenderer scene) {
    pushMatrix();
    translate(pos.x, CHARACTER_GROUND_OFFSET, pos.z);
    rotateY(facing);
    noStroke();

    float breath = sin(t * 2.4) * 0.7;
    float sway = moving ? sin(walkPhase * 0.5) * 0.07 : sin(t * 1.2) * 0.02;
    float swing = moving ? sin(walkPhase) * 0.55 : sin(t * 1.6) * 0.06;
    float rk = recoilKick;

    translate(0, breath, 0);
    rotateY(sway);

    pushMatrix();
    translate(-7, -6, sin(walkPhase) * (moving ? 5 : 0));
    rotateX(swing);
    fill(35, 22, 12);
    box(10, 14, 14);
    popMatrix();

    pushMatrix();
    translate(7, -6, -sin(walkPhase) * (moving ? 5 : 0));
    rotateX(-swing);
    fill(35, 22, 12);
    box(10, 14, 14);
    popMatrix();

    pushMatrix();
    translate(-7, -22, sin(walkPhase) * (moving ? 3 : 0));
    rotateX(swing * 0.75);
    rotateZ(sin(walkPhase * 0.5) * (moving ? 0.06 : 0));
    fill(40, 50, 90);
    box(10, 20, 12);
    popMatrix();

    pushMatrix();
    translate(7, -22, -sin(walkPhase) * (moving ? 3 : 0));
    rotateX(-swing * 0.75);
    fill(40, 50, 90);
    box(10, 20, 12);
    popMatrix();

    pushMatrix();
    rotateX(sin(t * 1.9) * 0.035);
    rotateZ(swing * 0.12);
    translate(0, -42, sin(walkPhase * 2) * (moving ? 1.2 : 0));
    fill(58, 96, 145);
    box(22, 30, 28);
    pushMatrix();
    translate(0, 8, -10);
    fill(48, 80, 125);
    box(22, 16, 8);
    popMatrix();
    popMatrix();

    pushMatrix();
    translate(0, -34, 0);
    rotateX(sin(t * 2.1) * 0.02);
    fill(80, 60, 30);
    box(30, 4, 24);
    fill(220, 180, 60);
    translate(0, 0, 13);
    box(7, 5, 1);
    popMatrix();

    pushMatrix();
    translate(0, -48, 12);
    fill(160, 30, 30);
    box(20, 18, 1);
    popMatrix();

    pushMatrix();
    translate(-16, -50, 0);
    rotateX(swing * 1.15 + sin(t * 3) * 0.04);
    rotateZ(-0.08);
    fill(58, 96, 145);
    box(8, 22, 8);
    fill(238, 208, 170);
    translate(0, 12, 0);
    sphere(5);
    popMatrix();

    pushMatrix();
    translate(11, -49, 10);
    rotateX(swing * 0.35 + rk * 0.5);
    rotateZ(-PI / 2.8 + rk * 0.12);
    fill(58, 96, 145);
    box(7, 18, 7);
    popMatrix();

    pushMatrix();
    translate(0, -68, 0);
    rotateX(sin(t * 2.8) * 0.04);
    rotateY(sin(t * 1.7) * 0.05);
    fill(238, 208, 170);
    sphere(11);
    fill(58, 38, 22);
    translate(0, 4, 8);
    box(12, 2, 2);
    popMatrix();

    float hatBob = sin(t * 6.2f + walkPhase * 1.7f) * (moving ? 2.2f : 0.9f);
    float hatTiltX = sin(t * 4.1f + walkPhase) * (moving ? 0.06f : 0.025f);
    float hatTiltZ = cos(t * 5.3f + walkPhase * 0.8f) * (moving ? 0.04f : 0.02f);
    pushMatrix();
    translate(0, -78 + hatBob, 0);
    rotateX(hatTiltX);
    rotateZ(hatTiltZ);
    fill(72, 48, 26);
    scene.drawCylinder(17, 3, 16);
    translate(0, -8, 0);
    scene.drawCylinder(11, 14, 14);
    fill(180, 30, 30);
    translate(0, 6, 0);
    scene.drawCylinder(11.5, 2, 14);
    popMatrix();

    drawPlayerWeapon(rk, swing);

    popMatrix();
  }
}

class Bandit {
  PVector pos;
  float maxHp = 100;
  float hp = 100;
  int outfit;
  float speed;
  float phase;
  boolean alive = true;
  float hitFlashSec = 0;
  int lastDamageMs = -9999;
  int lastShotMs = -9999;
  float walkPhase = 0;
  int waveIndex = 1;
  int weaponType = BANDIT_WPN_REVOLVER;
  float recoilKick = 0;
  float stuckSec = 0;
  float lastMoveDist = 0;
  ArrayList<PVector> pathNodes;
  int pathStep = 0;
  float pathRefresh = 0;

  Bandit(float x, float z, int outfit, float speedMul, float hpMul, int wave, int weaponType) {
    pos = new PVector(x, 0, z);
    this.outfit = outfit;
    this.speed = speedMul;
    this.phase = random(TWO_PI);
    this.maxHp = 100 * hpMul;
    this.hp = maxHp;
    this.waveIndex = wave;
    this.weaponType = weaponType;
  }

  float shootIntervalSec() {
    float base = max(0.48f, 1.38f - max(1, session.ctx.currentWave) * 0.06f);
    if (weaponType == BANDIT_WPN_REPEATER) return base * 0.55f;
    if (weaponType == BANDIT_WPN_SHOTGUN) return base * 1.35f;
    return base;
  }

  void update(Player player, GameContext ctx, WorldScene world, AudioManager audio, float t, float dt) {
    if (!alive) return;

    recoilKick = max(0, recoilKick - dt * 7);

    if (ctx.finished || ctx.waveState != WAVE_STATE_FIGHT || ctx.wavePreviewTimer > 0) return;

    PVector toPlayer = PVector.sub(player.pos, pos);
    float dist = toPlayer.mag();

    pathRefresh -= dt;
    if (pathRefresh <= 0 || pathNodes == null || pathNodes.size() == 0) {
      pathRefresh = 0.38f;
      pathNodes = world.findPathWorld(pos.x, pos.z, player.pos.x, player.pos.z);
      pathStep = pathNodes != null && pathNodes.size() > 1 ? 1 : 0;
    }
    if (pathNodes != null && pathStep < pathNodes.size()) {
      PVector wp = pathNodes.get(pathStep);
      float dwp = dist(pos.x, pos.z, wp.x, wp.z);
      if (dwp < 70 && pathStep < pathNodes.size() - 1) pathStep++;
    }

    PVector before = pos.copy();
    if (dist > 1) {
      PVector wish;
      if (pathNodes != null && pathStep < pathNodes.size()) {
        PVector wp = pathNodes.get(pathStep);
        wish = new PVector(wp.x - pos.x, 0, wp.z - pos.z);
        if (wish.magSq() < 1) wish = toPlayer.copy();
      } else {
        wish = toPlayer.copy();
      }
      if (wish.magSq() > 1e-6) wish.normalize();

      PVector tangent = new PVector(-toPlayer.z, 0, toPlayer.x);
      float strafeAmt = sin(t * 2.5f + phase) * 0.22f;
      if (dist < 58) {
        wish.mult(-0.45f);
        wish.add(PVector.mult(tangent, strafeAmt * 1.1f));
      } else if (dist < 120) {
        wish.add(PVector.mult(tangent, strafeAmt * 0.5f));
      }
      if (wish.magSq() > 1e-6) wish.normalize();

      PVector avoid = world.colliderSteerForce(pos.x, pos.z, 20);
      if (avoid.magSq() > 0.01f) {
        wish.add(PVector.mult(avoid, 1.35f));
        if (wish.magSq() > 1e-6) wish.normalize();
      }

      float stepLen = speed * 85 * dt;
      PVector delta = world.pickClearStepXZ(pos, wish, stepLen, 18);
      if (delta.magSq() < stepLen * stepLen * 0.06f && dist > 45) {
        delta = world.pickClearStepXZ(pos, wish, stepLen * 1.4f, 16);
        if (delta.magSq() < 1) {
          for (int tryDir = 0; tryDir < 8; tryDir++) {
            float a = tryDir * TWO_PI / 8.0f;
            PVector probe = new PVector(cos(a), 0, sin(a));
            delta = world.pickClearStepXZ(pos, probe, stepLen, 18);
            if (delta.magSq() > 1) break;
          }
        }
      }
      pos.add(delta);
      walkPhase += dt * 9;
    }

    pos.x = constrain(pos.x, -ctx.arenaHalfW + 70, ctx.arenaHalfW - 70);
    pos.z = constrain(pos.z, -ctx.arenaHalfH + 70, ctx.arenaHalfH - 70);
    world.resolveCircleColliders(pos, 18, 14);

    lastMoveDist = dist(before.x, before.z, pos.x, pos.z);
    if (lastMoveDist < 0.8f * speed * 85 * dt && dist > 50) stuckSec += dt;
    else stuckSec = max(0, stuckSec - dt * 2);
    if (stuckSec > 0.35f) world.unstuckBandit(this, player);

    if (dist < 56) {
      int now = millis();
      if (now - lastDamageMs > 680) {
        player.hp -= 6;
        lastDamageMs = now;
        audio.playWavSafe("hit_player.wav");
      }
    }

    if (dist > 95 && dist < 620) {
      int now = millis();
      if (now - lastShotMs > shootIntervalSec() * 1000) {
        lastShotMs = now;
        recoilKick = weaponType == BANDIT_WPN_SHOTGUN ? 1.15f : 0.95f;
        fireAtPlayer(player, ctx, audio);
      }
    }

    hitFlashSec = max(0, hitFlashSec - dt);
  }

  void fireAtPlayer(Player player, GameContext ctx, AudioManager audio) {
    float yaw = atan2(player.pos.x - pos.x, player.pos.z - pos.z);
    float rk = recoilKick;
    float lx = 5, ly = -49, lz = 52 - rk * 9;
    float c = cos(yaw), s = sin(yaw);
    PVector tip = new PVector(pos.x + lx * c + lz * s, ly + rk * 2, pos.z - lx * s + lz * c);
    PVector dir = PVector.sub(player.pos, tip);
    dir.y = 0;
    if (dir.magSq() < 4) return;
    dir.normalize();
    if (weaponType == BANDIT_WPN_SHOTGUN) {
      for (int i = -2; i <= 2; i++) {
        PVector d = session.world.rotateDirXZ(dir, i * 0.11f);
        ctx.enemyBullets.add(new EnemyBullet(tip, PVector.mult(d, 420), 6));
      }
    } else if (weaponType == BANDIT_WPN_REPEATER) {
      ctx.enemyBullets.add(new EnemyBullet(tip, PVector.mult(dir, 620), 8));
    } else {
      ctx.enemyBullets.add(new EnemyBullet(tip, PVector.mult(dir, 520), 11));
    }
    audio.playEnemyGunSound();
  }

  /** @return true if this hit killed the bandit (loot is spawned from main sketch). */
  boolean takeHit(float dmg, GameContext ctx, AudioManager audio, GameSession session) {
    if (!alive) return false;
    hp -= dmg;
    hitFlashSec = 0.18;
    audio.playWavSafe("hit_enemy.wav");

    for (int i = 0; i < 7; i++) {
      float a = random(TWO_PI);
      float p = random(0.5, 1.4);
      ctx.hitSparks.add(new HitSpark(pos.x, -45, pos.z,
        cos(a) * p * 130, -random(60, 200), sin(a) * p * 130));
    }

    if (hp <= 0) {
      hp = 0;
      alive = false;
      ctx.addKill();
      ctx.addScore(100 * ctx.currentWave + 15);

      session.spawnBanditGore(pos.x, pos.z, outfit);

      for (int i = 0; i < 12; i++) {
        float a = random(TWO_PI);
        float p = random(0.35, 1.2);
        ctx.hitSparks.add(new HitSpark(pos.x, -40, pos.z,
          cos(a) * p * 140, -random(90, 240), sin(a) * p * 140));
      }
      return true;
    }
    return false;
  }

  void display(float t, Player player, SceneRenderer scene) {
    if (!alive) return;

    pushMatrix();
    translate(pos.x, CHARACTER_GROUND_OFFSET, pos.z);
    float bob = sin(t * 8.0 + phase) * 2.2;
    translate(0, bob, 0);
    rotateY(atan2(player.pos.x - pos.x, player.pos.z - pos.z));

    drawBanditModel(t, scene);
    popMatrix();
  }

  void drawBanditModel(float t, SceneRenderer scene) {
    noStroke();
    float fa = constrain(hitFlashSec / 0.11, 0, 1);
    float swing = sin(walkPhase) * 0.58;
    float rk = recoilKick;
    float idle = sin(t * 2.2 + phase) * 0.6;
    float bob = sin(walkPhase * 2.1 + phase) * 1.3;
    int style = abs(outfit) % 5;
    float bodyScale = 1.0;
    if (style == 1) bodyScale = 1.06f;
    if (style == 3) bodyScale = 0.94f;
    int coat = outfit;
    int vest = color(red(outfit) * 0.72, green(outfit) * 0.72, blue(outfit) * 0.72);
    int scarf = color(160, 42, 38);
    if (style == 0) scarf = color(180, 50, 42);
    if (style == 2) scarf = color(90, 110, 150);
    if (style == 4) scarf = color(120, 95, 50);

    pushMatrix();
    translate(-7, -6, 0);
    rotateX(swing);
    fill(40, 24, 12);
    box(10, 14, 14);
    popMatrix();

    pushMatrix();
    translate(7, -6, 0);
    rotateX(-swing);
    fill(40, 24, 12);
    box(10, 14, 14);
    popMatrix();

    pushMatrix();
    translate(-7, -22, 0);
    rotateX(swing * 0.85);
    rotateZ(sin(walkPhase * 0.55) * 0.08);
    fill(75, 50, 30);
    box(10, 20, 12);
    popMatrix();

    pushMatrix();
    translate(7, -22, 0);
    rotateX(-swing * 0.85);
    fill(75, 50, 30);
    box(10, 20, 12);
    popMatrix();

    pushMatrix();
    translate(0, bob, 0);
    rotateX(sin(walkPhase * 1.8 + phase) * 0.05);
    rotateZ(swing * 0.14);
    scale(bodyScale, bodyScale, bodyScale);
    translate(0, -44, 0);
    fill(coat);
    box(28, 32, 22);
    fill(vest);
    pushMatrix();
    translate(0, 4, 12);
    box(28, 18, 2);
    if (style == 2) {
      fill(60, 75, 95);
      translate(0, 6, 1);
      box(16, 14, 2);
    }
    popMatrix();
    popMatrix();

    pushMatrix();
    translate(0, -64 + bob * 0.4 + idle * 0.15, 6);
    rotateX(sin(t * 2.6 + phase) * 0.06);
    fill(scarf);
    box(15, 8, 3);
    popMatrix();

    pushMatrix();
    translate(0, -68 + bob * 0.25, 0);
    rotateX(sin(t * 3 + phase) * 0.05);
    rotateY(sin(t * 1.4 + phase) * 0.06);
    fill(225, 194, 152);
    sphere(11);
    if (style == 4) {
      fill(50, 35, 22);
      translate(0, 4, 10);
      box(14, 2, 2);
    }
    popMatrix();

    drawBanditHatStyle(style, t, walkPhase, phase, bob, scene);

    pushMatrix();
    translate(-14, -50 + bob * 0.2, 0);
    rotateX(swing * 1.1 + sin(t * 2.8 + phase) * 0.06);
    rotateZ(0.06);
    fill(coat);
    box(8, 22, 8);
    popMatrix();

    pushMatrix();
    translate(11, -49, 12);
    rotateX(swing * 0.4 + rk * 0.45);
    rotateZ(-PI / 2.9 + rk * 0.14);
    fill(coat);
    box(7, 17, 7);
    popMatrix();

    drawBanditWeaponModel(rk, swing);

    if (fa > 0.03) {
      pushMatrix();
      translate(0, -46, 0);
      noStroke();
      blendMode(BLEND);
      emissive(255, 235, 210);
      fill(255, 250, 245, min(255, fa * 220));
      sphere(10 + fa * 16);
      emissive(0, 0, 0);
      popMatrix();
    }
  }

  void drawBanditWeaponModel(float rk, float swing) {
    pushMatrix();
    translate(5, -49, 44);
    rotateX(rk * 0.5 + swing * 0.1);
    rotateZ(rk * 0.09);
    translate(0, rk * 3.5, -rk * 14);
    fill(42);
    if (weaponType == BANDIT_WPN_SHOTGUN) {
      box(6, 5, 18);
      fill(48);
      box(7, 4, 16);
    } else if (weaponType == BANDIT_WPN_REPEATER) {
      box(3, 3, 38);
      fill(48);
      box(4, 3, 34);
    } else {
      box(4, 4, 30);
      fill(48);
      box(5, 4, 26);
    }
    popMatrix();
  }

  void drawBanditHatStyle(int style, float t, float walkPhase, float phase, float bob, SceneRenderer scene) {
    float hatBob = sin(t * 6.2f + walkPhase * 1.7f + phase) * 1.9f;
    float hatTiltX = sin(t * 4.1f + walkPhase + phase * 0.5f) * 0.05f;
    float hatTiltZ = cos(t * 5.3f + walkPhase * 0.8f + phase) * 0.035f;
    pushMatrix();
    translate(0, -78 + hatBob, 0);
    rotateX(hatTiltX);
    rotateZ(hatTiltZ);
    if (style == 0) {
      fill(45, 28, 16);
      scene.drawCylinder(17, 3, 14);
      translate(0, -7, 0);
      scene.drawCylinder(11, 13, 14);
      fill(170, 40, 35);
      translate(0, 5, 0);
      scene.drawCylinder(12, 2, 14);
    } else if (style == 1) {
      fill(35, 35, 38);
      scene.drawCylinder(18, 2, 14);
      translate(0, -8, 0);
      scene.drawCylinder(12, 14, 14);
    } else if (style == 2) {
      fill(55, 38, 22);
      scene.drawCylinder(16, 3, 14);
      translate(0, -6, 0);
      scene.drawCylinder(11, 10, 14);
      fill(90, 70, 45);
      translate(0, 7, 0);
      box(13, 2, 12);
    } else if (style == 3) {
      fill(28, 28, 32);
      scene.drawCylinder(15, 4, 14);
      translate(0, -9, 0);
      scene.drawCylinder(9, 11, 14);
    } else {
      fill(62, 42, 20);
      scene.drawCylinder(16, 3, 14);
      translate(0, -7, 0);
      scene.drawCylinder(10, 12, 14);
      fill(210, 180, 60);
      translate(0, 6, 0);
      box(14, 3, 13);
    }
    popMatrix();
  }
}

class LootPickup {
  static final int LOOT_HEALTH = 0;
  static final int LOOT_AMMO = 1;

  float x, z;
  int kind;
  boolean gone = false;
  float spin;

  LootPickup(float x, float z, int kind) {
    this.x = x;
    this.z = z;
    this.kind = kind;
    spin = random(TWO_PI);
  }

  void update(Player pl, GameSession session) {
    if (gone) return;
    float dx = pl.pos.x - x;
    float dz = pl.pos.z - z;
    if (dx * dx + dz * dz < 36 * 36) {
      gone = true;
      session.spawnPickupPlusBurst(session.p.screenX(x, -70, z), session.p.screenY(x, -70, z), kind);
      if (kind == LOOT_HEALTH) {
        pl.hp = min(pl.maxHp, pl.hp + 28);
        session.audio.playHealthPickupSound();
      } else {
        int sum = 0;
        for (int i = 0; i < 3; i++) {
          if (!pl.isWeaponUnlocked(i)) continue;
          int add = (i == 1 ? 3 : 8);
          int before = pl.wAmmo[i];
          pl.wAmmo[i] = min(pl.wMax[i], pl.wAmmo[i] + add);
          sum += pl.wAmmo[i] - before;
        }
        if (sum > 0) {
          float psx = session.p.screenX(x, -52, z);
          float psy = session.p.screenY(x, -52, z);
          session.spawnAmmoGainFloat(psx, psy, sum);
        }
        session.audio.playBulletPickupSound();
      }
    }
  }

  void display(float t, SceneRenderer scene) {
    if (gone) return;
    float bob = sin(t * 5 + spin) * 7;
    float pulse = 0.82 + 0.18 * sin(t * 7 + spin);
    float glow = 0.65 + 0.35 * sin(t * 4.5 + spin * 0.7);
    pushMatrix();
    translate(x, -18 + bob, z);
    rotateY(t * 1.2 + spin);
    noStroke();
    if (kind == LOOT_HEALTH) {
      pushMatrix();
      rotateX(HALF_PI);
      emissive(255, 40, 35);
      fill(255, 60, 55, (int)(140 * glow));
      ellipse(0, 0, 34 * pulse, 34 * pulse);
      fill(255, 90, 85, (int)(90 * glow));
      ellipse(0, 0, 22 * pulse, 22 * pulse);
      emissive(0, 0, 0);
      popMatrix();

      emissive(120, 20, 18);
      fill(235, 55, 50, (int)(255 * pulse));
      scene.drawCylinder(12 * pulse, 5, 14);
      fill(255, 95, 90);
      translate(0, -12, 0);
      box(4, 18, 4);
      translate(0, 9, 0);
      box(18, 4, 4);
      emissive(255, 80, 75);
      fill(255, 140, 130, (int)(200 * glow));
      translate(0, -3, 0);
      sphere(9 * pulse);
      emissive(0, 0, 0);
    } else {
      fill(72, 48, 28);
      box(18, 12, 14);
      fill(95, 78, 42);
      translate(0, 7, 0);
      box(16, 3, 12);
      fill(120, 115, 105);
      translate(0, -2, 7);
      box(14, 2, 2);
      fill(180, 175, 160);
      for (int i = -2; i <= 2; i++) {
        pushMatrix();
        translate(i * 3.2f, 10, 0);
        scene.drawCylinder(1.4f, 5, 6);
        popMatrix();
      }
      emissive(60, 55, 30);
      fill(255, 230, 120, (int)(100 * pulse));
      translate(0, 14, 0);
      sphere(4);
      emissive(0, 0, 0);
    }
    popMatrix();
  }
}

class Bullet {
  static final int KIND_REVOLVER = 0;
  static final int KIND_SHOTGUN = 1;
  static final int KIND_REPEATER = 2;

  PVector pos, vel, prevPos;
  boolean alive = true;
  float life = 1.5;
  float dmg = 28;
  int kind = KIND_REVOLVER;

  Bullet(PVector start, PVector velocity) {
    this(start, velocity, 28, KIND_REVOLVER);
  }

  Bullet(PVector start, PVector velocity, float dmg) {
    this(start, velocity, dmg, KIND_REVOLVER);
  }

  Bullet(PVector start, PVector velocity, float dmg, int kind) {
    pos = start.copy();
    prevPos = start.copy();
    vel = velocity.copy();
    this.dmg = dmg;
    this.kind = kind;
    if (kind == KIND_SHOTGUN) life = 0.85f;
    if (kind == KIND_REPEATER) life = 1.35f;
  }

  void update(float dt, GameContext ctx) {
    if (!alive) return;
    prevPos = pos.copy();
    pos.add(PVector.mult(vel, dt));
    life -= dt;
    if (life <= 0) alive = false;
    if (abs(pos.x) > ctx.arenaHalfW + 200 || abs(pos.z) > ctx.arenaHalfH + 200) alive = false;
  }

  void display() {
    if (!alive) return;
    noStroke();
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    float yaw = atan2(vel.x, vel.z);

    stroke(255, 0, 0);
    if (kind == KIND_SHOTGUN) {
      strokeWeight(2);
      line(0, 0, 0,
        -(pos.x - prevPos.x), -(pos.y - prevPos.y), -(pos.z - prevPos.z));
      noStroke();
      fill(255, 0, 0);
      sphere(2.8f);
      fill(200, 0, 0);
      sphere(5);
    } else if (kind == KIND_REPEATER) {
      strokeWeight(2);
      line(0, 0, 0,
        -(pos.x - prevPos.x), -(pos.y - prevPos.y), -(pos.z - prevPos.z));
      noStroke();
      rotateY(yaw);
      fill(255, 0, 0);
      box(2, 2, 11);
      fill(220, 0, 0);
      sphere(3);
    } else {
      strokeWeight(3);
      line(0, 0, 0,
        -(pos.x - prevPos.x), -(pos.y - prevPos.y), -(pos.z - prevPos.z));
      noStroke();
      fill(255, 0, 0);
      sphere(4);
      fill(200, 0, 0);
      sphere(8);
    }
    popMatrix();
  }
}

class EnemyBullet {
  PVector pos, vel, prevPos;
  boolean alive = true;
  float life = 2.2;
  float spin = 0;
  float dmg = 14;

  EnemyBullet(PVector start, PVector velocity) {
    this(start, velocity, 14);
  }

  EnemyBullet(PVector start, PVector velocity, float dmg) {
    pos = start.copy();
    prevPos = start.copy();
    vel = velocity.copy();
    this.dmg = dmg;
    spin = random(TWO_PI);
    if (dmg <= 9) life = 1.6f;
  }

  void update(float dt, GameContext ctx) {
    if (!alive) return;
    prevPos = pos.copy();
    vel.y += 38 * dt;
    pos.add(PVector.mult(vel, dt));
    spin += dt * 22;
    life -= dt;
    if (life <= 0) alive = false;
    if (abs(pos.x) > ctx.arenaHalfW + 220 || abs(pos.z) > ctx.arenaHalfH + 220) alive = false;
  }

  void display() {
    if (!alive) return;
    PVector fwd = vel.copy();
    if (fwd.magSq() < 1) fwd = PVector.sub(pos, prevPos);
    if (fwd.magSq() < 1e-4) fwd = new PVector(0, 0, 1);
    fwd.normalize();
    float yaw = atan2(fwd.x, fwd.z);
    float horiz = sqrt(fwd.x * fwd.x + fwd.z * fwd.z);
    float pitch = atan2(-fwd.y, max(0.001, horiz));

    stroke(200, 0, 0);
    strokeWeight(5);
    line(prevPos.x, prevPos.y, prevPos.z, pos.x, pos.y, pos.z);
    stroke(255, 0, 0);
    strokeWeight(3);
    line(prevPos.x, prevPos.y, prevPos.z, pos.x, pos.y, pos.z);
    noStroke();

    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateY(yaw);
    rotateX(pitch);
    rotateZ(sin(spin) * 0.08);

    emissive(255, 0, 0);
    fill(200, 0, 0);
    pushMatrix();
    scale(2.4, 2.4, 1);
    sphere(5);
    popMatrix();
    fill(255, 0, 0);
    pushMatrix();
    scale(1.5, 1.5, 4.2);
    sphere(3);
    popMatrix();
    translate(0, 0, 10);
    sphere(3.2);
    emissive(0, 0, 0);

    popMatrix();
  }
}

class HitSpark extends GameParticle {
  PVector pos, vel;

  HitSpark(float x, float y, float z, float vx, float vy, float vz) {
    super(random(0.25f, 0.5f));
    pos = new PVector(x, y, z);
    vel = new PVector(vx, vy, vz);
  }

  protected void onUpdate(float dt) {
    pos.add(PVector.mult(vel, dt));
    vel.y += 700 * dt;
  }

  public void display() {
    if (!isAlive()) return;
    float a = constrain(life / lifeMax, 0, 1);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    noStroke();
    fill(255, 250, 200, min(255, 280 * a));
    sphere(1.6 + 1.8 * a);
    popMatrix();
  }
}

class GibChunk extends GameParticle {
  PVector pos, vel, rot, rotVel;
  float half;
  int col;
  boolean asSphere;

  GibChunk(float x, float y, float z, PVector v, int c) {
    super(random(1.85f, 2.9f));
    pos = new PVector(x, y, z);
    vel = v;
    rot = new PVector(random(TWO_PI), random(TWO_PI), random(TWO_PI));
    rotVel = new PVector(random(-5.5, 5.5), random(-5.5, 5.5), random(-5.5, 5.5));
    half = random(3.5, 10.5);
    col = c;
    asSphere = random(1) < 0.48;
  }

  protected void onUpdate(float dt) {
    vel.y += 470 * dt;
    pos.add(PVector.mult(vel, dt));
    if (pos.y > 0) {
      pos.y = 0;
      vel.y *= -0.32;
      vel.x *= 0.86;
      vel.z *= 0.86;
    }
    rot.add(PVector.mult(rotVel, dt));
    rotVel.mult(0.988);
  }

  public void display() {
    if (!isAlive()) return;
    float a = constrain(life / lifeMax, 0, 1);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateX(rot.x);
    rotateY(rot.y);
    rotateZ(rot.z);
    noStroke();
    fill(red(col), green(col), blue(col), min(255, 185 + 70 * a));
    if (asSphere) sphere(half);
    else box(half * 2.1, half * 1.35, half * 2.1);
    popMatrix();
  }
}

class BloodParticle extends GameParticle {
  PVector pos, vel;
  float sz;
  int shade;

  BloodParticle(float x, float y, float z, PVector v) {
    super(random(0.5f, 1.05f));
    pos = new PVector(x, y, z);
    vel = v;
    sz = random(2.2, 7);
    shade = (int)random(95, 165);
  }

  protected void onUpdate(float dt) {
    vel.y += 480 * dt;
    pos.add(PVector.mult(vel, dt));
    if (pos.y > 0) {
      pos.y = 0;
      vel.y *= -0.12;
      vel.x *= 0.82;
      vel.z *= 0.82;
    }
    vel.x *= 0.993;
    vel.z *= 0.993;
  }

  public void display() {
    if (!isAlive()) return;
    float a = constrain(life / lifeMax, 0, 1);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateX(HALF_PI);
    noStroke();
    fill(shade, 10, 16, min(255, 230 * a + 20));
    ellipse(0, 0, sz * 2.2 * (0.55 + 0.45 * a), sz * 1.5 * (0.55 + 0.45 * a));
    popMatrix();
  }
}
