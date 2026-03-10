import 'raw_gamepad_info.dart';
import 'state.dart';

/// Internal contract that platform-specific backends implement.
///
/// Each platform (XInput, evdev, GameController.framework, Android)
/// provides a concrete implementation. Consumer code never interacts
/// with this interface directly — [GamepadManager] mediates.
abstract interface class GamepadBackend {
  /// Returns info for all currently connected gamepads.
  List<RawGamepadInfo> enumerate();

  /// Reads the current input state for the device at [index].
  GamepadState poll(int index);

  /// Releases platform resources held by this backend.
  void dispose();
}
