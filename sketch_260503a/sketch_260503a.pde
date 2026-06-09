
import java.util.ArrayList;
import java.util.Locale;
import java.io.File;
import javax.sound.sampled.Clip;
import processing.event.KeyEvent;
import processing.event.MouseEvent;

/** Thin entry point — delegates to GameSession (SEN3301 OOP structure). */
GameSession session;

void settings() {
  if (session == null) session = new GameSession(this);
  session.settings();
}

void setup() {
  if (session == null) session = new GameSession(this);
  session.setup();
}

void draw() {
  session.draw();
}

void keyPressed(KeyEvent event) {
  session.input.onKeyPressed(event.isShiftDown());
}

void keyReleased() {
  session.input.onKeyReleased();
}

void mousePressed() {
  session.input.onMousePressed();
}

void mouseReleased() {
  session.input.onMouseReleased();
}

void mouseDragged() {
  session.input.onMouseDragged();
}

void mouseWheel(MouseEvent e) {
  session.input.onMouseWheel(e);
}
