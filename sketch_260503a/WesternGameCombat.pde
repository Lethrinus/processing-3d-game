// Weapon definitions for player and bandits.

class Weapon {
  final String name;
  final int maxAmmo;
  final float reloadSec;
  final float cooldown;
  final float bulletSpeed;
  final float bulletDamage;
  final int bulletKind;

  Weapon(String name, int maxAmmo, float reloadSec, float cooldown,
         float bulletSpeed, float bulletDamage, int bulletKind) {
    this.name = name;
    this.maxAmmo = maxAmmo;
    this.reloadSec = reloadSec;
    this.cooldown = cooldown;
    this.bulletSpeed = bulletSpeed;
    this.bulletDamage = bulletDamage;
    this.bulletKind = bulletKind;
  }

}

Weapon weaponRevolver() {
  return new Weapon("Revolver", 30, 1.45f, 0.17f, 1060, 30, Bullet.KIND_REVOLVER);
}

Weapon weaponShotgun() {
  return new Weapon("Shotgun", 8, 2.25f, 0.5f, 980, 24, Bullet.KIND_SHOTGUN);
}

Weapon weaponRepeater() {
  return new Weapon("Repeater", 40, 1.35f, 0.11f, 1180, 19, Bullet.KIND_REPEATER);
}

Weapon[] playerWeaponLoadout() {
  return new Weapon[]{weaponRevolver(), weaponShotgun(), weaponRepeater()};
}

class WeaponState {
  final Weapon weapon;
  int ammo;
  boolean unlocked;

  WeaponState(Weapon weapon, boolean unlocked) {
    this.weapon = weapon;
    this.ammo = weapon.maxAmmo;
    this.unlocked = unlocked;
  }

  void refill() {
    ammo = weapon.maxAmmo;
  }
}
