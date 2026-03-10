import 'dart:math' as math;

import 'package:gamepad/gamepad.dart';
import 'package:test/test.dart';

void main() {
  group('DeadZone', () {
    group('apply (axial)', () {
      final dz = DeadZone(0.2);

      test('zero input returns zero', () {
        expect(dz.apply(0.0), 0.0);
      });

      test('value at threshold returns zero', () {
        expect(dz.apply(0.2), 0.0);
        expect(dz.apply(-0.2), 0.0);
      });

      test('value just beyond threshold is near zero', () {
        final result = dz.apply(0.21);
        expect(result, greaterThan(0.0));
        expect(result, lessThan(0.05));
      });

      test('maximum input returns 1.0', () {
        expect(dz.apply(1.0), 1.0);
      });

      test('minimum input returns -1.0', () {
        expect(dz.apply(-1.0), -1.0);
      });

      test('positive value rescaled correctly', () {
        // With threshold 0.2, midpoint raw = 0.6 → (0.6 - 0.2) / (1.0 - 0.2) = 0.5
        expect(dz.apply(0.6), closeTo(0.5, 1e-10));
      });

      test('negative value rescaled correctly', () {
        expect(dz.apply(-0.6), closeTo(-0.5, 1e-10));
      });

      test('value within dead zone returns zero', () {
        expect(dz.apply(0.1), 0.0);
        expect(dz.apply(-0.15), 0.0);
      });
    });

    group('applyCircular', () {
      final dz = DeadZone(0.2);

      test('origin returns (0, 0)', () {
        final (x, y) = dz.applyCircular(0.0, 0.0);
        expect(x, 0.0);
        expect(y, 0.0);
      });

      test('magnitude at threshold returns (0, 0)', () {
        // Point on threshold circle: (0.2, 0.0)
        final (x, y) = dz.applyCircular(0.2, 0.0);
        expect(x, 0.0);
        expect(y, 0.0);
      });

      test('full deflection on axis returns unit', () {
        final (x, y) = dz.applyCircular(1.0, 0.0);
        expect(x, closeTo(1.0, 1e-10));
        expect(y, closeTo(0.0, 1e-10));
      });

      test('full deflection negative', () {
        final (x, y) = dz.applyCircular(0.0, -1.0);
        expect(x, closeTo(0.0, 1e-10));
        expect(y, closeTo(-1.0, 1e-10));
      });

      test('diagonal preserves direction', () {
        final raw = 0.8;
        final (x, y) = dz.applyCircular(raw, raw);
        // Both components should be positive and equal.
        expect(x, greaterThan(0.0));
        expect(y, greaterThan(0.0));
        expect(x, closeTo(y, 1e-10));
      });

      test('inside dead zone circle returns (0, 0)', () {
        // Magnitude of (0.1, 0.1) ≈ 0.141, below 0.2 threshold.
        final (x, y) = dz.applyCircular(0.1, 0.1);
        expect(x, 0.0);
        expect(y, 0.0);
      });

      test('rescales magnitude to eliminate discontinuity', () {
        // Point just beyond threshold on x-axis.
        final (x, _) = dz.applyCircular(0.6, 0.0);
        // (0.6 - 0.2) / (1.0 - 0.2) = 0.5
        expect(x, closeTo(0.5, 1e-10));
      });

      test('clamps output magnitude to 1.0', () {
        // Input beyond unit circle.
        final (x, y) = dz.applyCircular(1.0, 1.0);
        final mag = math.sqrt(x * x + y * y);
        expect(mag, closeTo(1.0, 1e-10));
      });
    });

    group('edge cases', () {
      test('zero threshold passes through', () {
        final dz = DeadZone(0.0);
        expect(dz.apply(0.5), closeTo(0.5, 1e-10));
        expect(dz.apply(0.0), 0.0);
      });

      test('threshold of 1.0 always returns zero', () {
        final dz = DeadZone(1.0);
        expect(dz.apply(0.5), 0.0);
        expect(dz.apply(1.0), 0.0);
      });
    });
  });
}
