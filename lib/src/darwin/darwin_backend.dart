/// macOS/iOS [GamepadBackend] implementation using GameController.framework.
///
/// Uses direct ObjC runtime FFI calls — no ffigen, no build hook.
/// The framework is loaded at runtime via [DynamicLibrary.open].
library;

import 'dart:ffi';

import '../backend.dart';
import '../raw_gamepad_info.dart';
import '../state.dart';
import 'game_controller.dart';
import 'objc.dart';

/// GameController.framework backend for macOS and iOS.
///
/// Polls `[GCController controllers]` on each [enumerate] call.
/// Caches controller pointers by index for [poll].
class DarwinBackend implements GamepadBackend {
  final Map<int, Pointer<Void>> _controllers = {};

  @override
  List<RawGamepadInfo> enumerate() {
    final pool = autoreleasePoolPush();
    try {
      final controllers = gcEnumerateControllers();
      _controllers.clear();

      final results = <RawGamepadInfo>[];
      for (final c in controllers) {
        _controllers[c.index] = c.ptr;
        results.add(RawGamepadInfo(index: c.index, name: c.name));
      }
      return results;
    } finally {
      autoreleasePoolPop(pool);
    }
  }

  @override
  GamepadState poll(int index) {
    final controller = _controllers[index];
    if (controller == null) return GamepadState();

    final pool = autoreleasePoolPush();
    try {
      return gcReadState(controller);
    } finally {
      autoreleasePoolPop(pool);
    }
  }

  @override
  void dispose() {
    _controllers.clear();
  }
}
