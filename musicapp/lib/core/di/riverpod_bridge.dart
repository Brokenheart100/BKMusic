import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/core/services/audio_manager.dart';

/// [桥梁]
/// 将 GetIt 中的 AudioManager 单例注入到 Riverpod 的世界中。
/// 这样我们既保留了 DI 的解耦，又享受了 Riverpod 的响应式能力。
final audioManagerProvider = Provider<AudioManager>((ref) {
  return getIt<AudioManager>();
});
