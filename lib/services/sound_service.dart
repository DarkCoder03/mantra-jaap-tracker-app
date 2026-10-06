import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Only files that exist in assets/sounds/ are listed; unknown types fall
  /// back to the bell instead of failing silently.
  static const Map<String, String> _files = {
    'bell': 'bell.mp3',
    'chime': 'chime.mp3',
    'ghanta': 'ghanta.mp3',
    'damru': 'drum.mp3',
    'flute': 'flute.mp3',
  };

  Future<void> playByType(String type) async {
    final file = _files[type] ?? _files['bell']!;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // Audio focus or decoder errors must never interrupt counting.
    }
  }
}
