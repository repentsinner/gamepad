import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

/// Fake backend for testing the interface contract.
class FakeBackend implements GamepadBackend {
  final List<RawGamepadInfo> _devices;
  final Map<int, GamepadState> _states;
  bool disposed = false;

  FakeBackend({
    List<RawGamepadInfo> devices = const [],
    Map<int, GamepadState>? states,
  })  : _devices = devices,
        _states = states ?? {};

  @override
  List<RawGamepadInfo> enumerate() => List.unmodifiable(_devices);

  @override
  GamepadState poll(int index) => _states[index] ?? GamepadState();

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  group('GamepadBackend contract', () {
    test('enumerate returns empty list when no devices', () {
      final backend = FakeBackend();
      expect(backend.enumerate(), isEmpty);
    });

    test('enumerate returns connected devices', () {
      final backend = FakeBackend(devices: [
        RawGamepadInfo(index: 0, name: 'Controller A'),
        RawGamepadInfo(index: 1, name: 'Controller B'),
      ]);
      final devices = backend.enumerate();
      expect(devices, hasLength(2));
      expect(devices[0].name, 'Controller A');
      expect(devices[1].index, 1);
    });

    test('poll returns state for a given index', () {
      final state = GamepadState(
        axes: {GamepadAxis.leftStickX: 0.75},
        pressed: {GamepadButton.a},
      );
      final backend = FakeBackend(states: {0: state});
      expect(backend.poll(0), equals(state));
    });

    test('poll returns default state for unknown index', () {
      final backend = FakeBackend();
      final state = backend.poll(99);
      expect(state.pressed, isEmpty);
      expect(state.axes[GamepadAxis.leftStickX], 0.0);
    });

    test('dispose marks backend as disposed', () {
      final backend = FakeBackend();
      expect(backend.disposed, isFalse);
      backend.dispose();
      expect(backend.disposed, isTrue);
    });
  });

  group('RawGamepadInfo', () {
    test('equality based on index and name', () {
      const a = RawGamepadInfo(index: 0, name: 'Pad');
      const b = RawGamepadInfo(index: 0, name: 'Pad');
      const c = RawGamepadInfo(index: 1, name: 'Pad');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
