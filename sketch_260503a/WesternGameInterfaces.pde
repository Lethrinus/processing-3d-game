// Core interfaces and abstract bases for game objects.

interface Updatable {
  void update(float dt);
}

interface Drawable {
  void display();
}

interface Particle extends Updatable, Drawable {
  boolean isAlive();
}

abstract class GameParticle implements Particle {
  float life;
  float lifeMax;

  GameParticle(float lifeMax) {
    this.lifeMax = lifeMax;
    this.life = lifeMax;
  }

  public boolean isAlive() {
    return life > 0;
  }

  public void update(float dt) {
    life -= dt;
    onUpdate(dt);
  }

  protected void onUpdate(float dt) {}

  public abstract void display();
}

abstract class Projectile extends GameParticle {
  PVector pos, vel, prevPos;
  boolean alive = true;
  float dmg;

  Projectile(PVector start, PVector velocity, float life, float dmg) {
    super(life);
    pos = start.copy();
    prevPos = start.copy();
    vel = velocity.copy();
    this.dmg = dmg;
  }

  public boolean isAlive() {
    return alive && life > 0;
  }

  public void update(float dt) {
    if (!alive) return;
    super.update(dt);
    onProjectileUpdate(dt);
    if (life <= 0) alive = false;
  }

  protected abstract void onProjectileUpdate(float dt);

  protected void moveProjectile(float dt) {
    prevPos = pos.copy();
    pos.add(PVector.mult(vel, dt));
  }

  protected boolean outOfArena(GameContext ctx) {
    return abs(pos.x) > ctx.arenaHalfW + 200 || abs(pos.z) > ctx.arenaHalfH + 200;
  }
}
