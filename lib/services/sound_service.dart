import 'package:flutter/services.dart';

class SoundService {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  static void playMove() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playCapture() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playCheck() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  static void playGameOver() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
