// Audio playback and music management (WAV only).

class AudioManager {
  final PApplet p;
  final GameContext ctx;

  static final float INGAME_MUSIC_GAIN = 0.21f;
  static final float WAVE_BREAK_MUSIC_GAIN = 0.22f;

  AudioManager(PApplet p, GameContext ctx) {
    this.p = p;
    this.ctx = ctx;
  }

  void playSoundSafe(String... names) {
    if (SoundHelper.sfxVolume <= 0.0001f) return;
    for (String name : names) {
      File f = new File(p.dataPath("sounds/" + name));
      if (f.exists()) {
        SoundHelper.playSoundFile(f.getAbsolutePath(), SoundHelper.sfxVolume);
        return;
      }
    }
  }

  void playWavSafe(String name) {
    if (name.equals("gun_player.wav")) {
      playSoundSafe("gun_player.wav");
      return;
    }
    if (name.equals("reload.wav")) {
      playSoundSafe("gun_reload.wav");
      return;
    }
    playSoundSafe(name);
  }

  void playPickupSound() {
    playBulletPickupSound();
  }

  void playHealthPickupSound() {
    playSoundSafe("health_pickup.wav");
  }

  void playBulletPickupSound() {
    playSoundSafe("bullet_pickup.wav");
  }

  void playEnemyGunSound() {
    playSoundSafe("enemy_gunshot.wav");
  }

  void playUiClick() {
    playSoundSafe("ui_click.wav");
  }

  String firstSoundPath(String... names) {
    for (String name : names) {
      File f = new File(p.dataPath("sounds/" + name));
      if (f.exists()) return f.getAbsolutePath();
    }
    return null;
  }

  float effectiveInGameMusicVolume() {
    float vol = ctx.settingsMusicVol * INGAME_MUSIC_GAIN;
    if (ctx.waveState == WAVE_STATE_BREAK) vol *= WAVE_BREAK_MUSIC_GAIN;
    return vol;
  }

  void applyVolumes() {
    SoundHelper.sfxVolume = ctx.settingsSfxVol;
    SoundHelper.musicVolume = ctx.settingsMusicVol;
    if (ctx.musicClip != null && ctx.musicClip.isOpen()) {
      float vol = ctx.gameFlow == FLOW_PLAY ? effectiveInGameMusicVolume() : ctx.settingsMusicVol;
      setClipVolume(ctx.musicClip, vol);
    }
  }

  void stopMusic() {
    if (ctx.musicClip != null) {
      ctx.musicClip.stop();
      ctx.musicClip.close();
      ctx.musicClip = null;
    }
  }

  void startMenuMusic() {
    stopMusic();
    String path = firstSoundPath("western_soundtrack.wav");
    if (path == null) return;
    ctx.musicClip = SoundHelper.openMusicLoop(path, ctx.settingsMusicVol);
  }

  void startInGameMusic() {
    stopMusic();
    String path = firstSoundPath("ingame_theme.wav");
    if (path == null) return;
    ctx.musicClip = SoundHelper.openMusicLoop(path, effectiveInGameMusicVolume());
  }

  void startMusicIfAny() {
    startInGameMusic();
  }

  /** Duck in-game music during wave breaks; stop on pause; restore when fighting again. */
  void syncPlayMusic() {
    if (ctx.gameFlow != FLOW_PLAY || ctx.finished) return;

    if (ctx.gamePaused || ctx.settingsMusicVol <= 0.0001f) {
      if (ctx.musicClip != null) stopMusic();
      return;
    }

    if (ctx.musicClip == null) {
      startInGameMusic();
      return;
    }

    setClipVolume(ctx.musicClip, effectiveInGameMusicVolume());
  }

  void ensureMenuMusic() {
    if (ctx.menuMusicStarted) return;
    ctx.menuMusicStarted = true;
    applyVolumes();
    if (ctx.settingsMusicVol > 0.0001f
        && (ctx.gameFlow == FLOW_TITLE || ctx.gameFlow == FLOW_CONTROLS || ctx.gameFlow == FLOW_SETTINGS)) {
      startMenuMusic();
    }
  }

  void applyVolumesFull() {
    ctx.settingsSfxVol = sanitizeVolume(ctx.settingsSfxVol, GAME_SFX_VOLUME_DEFAULT);
    ctx.settingsMusicVol = sanitizeVolume(ctx.settingsMusicVol, GAME_MUSIC_VOLUME_DEFAULT);
    applyVolumes();
    if (ctx.settingsMusicVol <= 0.0001f) {
      stopMusic();
      return;
    }
    if (ctx.gameFlow == FLOW_PLAY) {
      syncPlayMusic();
    } else if (ctx.menuMusicStarted
        && (ctx.gameFlow == FLOW_TITLE || ctx.gameFlow == FLOW_CONTROLS || ctx.gameFlow == FLOW_SETTINGS)) {
      if (ctx.musicClip == null) startMenuMusic();
      else setClipVolume(ctx.musicClip, ctx.settingsMusicVol);
    }
  }

  float sanitizeVolume(float v, float fallback) {
    if (Float.isNaN(v) || Float.isInfinite(v)) return fallback;
    return constrain(v, 0, 1);
  }

  void setClipVolume(javax.sound.sampled.Clip clip, float vol) {
    SoundHelper.setClipVolume(clip, vol);
  }
}
