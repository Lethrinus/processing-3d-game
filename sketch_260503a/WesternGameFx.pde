// Muzzle flash, shell casings — compiled with the sketch.

class MuzzleFlash {
  PVector pos;
  float life = 0.09f;
  float lifeMax = 0.09f;
  float angle;
  int weaponKind;

  MuzzleFlash(PVector pos, float angle, int weaponSlot) {
    this.pos = pos.copy();
    this.angle = angle;
    this.weaponKind = weaponSlot;
    if (weaponSlot == 1) {
      lifeMax = 0.11f;
      life = lifeMax;
    } else if (weaponSlot == 2) {
      lifeMax = 0.09f;
      life = lifeMax;
    } else {
      lifeMax = 0.07f;
      life = lifeMax;
    }
  }

  void update(float dt) {
    life -= dt;
  }

  void display() {
    if (life <= 0) return;
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
        fill(255, 180, 80, min(255, 180 * a));
        sphere(8 + 7 * inv);
        emissive(0, 0, 0);
        popMatrix();
      }
      stroke(255, 230, 160, min(255, 240 * a));
      strokeWeight(2.5f);
      for (int r = 0; r < 14; r++) {
        float ang = TWO_PI * r / 14.0f + angle * 0.2f;
        float r0 = 6 + 8 * inv;
        float r1 = 22 + 18 * inv;
        line(cos(ang) * r0, 0, sin(ang) * r0, cos(ang) * r1, 0, sin(ang) * r1);
      }
    } else if (weaponKind == 2) {
      emissive(200, 230, 255);
      fill(220, 245, 255, min(255, 230 * a));
      box(3, 3, 14 + 8 * inv);
      fill(255, 255, 255, min(255, 200 * a));
      sphere(5 + 4 * inv);
      fill(180, 210, 255, min(255, 160 * a));
      sphere(10 + 6 * inv);
      emissive(0, 0, 0);
      stroke(200, 235, 255, min(255, 220 * a));
      strokeWeight(2);
      for (int i = 0; i < 8; i++) {
        float ang = TWO_PI * i / 8.0f;
        line(cos(ang) * 4, 0, sin(ang) * 4, cos(ang) * (16 + 12 * inv), 0, sin(ang) * (16 + 12 * inv));
      }
    } else {
      emissive(255, 245, 200);
      fill(255, 252, 230, min(255, 250 * a));
      sphere(4 + 2 * inv);
      fill(255, 220, 120, min(255, 200 * a));
      sphere(7 + 4 * inv);
      emissive(0, 0, 0);
      stroke(255, 250, 220, min(255, 230 * a));
      strokeWeight(1.8f);
      for (int i = 0; i < 8; i++) {
        float ang = TWO_PI * i / 8.0f;
        float r0 = 4 + 4 * inv;
        float r1 = 14 + 10 * inv;
        line(cos(ang) * r0, 0, sin(ang) * r0, cos(ang) * r1, 0, sin(ang) * r1);
      }
    }
    noStroke();
    blendMode(BLEND);
    popMatrix();
  }
}

class ShellCasing {
  PVector pos, vel;
  float rotX, rotY, rotZ;
  float spinX, spinY, spinZ;
  float life = 1.1f;
  float lifeMax = 1.1f;

  ShellCasing(PVector tip, float facing) {
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

  void update(float dt) {
    life -= dt;
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
      spinX *= 0.6f;
      spinZ *= 0.6f;
    }
  }

  void display() {
    if (life <= 0) return;
    float a = constrain(life / lifeMax, 0, 1);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateY(rotY);
    rotateX(rotX);
    rotateZ(rotZ);
    noStroke();
    fill(210, 175, 55, min(255, 240 * a));
    box(2.2f, 1.1f, 3.2f);
    fill(185, 150, 45, min(255, 200 * a));
    box(2.6f, 1.3f, 2.4f);
    popMatrix();
  }
}
