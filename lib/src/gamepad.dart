import 'state.dart';

/// A connected gamepad controller.
class Gamepad {
  /// Platform-assigned device index.
  ///
  /// Stable for the lifetime of a connection. May change across
  /// disconnect/reconnect cycles.
  final int index;

  /// Human-readable device name reported by the OS.
  final String name;

  /// Current input state, updated by [GamepadManager.poll].
  GamepadState state;

  Gamepad({required this.index, required this.name})
      : state = GamepadState();
}
