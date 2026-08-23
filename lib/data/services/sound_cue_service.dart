import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short audio/haptic cues for payment outcomes.
///
/// Placeholder tones: failure uses [SystemSoundType.alert]; pending uses a
/// light double-click pattern. Replace with real assets under assets/sounds/
/// when available (failure.mp3, pending.mp3).
class SoundCueService {
  SoundCueService._();
  static final SoundCueService instance = SoundCueService._();
  factory SoundCueService() => instance;

  final _player = AudioPlayer();

  Future<void> success() async {
    await SystemSound.play(SystemSoundType.click);
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (_) {
      // Asset is optional; haptic + system click still fire.
    }
  }

  Future<void> failure() async {
    await HapticFeedback.heavyImpact();
    // Placeholder: system alert until failure.mp3 is added.
    await SystemSound.play(SystemSoundType.alert);
    try {
      await _player.play(AssetSource('sounds/failure.mp3'));
    } catch (_) {}
  }

  Future<void> pending() async {
    await HapticFeedback.mediumImpact();
    // Placeholder: neutral double-tap click until pending.mp3 is added.
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await SystemSound.play(SystemSoundType.click);
    try {
      await _player.play(AssetSource('sounds/pending.mp3'));
    } catch (_) {}
  }
}
