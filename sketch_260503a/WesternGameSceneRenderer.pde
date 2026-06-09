// SceneRenderer — 3D environment, sky, buildings, and world props.

class SceneRenderer {
  final PApplet p;
  final GameContext ctx;

  SceneRenderer(PApplet p, GameContext ctx) {
    this.p = p;
    this.ctx = ctx;
  }

  boolean hasCustomSky() {
    return ctx.skyCubemapReady || ctx.texSky != null;
  }

  float getSkyRadius() {
    return max(ctx.arenaHalfW, ctx.arenaHalfH) * 2.9f;
  }

  void drawTexturedGroundPlane(float cx, float cz, float w, float h, float y, int tilesX, int tilesZ) {
    if (ctx.texGround == null) return;

    p.pushMatrix();
    p.translate(cx, y, cz);
    p.rotateX(HALF_PI);

    float hw = w * 0.5f;
    float hh = h * 0.5f;
    float tileW = w / tilesX;
    float tileH = h / tilesZ;
    int tw = ctx.texGround.width;
    int th = ctx.texGround.height;

    p.noStroke();
    p.noTint();
    p.fill(255);
    p.emissive(0, 0, 0);
    p.textureMode(IMAGE);

    for (int ix = 0; ix < tilesX; ix++) {
      for (int iz = 0; iz < tilesZ; iz++) {
        float x0 = -hw + ix * tileW;
        float x1 = x0 + tileW;
        float y0 = -hh + iz * tileH;
        float y1 = y0 + tileH;
        p.beginShape(QUADS);
        p.texture(ctx.texGround);
        p.vertex(x0, y0, 0, 0, 0);
        p.vertex(x1, y0, 0, tw, 0);
        p.vertex(x1, y1, 0, tw, th);
        p.vertex(x0, y1, 0, 0, th);
        p.endShape();
      }
    }

    p.noTexture();
    p.textureMode(NORMAL);
    p.popMatrix();
  }

  void drawSkyboxFace(PImage tex, float s, int face) {
    if (tex == null || face == 2) return;
    int w = tex.width;
    int h = tex.height;
    float vH = h * SKYBOX_HORIZON_UV;
    float gY = GROUND_Y;
    p.beginShape(QUADS);
    p.texture(tex);
    p.textureMode(IMAGE);
    switch (face) {
      case 0: // +X right
        p.vertex( s, -s,  s, 0, 0);
        p.vertex( s, -s, -s, w, 0);
        p.vertex( s, gY, -s, w, vH);
        p.vertex( s, gY,  s, 0, vH);
        break;
      case 1: // -X left
        p.vertex(-s, -s, -s, 0, 0);
        p.vertex(-s, -s,  s, w, 0);
        p.vertex(-s, gY,  s, w, vH);
        p.vertex(-s, gY, -s, 0, vH);
        break;
      case 2: // +Y down — skip (arena ground is the floor)
        break;
      case 3: // -Y up (zenith)
        p.vertex(-s, -s,  s, 0, 0);
        p.vertex(-s, -s, -s, w, 0);
        p.vertex( s, -s, -s, w, h);
        p.vertex( s, -s,  s, 0, h);
        break;
      case 4: // +Z
        p.vertex(-s, -s,  s, 0, 0);
        p.vertex( s, -s,  s, w, 0);
        p.vertex( s, gY,  s, w, vH);
        p.vertex(-s, gY,  s, 0, vH);
        break;
      case 5: // -Z
        p.vertex( s, -s, -s, 0, 0);
        p.vertex(-s, -s, -s, w, 0);
        p.vertex(-s, gY, -s, w, vH);
        p.vertex( s, gY, -s, 0, vH);
        break;
    }
    p.endShape();
  }

  void drawSkyCubemap(float halfSize) {
    float s = halfSize;
    p.fill(255);
    p.emissive(0, 0, 0);
    drawSkyboxFace(ctx.skyCubemap[3], s, 3);
    for (int f = 0; f < 6; f++) {
      if (f == 2 || f == 3) continue;
      drawSkyboxFace(ctx.skyCubemap[f], s, f);
    }
    p.noTexture();
    p.textureMode(NORMAL);
  }

  void drawTexturedSkyCylinder(PImage tex, float radius, float yBot, float yTop, int segs, int bands) {
    p.textureMode(IMAGE);
    int tw = tex.width;
    int th = tex.height;
    p.fill(255);
    p.emissive(0, 0, 0);
    for (int b = 0; b < bands; b++) {
      float f0 = (float) b / bands;
      float f1 = (float) (b + 1) / bands;
      float y0 = lerp(yBot, yTop, f0);
      float y1 = lerp(yBot, yTop, f1);
      float imgV0 = lerp(th, 0, f0);
      float imgV1 = lerp(th, 0, f1);
      for (int i = 0; i < segs; i++) {
        float a0 = TWO_PI * i / segs;
        float a1 = TWO_PI * (i + 1) / segs;
        float imgU0 = (float) i / segs * tw;
        float imgU1 = (float) (i + 1) / segs * tw;
        p.beginShape(QUADS);
        p.texture(tex);
        p.vertex(cos(a0) * radius, y0, sin(a0) * radius, imgU0, imgV0);
        p.vertex(cos(a1) * radius, y0, sin(a1) * radius, imgU1, imgV0);
        p.vertex(cos(a1) * radius, y1, sin(a1) * radius, imgU1, imgV1);
        p.vertex(cos(a0) * radius, y1, sin(a0) * radius, imgU0, imgV1);
        p.endShape();
      }
    }
    p.noTexture();
    p.textureMode(NORMAL);
  }

  int westernSkyColorAt(float u) {
    u = constrain(u, 0, 1);
    if (u < 0.2f) return p.lerpColor(p.color(255, 228, 175), p.color(255, 185, 105), u / 0.2f);
    if (u < 0.45f) return p.lerpColor(p.color(255, 185, 105), p.color(235, 130, 80), (u - 0.2f) / 0.25f);
    if (u < 0.68f) return p.lerpColor(p.color(235, 130, 80), p.color(175, 105, 115), (u - 0.45f) / 0.23f);
    return p.lerpColor(p.color(175, 105, 115), p.color(98, 118, 148), (u - 0.68f) / 0.32f);
  }

  void drawWesternSky(float t) {
    if (ctx.player == null) return;
    p.hint(DISABLE_DEPTH_TEST);
    p.noStroke();
    p.pushMatrix();
    p.translate(ctx.player.pos.x, 0, ctx.player.pos.z);

    float skyR = getSkyRadius();
    float horizonY = -22;
    float zenithY = -1200;

    if (ctx.skyCubemapReady) {
      drawSkyCubemap(skyR);
      p.hint(ENABLE_DEPTH_TEST);
      p.popMatrix();
      session.reset3DDrawState();
      return;
    }
    if (ctx.texSky != null) {
      drawTexturedSkyCylinder(ctx.texSky, skyR, horizonY, zenithY, 36, 10);
      p.hint(ENABLE_DEPTH_TEST);
      p.popMatrix();
      session.reset3DDrawState();
      return;
    }

    int segs = 28;
    int bands = 9;
    for (int b = 0; b < bands; b++) {
      float u0 = b / (float) bands;
      float u1 = (b + 1) / (float) bands;
      float y0 = lerp(horizonY, zenithY, u0);
      float y1 = lerp(horizonY, zenithY, u1);
      for (int i = 0; i < segs; i++) {
        float a0 = TWO_PI * i / segs;
        float a1 = TWO_PI * (i + 1) / segs;
        p.beginShape(QUADS);
        p.fill(westernSkyColorAt(u0));
        p.vertex(cos(a0) * skyR, y0, sin(a0) * skyR);
        p.vertex(cos(a1) * skyR, y0, sin(a1) * skyR);
        p.fill(westernSkyColorAt(u1));
        p.vertex(cos(a1) * skyR, y1, sin(a1) * skyR);
        p.vertex(cos(a0) * skyR, y1, sin(a0) * skyR);
        p.endShape(CLOSE);
      }
    }

    float sunAngle = 0.55f + sin(t * 0.04f) * 0.04f;
    float sunDist = skyR * 0.78f;
    float sunX = cos(sunAngle) * sunDist;
    float sunZ = sin(sunAngle) * sunDist;
    float sunY = horizonY + 28;
    p.fill(255, 160, 70, 35);
    p.ellipse(sunX, sunY, 340, 200);
    p.fill(255, 195, 95, 70);
    p.ellipse(sunX, sunY, 200, 120);
    p.fill(255, 225, 155, 200);
    p.ellipse(sunX, sunY, 95, 55);

    for (int c = 0; c < 7; c++) {
      float ca = c * 1.15f + t * 0.015f;
      float cx = cos(ca) * skyR * (0.35f + p.noise(c) * 0.25f);
      float cz = sin(ca) * skyR * (0.35f + p.noise(c + 3) * 0.25f);
      float cy = lerp(horizonY, zenithY, 0.42f + p.noise(c * 0.2) * 0.2f);
      float cw = 180 + p.noise(c, t * 0.03f) * 120;
      float ch = 28 + p.noise(c + 1) * 18;
      p.fill(255, 210, 175, 28 + (int)(p.noise(c * 0.7) * 22));
      p.ellipse(cx, cy, cw, ch);
      p.fill(255, 235, 210, 18);
      p.ellipse(cx + cw * 0.08f, cy - ch * 0.15f, cw * 0.55f, ch * 0.65f);
    }

    for (int h = 0; h < 3; h++) {
      float hy = horizonY + 8 + h * 14;
      p.fill(255, 200, 140, 22 - h * 5);
      p.beginShape(QUAD_STRIP);
      for (int i = 0; i <= segs; i++) {
        float a = TWO_PI * i / segs;
        float r = skyR * (0.92f - h * 0.04f);
        p.vertex(cos(a) * r, hy, sin(a) * r);
        p.vertex(cos(a) * r, hy + 35, sin(a) * r);
      }
      p.endShape();
    }

    p.hint(ENABLE_DEPTH_TEST);
    p.popMatrix();
    session.reset3DDrawState();
  }

  void drawDistantHorizon(float t) {
    if (ctx.player == null) return;
    if (hasCustomSky()) return;
    p.hint(DISABLE_DEPTH_TEST);
    p.noStroke();
    p.pushMatrix();
    p.translate(ctx.player.pos.x, 0, ctx.player.pos.z);
    float ringR = max(ctx.arenaHalfW, ctx.arenaHalfH) * 1.52f;

    p.fill(118, 78, 52, 200);
    p.beginShape(TRIANGLE_FAN);
    p.vertex(0, -16, 0);
    for (int i = 0; i <= 36; i++) {
      float a = TWO_PI * i / 36;
      float mesa = p.noise(i * 0.35, 1.2) > 0.62 ? 1.35f : 1.0f;
      float h = (28 + p.noise(i * 0.42, t * 0.04) * 48) * mesa;
      p.vertex(cos(a) * ringR, -16 - h, sin(a) * ringR);
    }
    p.endShape(CLOSE);

    p.fill(88, 55, 38, 210);
    p.beginShape(TRIANGLE_FAN);
    p.vertex(0, -14, 0);
    for (int i = 0; i <= 36; i++) {
      float a = TWO_PI * i / 36 + 0.08f;
      float h = 14 + p.noise(i * 0.5 + 20, t * 0.035) * 22;
      p.vertex(cos(a) * ringR * 0.94f, -14 - h, sin(a) * ringR * 0.94f);
    }
    p.endShape(CLOSE);

    p.fill(255, 210, 155, 45);
    p.beginShape(QUAD_STRIP);
    for (int i = 0; i <= 40; i++) {
      float a = TWO_PI * i / 40;
      p.vertex(cos(a) * ringR * 0.98f, -8, sin(a) * ringR * 0.98f);
      p.vertex(cos(a) * ringR * 0.98f, 25, sin(a) * ringR * 0.98f);
    }
    p.endShape();

    p.hint(ENABLE_DEPTH_TEST);
    p.popMatrix();
    session.reset3DDrawState();
  }

  void drawWesternEnvironment(float t) {
    p.noStroke();
    session.reset3DDrawState();
    drawWesternSky(t);
    drawDistantHorizon(t);

    float skyR = getSkyRadius();
    float maxPlayerDist = sqrt(ctx.arenaHalfW * ctx.arenaHalfW + ctx.arenaHalfH * ctx.arenaHalfH);
    float groundHalf = maxPlayerDist + skyR * 1.08f;
    int groundTiles = max(14, (int)(groundHalf / 260f));
    drawTexturedGroundPlane(0, 0, groundHalf * 2f, groundHalf * 2f, GROUND_Y, groundTiles, groundTiles);

    drawMapAmbience(t);

    drawSaloon(ctx.worldX(-560), ctx.worldZ(-220), t);
    drawSheriffOffice(ctx.worldX(560), ctx.worldZ(-190));
    drawBarn(ctx.worldX(-540), ctx.worldZ(250));
    drawWaterTower(ctx.worldX(520), ctx.worldZ(250));
    drawWagon(ctx.worldX(-150), ctx.worldZ(60));
    drawTrainCar(ctx.worldX(720), ctx.worldZ(30));

    drawRockCluster(ctx.worldX(-420), ctx.worldZ(-480), t, 1.1);
    drawRockCluster(ctx.worldX(520), ctx.worldZ(420), t, 0.85);
    drawRockCluster(ctx.worldX(-820), ctx.worldZ(380), t, 0.95);

    drawCactus(ctx.worldX(-130), ctx.worldZ(-380));
    drawCactus(ctx.worldX(160), ctx.worldZ(-310));
    drawCactus(ctx.worldX(180), ctx.worldZ(350));
    drawCactus(ctx.worldX(-220), ctx.worldZ(320));
    drawCactus(ctx.worldX(-680), ctx.worldZ(50));
    drawCactus(ctx.worldX(680), ctx.worldZ(-50));

    drawBarrel(ctx.worldX(-30), ctx.worldZ(-130));
    drawBarrel(ctx.worldX(30), ctx.worldZ(-150));
    drawBarrel(ctx.worldX(70), ctx.worldZ(120));
    drawBarrel(ctx.worldX(-380), ctx.worldZ(0));

    float fenceStep = 102;
    for (float x = -ctx.arenaHalfW; x <= ctx.arenaHalfW; x += fenceStep) {
      drawFencePost(x, -ctx.arenaHalfH - ctx.worldZ(50));
      drawFencePost(x, ctx.arenaHalfH + ctx.worldZ(50));
    }
    for (float z = -ctx.arenaHalfH; z <= ctx.arenaHalfH; z += fenceStep) {
      drawFencePost(-ctx.arenaHalfW - ctx.worldX(50), z);
      drawFencePost(ctx.arenaHalfW + ctx.worldX(50), z);
    }

    p.noTexture();
    p.textureMode(NORMAL);
  }

  void drawMapAmbience(float t) {
    p.noStroke();

    float salX = ctx.worldX(-560), salZ = ctx.worldZ(-220);
    p.pushMatrix();
    p.translate(salX + ctx.worldX(55), -8, salZ + ctx.worldZ(75));
    float flicker = 0.7f + 0.3f * p.noise(t * 4.2);
    p.emissive(255, 140, 60);
    p.fill(255, 120 + flicker * 80, 40, 200);
    p.sphere(6 + flicker * 2);
    p.fill(255, 200, 100, 90);
    p.translate(0, 8, 0);
    p.sphere(3 + flicker);
    p.emissive(0, 0, 0);
    p.popMatrix();

    float[][] lanterns = {
      {ctx.worldX(-560), ctx.worldZ(-220), ctx.worldX(90)},
      {ctx.worldX(560), ctx.worldZ(-190), ctx.worldX(85)},
      {ctx.worldX(-540), ctx.worldZ(250), ctx.worldX(70)}
    };
    for (int i = 0; i < lanterns.length; i++) {
      p.pushMatrix();
      p.translate(lanterns[i][0], -72, lanterns[i][1] + lanterns[i][2]);
      float glow = 0.65f + 0.35f * sin(t * 3.1 + i * 1.7);
      p.emissive(255, 200, 120);
      p.fill(255, 220, 150, 180 * glow);
      p.sphere(4);
      p.emissive(0, 0, 0);
      p.popMatrix();
    }

    p.pushMatrix();
    p.translate(ctx.worldX(560), -108, ctx.worldZ(-190) + ctx.worldZ(88));
    p.rotateY(sin(t * 0.9) * 0.12);
    p.fill(200, 165, 90);
    p.box(18, 4, 2);
    p.popMatrix();

    p.emissive(0, 0, 0);
  }

  void drawRockCluster(float x, float z, float t, float scl) {
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();
    for (int i = 0; i < 4; i++) {
      p.pushMatrix();
      p.translate(sin(i * 1.7 + t * 0.05) * 8 * scl, 0, cos(i * 2.1) * 6 * scl);
      p.rotateY(i * 0.4 + t * 0.02);
      p.fill(95 + i * 8, 68 + i * 5, 48);
      p.box(14 * scl + i * 3, 10 * scl, 12 * scl + i * 2);
      p.popMatrix();
    }
    p.popMatrix();
  }

  void drawSaloon(float x, float z, float t) {
    PImage wood = pickWoodTexture(x, z);
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();

    p.pushMatrix();
    p.translate(0, -46, 0);
    drawBuildingWallBox(260, 92, 190, 132, 89, 55, wood);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -100, 0);
    drawBuildingRoofBox(280, 16, 200, 95, 60, 35);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -120, 90);
    p.fill(180, 130, 75);
    p.box(220, 56, 6);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -126, 92);
    p.fill(60, 30, 15);
    p.box(160, 22, 1.5);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -76, 110);
    p.fill(85, 55, 30);
    p.box(220, 6, 50);
    p.popMatrix();

    for (int i = -3; i <= 3; i++) {
      p.pushMatrix();
      p.translate(i * 35, -38, 130);
      p.fill(105, 70, 45);
      drawCylinder(4, 76, 10);
      p.popMatrix();
    }

    float doorAngle = sin(t * 1.2) * 0.18;
    p.pushMatrix();
    p.translate(-16, -45, 95);
    p.rotateY(doorAngle);
    p.fill(120, 75, 40);
    p.box(28, 50, 2);
    p.popMatrix();

    p.pushMatrix();
    p.translate(16, -45, 95);
    p.rotateY(-doorAngle);
    p.fill(120, 75, 40);
    p.box(28, 50, 2);
    p.popMatrix();

    p.popMatrix();
  }

  void drawSheriffOffice(float x, float z) {
    PImage wood = pickWoodTexture(x, z);
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();

    p.pushMatrix();
    p.translate(0, -44, 0);
    drawBuildingWallBox(220, 88, 170, 119, 83, 49, wood);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -94, 0);
    drawBuildingRoofBox(238, 18, 186, 98, 66, 43);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -110, 85);
    p.fill(180, 145, 92);
    p.box(140, 22, 4);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -110, 88);
    p.fill(220, 180, 60);
    p.box(14, 14, 1);
    p.popMatrix();

    for (int i = -1; i <= 1; i += 2) {
      p.pushMatrix();
      p.translate(i * 90, -25, 110);
      p.fill(70, 45, 25);
      drawCylinder(5, 50, 10);
      p.popMatrix();
    }

    p.popMatrix();
  }

  void drawBarn(float x, float z) {
    PImage wood = pickWoodTexture(x, z);
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();

    p.pushMatrix();
    p.translate(0, -45, 0);
    drawBuildingWallBox(250, 90, 170, 125, 50, 40, wood);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -90, 0);
    if (ctx.texBuildingRoof != null || wood != null) {
      drawTexturedBarnRoof(130, 55, 90, ctx.texBuildingRoof, wood);
    } else {
      p.fill(82, 38, 30);
      p.beginShape(QUADS);
      p.vertex(-130, 0, -90);
      p.vertex(0, -55, -90);
      p.vertex(0, -55, 90);
      p.vertex(-130, 0, 90);
      p.vertex(0, -55, -90);
      p.vertex(130, 0, -90);
      p.vertex(130, 0, 90);
      p.vertex(0, -55, 90);
      p.endShape();
      p.beginShape(TRIANGLES);
      p.vertex(-130, 0, 90);
      p.vertex(0, -55, 90);
      p.vertex(130, 0, 90);
      p.vertex(-130, 0, -90);
      p.vertex(130, 0, -90);
      p.vertex(0, -55, -90);
      p.endShape();
    }
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -45, 86);
    p.fill(60, 30, 20);
    p.box(60, 80, 2);
    p.popMatrix();

    p.popMatrix();
  }

  void drawWaterTower(float x, float z) {
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();

    for (int i = 0; i < 4; i++) {
      p.pushMatrix();
      float sx = (i < 2) ? -32 : 32;
      float sz = (i % 2 == 0) ? -32 : 32;
      p.translate(sx, -55, sz);
      p.fill(110, 76, 52);
      drawCylinder(5, 110, 8);
      p.popMatrix();
    }

    p.pushMatrix();
    p.translate(0, -135, 0);
    if (ctx.texBarrel != null) {
      drawTexturedCylinder(ctx.texBarrel, 56, 70, 26, false);
    } else {
      p.fill(146, 104, 73);
      drawCylinder(56, 70, 24);
    }

    p.fill(80, 50, 30);
    for (int i = -1; i <= 1; i++) {
      p.pushMatrix();
      p.translate(0, i * 25, 0);
      drawCylinder(57, 4, 24);
      p.popMatrix();
    }

    p.fill(95, 60, 35);
    p.translate(0, -50, 0);
    drawCone(60, 30, 20);
    p.popMatrix();

    p.popMatrix();
  }

  void drawWagon(float x, float z) {
    p.pushMatrix();
    p.translate(x, 0, z);
    p.rotateY(-PI / 5);
    p.noStroke();

    p.pushMatrix();
    p.translate(0, -28, 0);
    p.fill(140, 92, 56);
    p.box(140, 28, 70);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -50, -38);
    p.fill(110, 70, 42);
    p.box(140, 18, 4);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -50, 38);
    p.fill(110, 70, 42);
    p.box(140, 18, 4);
    p.popMatrix();

    p.pushMatrix();
    p.translate(72, -50, 0);
    p.fill(110, 70, 42);
    p.box(4, 18, 76);
    p.popMatrix();

    p.pushMatrix();
    p.translate(-72, -50, 0);
    p.fill(110, 70, 42);
    p.box(4, 18, 76);
    p.popMatrix();

    for (int sx = -1; sx <= 1; sx += 2) {
      for (int sz = -1; sz <= 1; sz += 2) {
        p.pushMatrix();
        p.translate(sx * 50, -16, sz * 38);
        p.rotateX(HALF_PI);
        p.fill(45, 28, 18);
        drawCylinder(18, 8, 16);
        p.fill(85, 60, 35);
        drawCylinder(7, 9, 12);
        p.popMatrix();
      }
    }

    p.pushMatrix();
    p.translate(85, -22, 0);
    p.fill(95, 65, 40);
    p.box(80, 4, 4);
    p.popMatrix();

    p.pushMatrix();
    p.translate(115, -16, 0);
    p.fill(75, 50, 30);
    p.box(20, 6, 30);
    p.popMatrix();

    p.pushMatrix();
    p.translate(20, -50, 10);
    p.fill(150, 110, 70);
    p.box(28, 20, 22);
    p.popMatrix();

    p.pushMatrix();
    p.translate(-20, -45, -10);
    p.fill(140, 100, 60);
    p.box(30, 24, 22);
    p.popMatrix();

    p.popMatrix();
  }

  void drawTrainCar(float x, float z) {
    PImage wood = pickWoodTexture(x, z);
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();

    p.pushMatrix();
    p.translate(0, -55, 0);
    drawBuildingWallBox(220, 60, 90, 60, 30, 30, wood);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -95, 0);
    drawBuildingRoofBox(232, 12, 96, 40, 22, 22);
    p.popMatrix();

    for (int sx = -1; sx <= 1; sx += 2) {
      p.pushMatrix();
      p.translate(sx * 80, -16, 0);
      p.rotateX(HALF_PI);
      p.fill(40, 25, 15);
      drawCylinder(16, 14, 14);
      p.popMatrix();
    }

    p.popMatrix();
  }

  void drawCactus(float x, float z) {
    p.pushMatrix();
    p.translate(x, 0, z);
    p.noStroke();
    boolean useTex = ctx.texCactus != null;
    if (!useTex) p.fill(60, 132, 71);
    else p.fill(75, 140, 82);

    p.pushMatrix();
    p.translate(0, -45, 0);
    if (useTex) drawTexturedCylinder(ctx.texCactus, 12, 90, 12, false);
    else drawCylinder(12, 90, 12);
    p.popMatrix();

    p.pushMatrix();
    p.translate(0, -94, 0);
    if (useTex) drawTexturedSphere(ctx.texCactus, 12, 14);
    else p.sphere(12);
    p.popMatrix();

    p.pushMatrix();
    p.translate(-22, -55, 0);
    p.rotateZ(PI / 3);
    if (useTex) drawTexturedCylinder(ctx.texCactus, 7, 26, 10, false);
    else drawCylinder(7, 26, 10);
    p.popMatrix();
    p.pushMatrix();
    p.translate(-30, -68, 0);
    if (useTex) drawTexturedCylinder(ctx.texCactus, 7, 18, 10, false);
    else drawCylinder(7, 18, 10);
    p.popMatrix();
    p.pushMatrix();
    p.translate(-30, -77, 0);
    if (useTex) drawTexturedSphere(ctx.texCactus, 7, 12);
    else p.sphere(7);
    p.popMatrix();

    p.pushMatrix();
    p.translate(20, -45, 0);
    p.rotateZ(-PI / 3);
    if (useTex) drawTexturedCylinder(ctx.texCactus, 6, 22, 10, false);
    else drawCylinder(6, 22, 10);
    p.popMatrix();
    p.pushMatrix();
    p.translate(26, -56, 0);
    if (useTex) drawTexturedCylinder(ctx.texCactus, 6, 14, 10, false);
    else drawCylinder(6, 14, 10);
    p.popMatrix();
    p.pushMatrix();
    p.translate(26, -63, 0);
    if (useTex) drawTexturedSphere(ctx.texCactus, 6, 12);
    else p.sphere(6);
    p.popMatrix();

    if (useTex) p.noTint();
    p.popMatrix();
  }

  void drawBarrel(float x, float z) {
    p.pushMatrix();
    p.translate(x, -18, z);
    p.noStroke();
    if (ctx.texBarrel != null) {
      drawTexturedCylinder(ctx.texBarrel, 16, 36, 22, false);
    } else {
      p.fill(121, 81, 50);
      drawCylinder(16, 36, 16);
    }
    p.fill(64, 49, 40);
    p.pushMatrix();
    p.translate(0, -10, 0);
    drawCylinder(17.5, 4, 16);
    p.popMatrix();
    p.pushMatrix();
    p.translate(0, 10, 0);
    drawCylinder(17.5, 4, 16);
    p.popMatrix();
    p.popMatrix();
  }

  void drawFencePost(float x, float z) {
    p.pushMatrix();
    p.translate(x, -35, z);
    if (ctx.texFence != null) {
      p.fill(255);
      drawTexturedCylinder(ctx.texFence, 7, 70, 12, false);
    } else {
      p.fill(118, 82, 54);
      drawCylinder(7, 70, 10);
    }
    p.translate(0, -38, 0);
    if (ctx.texRoof != null) {
      drawTexturedCone(ctx.texRoof, 9, 14, 12);
    } else {
      p.fill(88, 62, 42);
      drawCone(9, 14, 10);
    }
    p.popMatrix();
  }

  PImage pickWoodTexture(float worldX, float worldZ) {
    PImage[] opts = {ctx.texWood1, ctx.texWood2, ctx.texWood3};
    int n = 0;
    for (int i = 0; i < opts.length; i++) {
      if (opts[i] != null) n++;
    }
    if (n == 0) {
      if (ctx.texBuildingWood != null) return ctx.texBuildingWood;
      return ctx.texBarrel;
    }
    int pick = abs((int)(worldX * 12.9898f + worldZ * 78.233f)) % n;
    int seen = 0;
    for (int i = 0; i < opts.length; i++) {
      if (opts[i] == null) continue;
      if (seen == pick) return opts[i];
      seen++;
    }
    return ctx.texWood1;
  }

  void drawTexQuad(PImage tex, float x0, float y0, float z0, float u0, float v0,
      float x1, float y1, float z1, float u1, float v1,
      float x2, float y2, float z2, float u2, float v2,
      float x3, float y3, float z3, float u3, float v3) {
    p.beginShape(QUADS);
    p.texture(tex);
    p.textureMode(NORMAL);
    p.textureWrap(REPEAT);
    p.vertex(x0, y0, z0, u0, v0);
    p.vertex(x1, y1, z1, u1, v1);
    p.vertex(x2, y2, z2, u2, v2);
    p.vertex(x3, y3, z3, u3, v3);
    p.endShape();
  }

  /** Box walls (4 sides) + optional top — same layout as p.box(w,h,d) centered at origin. */
  void drawTexturedBuildingBox(float w, float h, float d, PImage wallTex, PImage roofTex, boolean roofTop) {
    if (wallTex == null) return;
    float hw = w * 0.5f;
    float hh = h * 0.5f;
    float hd = d * 0.5f;
    float uW = w / BUILDING_TEX_TILE;
    float vH = h / BUILDING_TEX_TILE;
    float uD = d / BUILDING_TEX_TILE;
    p.noStroke();
    p.noTint();
    p.fill(255);

    drawTexQuad(wallTex,
      -hw, -hh, hd, 0, 0,  hw, -hh, hd, uW, 0,  hw, hh, hd, uW, vH,  -hw, hh, hd, 0, vH);
    drawTexQuad(wallTex,
      hw, -hh, -hd, 0, 0,  -hw, -hh, -hd, uW, 0,  -hw, hh, -hd, uW, vH,  hw, hh, -hd, 0, vH);
    drawTexQuad(wallTex,
      hw, -hh, hd, 0, 0,  hw, -hh, -hd, uD, 0,  hw, hh, -hd, uD, vH,  hw, hh, hd, 0, vH);
    drawTexQuad(wallTex,
      -hw, -hh, -hd, 0, 0,  -hw, -hh, hd, uD, 0,  -hw, hh, hd, uD, vH,  -hw, hh, -hd, 0, vH);

    if (roofTop) {
      PImage topTex = roofTex != null ? roofTex : wallTex;
      drawTexQuad(topTex,
        -hw, -hh, -hd, 0, 0,  hw, -hh, -hd, uW, 0,  hw, -hh, hd, uW, uD,  -hw, -hh, hd, 0, uD);
    }
    p.noTexture();
    p.textureMode(NORMAL);
  }

  void drawBuildingWallBox(float w, float h, float d, int r, int g, int b, PImage woodTex) {
    if (woodTex != null) {
      drawTexturedBuildingBox(w, h, d, woodTex, null, false);
    } else {
      p.fill(r, g, b);
      p.box(w, h, d);
    }
  }

  void drawBuildingRoofBox(float w, float h, float d, int r, int g, int b) {
    if (ctx.texBuildingRoof != null || ctx.texBuildingWood != null) {
      drawTexturedBuildingBox(w, h, d, ctx.texBuildingRoof != null ? ctx.texBuildingRoof : ctx.texBuildingWood,
        ctx.texBuildingRoof, true);
    } else {
      p.fill(r, g, b);
      p.box(w, h, d);
    }
  }

  /** Barn gable roof — two slopes + front/back triangles. */
  void drawTexturedBarnRoof(float halfW, float peakDrop, float halfD, PImage roofTex, PImage gableTex) {
    if (roofTex == null) return;
    float slopeLen = sqrt(halfW * halfW + peakDrop * peakDrop);
    float uSlope = slopeLen / BUILDING_TEX_TILE;
    float vD = (halfD * 2f) / BUILDING_TEX_TILE;
    p.noStroke();
    p.noTint();
    p.fill(255);

    drawTexQuad(roofTex,
      -halfW, 0, -halfD, 0, 0,  0, -peakDrop, -halfD, uSlope, 0,
      0, -peakDrop, halfD, uSlope, vD,  -halfW, 0, halfD, 0, vD);
    drawTexQuad(roofTex,
      0, -peakDrop, -halfD, 0, 0,  halfW, 0, -halfD, uSlope, 0,
      halfW, 0, halfD, uSlope, vD,  0, -peakDrop, halfD, 0, vD);

    PImage gt = gableTex != null ? gableTex : roofTex;
    p.beginShape(TRIANGLES);
    p.texture(gt);
    p.textureMode(NORMAL);
    p.vertex(-halfW, 0, halfD, 0, 0);
    p.vertex(0, -peakDrop, halfD, 0.5, 1);
    p.vertex(halfW, 0, halfD, 1, 0);
    p.vertex(-halfW, 0, -halfD, 0, 0);
    p.vertex(halfW, 0, -halfD, 1, 0);
    p.vertex(0, -peakDrop, -halfD, 0.5, 1);
    p.endShape();
    p.noTexture();
    p.textureMode(NORMAL);
  }

  /** Cylinder body — texture on side faces (UV). */
  void drawTexturedCylinder(PImage tex, float radius, float h, int detail, boolean withCaps) {
    if (tex == null) {
      drawCylinder(radius, h, detail);
      return;
    }
    p.textureMode(NORMAL);
    p.noStroke();
    p.beginShape(QUAD_STRIP);
    p.texture(tex);
    for (int i = 0; i <= detail; i++) {
      float a = TWO_PI * i / detail;
      float xx = cos(a) * radius;
      float zz = sin(a) * radius;
      float u = (float)i / detail;
      p.vertex(xx, -h / 2.0, zz, u, 0);
      p.vertex(xx, h / 2.0, zz, u, 1);
    }
    p.endShape();
    if (withCaps) {
      int bc = p.color(90, 60, 40);
      p.fill(p.red(bc), green(bc), blue(bc));
      p.beginShape(TRIANGLE_FAN);
      p.vertex(0, -h / 2.0, 0);
      for (int i = 0; i <= detail; i++) {
        float a = TWO_PI * i / detail;
        p.vertex(cos(a) * radius, -h / 2.0, sin(a) * radius);
      }
      p.endShape();
      p.beginShape(TRIANGLE_FAN);
      p.vertex(0, h / 2.0, 0);
      for (int i = detail; i >= 0; i--) {
        float a = TWO_PI * i / detail;
        p.vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
      }
      p.endShape();
    }
    p.noTexture();
  }

  /** Sphere with lat/long UV wrap (cactus tips). Inherits p.fill() from caller like drawTexturedCylinder. */
  void drawTexturedSphere(PImage tex, float radius, int detail) {
    if (tex == null) {
      p.sphere(radius);
      return;
    }
    p.textureMode(NORMAL);
    p.noStroke();
    for (int lat = 0; lat < detail; lat++) {
      float lat0 = PI * (-0.5f + (float) lat / detail);
      float lat1 = PI * (-0.5f + (float) (lat + 1) / detail);
      float y0 = sin(lat0) * radius;
      float y1 = sin(lat1) * radius;
      float r0 = cos(lat0) * radius;
      float r1 = cos(lat1) * radius;
      p.beginShape(QUAD_STRIP);
      p.texture(tex);
      for (int lon = 0; lon <= detail; lon++) {
        float lonAngle = TWO_PI * lon / detail;
        float x0 = cos(lonAngle) * r0;
        float z0 = sin(lonAngle) * r0;
        float x1 = cos(lonAngle) * r1;
        float z1 = sin(lonAngle) * r1;
        float u = (float) lon / detail;
        float v0 = (float) lat / detail;
        float v1 = (float) (lat + 1) / detail;
        p.vertex(x0, y0, z0, u, v0);
        p.vertex(x1, y1, z1, u, v1);
      }
      p.endShape();
    }
    p.noTexture();
  }

  /** Cone roof / fence post cap — texture mapping. */
  void drawTexturedCone(PImage tex, float radius, float h, int detail) {
    if (tex == null) {
      drawCone(radius, h, detail);
      return;
    }
    p.textureMode(NORMAL);
    p.noStroke();
    float half = h * 0.5;
    for (int i = 0; i < detail; i++) {
      float a0 = TWO_PI * i / detail;
      float a1 = TWO_PI * (i + 1) / detail;
      float u0 = (float)i / detail;
      float u1 = (float)(i + 1) / detail;
      p.beginShape(TRIANGLES);
      p.texture(tex);
      p.vertex(0, -half, 0, 0.5, 0);
      p.vertex(cos(a0) * radius, half, sin(a0) * radius, u0, 1);
      p.vertex(cos(a1) * radius, half, sin(a1) * radius, u1, 1);
      p.endShape();
    }
    p.noTexture();
  }

  void drawCone(float radius, float h, int detail) {
    p.beginShape(TRIANGLE_FAN);
    p.vertex(0, -h / 2.0, 0);
    for (int i = 0; i <= detail; i++) {
      float a = TWO_PI * i / detail;
      p.vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
    }
    p.endShape();

    p.beginShape(TRIANGLE_FAN);
    p.vertex(0, h / 2.0, 0);
    for (int i = detail; i >= 0; i--) {
      float a = TWO_PI * i / detail;
      p.vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
    }
    p.endShape();
  }

  void drawCylinder(float radius, float h, int detail) {
    p.beginShape(QUAD_STRIP);
    for (int i = 0; i <= detail; i++) {
      float a = TWO_PI * i / detail;
      float xx = cos(a) * radius;
      float zz = sin(a) * radius;
      p.vertex(xx, -h / 2.0, zz);
      p.vertex(xx, h / 2.0, zz);
    }
    p.endShape();

    p.beginShape(TRIANGLE_FAN);
    p.vertex(0, -h / 2.0, 0);
    for (int i = 0; i <= detail; i++) {
      float a = TWO_PI * i / detail;
      p.vertex(cos(a) * radius, -h / 2.0, sin(a) * radius);
    }
    p.endShape();

    p.beginShape(TRIANGLE_FAN);
    p.vertex(0, h / 2.0, 0);
    for (int i = detail; i >= 0; i--) {
      float a = TWO_PI * i / detail;
      p.vertex(cos(a) * radius, h / 2.0, sin(a) * radius);
    }
    p.endShape();
  }

  float ease(float x) {
    return 1 - (1 - x) * (1 - x);
  }

  void drawAimMarker(PVector aim, float t) {
    p.pushMatrix();
    p.translate(aim.x, -1.5, aim.z);
    p.rotateX(HALF_PI);
    p.noFill();
    p.stroke(255, 220, 100, 230);
    p.strokeWeight(2);
    float r = 14 + sin(t * 8) * 2;
    p.ellipse(0, 0, r * 2, r * 2);
    p.line(-r - 4, 0, -r - 14, 0);
    p.line(r + 4, 0, r + 14, 0);
    p.line(0, -r - 4, 0, -r - 14);
    p.line(0, r + 4, 0, r + 14);
    p.noStroke();
    p.popMatrix();
  }

}
