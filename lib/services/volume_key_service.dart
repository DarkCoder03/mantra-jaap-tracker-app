import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum VolumeKey { up, down }

/// Hardware volume buttons as counter input (Android).
///
/// While something is listening to [events], MainActivity consumes the
/// volume keys, so they count instead of changing the volume. Cancelling the
/// subscription hands the keys straight back to the system.
///
/// iOS does not let apps intercept the volume buttons without private APIs
/// (an App Store rejection risk), so it reports [isSupported] = false.
abstract final class VolumeKeyService {
  static const EventChannel _channel = EventChannel('mantra_jaap/volume_keys');

  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Stream<VolumeKey> get events {
    if (!isSupported) return const Stream<VolumeKey>.empty();
    return _channel
        .receiveBroadcastStream()
        .where((e) => e == 'up' || e == 'down')
        .map((e) => e == 'up' ? VolumeKey.up : VolumeKey.down);
  }
}
