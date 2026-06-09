// Keyboard and mouse input routing.

class InputHandler {
  final PApplet p;
  final GameContext ctx;
  final GameSession session;

  InputHandler(PApplet p, GameContext ctx, GameSession session) {
    this.p = p;
    this.ctx = ctx;
    this.session = session;
  }

  void onKeyPressed(boolean shiftDown) {
    if (ctx.gameFlow == FLOW_PLAY && !ctx.finished) {
      if (p.key == ESC || p.keyCode == ESC) {
        p.key = 0;
        session.setGamePaused(!ctx.gamePaused);
        return;
      }
      if (ctx.gamePaused) {
        if (p.key == 'p' || p.key == 'P' || p.key == '\n' || p.key == '\r') {
          session.setGamePaused(false);
        }
        return;
      }
    }
    if (ctx.gameFlow == FLOW_SETTINGS) {
      if (p.key == ESC || p.keyCode == ESC) {
        p.key = 0;
        ctx.gameFlow = FLOW_TITLE;
        session.saveProgression();
        return;
      }
      float step = 0.04f;
      if (p.keyCode == LEFT) {
        if (shiftDown) ctx.settingsMusicVol = max(0, ctx.settingsMusicVol - step);
        else ctx.settingsSfxVol = max(0, ctx.settingsSfxVol - step);
        session.audio.applyVolumesFull();
        return;
      }
      if (p.keyCode == RIGHT) {
        if (shiftDown) ctx.settingsMusicVol = min(1, ctx.settingsMusicVol + step);
        else ctx.settingsSfxVol = min(1, ctx.settingsSfxVol + step);
        session.audio.applyVolumesFull();
        return;
      }
    }
    if (p.key == 'w' || p.key == 'W') ctx.moveW = true;
    if (p.key == 'a' || p.key == 'A') ctx.moveA = true;
    if (p.key == 's' || p.key == 'S') ctx.moveS = true;
    if (p.key == 'd' || p.key == 'D') ctx.moveD = true;
    if (p.key == 'q' || p.key == 'Q') {
      ctx.finished = true;
      ctx.gameStateText = "QUIT";
      session.audio.stopMusic();
    }
    if (p.key == 'r' || p.key == 'R') {
      if (ctx.finished) session.beginPlaySession();
      else if (ctx.gameFlow == FLOW_PLAY && !ctx.showControlsOverlay && !ctx.gamePaused) {
        ctx.player.startReload(ctx, session.audio);
      }
    }
    if (p.key == 'h' || p.key == 'H') {
      if (ctx.gameFlow == FLOW_PLAY && !ctx.finished && !ctx.gamePaused) {
        ctx.showControlsOverlay = !ctx.showControlsOverlay;
        if (ctx.showControlsOverlay) ctx.shooting = false;
      }
    }
    if (!ctx.finished && ctx.gameFlow == FLOW_PLAY && !ctx.showControlsOverlay && !ctx.gamePaused) {
      if (p.key == '1') ctx.player.setWeaponSlot(0, ctx);
      if (p.key == '2') ctx.player.setWeaponSlot(1, ctx);
      if (p.key == '3') ctx.player.setWeaponSlot(2, ctx);
      if (p.key == ' ' && ctx.waveState == WAVE_STATE_BREAK) ctx.waveBreakTimer = 0;
      if (p.key == 't' || p.key == 'T') session.waves.forceCompleteCurrentWave();
    }
    if (p.key == CODED && p.keyCode == SHIFT) ctx.sprintHeld = true;
  }

  void onKeyReleased() {
    if (p.key == 'w' || p.key == 'W') ctx.moveW = false;
    if (p.key == 'a' || p.key == 'A') ctx.moveA = false;
    if (p.key == 's' || p.key == 'S') ctx.moveS = false;
    if (p.key == 'd' || p.key == 'D') ctx.moveD = false;
    if (p.key == CODED && p.keyCode == SHIFT) ctx.sprintHeld = false;
  }

  void onMousePressed() {
    if (ctx.gameFlow == FLOW_TITLE) {
      if (session.ui.settingsButtonHit(p.mouseX, p.mouseY)) {
        session.audio.playUiClick();
        ctx.gameFlow = FLOW_SETTINGS;
        return;
      }
      if (session.ui.titleModeButtonHit(p.mouseX, p.mouseY, ctx.storyBtnX, ctx.storyBtnY)) {
        session.audio.playUiClick();
        ctx.selectedGameMode = GAME_MODE_STORY;
        ctx.gameFlow = FLOW_CONTROLS;
        return;
      }
      if (session.ui.titleModeButtonHit(p.mouseX, p.mouseY, ctx.endlessBtnX, ctx.endlessBtnY)) {
        session.audio.playUiClick();
        ctx.selectedGameMode = GAME_MODE_ENDLESS;
        ctx.gameFlow = FLOW_CONTROLS;
        return;
      }
      return;
    }
    if (ctx.gameFlow == FLOW_SETTINGS) {
      if (session.displayModeButtonHit(p.mouseX, p.mouseY)) {
        session.audio.playUiClick();
        session.applyDisplayMode(!ctx.settingsFullscreen);
        return;
      }
      float barX = p.width * 0.5f - ctx.settingsBarW * 0.5f;
      if (p.mouseY >= ctx.settingsSfxBarY - 10 && p.mouseY <= ctx.settingsSfxBarY + ctx.settingsBarH + 10
          && p.mouseX >= barX - 8 && p.mouseX <= barX + ctx.settingsBarW + 8) {
        session.audio.playUiClick();
        ctx.settingsDraggingSfx = true;
        ctx.settingsSfxVol = session.ui.volumeFromBarX(p.mouseX, barX);
        session.audio.applyVolumesFull();
      }
      if (p.mouseY >= ctx.settingsMusicBarY - 10 && p.mouseY <= ctx.settingsMusicBarY + ctx.settingsBarH + 10
          && p.mouseX >= barX - 8 && p.mouseX <= barX + ctx.settingsBarW + 8) {
        session.audio.playUiClick();
        ctx.settingsDraggingMusic = true;
        ctx.settingsMusicVol = session.ui.volumeFromBarX(p.mouseX, barX);
        session.audio.applyVolumesFull();
      }
      return;
    }
    if (ctx.gameFlow == FLOW_CONTROLS) {
      session.audio.playUiClick();
      session.beginPlaySession();
      return;
    }
    if (ctx.gameFlow == FLOW_PLAY) {
      if (ctx.gamePaused && !ctx.finished) {
        if (session.ui.pauseButtonHit(p.mouseX, p.mouseY, ctx.pauseContinueBtnX, ctx.pauseContinueBtnY)) {
          session.audio.playUiClick();
          session.setGamePaused(false);
          return;
        }
        if (session.ui.pauseButtonHit(p.mouseX, p.mouseY, ctx.pauseMenuBtnX, ctx.pauseMenuBtnY)) {
          session.audio.playUiClick();
          session.returnToTitleFromPause();
          return;
        }
        return;
      }
      if (ctx.showControlsOverlay) {
        session.audio.playUiClick();
        ctx.showControlsOverlay = false;
        return;
      }
      if (p.mouseButton == LEFT && session.ui.controlsHudButtonHit(p.mouseX, p.mouseY)) {
        session.audio.playUiClick();
        ctx.showControlsOverlay = true;
        ctx.shooting = false;
        return;
      }
      if (p.mouseButton == LEFT) ctx.shooting = true;
    }
  }

  void onMouseReleased() {
    if (p.mouseButton == LEFT) ctx.shooting = false;
    if (ctx.settingsDraggingSfx || ctx.settingsDraggingMusic) {
      ctx.settingsDraggingSfx = false;
      ctx.settingsDraggingMusic = false;
      session.saveProgression();
    }
  }

  void onMouseDragged() {
    if (ctx.gameFlow == FLOW_SETTINGS) {
      session.ui.updateSettingsFromMouse(p.mouseX, p.mouseY);
      return;
    }
    if (p.mouseButton == RIGHT) {
      float dx = p.mouseX - p.pmouseX;
      float dy = p.mouseY - p.pmouseY;
      ctx.camYaw -= dx * 0.008;
      ctx.camPitch -= dy * 0.005;
      ctx.camPitch = constrain(ctx.camPitch, 0.45, 1.12);
    }
  }

  void onMouseWheel(MouseEvent e) {
    float scroll = e.getCount();
    ctx.camDist += scroll * 60;
    ctx.camDist = constrain(ctx.camDist, ctx.camDistMin, ctx.camDistMax);
  }
}
