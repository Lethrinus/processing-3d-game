// Asset loading helpers and ControlPanelRow config.

class ControlPanelRow {
  String title;
  String[] keyLabels;
  PImage[] mouseIcons;
  int layout = CTRL_LAYOUT_ROW;
}

class AssetLoader {
  final PApplet p;
  final GameContext ctx;

  AssetLoader(PApplet p, GameContext ctx) {
    this.p = p;
    this.ctx = ctx;
  }

  PImage tryLoadImage(String relPath) {
    File f = new File(p.dataPath(relPath));
    if (!f.exists()) return null;
    PImage img = p.loadImage(relPath);
    if (img == null || img.width < 2) return null;
    return img;
  }

  PImage makeNoiseGroundTexture() {
    PImage g = p.createImage(128, 128, ARGB);
    g.loadPixels();
    for (int y = 0; y < g.height; y++) {
      for (int x = 0; x < g.width; x++) {
        float n = p.noise(x * 0.12f, y * 0.12f);
        g.pixels[y * g.width + x] = p.color(120 + n * 55, 80 + n * 40, 45 + n * 35);
      }
    }
    g.updatePixels();
    return g;
  }

  PImage makeWoodStripes() {
    PImage g = p.createImage(64, 128, ARGB);
    g.loadPixels();
    for (int y = 0; y < g.height; y++) {
      for (int x = 0; x < g.width; x++) {
        float n = p.noise(x * 0.2f, y * 0.08f);
        g.pixels[y * g.width + x] = p.color(95 + n * 50, 58 + n * 35, 32 + n * 25);
      }
    }
    g.updatePixels();
    return g;
  }

  PImage makeRustTexture() {
    PImage g = p.createImage(64, 64, ARGB);
    g.loadPixels();
    for (int y = 0; y < g.height; y++) {
      for (int x = 0; x < g.width; x++) {
        float n = p.noise(x * 0.25f, y * 0.25f);
        g.pixels[y * g.width + x] = p.color(110 + n * 60, 55 + n * 30, 35 + n * 25);
      }
    }
    g.updatePixels();
    return g;
  }

  void loadTextureAssets() {
    ctx.texBarrel = tryLoadImage("textures/barrel_wood.jpg");
    if (ctx.texBarrel == null) ctx.texBarrel = tryLoadImage("textures/barrel_wood.png");
    if (ctx.texBarrel == null) ctx.texBarrel = makeWoodStripes();
    ctx.texRoof = tryLoadImage("textures/roof_rust.jpg");
    if (ctx.texRoof == null) ctx.texRoof = tryLoadImage("textures/roof_rust.png");
    if (ctx.texRoof == null) ctx.texRoof = makeRustTexture();
    ctx.texGround = tryLoadImage("textures/ground_dirt.jpg");
    if (ctx.texGround == null) ctx.texGround = tryLoadImage("textures/ground_dirt.png");
    if (ctx.texGround == null) ctx.texGround = makeNoiseGroundTexture();
    ctx.texCactus = tryLoadImage("textures/cactus.png");
    ctx.texWood1 = tryLoadImage("textures/wood1.jpg");
    if (ctx.texWood1 == null) ctx.texWood1 = tryLoadImage("textures/wood1.png");
    ctx.texWood2 = tryLoadImage("textures/wood2.jpg");
    if (ctx.texWood2 == null) ctx.texWood2 = tryLoadImage("textures/wood2.png");
    ctx.texWood3 = tryLoadImage("textures/wood3.jpg");
    if (ctx.texWood3 == null) ctx.texWood3 = tryLoadImage("textures/wood3.png");
    ctx.texFence = tryLoadImage("textures/fence.jpg");
    if (ctx.texFence == null) ctx.texFence = tryLoadImage("textures/fence.png");
    ctx.texBuildingWood = tryLoadImage("textures/building_wood.jpg");
    if (ctx.texBuildingWood == null) ctx.texBuildingWood = tryLoadImage("textures/building_wood.png");
    if (ctx.texBuildingWood == null) ctx.texBuildingWood = ctx.texWood1;
    ctx.texBuildingRoof = tryLoadImage("textures/building_roof.jpg");
    if (ctx.texBuildingRoof == null) ctx.texBuildingRoof = tryLoadImage("textures/building_roof.png");
    if (ctx.texBuildingRoof == null) ctx.texBuildingRoof = ctx.texRoof;
    ctx.texSky = tryLoadImage("textures/sky_horizon.jpg");
    if (ctx.texSky == null) ctx.texSky = tryLoadImage("textures/sky_horizon.png");
    if (ctx.texSky == null) ctx.texSky = tryLoadImage("textures/sky_panorama.jpg");
    if (ctx.texSky == null) ctx.texSky = tryLoadImage("textures/sky_panorama.png");
    if (ctx.texSky == null) ctx.texSky = tryLoadImage("textures/sky_stars.png");
    loadSkyCubemapAssets();
  }

  void loadSkyCubemapAssets() {
    ctx.skyCubemapReady = false;
    for (int i = 0; i < 6; i++) ctx.skyCubemap[i] = null;
    String[][] faceNames = {{"px", "posx"}, {"nx", "negx"}, {"py", "posy"}, {"ny", "negy"}, {"pz", "posz"}, {"nz", "negz"}};
    boolean separateOk = true;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < faceNames[i].length; j++) {
        ctx.skyCubemap[i] = tryLoadImage("textures/sky_cubemap/" + faceNames[i][j] + ".jpg");
        if (ctx.skyCubemap[i] == null) {
          ctx.skyCubemap[i] = tryLoadImage("textures/sky_cubemap/" + faceNames[i][j] + ".png");
        }
        if (ctx.skyCubemap[i] != null) break;
      }
      if (ctx.skyCubemap[i] == null) separateOk = false;
    }
    if (separateOk) {
      ctx.skyCubemapReady = true;
      return;
    }
    for (int i = 0; i < 6; i++) ctx.skyCubemap[i] = null;
    PImage cross = tryLoadImage("textures/sky_cubemap/cubemap.png");
    if (cross == null) cross = tryLoadImage("textures/sky_cubemap/sky_cubemap.png");
    if (cross == null) cross = tryLoadImage("textures/sky_cubemap.png");
    if (cross != null) ctx.skyCubemapReady = loadCubemapFromCrossLayout(cross);
  }

  boolean loadCubemapFromCrossLayout(PImage cross) {
    int face = cross.width / 4;
    if (face < 2 || face * 3 != cross.height) return false;
    int[][] colsRows = {{2, 1}, {0, 1}, {1, 2}, {1, 0}, {1, 1}, {3, 1}};
    for (int i = 0; i < 6; i++) {
      int col = colsRows[i][0];
      int row = colsRows[i][1];
      ctx.skyCubemap[i] = cross.get(col * face, row * face, face, face);
      if (ctx.skyCubemap[i] == null) return false;
    }
    return true;
  }

  void loadUiAssets() {
    ctx.uiWesternBg = tryLoadImage("ui/western_bg.png");
    ctx.uiBtnControls = tryLoadImage("ui/btn_controls.png");
    ctx.uiBtnControlsHot = tryLoadImage("ui/btn_controls_hot.png");
    if (ctx.uiBtnControlsHot == null) ctx.uiBtnControlsHot = ctx.uiBtnControls;
  }

  PImage tryLoadControlMouseIcon(String fileName) {
    PImage img = tryLoadImage("controls/" + fileName);
    if (img != null) return img;
    return tryLoadImage("ui/controls/" + fileName);
  }

  PImage[] loadControlMouseIcons(String[] files) {
    if (files == null || files.length == 0) return new PImage[0];
    ArrayList<PImage> list = new ArrayList<PImage>();
    for (String f : files) {
      if (f == null || f.length() == 0) continue;
      PImage img = tryLoadControlMouseIcon(f);
      if (img != null) list.add(img);
    }
    return list.toArray(new PImage[0]);
  }

  void loadControlPanelAssets() {
    Object[][] defs = {
      {CTRL_LAYOUT_WASD, "Move", new String[] {"W", "A", "S", "D"}, null},
      {CTRL_LAYOUT_ROW, "Shoot", null, new String[] {"mouse_left.png"}},
      {CTRL_LAYOUT_ROW, "Camera", null, new String[] {"mouse_right.png"}},
      {CTRL_LAYOUT_ROW, "Zoom", null, new String[] {"mouse_scroll.png"}},
      {CTRL_LAYOUT_ROW, "Weapons", new String[] {"1", "2", "3"}, null},
      {CTRL_LAYOUT_ROW, "Reload", new String[] {"R"}, null},
      {CTRL_LAYOUT_ROW, "Sprint", new String[] {"Shift"}, null},
      {CTRL_LAYOUT_ROW, "Wave skip", new String[] {"Space"}, null},
      {CTRL_LAYOUT_ROW, "Pause", new String[] {"Esc"}, null},
      {CTRL_LAYOUT_ROW, "Test", new String[] {"T"}, null},
      {CTRL_LAYOUT_ROW, "Quit", new String[] {"Q"}, null}
    };
    ctx.controlPanelRows = new ControlPanelRow[defs.length];
    for (int i = 0; i < defs.length; i++) {
      ControlPanelRow row = new ControlPanelRow();
      row.layout = (Integer) defs[i][0];
      row.title = (String) defs[i][1];
      row.keyLabels = (String[]) defs[i][2];
      row.mouseIcons = loadControlMouseIcons((String[]) defs[i][3]);
      ctx.controlPanelRows[i] = row;
    }
  }
}
