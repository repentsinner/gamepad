import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

void main() {
  group('GamepadState', () {
    test('default factory creates zeroed axes and no pressed buttons', () {
      final state = GamepadState();
      for (final axis in GamepadAxis.values) {
        expect(state.axes[axis], 0.0);
      }
      expect(state.pressed, isEmpty);
    });

    test('stores axis values from constructor', () {
      final state = GamepadState(
        axes: {GamepadAxis.leftStickX: 0.5, GamepadAxis.leftTrigger: 1.0},
        pressed: {},
      );
      expect(state.axes[GamepadAxis.leftStickX], 0.5);
      expect(state.axes[GamepadAxis.leftTrigger], 1.0);
      // Unspecified axes default to 0.0
      expect(state.axes[GamepadAxis.rightStickX], 0.0);
    });

    test('stores pressed buttons from constructor', () {
      final state = GamepadState(
        axes: {},
        pressed: {GamepadButton.a, GamepadButton.start},
      );
      expect(state.pressed, contains(GamepadButton.a));
      expect(state.pressed, contains(GamepadButton.start));
      expect(state.pressed, isNot(contains(GamepadButton.b)));
    });

    test('axes map is unmodifiable', () {
      final state = GamepadState();
      expect(
        () => state.axes[GamepadAxis.leftStickX] = 1.0,
        throwsUnsupportedError,
      );
    });

    test('pressed set is unmodifiable', () {
      final state = GamepadState(
        pressed: {GamepadButton.a},
      );
      expect(
        () => state.pressed.add(GamepadButton.b),
        throwsUnsupportedError,
      );
    });

    test('equality based on axes and pressed', () {
      final a = GamepadState(
        axes: {GamepadAxis.leftStickX: 0.5},
        pressed: {GamepadButton.a},
      );
      final b = GamepadState(
        axes: {GamepadAxis.leftStickX: 0.5},
        pressed: {GamepadButton.a},
      );
      final c = GamepadState(
        axes: {GamepadAxis.leftStickX: 0.7},
        pressed: {GamepadButton.a},
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
