import 'dart:async';

import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

/// Fake backend that simulates device connect/disconnect.
class FakeBackend implements GamepadBackend {
  List<RawGamepadInfo> devices = [];
  Map<int, GamepadState> states = {};
  bool disposed = false;

  @override
  List<RawGamepadInfo> enumerate() => List.unmodifiable(devices);

  @override
  GamepadState poll(int index) => states[index] ?? GamepadState();

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  group('GamepadManager', () {
    late FakeBackend backend;
    late GamepadManager manager;

    setUp(() {
      backend = FakeBackend();
      manager = GamepadManager(backend: backend);
    });

    tearDown(() {
      manager.dispose();
    });

    test('gamepads is empty initially', () {
      expect(manager.gamepads, isEmpty);
    });

    test('poll detects newly connected gamepad', () async {
      backend.devices = [RawGamepadInfo(index: 0, name: 'Pad A')];

      final events = <GamepadConnectionEvent>[];
      manager.connectionEvents.listen(events.add);

      manager.poll();
      // Allow stream event to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(manager.gamepads, hasLength(1));
      expect(manager.gamepads[0]!.name, 'Pad A');
      expect(events, hasLength(1));
      expect(events[0], isA<GamepadConnected>());
    });

    test('poll detects disconnected gamepad', () async {
      backend.devices = [RawGamepadInfo(index: 0, name: 'Pad A')];
      manager.poll();
      await Future<void>.delayed(Duration.zero);

      // Disconnect.
      backend.devices = [];
      final events = <GamepadConnectionEvent>[];
      manager.connectionEvents.listen(events.add);

      manager.poll();
      await Future<void>.delayed(Duration.zero);

      expect(manager.gamepads, isEmpty);
      expect(events, hasLength(1));
      expect(events[0], isA<GamepadDisconnected>());
    });

    test('poll updates gamepad state', () {
      backend.devices = [RawGamepadInfo(index: 0, name: 'Pad A')];
      backend.states = {
        0: GamepadState(
          axes: {GamepadAxis.leftStickX: 0.5},
          pressed: {GamepadButton.a},
        ),
      };
      manager.poll();
      final pad = manager.gamepads[0]!;
      expect(pad.state.axes[GamepadAxis.leftStickX], 0.5);
      expect(pad.state.pressed, contains(GamepadButton.a));
    });

    test('poll updates state on subsequent calls', () {
      backend.devices = [RawGamepadInfo(index: 0, name: 'Pad A')];
      backend.states = {
        0: GamepadState(pressed: {GamepadButton.a}),
      };
      manager.poll();

      backend.states = {
        0: GamepadState(pressed: {GamepadButton.b}),
      };
      manager.poll();

      final pad = manager.gamepads[0]!;
      expect(pad.state.pressed, contains(GamepadButton.b));
      expect(pad.state.pressed, isNot(contains(GamepadButton.a)));
    });

    test('dispose cleans up backend and closes stream', () async {
      manager.dispose();
      expect(backend.disposed, isTrue);

      // Stream should be done.
      final done = Completer<void>();
      manager.connectionEvents.listen(
        null,
        onDone: done.complete,
      );
      await done.future;
    });

    test('multiple gamepads tracked simultaneously', () async {
      backend.devices = [
        RawGamepadInfo(index: 0, name: 'Pad A'),
        RawGamepadInfo(index: 1, name: 'Pad B'),
      ];
      manager.poll();
      await Future<void>.delayed(Duration.zero);

      expect(manager.gamepads, hasLength(2));
      expect(manager.gamepads[0]!.name, 'Pad A');
      expect(manager.gamepads[1]!.name, 'Pad B');
    });
  });
}
