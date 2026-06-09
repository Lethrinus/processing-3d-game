// UIRenderer — menus, HUD, and 2D overlays.

class UIRenderer {
  final PApplet p;
  final GameContext ctx;
  final GameSession session;

  UIRenderer(PApplet p, GameContext ctx, GameSession session) {
    this.p = p;
    this.ctx = ctx;
    this.session = session;
  }

  void drawWesternMenuBgImage() {
    if (ctx.uiWesternBg != null) {
      p.imageMode(CORNER);
      p.image(ctx.uiWesternBg, 0, 0, p.width, p.height);
      p.imageMode(CORNER);
      return;
    }
    p.noStroke();
    p.fill(28, 16, 10);
    p.rect(0, 0, p.width, p.height);
    p.fill(48, 28, 16, 120);
    p.rect(0, p.height * 0.55f, p.width, p.height * 0.45f);
  }

  void drawTitleMexicanWave(String title, float cx, float cy, int fontSize) {
    p.textSize(fontSize);
    float totalW = 0;
    for (int i = 0; i < title.length(); i++) {
      totalW += p.textWidth(title.charAt(i)) + TITLE_WAVE_SPACING * fontSize * 0.1f;
    }
    float x = cx - totalW * 0.5f;
    for (int i = 0; i < title.length(); i++) {
      char c = title.charAt(i);
      float w = p.textWidth(c);
      float phase = p.millis() * TITLE_WAVE_SPEED + i * 0.55f;
      float yOff = sin(phase) * TITLE_WAVE_AMP;
      p.fill(0, 0, 0, 140);
      p.text(c, x + w * 0.5f + 2, cy + yOff + 2);
      p.fill(255, 235, 175);
      p.text(c, x + w * 0.5f, cy + yOff);
      x += w + TITLE_WAVE_SPACING * fontSize * 0.1f;
    }
  }

  void drawMenuExtras(float centerX) {
    p.textSize(MENU_SCORE_SIZE);
    p.fill(220, 195, 140);
    p.text("High score: " + ctx.progressionHighScore, centerX, p.height * 0.52f);
    p.textSize(MENU_CREDITS_SIZE);
    p.fill(160, 130, 90);
    p.text("Yavuzhan · SEN3301 2025–26", centerX, p.height * 0.88f);
    float blink = map(sin(p.millis() * CLICK_BLINK_SPEED), -1, 1, CLICK_ALPHA_MIN, CLICK_ALPHA_MAX);
    p.textSize(MENU_CLICK_SIZE);
    p.fill(255, 248, 220, blink);
    if (ctx.gameFlow == FLOW_CONTROLS) p.text("Click to play", centerX, p.height * 0.82f);
  }

  void drawUiButton(PImage img, PImage imgHot, float x, float y, float w, float h, boolean hot) {
    p.rectMode(CORNER);
    PImage use = hot && imgHot != null ? imgHot : img;
    if (use != null) {
      p.imageMode(CORNER);
      p.image(use, x, y, w, h);
      return;
    }
    p.noStroke();
    p.fill(hot ? 72 : 48, 32, 18, 240);
    p.rect(x, y, w, h, 6);
    p.stroke(200, 155, 75, hot ? 255 : 200);
    p.strokeWeight(1.5f);
    p.noFill();
    p.rect(x + 1, y + 1, w - 2, h - 2, 5);
    p.noStroke();
  }


  void drawTitleScreen() {
    if (ctx.musicClip == null) session.audio.startMenuMusic();
    p.hint(DISABLE_DEPTH_TEST);
    p.camera();
    p.perspective();
    p.noLights();
    drawWesternMenuBgImage();
    p.hint(ENABLE_DEPTH_TEST);

    float centerX = p.width * 0.5f;
    session.textFontDisplay();
    p.textAlign(CENTER, CENTER);
    String title = "MAN WITH NO NAME";
    float titleY = p.height * 0.38f;
    drawTitleMexicanWave(title, centerX, titleY, TITLE_FONT_SIZE);

    session.textFontBody();
    p.textAlign(CENTER, CENTER);
    p.textSize(MENU_SUBTITLE_SIZE);
    p.fill(255, 248, 225);
    p.text("SEN3301 — 3D Arena Shootout", centerX, p.height * 0.46);
    drawMenuExtras(centerX);

    ctx.storyBtnX = centerX - ctx.storyBtnW * 0.5f;
    ctx.storyBtnY = p.height * 0.56f;
    ctx.endlessBtnX = ctx.storyBtnX;
    ctx.endlessBtnY = p.height * 0.64f;
    boolean storyHot = titleModeButtonHit(p.mouseX, p.mouseY, ctx.storyBtnX, ctx.storyBtnY);
    boolean endlessHot = titleModeButtonHit(p.mouseX, p.mouseY, ctx.endlessBtnX, ctx.endlessBtnY);
    drawTitleModeButton(ctx.storyBtnX, ctx.storyBtnY, ctx.storyBtnW, ctx.storyBtnH, "BOUNTY RUN", "9 waves · win the frontier", storyHot);
    drawTitleModeButton(ctx.endlessBtnX, ctx.endlessBtnY, ctx.storyBtnW, ctx.storyBtnH, "ENDLESS", "Rising difficulty · no final wave", endlessHot);

    ctx.settingsBtnX = centerX - ctx.settingsBtnW * 0.5f;
    ctx.settingsBtnY = p.height * 0.74f;
    boolean settingsHot = settingsButtonHit(p.mouseX, p.mouseY);
    p.noStroke();
    p.fill(32, 18, 10, settingsHot ? 210 : 175);
    p.rect(ctx.settingsBtnX, ctx.settingsBtnY, ctx.settingsBtnW, ctx.settingsBtnH, 8);
    p.stroke(200, 145, 70, settingsHot ? 255 : 200);
    p.strokeWeight(2);
    p.noFill();
    p.rect(ctx.settingsBtnX + 1, ctx.settingsBtnY + 1, ctx.settingsBtnW - 2, ctx.settingsBtnH - 2, 7);
    p.noStroke();
    session.textFontDisplay();
    p.textSize(20);
    p.fill(255, 248, 220, settingsHot ? 255 : 230);
    p.text("SETTINGS", centerX, ctx.settingsBtnY + ctx.settingsBtnH * 0.52f);
    session.reset2DDrawState();
  }

  boolean settingsButtonHit(float mx, float my) {
    return mx >= ctx.settingsBtnX && mx <= ctx.settingsBtnX + ctx.settingsBtnW
      && my >= ctx.settingsBtnY && my <= ctx.settingsBtnY + ctx.settingsBtnH;
  }

  boolean titleModeButtonHit(float mx, float my, float bx, float by) {
    return mx >= bx && mx <= bx + ctx.storyBtnW && my >= by && my <= by + ctx.storyBtnH;
  }

  void drawTitleModeButton(float bx, float by, float bw, float bh, String title, String sub, boolean hot) {
    p.noStroke();
    p.fill(32, 18, 10, hot ? 225 : 185);
    p.rect(bx, by, bw, bh, 10);
    p.stroke(200, 145, 70, hot ? 255 : 200);
    p.strokeWeight(2);
    p.noFill();
    p.rect(bx + 1, by + 1, bw - 2, bh - 2, 9);
    p.noStroke();
    p.textAlign(CENTER, CENTER);
    session.textFontDisplay();
    p.textSize(24);
    p.fill(255, 248, 220, hot ? 255 : 235);
    p.text(title, bx + bw * 0.5f, by + bh * 0.38f);
    session.textFontBody();
    p.textSize(14);
    p.fill(210, 195, 170, hot ? 255 : 220);
    p.text(sub, bx + bw * 0.5f, by + bh * 0.72f);
  }

  void drawSettingsScreen() {
    if (ctx.musicClip == null) session.audio.startMenuMusic();
    p.hint(DISABLE_DEPTH_TEST);
    p.camera();
    p.perspective();
    p.noLights();
    drawWesternMenuBgImage();
    float cx = p.width * 0.5f;
    float panelW = min(p.width - 48, 560);
    float panelH = min(p.height - 100, 420);
    float px = (p.width - panelW) * 0.5f;
    float py = (p.height - panelH) * 0.5f;
    drawWesternPanel(px, py, panelW, panelH, 14);
    p.textAlign(CENTER, TOP);
    session.textFontDisplay();
    p.fill(255, 242, 175);
    p.textSize(40);
    p.text("SETTINGS", cx, py + 22);
    session.textFontBody();
    p.textSize(17);
    p.fill(235, 220, 195);
    p.text("Drag sliders", cx, py + 68);

    float barX = cx - ctx.settingsBarW * 0.5f;
    ctx.settingsSfxBarY = py + 118;
    ctx.settingsMusicBarY = py + 188;
    drawVolumeSlider("SFX", ctx.settingsSfxVol, barX, ctx.settingsSfxBarY);
    drawVolumeSlider("MUSIC", ctx.settingsMusicVol, barX, ctx.settingsMusicBarY);

    ctx.settingsDisplayBtnX = cx - ctx.settingsDisplayBtnW * 0.5f;
    ctx.settingsDisplayBtnY = py + 258;
    boolean displayHot = session.displayModeButtonHit(p.mouseX, p.mouseY);
    p.noStroke();
    p.fill(32, 18, 10, displayHot ? 225 : 185);
    p.rect(ctx.settingsDisplayBtnX, ctx.settingsDisplayBtnY, ctx.settingsDisplayBtnW, ctx.settingsDisplayBtnH, 8);
    p.stroke(200, 145, 70, displayHot ? 255 : 200);
    p.strokeWeight(2);
    p.noFill();
    p.rect(ctx.settingsDisplayBtnX + 1, ctx.settingsDisplayBtnY + 1, ctx.settingsDisplayBtnW - 2, ctx.settingsDisplayBtnH - 2, 7);
    p.noStroke();
    session.textFontBody();
    p.textAlign(CENTER, CENTER);
    p.textSize(17);
    p.fill(255, 248, 220, displayHot ? 255 : 230);
    String modeLabel = ctx.settingsFullscreen ? "FULLSCREEN" : "WINDOWED 1280×720";
    p.text(modeLabel, cx, ctx.settingsDisplayBtnY + ctx.settingsDisplayBtnH * 0.5f);
    p.textAlign(CENTER, TOP);

    p.textSize(15);
    p.fill(210, 195, 170);
    p.text("p.ESC — back to title", cx, py + panelH - 36);
    session.reset2DDrawState();
  }

  void drawVolumeSlider(String label, float val, float x, float y) {
    session.textFontBody();
    float safe = session.sanitizeVolume(val, label.equals("SFX") ? GAME_SFX_VOLUME_DEFAULT : GAME_MUSIC_VOLUME_DEFAULT);
    p.textAlign(LEFT, CENTER);
    p.textSize(18);
    p.fill(255, 245, 220);
    p.text(label, x, y - 22);
    p.textAlign(RIGHT, CENTER);
    p.text((int)(safe * 100 + 0.5f) + "%", x + ctx.settingsBarW, y - 22);
    p.noStroke();
    p.fill(28, 16, 10, 220);
    p.rect(x, y, ctx.settingsBarW, ctx.settingsBarH, 6);
    float fillW = ctx.settingsBarW * safe;
    p.fill(200, 120, 45, 240);
    p.rect(x, y, max(4, fillW), ctx.settingsBarH, 6);
    p.stroke(220, 170, 90);
    p.strokeWeight(2);
    float knobX = x + fillW;
    p.line(knobX, y - 2, knobX, y + ctx.settingsBarH + 2);
    p.noStroke();
  }

  float volumeFromBarX(float mx, float barX) {
    return constrain((mx - barX) / ctx.settingsBarW, 0, 1);
  }

  void updateSettingsFromMouse(float mx, float my) {
    float barX = p.width * 0.5f - ctx.settingsBarW * 0.5f;
    if (ctx.settingsDraggingSfx || (mx >= barX && mx <= barX + ctx.settingsBarW
        && my >= ctx.settingsSfxBarY - 8 && my <= ctx.settingsSfxBarY + ctx.settingsBarH + 8)) {
      ctx.settingsSfxVol = volumeFromBarX(mx, barX);
      session.audio.applyVolumesFull();
      if (ctx.settingsDraggingSfx) session.maybePreviewSfxVolume();
    }
    if (ctx.settingsDraggingMusic || (mx >= barX && mx <= barX + ctx.settingsBarW
        && my >= ctx.settingsMusicBarY - 8 && my <= ctx.settingsMusicBarY + ctx.settingsBarH + 8)) {
      ctx.settingsMusicVol = volumeFromBarX(mx, barX);
      session.audio.applyVolumesFull();
    }
  }

  void drawControlsIntroScreen() {
    p.hint(DISABLE_DEPTH_TEST);
    p.camera();
    p.perspective();
    p.noLights();
    drawWesternMenuBgImage();
    drawMenuExtras(p.width * 0.5f);
    drawControlsOverlayPanel("Click anywhere to start", true);
    session.reset2DDrawState();
  }

  void drawControlsOverlayPanel(String footer, boolean fullBackdrop) {
    p.hint(DISABLE_DEPTH_TEST);
    p.camera();
    p.perspective();
    p.rectMode(CORNER);
    if (fullBackdrop) {
      p.noStroke();
      p.fill(0, 90);
      p.rect(0, 0, p.width, p.height);
    } else {
      p.noStroke();
      p.fill(0, 165);
      p.rect(0, 0, p.width, p.height);
    }

    int count = ctx.controlPanelRows != null ? ctx.controlPanelRows.length : 0;
    int cols = CTRL_GRID_COLS;
    int gridRows = count > 0 ? (count + cols - 1) / cols : 0;

    final float keySize = 40;
    final float mouseSize = 54;
    final float iconGap = 5;
    final float cellPad = 10;
    final float gridGap = 10;
    final float labelH = 36;
    float iconAreaH = max(keySize * 2 + iconGap + 4, mouseSize + 4);
    float cellW = 168;
    float cellH = iconAreaH + labelH + cellPad * 2;
    float gridW = cols * cellW + (cols - 1) * gridGap;
    float gridH = gridRows * cellH + max(0, gridRows - 1) * gridGap;

    float titleBlockH = 48;
    float footerBlockH = 58;
    float panelW = min(p.width - 28, gridW + 44);
    float panelH = min(p.height - 36, titleBlockH + gridH + footerBlockH + 24);
    float px = (p.width - panelW) * 0.5f;
    float py = (p.height - panelH) * 0.5f;
    drawWesternPanel(px, py, panelW, panelH, 12);

    p.textAlign(CENTER, TOP);
    session.textFontDisplay();
    p.fill(255, 242, 175);
    p.textSize(32);
    p.text("CONTROLS", p.width * 0.5f, py + 12);

    float gridX = px + (panelW - gridW) * 0.5f;
    float gridY = py + titleBlockH;
    if (ctx.controlPanelRows != null) {
      for (int i = 0; i < ctx.controlPanelRows.length; i++) {
        int col = i % cols;
        int row = i / cols;
        float cx = gridX + col * (cellW + gridGap);
        float cy = gridY + row * (cellH + gridGap);
        drawControlGridCell(cx, cy, cellW, cellH, ctx.controlPanelRows[i], keySize, mouseSize, iconGap, iconAreaH, labelH);
      }
    }

    String modeLine = ctx.endlessMode || ctx.selectedGameMode == GAME_MODE_ENDLESS
      ? "Endless — difficulty rises each wave · survive the timer"
      : STORY_MAX_WAVES + " waves · clear all bandits or survive the timer";
    p.textSize(13);
    p.textLeading(17);
    p.fill(245, 235, 210);
    p.text(modeLine, p.width * 0.5f, py + panelH - footerBlockH + 4);
    p.textSize(17);
    p.textLeading(20);
    p.fill(255, 252, 240);
    p.text(footer, p.width * 0.5f, py + panelH - 26);
    session.reset2DDrawState();
  }

  void drawControlKeyButton(String label, float x, float y, float w, float h) {
    p.noStroke();
    p.fill(0, 50);
    p.rect(x + 1.5f, y + 2.5f, w, h, 6);
    p.fill(252, 246, 232);
    p.rect(x, y, w, h, 6);
    p.stroke(145, 95, 48, 200);
    p.strokeWeight(1.2f);
    p.noFill();
    p.rect(x + 0.5f, y + 0.5f, w - 1, h - 1, 5);
    p.noStroke();
    session.textFontBody();
    p.textAlign(CENTER, CENTER);
    float ts = min(h * 0.5f, w * 0.78f);
    if (label.length() > 4) ts *= 0.68f;
    else if (label.length() > 1) ts *= 0.82f;
    p.textSize(ts);
    p.fill(32, 20, 12);
    p.text(label, x + w * 0.5f, y + h * 0.52f);
  }

  void drawControlMouseIcon(PImage img, float x, float y, float size) {
    if (img == null) return;
    p.imageMode(CORNER);
    p.noStroke();
    p.fill(0, 45);
    p.rect(x + 1, y + 2, size, size, 5);
    p.image(img, x, y, size, size);
  }

  void drawControlKeysWASD(String[] keys, float x, float y, float size, float gap) {
    if (keys == null || keys.length < 4) return;
    float midX = x + size + gap;
    drawControlKeyButton(keys[0], midX, y, size, size);
    float row2Y = y + size + gap;
    drawControlKeyButton(keys[1], x, row2Y, size, size);
    drawControlKeyButton(keys[2], midX, row2Y, size, size);
    drawControlKeyButton(keys[3], x + (size + gap) * 2, row2Y, size, size);
  }

  void drawControlKeysRow(String[] keys, float x, float y, float size, float gap) {
    if (keys == null) return;
    float ix = x;
    for (String k : keys) {
      float kw = controlKeyWidth(k, size);
      drawControlKeyButton(k, ix, y, kw, size);
      ix += kw + gap;
    }
  }

  void drawControlMouseRow(PImage[] icons, float x, float y, float size, float gap) {
    if (icons == null) return;
    float ix = x;
    for (PImage img : icons) {
      drawControlMouseIcon(img, ix, y, size);
      ix += size + gap;
    }
  }


  float controlKeyWidth(String label, float baseSize) {
    if (label == null || label.length() == 0) return baseSize;
    if (label.length() == 1) return baseSize;
    if (label.equals("Shift")) return baseSize * 1.75f;
    if (label.equals("Space")) return baseSize * 2.35f;
    if (label.equals("Esc")) return baseSize * 1.2f;
    return baseSize * max(1.15f, 0.45f * label.length() + 0.55f);
  }

  float controlCellIconBlockW(ControlPanelRow row, float keySize, float mouseSize, float iconGap) {
    if (row.layout == CTRL_LAYOUT_WASD && row.keyLabels != null && row.keyLabels.length >= 4) {
      return keySize * 3 + iconGap * 2;
    }
    if (row.keyLabels != null && row.keyLabels.length > 0) {
      float w = 0;
      for (int i = 0; i < row.keyLabels.length; i++) {
        w += controlKeyWidth(row.keyLabels[i], keySize);
        if (i > 0) w += iconGap;
      }
      return w;
    }
    if (row.mouseIcons != null && row.mouseIcons.length > 0) {
      return row.mouseIcons.length * mouseSize + max(0, row.mouseIcons.length - 1) * iconGap;
    }
    return 0;
  }

  float controlCellIconBlockH(ControlPanelRow row, float keySize, float mouseSize, float iconGap) {
    if (row.layout == CTRL_LAYOUT_WASD && row.keyLabels != null && row.keyLabels.length >= 4) {
      return keySize * 2 + iconGap;
    }
    if (row.mouseIcons != null && row.mouseIcons.length > 0) return mouseSize;
    return keySize;
  }

  void drawControlGridCell(float cx, float cy, float cw, float ch, ControlPanelRow row,
      float keySize, float mouseSize, float iconGap, float iconAreaH, float labelH) {
    p.noStroke();
    p.fill(32, 20, 12, 215);
    p.rect(cx, cy, cw, ch, 7);
    p.stroke(150, 100, 50, 140);
    p.strokeWeight(1);
    p.noFill();
    p.rect(cx + 1, cy + 1, cw - 2, ch - 2, 6);
    p.noStroke();

    float blockW = controlCellIconBlockW(row, keySize, mouseSize, iconGap);
    float blockH = controlCellIconBlockH(row, keySize, mouseSize, iconGap);
    float iconX = cx + (cw - blockW) * 0.5f;
    float iconY = cy + 10 + (iconAreaH - blockH) * 0.5f;

    if (row.layout == CTRL_LAYOUT_WASD && row.keyLabels != null && row.keyLabels.length >= 4) {
      drawControlKeysWASD(row.keyLabels, iconX, iconY, keySize, iconGap);
    } else if (row.keyLabels != null && row.keyLabels.length > 0) {
      drawControlKeysRow(row.keyLabels, iconX, iconY, keySize, iconGap);
    } else if (row.mouseIcons != null && row.mouseIcons.length > 0) {
      drawControlMouseRow(row.mouseIcons, iconX, iconY, mouseSize, iconGap);
    }

    session.textFontBody();
    p.textAlign(CENTER, TOP);
    p.textSize(13);
    p.textLeading(16);
    p.fill(255, 248, 235);
    p.text(row.title, cx + cw * 0.5f, cy + ch - labelH + 4);
  }

  boolean controlsHudButtonHit(float mx, float my) {
    return mx >= ctx.controlsBtnX && mx <= ctx.controlsBtnX + ctx.controlsBtnW
      && my >= ctx.controlsBtnY && my <= ctx.controlsBtnY + ctx.controlsBtnH;
  }

  void drawControlsHudButton() {
    ctx.controlsBtnX = 340;
    ctx.controlsBtnY = 12;
    ctx.controlsBtnW = 96;
    ctx.controlsBtnH = 26;
    boolean hot = controlsHudButtonHit(p.mouseX, p.mouseY);
    drawUiButton(ctx.uiBtnControls, ctx.uiBtnControlsHot, ctx.controlsBtnX, ctx.controlsBtnY, ctx.controlsBtnW, ctx.controlsBtnH, hot);
    if (ctx.uiBtnControls == null) {
      session.textFontBody();
      p.textAlign(CENTER, CENTER);
      p.textSize(10);
      p.fill(248, 215, 125);
      p.text("Controls", ctx.controlsBtnX + ctx.controlsBtnW * 0.5, ctx.controlsBtnY + ctx.controlsBtnH * 0.5 + 1);
    }
    session.reset2DDrawState();
  }

  boolean pauseButtonHit(float mx, float my, float bx, float by) {
    return mx >= bx && mx <= bx + pauseBtnW && my >= by && my <= by + pauseBtnH;
  }

  void drawPauseOverlay() {
    p.hint(DISABLE_DEPTH_TEST);
    p.camera();
    p.perspective();
    p.noStroke();
    p.fill(0, 0, 0, 200);
    p.rect(0, 0, p.width, p.height);
    p.fill(40, 18, 8, 90);
    p.rect(0, 0, p.width, p.height * 0.22f);
    p.rect(0, p.height * 0.78f, p.width, p.height * 0.22f);

    float cx = p.width * 0.5f;
    float panelW = min(p.width - 56, 500);
    float panelH = 340;
    float px = (p.width - panelW) * 0.5f;
    float py = (p.height - panelH) * 0.5f;
    drawWesternPanel(px, py, panelW, panelH, 16);

    p.stroke(190, 140, 65, 200);
    p.strokeWeight(2);
    float ruleY = py + 78;
    p.line(px + 36, ruleY, px + panelW - 36, ruleY);
    p.noStroke();

    session.textFontDisplay();
    p.textAlign(CENTER, CENTER);
    p.fill(255, 242, 175);
    p.textSize(46);
    p.text("PAUSED", cx, py + 46);

    session.textFontBody();
    p.textSize(15);
    p.fill(220, 200, 168);
    if (ctx.player != null && ctx.gameFlow == FLOW_PLAY) {
      float timeLeft = max(0, ctx.gameDurationSec + ctx.extraTimeSec - session.gameElapsedSec());
      p.text("Wave " + ctx.currentWave + "  ·  Score " + ctx.score + "  ·  Kills " + ctx.kills
        + "  ·  " + nf(timeLeft, 0, 0) + "s left", cx, py + 102);
    } else {
      p.text("Take a breath, partner", cx, py + 102);
    }

    p.textSize(13);
    p.fill(175, 155, 130);
    p.text("p.ESC or P — resume", cx, py + 128);

    ctx.pauseContinueBtnX = cx - pauseBtnW * 0.5f;
    ctx.pauseContinueBtnY = py + 158;
    ctx.pauseMenuBtnX = ctx.pauseContinueBtnX;
    ctx.pauseMenuBtnY = py + 222;
    boolean contHot = pauseButtonHit(p.mouseX, p.mouseY, ctx.pauseContinueBtnX, ctx.pauseContinueBtnY);
    boolean menuHot = pauseButtonHit(p.mouseX, p.mouseY, ctx.pauseMenuBtnX, ctx.pauseMenuBtnY);
    drawPauseMenuButton(ctx.pauseContinueBtnX, ctx.pauseContinueBtnY, "CONTINUE", contHot);
    drawPauseMenuButton(ctx.pauseMenuBtnX, ctx.pauseMenuBtnY, "MAIN MENU", menuHot);
    session.reset2DDrawState();
  }

  void drawPauseMenuButton(float bx, float by, String label, boolean hot) {
    p.noStroke();
    p.fill(32, 18, 10, hot ? 225 : 185);
    p.rect(bx, by, pauseBtnW, pauseBtnH, 8);
    p.stroke(200, 145, 70, hot ? 255 : 200);
    p.strokeWeight(2);
    p.noFill();
    p.rect(bx + 1, by + 1, pauseBtnW - 2, pauseBtnH - 2, 7);
    p.noStroke();
    p.textAlign(CENTER, CENTER);
    session.textFontDisplay();
    p.textSize(20);
    p.fill(255, 248, 220, hot ? 255 : 235);
    p.text(label, bx + pauseBtnW * 0.5f, by + pauseBtnH * 0.52f);
  }

  void drawWeaponUnlockBanner2D() {
    if (ctx.weaponUnlockBannerTimer <= 0 || ctx.weaponUnlockBannerText.length() == 0) return;
    float u = constrain(ctx.weaponUnlockBannerTimer / 3.5f, 0, 1);
    int a = (int)(255 * min(1, u * 2.2f));
    session.textFontDisplay();
    p.textAlign(CENTER, CENTER);
    p.textSize(28);
    p.fill(0, 0, 0, a * 0.6f);
    p.text(ctx.weaponUnlockBannerText, p.width * 0.5f + 2, p.height * 0.2f + 2);
    p.fill(255, 220, 120, a);
    p.text(ctx.weaponUnlockBannerText, p.width * 0.5f, p.height * 0.2f);
  }



  // === Game state ===

  /** Test p.key [T]: instantly end the current wave (clears spawns + living ctx.bandits). */


  // === HUD / 2D overlays ===

  void drawHealthBars(ArrayList<float[]> positions) {
    p.rectMode(CORNER);
    for (float[] bar : positions) {
      float w = 58;
      float h = 8;
      float px = bar[0] - w * 0.5;
      float py = bar[1];
      p.noStroke();
      p.fill(0, 100);
      p.rect(px + 2, py + 2, w + 4, h + 4, 4);
      p.fill(28, 18, 12, 235);
      p.rect(px - 1, py - 1, w + 2, h + 2, 4);
      p.noFill();
      p.stroke(140, 95, 45, 200);
      p.strokeWeight(1);
      p.rect(px, py, w, h, 3);
      p.noStroke();
      p.fill(48, 30, 20);
      p.rect(px + 1, py + 1, w - 2, h - 2, 2);
      p.fill(220, 75, 55);
      p.rect(px + 2, py + 2, (w - 4) * bar[2], h - 4, 2);
      p.fill(255, 200, 180, 90);
      p.rect(px + 2, py + 2, (w - 4) * bar[2], max(1, (h - 4) * 0.35f), 2);
    }
  }

  void drawWesternPanel(float x, float y, float w, float h, float cornerR) {
    p.rectMode(CORNER);
    p.noStroke();
    p.fill(0, 70);
    p.rect(x + 5, y + 6, w, h, cornerR);
    p.fill(20, 12, 7, 248);
    p.rect(x, y, w, h, cornerR);
    p.fill(52, 34, 18, 115);
    p.rect(x, y, w, min(36, h * 0.42f), cornerR);
    p.fill(0, 100);
    p.rect(x + 4, y + h - 5, w - 8, 3, 2);
    p.noFill();
    p.stroke(85, 52, 24, 255);
    p.strokeWeight(1);
    p.rect(x + 3, y + 3, w - 6, h - 6, max(2, cornerR - 2));
    p.stroke(235, 195, 105, 210);
    p.strokeWeight(2);
    p.rect(x, y, w, h, cornerR);
    p.stroke(255, 250, 230, 55);
    p.strokeWeight(1);
    p.rect(x + 1, y + 1, w - 2, h - 2, max(1, cornerR - 1));
    p.noStroke();
  }

  void drawHudLabelShadow(String s, float x, float y, int col) {
    session.textFontBody();
    p.textAlign(LEFT, TOP);
    p.fill(0, 130);
    p.text(s, x + 1, y + 1);
    p.fill(col);
    p.text(s, x, y);
  }

  /** Left bounty panel — full labels, sized to Sancreek metrics. */
  void drawLeftBountyHud(float lx, float ly) {
    session.textFontBody();
    float padX = 16;
    float padY = 12;
    float lineGap = 7;
    float pw = HUD_LEFT_PANEL_W;

    p.textAlign(LEFT, TOP);
    p.textSize(15);
    p.textLeading(18);
    float h0 = p.textAscent() + p.textDescent() + lineGap;
    p.textSize(19);
    p.textLeading(22);
    float h1 = p.textAscent() + p.textDescent() + lineGap;
    p.textSize(15);
    p.textLeading(18);
    float h2 = p.textAscent() + p.textDescent();
    float ph = padY * 2 + h0 + h1 * 4 + h2;

    drawWesternPanel(lx, ly, pw, ph, 9);

    String waveLine = ctx.endlessMode
      ? ("Wave  " + ctx.currentWave)
      : ("Wave  " + ctx.currentWave + " / " + STORY_MAX_WAVES);
    String modeHud = ctx.endlessMode ? "Mode  Endless" : "Mode  Bounty";
    float y = ly + padY;
    p.fill(200, 155, 75);
    p.textSize(15);
    p.textLeading(18);
    p.text("◆ BOUNTY", lx + padX, y);
    y += h0;
    p.textSize(19);
    p.textLeading(22);
    drawHudLabelShadow(waveLine, lx + padX, y, p.color(255, 238, 210));
    y += h1;
    drawHudLabelShadow("Score  " + ctx.score, lx + padX, y, p.color(235, 220, 198));
    y += h1;
    drawHudLabelShadow("Kills  " + ctx.kills, lx + padX, y, p.color(220, 205, 185));
    y += h1;
    drawHudLabelShadow(modeHud, lx + padX, y, p.color(200, 175, 130));
    y += h1;
    p.textSize(15);
    p.textLeading(18);
    p.fill(175, 155, 130);
    p.text("Best run  " + ctx.progressionHighScore, lx + padX, y);
  }

  /** Bottom-right weapon + ammo stack (avoids overlapping anchors). */
  void drawRightWeaponAmmoHud(float hpBarY, float t) {
    float panelW = 220;
    float panelH = 118;
    float panelX = p.width - panelW - 8;
    float panelY = hpBarY - panelH - 4;
    float glow = 0.88 + 0.12 * sin(t * 3.2);

    p.rectMode(CORNER);
    p.noStroke();
    p.fill(12, 8, 5, 195);
    p.rect(panelX, panelY, panelW, panelH, 8);
    p.fill(28, 18, 10, 120);
    p.rect(panelX + 2, panelY + 2, panelW - 4, panelH - 4, 7);
    p.stroke(210, 155, 70, (int)(180 * glow));
    p.strokeWeight(1.5);
    p.noFill();
    p.rect(panelX + 1, panelY + 1, panelW - 2, panelH - 2, 8);
    p.noStroke();

    float x = p.width - 22;
    float y = hpBarY - 14;
    int slot = ctx.player.weaponSlot;
    p.textAlign(RIGHT, BOTTOM);

    if (ctx.player.reloading) {
      session.textFontDisplay();
      p.textSize(26);
      p.fill(0, 140);
      p.text("RELOAD…", x + 1, y + 1);
      p.fill(140, 220, 255);
      p.text("RELOAD…", x, y);
      y -= p.textAscent() + p.textDescent() + 8;
      session.textFontDisplay();
      p.textSize(20);
      p.fill(0, 120);
      p.text(ctx.player.weaponName().toUpperCase(), x + 1, y + 1);
      p.fill(255, 210, 120);
      p.text(ctx.player.weaponName().toUpperCase(), x, y);
      return;
    }

    session.textFontDisplay();
    p.textSize(52);
    String ams = str(ctx.player.wAmmo[slot]) + " / " + str(ctx.player.wMax[slot]);
    int amCol = ctx.player.wAmmo[slot] <= 0 ? p.color(255, 130, 95) : p.color(255, 252, 240);
    p.fill(0, 150);
    p.text(ams, x + 2, y + 2);
    p.fill(amCol);
    p.text(ams, x, y);
    y -= p.textAscent() + p.textDescent() + 6;

    if (!ctx.finished && ctx.player.wAmmo[slot] > 0 && ctx.player.wAmmo[slot] <= 5) {
      session.textFontBody();
      p.textSize(13);
      p.fill(255, 210, 80, (int)(240 * glow));
      p.text("LOW AMMO", x, y);
      y -= p.textAscent() + p.textDescent() + 8;
    }

    if (!ctx.endlessMode) {
      session.textFontBody();
      p.textSize(12);
      p.textLeading(14);
      p.fill(210, 185, 150);
      if (!ctx.player.isWeaponUnlocked(1)) {
        p.text("[2] Shotgun — wave " + UNLOCK_SHOTGUN_WAVE, x, y);
        y -= p.textAscent() + p.textDescent() + 3;
      } else if (!ctx.player.isWeaponUnlocked(2)) {
        p.text("[3] Repeater — wave " + UNLOCK_REPEATER_WAVE, x, y);
        y -= p.textAscent() + p.textDescent() + 3;
      }
    }

    session.textFontDisplay();
    p.textSize(22);
    String wpn = ctx.player.weaponName().toUpperCase();
    p.fill(0, 130);
    p.text(wpn, x + 1, y + 1);
    p.fill(255, 220, 130, (int)(255 * glow));
    p.text(wpn, x, y);
  }

  void drawRulesPanel2D() {
    p.rectMode(CORNER);
    float panelW = min(p.width - 36, 920);
    float panelH = 82;
    float panelX = (p.width - panelW) * 0.5;
    float panelY = 108;

    drawWesternPanel(panelX, panelY, panelW, panelH, 8);

    p.stroke(160, 110, 50, 140);
    p.strokeWeight(1);
    int rivets = max(5, (int)(panelW / 130));
    for (int ri = 0; ri <= rivets; ri++) {
      float u = panelX + 18 + ri * (panelW - 36) / (float) rivets;
      p.fill(90, 62, 30, 210);
      p.ellipse(u, panelY + panelH * 0.5, 5, 5);
      p.fill(200, 165, 85, 170);
      p.ellipse(u - 0.5, panelY + panelH * 0.5 - 0.5, 2, 2);
    }
    p.noStroke();

    p.textAlign(CENTER, TOP);
    session.textFontBody();
    p.textSize(9);
    p.textLeading(12);
    String line1 =
      "WASD · shoot · 1/2/3 · Shift sprint · R reload · RMB camera · wheel zoom";
    String line2 = ctx.endlessMode
      ? "Endless · p.ESC pause · SPACE skip break · Q quit"
      : STORY_MAX_WAVES + " waves · p.ESC pause · SPACE skip · Q quit";
    float cx = panelX + panelW * 0.5;
    float ty = panelY + 10;
    p.fill(0, 85);
    p.text(line1, cx + 1, ty + 1);
    p.text(line2, cx + 1, ty + 1 + 13);
    p.fill(248, 215, 125);
    p.text(line1, cx, ty);
    p.text(line2, cx, ty + 13);
  }

  void drawHudBar(float x, float y, float w, float h, float ratio, int colTrack, int colFill, int colBorder) {
    ratio = constrain(ratio, 0, 1);
    p.rectMode(CORNER);
    p.noStroke();
    p.fill(colTrack);
    p.rect(x, y, w, h, 5);
    p.fill(0, 70);
    p.rect(x + 2, y + 2, w - 4, h - 4, 4);
    float innerH = h - 5;
    float fw = (w - 5) * ratio;
    if (fw > 0.5) {
      p.fill(colFill);
      p.rect(x + 2.5f, y + 2.5f, fw, innerH, 3);
      p.fill(255, 55);
      p.rect(x + 2.5f, y + 2.5f, fw, max(2, innerH * 0.4f), 3);
      p.fill(0, 45);
      p.rect(x + 2.5f, y + 2.5f + innerH * 0.58f, fw, max(1, innerH * 0.38f), 2);
    }
    p.noFill();
    p.stroke(colBorder);
    p.strokeWeight(1.5);
    p.rect(x, y, w, h, 5);
    p.stroke(255, 238, 200, 75);
    p.strokeWeight(0.9);
    p.rect(x + 1, y + 1, w - 2, h - 2, 4);
    p.noStroke();
  }

  /** Readable ctx.player resource bar: ticks, gloss sweep, optional low pulse. */
  void drawHudResourceBar(float x, float y, float w, float h, float ratio,
    int colFill, int colTrack, int colBorder, float gameT, boolean pulseCritical, int majorTicks) {
    ratio = constrain(ratio, 0, 1);
    p.rectMode(CORNER);
    p.noStroke();
    p.fill(p.red(colTrack) * 0.45, green(colTrack) * 0.45, blue(colTrack) * 0.45);
    p.rect(x - 2, y - 2, w + 4, h + 4, 8);
    p.fill(colTrack);
    p.rect(x, y, w, h, 6);
    p.fill(0, 95);
    p.rect(x + 3, y + 3, w - 6, h - 6, 5);
    float inset = 5;
    float innerW = w - inset * 2;
    float innerH = h - inset * 2;
    float fw = innerW * ratio;
    if (fw > 1.2) {
      p.fill(colFill);
      p.rect(x + inset, y + inset, fw, innerH, 4);
      p.fill(255, 85);
      p.rect(x + inset, y + inset, fw, max(3, innerH * 0.36f), 4);
      p.fill(0, 55);
      p.rect(x + inset, y + inset + innerH * 0.55f, fw, max(2, innerH * 0.4f), 3);
      if (fw > 14) {
        float gw = max(5, fw * 0.13f);
        float gx = x + inset + fw * (0.55f + 0.35f * (0.5f + 0.5f * sin(gameT * 3.2f))) - gw * 0.5f;
        gx = constrain(gx, x + inset + 1, x + inset + fw - gw - 1);
        p.fill(255, 45);
        p.rect(gx, y + inset + 1, gw, innerH - 2, 2);
      }
    }
    p.stroke(0, 110);
    p.strokeWeight(1);
    for (int i = 1; i < majorTicks; i++) {
      float tx = x + inset + innerW * i / (float) majorTicks;
      p.line(tx, y + 4, tx, y + h - 4);
    }
    p.noStroke();
    p.stroke(colBorder);
    p.strokeWeight(2);
    p.noFill();
    p.rect(x, y, w, h, 6);
    p.stroke(255, 248, 220, 90);
    p.strokeWeight(1);
    p.rect(x + 1, y + 1, w - 2, h - 2, 5);
    p.noStroke();
    if (pulseCritical) {
      float e = 0.5f + 0.5f * sin(gameT * 10);
      p.stroke(255, 95, 75, 80 + 120 * e);
      p.strokeWeight(2);
      p.noFill();
      p.rect(x - 3, y - 3, w + 6, h + 6, 9);
      p.noStroke();
    }
  }

  void drawGameOverOverlay(float t) {
    boolean isWin = ctx.gameStateText.equals("YOU WIN");
    boolean isLoss = ctx.gameStateText.equals("YOU LOST") || ctx.gameStateText.equals("TIME OVER");

    p.hint(DISABLE_DEPTH_TEST);
    p.camera();
    p.perspective();
    p.noStroke();
    p.fill(0, 0, 0, isLoss ? 215 : 195);
    p.rect(0, 0, p.width, p.height);
    if (isLoss) {
      p.fill(72, 16, 10, 95);
      p.rect(0, 0, p.width, p.height);
      p.fill(40, 8, 5, 80);
      p.rect(0, p.height * 0.65f, p.width, p.height * 0.35f);
    } else if (isWin) {
      p.fill(28, 38, 18, 70);
      p.rect(0, 0, p.width, p.height);
    }

    float cx = p.width * 0.5f;
    float panelW = min(p.width - 52, 560);
    float panelH = isWin ? 318 : 336;
    float px = (p.width - panelW) * 0.5f;
    float py = (p.height - panelH) * 0.5f;
    drawWesternPanel(px, py, panelW, panelH, 16);

    p.stroke(isLoss ? p.color(160, 55, 40, 220) : p.color(190, 140, 65, 220));
    p.strokeWeight(2);
    float ruleY = py + 82;
    p.line(px + 40, ruleY, px + panelW - 40, ruleY);
    p.noStroke();

    session.textFontDisplay();
    p.textAlign(CENTER, CENTER);
    p.textSize(isLoss ? 48 : 50);
    p.fill(0, 120);
    p.text(ctx.gameStateText, cx + 2, py + 48);
    p.fill(isLoss ? p.color(255, 118, 88) : p.color(255, 242, 175));
    p.text(ctx.gameStateText, cx, py + 46);

    session.textFontBody();
    p.textSize(16);
    p.fill(isLoss ? p.color(220, 175, 155) : p.color(215, 200, 175));
    String sub;
    if (ctx.gameStateText.equals("YOU LOST")) sub = "The desert got the better of you, partner.";
    else if (ctx.gameStateText.equals("TIME OVER")) sub = "Sun went down — time's up.";
    else if (isWin) sub = ctx.endlessMode ? "You outlasted the frontier." : "All " + STORY_MAX_WAVES + " waves cleared.";
    else sub = "Ride on.";
    p.text(sub, cx, py + 108);

    p.textSize(14);
    p.fill(200, 180, 155);
    p.text("Wave " + ctx.currentWave + "  ·  Score " + ctx.score + "  ·  Kills " + ctx.kills, cx, py + 136);

    p.stroke(140, 95, 50, 120);
    p.strokeWeight(1);
    p.line(px + 48, py + 158, px + panelW - 48, py + 158);
    p.noStroke();

    p.textSize(15);
    p.fill(185, 168, 145);
    p.text("Best run  " + ctx.progressionHighScore + "     Lifetime ctx.kills  " + ctx.progressionTotalKills, cx, py + 182);

    p.textSize(16);
    p.fill(255, 235, 200);
    p.text("R — play again", cx, py + 228);
    p.textSize(14);
    p.fill(175, 155, 130);
    p.text("Q — quit to title (saves progress)", cx, py + 254);

    session.reset2DDrawState();
  }

  void drawTimeHud(float remaining, float timeBudget, float timeRatio, float t) {
    float tw = 198;
    float th = 68;
    float rx = p.width - tw - 12;
    float ry = 12;
    boolean urgent = remaining <= 35 && !ctx.finished;
    float pulse = urgent ? 0.82f + 0.18f * sin(t * 7.5f) : 1;

    drawWesternPanel(rx, ry, tw, th, 10);
    session.textFontDisplay();
    p.textAlign(LEFT, TOP);
    p.textSize(12);
    p.fill(200, 155, 75);
    p.text("TIME", rx + 14, ry + 10);

    int totalSec = max(0, (int)ceil(remaining));
    int mm = totalSec / 60;
    int ss = totalSec % 60;
    String clock = nf(mm, 1) + ":" + nf(ss, 2);

    p.textAlign(RIGHT, TOP);
    p.textSize(36);
    p.fill(0, 100);
    p.text(clock, rx + tw - 14, ry + 7);
    p.fill(urgent ? p.color(255, 130, 95, 255 * pulse) : p.color(255, 248, 235));
    p.text(clock, rx + tw - 15, ry + 6);

    int barCol = urgent ? p.color(235, 95, 55) : p.color(95, 175, 235);
    drawHudBar(rx + 14, ry + th - 14, tw - 28, 8, timeRatio,
      p.color(32, 20, 14), barCol, p.color(175, 125, 55));
  }

  /** Western HUD panels. */
  void drawHudDistributed(float t) {
    session.textFontBody();
    p.rectMode(CORNER);
    float remaining = max(0, ctx.gameDurationSec + ctx.extraTimeSec - t);
    float timeBudget = max(1, ctx.gameDurationSec + ctx.extraTimeSec);
    float timeRatio = remaining / timeBudget;

    drawLeftBountyHud(14, 12);
    drawTimeHud(remaining, timeBudget, timeRatio, t);

    float hpBarH = 26;
    float hpBarY = p.height - hpBarH;
    float hpR = max(0, ctx.player.hp / ctx.player.maxHp);
    int hpCol = p.lerpColor(p.color(210, 55, 48), p.color(72, 220, 118), hpR);
    boolean hpCrit = hpR <= 0.25 && ctx.player.hp > 0;
    drawHudResourceBar(0, hpBarY, p.width, hpBarH, hpR,
      hpCol, p.color(18, 10, 7), p.color(175, 120, 55), t, hpCrit, 24);
    session.textFontBody();
    p.textAlign(LEFT, CENTER);
    p.textSize(10);
    p.fill(255, 220, 185);
    p.text((int)ctx.player.hp + "/" + (int)ctx.player.maxHp, 12, hpBarY + hpBarH * 0.52);

    drawRightWeaponAmmoHud(hpBarY, t);

    if (ctx.finished) drawGameOverOverlay(t);
  }

  /** Reload progress bar at ctx.player feet (compact — no large panel). */
  void drawPlayerReloadBarScreen() {
    if (!ctx.player.reloading) return;
    float rd = ctx.player.wReloadSec[ctx.player.weaponSlot];
    float prog = 1.0 - constrain(ctx.player.reloadTimer / rd, 0, 1);
    float bw = 148;
    float bh = 12;
    float cx = constrain(ctx.playerScreenFootX, bw * 0.5f + 16, p.width - bw * 0.5f - 16);
    float cy = constrain(ctx.playerScreenFootY + 24, 100, p.height - 120);
    float left = cx - bw * 0.5;
    float top = cy - 10;
    p.rectMode(CORNER);
    p.noStroke();
    p.fill(14, 10, 7, 210);
    p.rect(left - 4, top - 14, bw + 8, bh + 22, 5);
    session.textFontDisplay();
    p.textAlign(CENTER, BOTTOM);
    p.textSize(10);
    p.fill(255, 235, 200);
    p.text("RELOAD", cx, top - 2);
    drawHudBar(left, top + 4, bw, bh, prog, p.color(32, 22, 16), p.color(95, 205, 255), p.color(190, 145, 65));
    session.reset2DDrawState();
  }

  /** Empty mag reminder. */
  void drawReloadNeededFeedback(float gameT) {
    if (ctx.finished || ctx.player.reloading || ctx.waveState == WAVE_STATE_BREAK) return;
    if (ctx.player.wAmmo[ctx.player.weaponSlot] > 0) return;
    float pulse = 0.5 + 0.5 * sin(gameT * 11);
    p.rectMode(CORNER);
    float bw = min(560, p.width - 48);
    float bh = 62;
    float bx = (p.width - bw) * 0.5;
    float by = p.height * 0.26;
    p.noStroke();
    p.fill(75, 28, 22, (int)(155 + 70 * pulse));
    p.rect(bx, by, bw, bh, 10);
    p.noFill();
    p.stroke(255, 210, 100, (int)(160 + 95 * pulse));
    p.strokeWeight(2.5 + pulse);
    p.rect(bx, by, bw, bh, 10);
    p.noStroke();
    p.textAlign(CENTER, CENTER);
    session.textFontDisplay();
    p.textSize(21);
    p.fill(0, 140);
    p.text("OUT OF AMMO  —  RELOAD [ R ]", p.width * 0.5 + 2, by + bh * 0.5 + 2);
    p.fill(255, 245, 220);
    p.text("OUT OF AMMO  —  RELOAD [ R ]", p.width * 0.5, by + bh * 0.5);
    session.textFontBody();
    p.textSize(13);
    p.fill(255, 220, 180, 220);
    p.text("You cannot fire until you reload.", p.width * 0.5, by + bh - 14);
  }

  void drawSpawnPreview2D(float t) {
    if (ctx.wavePreviewTimer <= 0) return;
    session.textFontDisplay();
    p.textAlign(CENTER, TOP);
    p.textSize(22);
    p.fill(0, 0, 0, 160);
    p.text("INCOMING  ·  " + str(max(1, (int)ceil(ctx.wavePreviewTimer))) + "s",
      p.width * 0.5f + 2, p.height * 0.12f + 2);
    p.fill(255, 220, 170, 235);
    p.text("INCOMING  ·  " + str(max(1, (int)ceil(ctx.wavePreviewTimer))) + "s", p.width * 0.5f, p.height * 0.12f);
  }

  void drawWaveBanner2D() {
    if (ctx.waveBannerTimer <= 0) return;
    float u = constrain(ctx.waveBannerTimer / WAVE_BANNER_DURATION, 0, 1);
    float enter = min(1, (1 - u) * 5.5f);
    float exitFade = u < 0.2f ? u / 0.2f : 1;
    int alpha = (int)(255 * enter * exitFade);
    if (alpha < 4) return;
    session.textFontDisplay();
    float cx = p.width * 0.5f;
    float cy = p.height * 0.34f;
    float scale = 1.0f + 0.12f * sin((1 - u) * PI);
    p.pushMatrix();
    p.translate(cx, cy);
    p.scale(scale);
    p.textAlign(CENTER, CENTER);
    p.textSize(72);
    p.fill(0, 0, 0, alpha / 2);
    p.text("WAVE " + ctx.waveBannerNumber, 4, 6);
    p.fill(255, 215, 120, alpha);
    p.text("WAVE " + ctx.waveBannerNumber, 0, 0);
    if (ctx.waveBannerTimer > WAVE_BANNER_DURATION * 0.45f) {
      p.textSize(36);
      p.fill(0, 0, 0, alpha / 2);
      p.text("DRAW!", 3, 58);
      p.fill(255, 80, 60, alpha);
      p.text("DRAW!", 0, 52);
    }
    p.popMatrix();
    p.noStroke();
    float barW = min(420, p.width * 0.55f);
    p.fill(120, 40, 30, alpha / 3);
    p.rect(cx - barW * 0.5f, cy + 72, barW, 4, 2);
  }


  /** Wave break — centered chip between left/right HUD (no full-p.width top bar). */
  void drawWaveIntermissionOverlay(float gameT) {
    if (ctx.finished || ctx.waveState != WAVE_STATE_BREAK) return;
    p.rectMode(CORNER);
    p.noStroke();
    float prog = constrain(ctx.waveBreakTimer / WAVE_BREAK_DURATION, 0, 1);

    final float leftHudW = HUD_LEFT_PANEL_W;
    final float rightHudW = 198;
    final float hudPad = 14;
    float macHudDrop = PApplet.platform == PConstants.MACOS ? 22 : 10;
    float leftEnd = hudPad + leftHudW + 16;
    float rightStart = p.width - hudPad - rightHudW - 16;
    float chipW = rightStart - leftEnd - 20;
    float chipH = 36;
    float chipY = 14 + macHudDrop;
    if (chipW < 240) {
      chipW = min(400, p.width - 56);
      chipY = 118 + macHudDrop;
    } else {
      chipW = constrain(chipW, 260, 440);
    }
    float chipX = p.width * 0.5f - chipW * 0.5f;

    drawWesternPanel(chipX, chipY, chipW, chipH, 8);
    drawHudBar(chipX + 12, chipY + chipH - 11, chipW - 24, 6, prog,
      p.color(35, 22, 16), p.color(120, 185, 235), p.color(175, 125, 55));

    session.textFontBody();
    p.textAlign(CENTER, CENTER);
    p.textSize(13);
    String line = "Wave break  ·  " + str(max(0, (int)ceil(ctx.waveBreakTimer))) + "s  ·  [SPACE] skip";
    p.fill(0, 120);
    p.text(line, chipX + chipW * 0.5f + 1, chipY + chipH * 0.42f);
    p.fill(255, 238, 205);
    p.text(line, chipX + chipW * 0.5f, chipY + chipH * 0.41f);
  }

  /** Hit feedback: red vignette from screen edges (no full-screen SCREEN blend). */
  void drawHurtFeedbackOverlay() {
    float ring = ctx.hurtRing;
    if (ring < 0.02f) return;
    p.rectMode(CORNER);
    p.noStroke();
    p.blendMode(BLEND);
    float edgeW = max(48, min(p.width, p.height) * 0.14f * (0.55f + ring * 0.85f));
    int steps = 12;
    for (int i = 0; i < steps; i++) {
      float t0 = (float) i / steps;
      float t1 = (float) (i + 1) / steps;
      int a = (int) (ring * 185 * (1 - (t0 + t1) * 0.5f));
      if (a < 2) continue;
      float band = edgeW * (t1 - t0);
      p.fill(180, 20, 25, a);
      p.rect(0, edgeW * t0, p.width, band);
      p.rect(0, p.height - edgeW * t1, p.width, band);
      p.rect(edgeW * t0, 0, band, p.height);
      p.rect(p.width - edgeW * t1, 0, band, p.height);
    }
  }
}
