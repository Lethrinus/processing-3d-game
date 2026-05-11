import javax.sound.sampled.*;
import java.io.File;

/** Plain Java helper: avoids Processing preprocessor clash with Clip.open/close. */
public class SoundHelper {
  public static void playWav(String absolutePath) {
    try {
      File f = new File(absolutePath);
      if (!f.exists()) return;
      AudioInputStream ais = AudioSystem.getAudioInputStream(f);
      Clip clip = AudioSystem.getClip();
      clip.open(ais);
      clip.start();
    } catch (Exception e) { /* yok say */ }
  }

  public static Clip openMusicLoop(String absolutePath) {
    try {
      File f = new File(absolutePath);
      if (!f.exists()) return null;
      AudioInputStream ais = AudioSystem.getAudioInputStream(f);
      Clip clip = AudioSystem.getClip();
      clip.open(ais);
      clip.loop(Clip.LOOP_CONTINUOUSLY);
      return clip;
    } catch (Exception e) {
      return null;
    }
  }

  public static void disposeClip(Clip clip) {
    try {
      if (clip != null) {
        clip.stop();
        clip.close();
      }
    } catch (Exception e) { /* yok say */ }
  }
}
