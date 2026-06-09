import javax.sound.sampled.*;
import java.io.*;

/** WAV playback with reliable volume (always downmix to 16-bit PCM, then scale samples). */
public class SoundHelper {
  public static float sfxVolume = 0.22f;
  public static float musicVolume = 0.16f;

  static float clampVol(float v) {
    return Math.max(0f, Math.min(1f, v));
  }

  public static void playSoundFile(String absolutePath) {
    playSoundFile(absolutePath, sfxVolume);
  }

  public static void playSoundFile(String absolutePath, float volume) {
    if (absolutePath == null) return;
    playWav(absolutePath, volume);
  }

  public static void playWav(String absolutePath) {
    playWav(absolutePath, sfxVolume);
  }

  public static void playWav(String absolutePath, float volume) {
    float v = clampVol(volume);
    if (v <= 0.0001f) return;
    try {
      File f = new File(absolutePath);
      if (!f.exists()) return;
      Clip clip = openClipFromWav(f, v);
      if (clip != null) {
        setClipVolume(clip, v);
        clip.start();
      }
    } catch (Exception e) { /* ignore */ }
  }

  public static Clip openMusicLoop(String absolutePath) {
    return openMusicLoop(absolutePath, musicVolume);
  }

  public static Clip openMusicLoop(String absolutePath, float volume) {
    float v = clampVol(volume);
    if (v <= 0.0001f) return null;
    try {
      File f = new File(absolutePath);
      if (!f.exists()) return null;
      Clip clip = openClipFromWav(f, v);
      if (clip != null) {
        setClipVolume(clip, v);
        clip.loop(Clip.LOOP_CONTINUOUSLY);
      }
      return clip;
    } catch (Exception e) {
      return null;
    }
  }

  /** Live volume for a playing clip (settings sliders). */
  public static void setClipVolume(Clip clip, float volume) {
    if (clip == null) return;
    try {
      if (!clip.isControlSupported(FloatControl.Type.MASTER_GAIN)) return;
      FloatControl gain = (FloatControl) clip.getControl(FloatControl.Type.MASTER_GAIN);
      float v = clampVol(volume);
      float dB = v <= 0.0001f ? gain.getMinimum() : 20f * (float) Math.log10(v);
      dB = Math.max(gain.getMinimum(), Math.min(gain.getMaximum(), dB));
      gain.setValue(dB);
    } catch (Exception e) { /* ignore */ }
  }

  static Clip openClipFromWav(File f, float volume) throws Exception {
    AudioInputStream ais = AudioSystem.getAudioInputStream(f);
    AudioFormat src = ais.getFormat();
    int channels = Math.max(1, src.getChannels());
    float rate = src.getSampleRate() > 0 ? src.getSampleRate() : 44100f;

    AudioFormat pcm16 = new AudioFormat(
      AudioFormat.Encoding.PCM_SIGNED,
      rate,
      16,
      channels,
      channels * 2,
      rate,
      false
    );

    if (!src.matches(pcm16)) {
      if (!AudioSystem.isConversionSupported(pcm16, src)) {
        pcm16 = new AudioFormat(
          AudioFormat.Encoding.PCM_SIGNED,
          44100f,
          16,
          channels,
          channels * 2,
          44100f,
          false
        );
      }
      ais = AudioSystem.getAudioInputStream(pcm16, ais);
    }

    byte[] raw = readAllBytes(ais);
    AudioFormat fmt = pcm16;
    scalePcm16Le(raw, fmt, volume);

    long frames = raw.length / fmt.getFrameSize();
    AudioInputStream scaled = new AudioInputStream(
      new ByteArrayInputStream(raw), fmt, frames
    );
    Clip clip = AudioSystem.getClip();
    clip.open(scaled);
    return clip;
  }

  static void scalePcm16Le(byte[] data, AudioFormat fmt, float volume) {
    if (volume >= 0.999f) return;
    int frameSize = fmt.getFrameSize();
    int channels = fmt.getChannels();
    if (fmt.getSampleSizeInBits() != 16 || frameSize < 2) return;

    for (int i = 0; i + frameSize <= data.length; i += frameSize) {
      for (int c = 0; c < channels; c++) {
        int off = i + c * 2;
        short s = (short) ((data[off + 1] << 8) | (data[off] & 0xff));
        int v = (int) (s * volume);
        if (v > 32767) v = 32767;
        if (v < -32768) v = -32768;
        s = (short) v;
        data[off] = (byte) (s & 0xff);
        data[off + 1] = (byte) ((s >> 8) & 0xff);
      }
    }
  }

  static byte[] readAllBytes(InputStream in) throws IOException {
    ByteArrayOutputStream buf = new ByteArrayOutputStream();
    byte[] chunk = new byte[16384];
    int n;
    while ((n = in.read(chunk)) > 0) buf.write(chunk, 0, n);
    in.close();
    return buf.toByteArray();
  }

  public static void disposeClip(Clip clip) {
    try {
      if (clip != null) {
        clip.stop();
        clip.close();
      }
    } catch (Exception e) { /* ignore */ }
  }
}
