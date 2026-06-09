// Arena colliders, pathfinding, and movement resolution.

class WorldScene {
  final PApplet p;
  final GameContext ctx;

  WorldScene(PApplet p, GameContext ctx) {
    this.p = p;
    this.ctx = ctx;
  }

  void buildSceneColliders() {
    ctx.sceneColliders.clear();
    addCollider(ctx.worldX(-666), ctx.worldX(-454), ctx.worldZ(-292), ctx.worldZ(-112));
    addCollider(ctx.worldX(470), ctx.worldX(650), ctx.worldZ(-266), ctx.worldZ(-116));
    addCollider(ctx.worldX(-640), ctx.worldX(-440), ctx.worldZ(176), ctx.worldZ(324));
    addCollider(ctx.worldX(450), ctx.worldX(590), ctx.worldZ(178), ctx.worldZ(320));
    addCircleCollider(ctx.worldX(-148), ctx.worldZ(58), ctx.worldX(44));
    addCollider(ctx.worldX(632), ctx.worldX(808), ctx.worldZ(-10), ctx.worldZ(70));
    addCircleCollider(ctx.worldX(520), ctx.worldZ(250), ctx.worldX(62));
    float cR = (ctx.worldX(26) + ctx.worldZ(26)) * 0.5f;
    addCircleCollider(ctx.worldX(-130), ctx.worldZ(-380), cR);
    addCircleCollider(ctx.worldX(160), ctx.worldZ(-310), cR);
    addCircleCollider(ctx.worldX(180), ctx.worldZ(350), cR);
    addCircleCollider(ctx.worldX(-220), ctx.worldZ(320), cR);
    addCircleCollider(ctx.worldX(-680), ctx.worldZ(50), cR);
    addCircleCollider(ctx.worldX(680), ctx.worldZ(-50), cR);
    float bR = (ctx.worldX(14) + ctx.worldZ(14)) * 0.5f;
    addCircleCollider(ctx.worldX(-30), ctx.worldZ(-130), bR);
    addCircleCollider(ctx.worldX(30), ctx.worldZ(-150), bR);
    addCircleCollider(ctx.worldX(70), ctx.worldZ(120), bR);
    addCircleCollider(ctx.worldX(-380), ctx.worldZ(0), bR);
    rebuildPathGrid();
  }

  void addCollider(float minX, float maxX, float minZ, float maxZ) {
    ctx.sceneColliders.add(new float[]{minX, maxX, minZ, maxZ});
  }

  void addCircleCollider(float cx, float cz, float radius) {
    addCollider(cx - radius, cx + radius, cz - radius, cz + radius);
  }

  int pathIndex(int gx, int gz) {
    return gx + gz * ctx.pathCols;
  }

  float pathCellCenterX(int gx) {
    return -ctx.arenaHalfW + (gx + 0.5f) * PATH_CELL;
  }

  float pathCellCenterZ(int gz) {
    return -ctx.arenaHalfH + (gz + 0.5f) * PATH_CELL;
  }

  int worldToGx(float x) {
    return constrain((int)floor((x + ctx.arenaHalfW) / PATH_CELL), 0, ctx.pathCols - 1);
  }

  int worldToGz(float z) {
    return constrain((int)floor((z + ctx.arenaHalfH) / PATH_CELL), 0, ctx.pathRows - 1);
  }

  void rebuildPathGrid() {
    ctx.pathCols = max(10, (int)ceil((ctx.arenaHalfW * 2f) / PATH_CELL));
    ctx.pathRows = max(10, (int)ceil((ctx.arenaHalfH * 2f) / PATH_CELL));
    ctx.pathBlocked = new boolean[ctx.pathCols * ctx.pathRows];
    for (int gz = 0; gz < ctx.pathRows; gz++) {
      for (int gx = 0; gx < ctx.pathCols; gx++) {
        float wx = pathCellCenterX(gx);
        float wz = pathCellCenterZ(gz);
        ctx.pathBlocked[pathIndex(gx, gz)] =
          !isInArenaXZ(wx, wz, 50) || circleOverlapsColliderXZ(wx, wz, 40);
      }
    }
  }

  int nearestFreePathCell(int gx, int gz) {
    if (!ctx.pathBlocked[pathIndex(gx, gz)]) return pathIndex(gx, gz);
    for (int ring = 1; ring < max(ctx.pathCols, ctx.pathRows); ring++) {
      for (int dz = -ring; dz <= ring; dz++) {
        for (int dx = -ring; dx <= ring; dx++) {
          if (abs(dx) != ring && abs(dz) != ring) continue;
          int nx = gx + dx, nz = gz + dz;
          if (nx < 0 || nz < 0 || nx >= ctx.pathCols || nz >= ctx.pathRows) continue;
          int idx = pathIndex(nx, nz);
          if (!ctx.pathBlocked[idx]) return idx;
        }
      }
    }
    return pathIndex(gx, gz);
  }

  ArrayList<PVector> findPathWorld(float sx, float sz, float ex, float ez) {
    ArrayList<PVector> out = new ArrayList<PVector>();
    if (ctx.pathBlocked == null || ctx.pathBlocked.length == 0) rebuildPathGrid();
    int sgx = worldToGx(sx), sgz = worldToGz(sz);
    int egx = worldToGx(ex), egz = worldToGz(ez);
    int start = nearestFreePathCell(sgx, sgz);
    int goal = nearestFreePathCell(egx, egz);
    if (start == goal) {
      out.add(new PVector(ex, 0, ez));
      return out;
    }
    int n = ctx.pathCols * ctx.pathRows;
    float[] gScore = new float[n];
    int[] cameFrom = new int[n];
    boolean[] closed = new boolean[n];
    for (int i = 0; i < n; i++) {
      gScore[i] = 1e9f;
      cameFrom[i] = -1;
    }
    gScore[start] = 0;
    int[] openSet = new int[n];
    int openCount = 0;
    openSet[openCount++] = start;
    while (openCount > 0) {
      int bestI = 0;
      float bestF = 1e9f;
      for (int oi = 0; oi < openCount; oi++) {
        int idx = openSet[oi];
        int gx = idx % ctx.pathCols, gz = idx / ctx.pathCols;
        float h = dist(gx, gz, egx, egz);
        float f = gScore[idx] + h;
        if (f < bestF) {
          bestF = f;
          bestI = oi;
        }
      }
      int current = openSet[bestI];
      openSet[bestI] = openSet[--openCount];
      if (closed[current]) continue;
      closed[current] = true;
      if (current == goal) {
        int c = goal;
        while (c != -1) {
          int gx = c % ctx.pathCols, gz = c / ctx.pathCols;
          out.add(0, new PVector(pathCellCenterX(gx), 0, pathCellCenterZ(gz)));
          c = cameFrom[c];
        }
        if (out.size() > 0) {
          PVector last = out.get(out.size() - 1);
          last.x = ex;
          last.z = ez;
        }
        return out;
      }
      int cgx = current % ctx.pathCols, cgz = current / ctx.pathCols;
      for (int d = 0; d < PATH_DIR_DX.length; d++) {
        int ngx = cgx + PATH_DIR_DX[d], ngz = cgz + PATH_DIR_DZ[d];
        if (ngx < 0 || ngz < 0 || ngx >= ctx.pathCols || ngz >= ctx.pathRows) continue;
        int ni = pathIndex(ngx, ngz);
        if (ctx.pathBlocked[ni] || closed[ni]) continue;
        float tentative = gScore[current] + PATH_CELL * PATH_DIR_COST[d];
        if (tentative < gScore[ni]) {
          cameFrom[ni] = current;
          gScore[ni] = tentative;
          boolean inOpen = false;
          for (int oi = 0; oi < openCount; oi++) {
            if (openSet[oi] == ni) {
              inOpen = true;
              break;
            }
          }
          if (!inOpen && openCount < n) openSet[openCount++] = ni;
        }
      }
    }
    return out;
  }

  void updateStaggeredSpawns(float dt) {
    if (!ctx.waveSpawning || ctx.pendingBanditSpawns.size() == 0) {
      ctx.waveSpawning = false;
      return;
    }
    ctx.staggerSpawnTimer -= dt;
    if (ctx.staggerSpawnTimer > 0) return;
    ctx.staggerSpawnTimer = STAGGER_SPAWN_INTERVAL;
    PendingBandit e = ctx.pendingBanditSpawns.remove(0);
    ctx.bandits.add(new Bandit(e.x, e.z, e.outfit, e.spdMul, e.hpMul, e.wave, e.weaponType));
    if (ctx.pendingBanditSpawns.size() == 0) ctx.waveSpawning = false;
  }

  void resolveCircleColliders(PVector pos, float r) {
    resolveCircleColliders(pos, r, 6);
  }

  void resolveCircleColliders(PVector pos, float r, int maxPass) {
    for (int pass = 0; pass < maxPass; pass++) {
      for (float[] b : ctx.sceneColliders) {
        float px = pos.x;
        float pz = pos.z;
        float cx = constrain(px, b[0], b[1]);
        float cz = constrain(pz, b[2], b[3]);
        float dx = px - cx;
        float dz = pz - cz;
        float d2 = dx * dx + dz * dz;
        if (d2 < r * r) {
          float d = sqrt(max(d2, 1e-8f));
          float push = r - d;
          pos.x += (dx / d) * push;
          pos.z += (dz / d) * push;
        }
      }
    }
  }

  boolean circleOverlapsColliderXZ(float px, float pz, float r) {
    for (float[] b : ctx.sceneColliders) {
      float cx = constrain(px, b[0], b[1]);
      float cz = constrain(pz, b[2], b[3]);
      float dx = px - cx;
      float dz = pz - cz;
      if (dx * dx + dz * dz < r * r) return true;
    }
    return false;
  }

  boolean isInArenaXZ(float x, float z, float margin) {
    return x > -ctx.arenaHalfW + margin && x < ctx.arenaHalfW - margin
      && z > -ctx.arenaHalfH + margin && z < ctx.arenaHalfH - margin;
  }

  boolean isWalkableSpawnXZ(float x, float z, float r) {
    return isInArenaXZ(x, z, 80) && !circleOverlapsColliderXZ(x, z, r);
  }

  void nudgeToClearPosition(PVector pos, float r) {
    resolveCircleColliders(pos, r, 16);
    if (!circleOverlapsColliderXZ(pos.x, pos.z, r * 0.9f)) return;
    float ox = pos.x, oz = pos.z;
    for (float ring = 35; ring < 320; ring += 32) {
      for (int i = 0; i < 16; i++) {
        float a = i * TWO_PI / 16.0f;
        float tx = ox + cos(a) * ring;
        float tz = oz + sin(a) * ring;
        if (isWalkableSpawnXZ(tx, tz, r)) {
          pos.x = tx;
          pos.z = tz;
          return;
        }
      }
    }
  }

  PVector colliderSteerForce(float px, float pz, float radius) {
    PVector acc = new PVector(0, 0, 0);
    float pad = radius + 42;
    for (float[] b : ctx.sceneColliders) {
      if (px > b[0] && px < b[1] && pz > b[2] && pz < b[3]) {
        float dl = px - b[0], dr = b[1] - px, db = pz - b[2], df = b[3] - pz;
        float m = min(dl, min(dr, min(db, df)));
        if (m == dl) acc.x -= 1.4f;
        else if (m == dr) acc.x += 1.4f;
        else if (m == db) acc.z -= 1.4f;
        else acc.z += 1.4f;
      }
      float cx = constrain(px, b[0], b[1]);
      float cz = constrain(pz, b[2], b[3]);
      float dx = px - cx, dz = pz - cz;
      float d2 = dx * dx + dz * dz;
      if (d2 < pad * pad && d2 > 1e-6f) {
        float d = sqrt(d2);
        float w = (pad - d) / pad;
        acc.x += (dx / d) * w * 1.2f;
        acc.z += (dz / d) * w * 1.2f;
      }
    }
    if (acc.magSq() > 1e-4f) {
      acc.normalize();
      acc.mult(0.85f);
    }
    return acc;
  }

  void unstuckBandit(Bandit b, Player player) {
    float r = 18;
    PVector best = null;
    float bestScore = -1e9f;
    for (int i = 0; i < 16; i++) {
      float a = i * TWO_PI / 16.0f + b.phase;
      for (float dist = 40; dist <= 140; dist += 35) {
        float tx = b.pos.x + cos(a) * dist;
        float tz = b.pos.z + sin(a) * dist;
        if (!isWalkableSpawnXZ(tx, tz, r)) continue;
        float dPlayer = dist(tx, tz, player.pos.x, player.pos.z);
        float score = -dPlayer + dist * 0.15f;
        if (score > bestScore) {
          bestScore = score;
          best = new PVector(tx, 0, tz);
        }
      }
    }
    if (best != null) {
      b.pos.x = best.x;
      b.pos.z = best.z;
    } else {
      nudgeToClearPosition(b.pos, r);
    }
    b.stuckSec = 0;
  }

  PVector rotateDirXZ(PVector d, float ang) {
    float nx = d.x * cos(ang) - d.z * sin(ang);
    float nz = d.x * sin(ang) + d.z * cos(ang);
    PVector o = new PVector(nx, 0, nz);
    if (o.magSq() > 1e-6) o.normalize();
    return o;
  }

  PVector pickClearStepXZ(PVector from, PVector preferDir, float len, float radius) {
    if (preferDir.magSq() < 1e-6) return new PVector(0, 0, 0);
    preferDir.normalize();
    PVector bestDelta = null;
    float bestScore = -1e9f;
    int nDirs = 16;
    for (int i = 0; i <= nDirs; i++) {
      PVector d;
      if (i == 0) d = preferDir.copy();
      else {
        float a = (i - 1) * TWO_PI / nDirs;
        d = new PVector(cos(a), 0, sin(a));
      }
      d.normalize();
      for (float scale = 1.0f; scale >= 0.35f; scale -= 0.325f) {
        float step = len * scale;
        float px = from.x + d.x * step;
        float pz = from.z + d.z * step;
        if (circleOverlapsColliderXZ(px, pz, radius)) continue;
        float dot = preferDir.x * d.x + preferDir.z * d.z;
        float score = dot * 2.0f + scale;
        if (score > bestScore) {
          bestScore = score;
          bestDelta = new PVector(d.x * step, 0, d.z * step);
        }
        break;
      }
    }
    if (bestDelta != null) return bestDelta;
    PVector perpL = new PVector(-preferDir.z, 0, preferDir.x);
    PVector perpR = new PVector(preferDir.z, 0, -preferDir.x);
    for (PVector side : new PVector[]{perpL, perpR}) {
      for (int sgn = -1; sgn <= 1; sgn += 2) {
        PVector d = PVector.mult(side, sgn);
        d.normalize();
        float px = from.x + d.x * len;
        float pz = from.z + d.z * len;
        if (!circleOverlapsColliderXZ(px, pz, radius)) {
          return new PVector(d.x * len, 0, d.z * len);
        }
      }
    }
    return new PVector(0, 0, 0);
  }
}
