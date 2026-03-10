@TestOn('mac-os')
library;

import 'package:gamepad/gamepad.dart';
import 'package:gamepad/src/darwin/darwin_backend.dart';
import 'package:test/test.dart';

void main() {
  group('DarwinBackend', () {
    late DarwinBackend backend;

    setUp(() {
      backend = DarwinBackend();
    });

    tearDown(() {
      backend.dispose();
    });

    test('construction succeeds (framework loads)', () {
      expect(backend, isA<GamepadBackend>());
    });

    test('enumerate returns a list', () {
      final devices = backend.enumerate();
      expect(devices, isA<List<RawGamepadInfo>>());
    });

    test('poll returns default state for invalid index', () {
      final state = backend.poll(999);
      expect(state, equals(GamepadState()));
    });

    test('dispose does not throw', () {
      expect(backend.dispose, returnsNormally);
    });

    test('enumerate then poll round-trips without error', () {
      final devices = backend.enumerate();
      for (final device in devices) {
        final state = backend.poll(device.index);
        expect(state, isA<GamepadState>());
      }
    });
  });
}
