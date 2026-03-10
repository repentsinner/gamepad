import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

void main() {
  group('GamepadConnectionEvent', () {
    late Gamepad gamepad;

    setUp(() {
      gamepad = Gamepad(index: 0, name: 'Test Pad');
    });

    test('GamepadConnected carries gamepad reference', () {
      final event = GamepadConnected(gamepad);
      expect(event.gamepad, same(gamepad));
    });

    test('GamepadDisconnected carries gamepad reference', () {
      final event = GamepadDisconnected(gamepad);
      expect(event.gamepad, same(gamepad));
    });

    test('sealed hierarchy exhaustive switch', () {
      // Verifies the sealed class can be exhaustively matched.
      GamepadConnectionEvent event = GamepadConnected(gamepad);
      final result = switch (event) {
        GamepadConnected() => 'connected',
        GamepadDisconnected() => 'disconnected',
      };
      expect(result, 'connected');
    });
  });
}
