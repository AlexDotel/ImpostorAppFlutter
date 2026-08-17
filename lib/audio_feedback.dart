import 'dart:async';

import 'package:flutter/services.dart';

enum AppSound { tap, select, confirm, back, toggle, reveal, timerEnd }

class AppAudio {
  AppAudio._();

  static bool enabled = true;
  static bool hapticsEnabled = true;
  static const _channel = MethodChannel('impostor/ui_audio');

  static const _volumes = <AppSound, double>{
    AppSound.tap: .28,
    AppSound.select: .34,
    AppSound.confirm: .42,
    AppSound.back: .28,
    AppSound.toggle: .32,
    AppSound.reveal: .46,
    AppSound.timerEnd: .72,
  };

  static void play(AppSound sound) {
    if (!enabled) return;
    unawaited(_play(sound));
  }

  static void feedback(AppSound sound) {
    play(sound);
    if (hapticsEnabled) HapticFeedback.selectionClick();
  }

  static Future<void> _play(AppSound sound) async {
    try {
      await _channel.invokeMethod<void>('play', {
        'sound': sound.name,
        'volume': _volumes[sound],
      });
    } catch (_) {
      // El audio nunca debe interrumpir una partida.
    }
  }
}
