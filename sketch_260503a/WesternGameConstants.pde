// Shared numeric and flow constants for Western Bounty.

final int WAVE_STATE_FIGHT = 0;
final int WAVE_STATE_BREAK = 1;
final float WAVE_BREAK_DURATION = 8.0;

final int GAME_MODE_STORY = 0;
final int GAME_MODE_ENDLESS = 1;
final int STORY_MAX_WAVES = 9;
final int UNLOCK_SHOTGUN_WAVE = 3;
final int UNLOCK_REPEATER_WAVE = 6;

final int BANDIT_WPN_REVOLVER = 0;
final int BANDIT_WPN_SHOTGUN = 1;
final int BANDIT_WPN_REPEATER = 2;

final float STAGGER_SPAWN_INTERVAL = 0.82f;
final float WAVE_PREVIEW_DURATION = 2.85f;
final float WAVE_BANNER_DURATION = 3.75f;

final float PATH_CELL = 100f;
final int[] PATH_DIR_DX = {1, -1, 0, 0, 1, 1, -1, -1};
final int[] PATH_DIR_DZ = {0, 0, 1, -1, 1, -1, 1, -1};
final float[] PATH_DIR_COST = {1, 1, 1, 1, 1.414f, 1.414f, 1.414f, 1.414f};

final float GAME_SFX_VOLUME_DEFAULT = 0.22f;
final float GAME_MUSIC_VOLUME_DEFAULT = 0.16f;
final int WINDOWED_W = 1280;
final int WINDOWED_H = 720;

final int TITLE_FONT_SIZE = 62;
final float TITLE_WAVE_SPEED = 0.0015f;
final float TITLE_WAVE_SPACING = 0.4f;
final float TITLE_WAVE_AMP = 6f;
final int MENU_SUBTITLE_SIZE = 24;
final int MENU_SCORE_SIZE = 20;
final int MENU_CREDITS_SIZE = 16;
final int MENU_CLICK_SIZE = 28;
final float CLICK_BLINK_SPEED = 0.004f;
final int CLICK_ALPHA_MIN = 100;
final int CLICK_ALPHA_MAX = 255;

final int FLOW_TITLE = 0;
final int FLOW_CONTROLS = 1;
final int FLOW_PLAY = 2;
final int FLOW_SETTINGS = 3;

final float HUD_LEFT_PANEL_W = 310;
final float pauseBtnW = 260;
final float pauseBtnH = 46;

final int CTRL_LAYOUT_ROW = 0;
final int CTRL_LAYOUT_WASD = 1;
final int CTRL_GRID_COLS = 4;

final float LEGACY_ARENA_W = 900;
final float LEGACY_ARENA_H = 620;
final float GROUND_Y = 0;
final float CHARACTER_GROUND_OFFSET = -1f;
final float SKYBOX_HORIZON_UV = 0.54f;
final float BUILDING_TEX_TILE = 96f;
