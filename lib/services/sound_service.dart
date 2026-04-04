import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playByType(String type) async {
    final file = switch (type) {
      'bell' => 'bell.mp3',
      'chime' => 'chime.mp3',
      'mantra' => 'mantra.mp3',
      'conch' => 'conch.mp3',
      'damru' => 'damru.mp3',
      'ghanta' => 'ghanta.mp3',
      'flute' => 'flute.mp3',
      _ => 'bell.mp3',
    };

    await _player.stop();
    await _player.play(AssetSource('sounds/$file'));
  }
}