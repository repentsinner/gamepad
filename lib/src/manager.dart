import 'dart:async';
import 'dart:collection';

import 'backend.dart';
import 'connection_event.dart';
import 'gamepad.dart';

/// Entry point for gamepad input. Enumerates controllers, tracks
/// hotplug events, and polls state.
///
/// Takes a [GamepadBackend] via constructor injection. Platform
/// backends are plugged in here.
class GamepadManager {
  final GamepadBackend _backend;
  final Map<int, Gamepad> _gamepads = {};
  final StreamController<GamepadConnectionEvent> _connectionController =
      StreamController.broadcast();

  GamepadManager({required GamepadBackend backend}) : _backend = backend;

  /// Currently connected gamepads, keyed by platform index.
  Map<int, Gamepad> get gamepads => UnmodifiableMapView(_gamepads);

  /// Stream of connect/disconnect events.
  Stream<GamepadConnectionEvent> get connectionEvents =>
      _connectionController.stream;

  /// Polls all connected gamepads for current input state.
  ///
  /// Detects newly connected and disconnected devices, fires
  /// [GamepadConnectionEvent]s, and updates each [Gamepad.state].
  void poll() {
    final enumerated = _backend.enumerate();
    final currentIndices = <int>{};

    for (final info in enumerated) {
      currentIndices.add(info.index);

      if (!_gamepads.containsKey(info.index)) {
        final pad = Gamepad(index: info.index, name: info.name);
        _gamepads[info.index] = pad;
        _connectionController.add(GamepadConnected(pad));
      }

      _gamepads[info.index]!.state = _backend.poll(info.index);
    }

    // Detect disconnections.
    final disconnected =
        _gamepads.keys.where((i) => !currentIndices.contains(i)).toList();
    for (final index in disconnected) {
      final pad = _gamepads.remove(index)!;
      _connectionController.add(GamepadDisconnected(pad));
    }
  }

  /// Releases platform resources and closes the connection event stream.
  void dispose() {
    _backend.dispose();
    _connectionController.close();
  }
}
