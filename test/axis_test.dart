import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

void main() {
  group('GamepadAxis', () {
    test('has exactly 6 values', () {
      expect(GamepadAxis.values, hasLength(6));
    });

    test('contains all expected axis identifiers', () {
      expect(GamepadAxis.values, containsAll([
        GamepadAxis.leftStickX,
        GamepadAxis.leftStickY,
        GamepadAxis.rightStickX,
        GamepadAxis.rightStickY,
        GamepadAxis.leftTrigger,
        GamepadAxis.rightTrigger,
      ]));
    });
  });
}
