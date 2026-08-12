import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundCueService {
  final _player = AudioPlayer();

  Future<void> success() async {
    SystemSound.play(SystemSoundType.click);
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (_) {
      // Asset is optional; haptic + system click still fire.
    }
  }
}
