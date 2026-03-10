import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

void main() {
  group('GamepadButton', () {
    test('has exactly 15 values', () {
      expect(GamepadButton.values, hasLength(15));
    });

    test('contains all expected button identifiers', () {
      expect(GamepadButton.values, containsAll([
        GamepadButton.a,
        GamepadButton.b,
        GamepadButton.x,
        GamepadButton.y,
        GamepadButton.leftBumper,
        GamepadButton.rightBumper,
        GamepadButton.leftStick,
        GamepadButton.rightStick,
        GamepadButton.dpadUp,
        GamepadButton.dpadDown,
        GamepadButton.dpadLeft,
        GamepadButton.dpadRight,
        GamepadButton.start,
        GamepadButton.select,
        GamepadButton.guide,
      ]));
    });
  });
}
