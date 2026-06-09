// 3D drawing for characters and loot (view layer).

class EntityRenderer {
  final PApplet p;
  final GameContext ctx;
  final SceneRenderer scene;

  EntityRenderer(PApplet p, GameContext ctx, SceneRenderer scene) {
    this.p = p;
    this.ctx = ctx;
    this.scene = scene;
  }

  void drawPlayer(Player pl, float t) {
    pl.display(t, scene);
  }

  void drawBandit(Bandit b, float t) {
    b.display(t, ctx.player, scene);
  }

  void drawLoot(LootPickup lp, float t) {
    lp.display(t, scene);
  }
}
