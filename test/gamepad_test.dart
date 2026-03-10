import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

void main() {
  group('Gamepad', () {
    test('exposes index and name', () {
      final pad = Gamepad(index: 2, name: 'Xbox Wireless Controller');
      expect(pad.index, 2);
      expect(pad.name, 'Xbox Wireless Controller');
    });

    test('state defaults to zeroed', () {
      final pad = Gamepad(index: 0, name: 'Pad');
      expect(pad.state.pressed, isEmpty);
      expect(pad.state.axes[GamepadAxis.leftStickX], 0.0);
    });
  });
}
