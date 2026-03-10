import 'gamepad.dart';

/// Event fired when a gamepad connects or disconnects.
sealed class GamepadConnectionEvent {
  /// The gamepad involved in this event.
  final Gamepad gamepad;

  GamepadConnectionEvent(this.gamepad);
}

/// A gamepad was connected.
class GamepadConnected extends GamepadConnectionEvent {
  GamepadConnected(super.gamepad);
}

/// A gamepad was disconnected.
class GamepadDisconnected extends GamepadConnectionEvent {
  GamepadDisconnected(super.gamepad);
}
