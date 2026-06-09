// Muzzle flash, shell casings, HUD particles — GameParticle hierarchy.

class MuzzleFlash extends GameParticle {
  PVector pos;
  float angle;
  int weaponKind;

  MuzzleFlash(PVector pos, float angle, int weaponSlot) {
    super(weaponSlot == 1 ? 0.11f : (weaponSlot == 2 ? 0.09f : 0.07f));
    this.pos = pos.copy();
    this.angle = angle;
    this.weaponKind = weaponSlot;
  }

  protected void onUpdate(float dt) {}

  public void display() {
    if (!isAlive()) return;
    float a = constrain(life / lifeMax, 0, 1);
    float inv = 1 - a;
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateY(angle);
    noStroke();
    blendMode(ADD);

    if (weaponKind == 1) {
      for (int i = -2; i <= 2; i++) {
        pushMatrix();
        rotateY(i * 0.11f);
        translate(0, 0, 2);
        emissive(255, 200, 120);
        fill(255, 220, 150, min(255, 220 * a));
        sphere(4 + 5 * inv);
        emissive(0, 0, 0);
        popMatrix();
      }
    } else if (weaponKind == 2) {
      emissive(200, 230, 255);
      fill(220, 245, 255, min(255, 230 * a));
      box(3, 3, 14 + 8 * inv);
      emissive(0, 0, 0);
    } else {
      emissive(255, 245, 200);
      fill(255, 252, 230, min(255, 250 * a));
      sphere(4 + 2 * inv);
      emissive(0, 0, 0);
    }
    blendMode(BLEND);
    popMatrix();
  }
}

class ShellCasing extends GameParticle {
  PVector pos, vel;
  float rotX, rotY, rotZ;
  float spinX, spinY, spinZ;

  ShellCasing(PVector tip, float facing) {
    super(1.1f);
    pos = tip.copy();
    float side = random(1) < 0.5 ? 1 : -1;
    float eject = random(0.65f, 1.05f);
    vel = new PVector(
      cos(facing + side * 0.55f) * eject * 140,
      random(60, 140),
      sin(facing + side * 0.55f) * eject * 140
    );
    rotX = random(TWO_PI);
    rotY = random(TWO_PI);
    rotZ = random(TWO_PI);
    spinX = random(-9, 9);
    spinY = random(-12, 12);
    spinZ = random(-9, 9);
  }

  protected void onUpdate(float dt) {
    pos.add(PVector.mult(vel, dt));
    vel.y -= 420 * dt;
    vel.x *= max(0, 1 - dt * 1.2f);
    vel.z *= max(0, 1 - dt * 1.2f);
    rotX += spinX * dt;
    rotY += spinY * dt;
    rotZ += spinZ * dt;
    if (pos.y < -8) {
      pos.y = -8;
      vel.y *= -0.35f;
    }
  }

  public void display() {
    if (!isAlive()) return;
    float a = constrain(life / lifeMax, 0, 1);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateY(rotY);
    rotateX(rotX);
    rotateZ(rotZ);
    noStroke();
    fill(210, 175, 55, min(255, 240 * a));
    box(2.2f, 1.1f, 3.2f);
    popMatrix();
  }
}

class AmmoGainFx extends GameParticle {
  float sx, sy;
  String label;
  float driftX;

  AmmoGainFx(float sx, float sy, String label) {
    super(1.08f);
    this.sx = sx;
    this.sy = sy;
    this.label = label;
    this.driftX = random(-40, 40);
  }

  protected void onUpdate(float dt) {
    sy -= dt * 88;
    sx += driftX * dt * 0.4f;
    driftX *= exp(-dt * 2.2f);
  }

  boolean dead() {
    return !isAlive();
  }

  void draw2D(PApplet p) {
    float u = (lifeMax - life) / lifeMax;
    float a = 255 * (1 - u * u);
    if (a < 5) return;
    p.pushStyle();
    p.textAlign(CENTER, CENTER);
    p.textSize(34);
    p.fill(70, 255, 130, a);
    p.text(label, sx, sy);
    p.popStyle();
  }

  public void display() {}
}

class PickupPlusFx extends GameParticle {
  float sx, sy;
  int kind;
  float driftVx;
  float riseSpd;

  PickupPlusFx(float sx, float sy, int kind, float driftVx, float riseSpd) {
    super(0.82f);
    this.sx = sx;
    this.sy = sy;
    this.kind = kind;
    this.driftVx = driftVx;
    this.riseSpd = riseSpd;
  }

  protected void onUpdate(float dt) {
    sy -= dt * riseSpd;
    sx += dt * driftVx;
  }

  boolean dead() {
    return !isAlive();
  }

  void draw2D(PApplet p) {
    float a = 255 * constrain(life / lifeMax, 0, 1);
    if (a < 6) return;
    p.pushStyle();
    p.textAlign(CENTER, CENTER);
    int c = kind == LootPickup.LOOT_AMMO ? p.color(255, 175, 85) : p.color(115, 255, 155);
    p.textSize(24);
    p.fill(c, a);
    p.text("+", sx, sy);
    p.popStyle();
  }

  public void display() {}
}

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
