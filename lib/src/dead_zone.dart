import 'dart:math' as math;

/// Dead zone filter for analog stick and trigger axes.
///
/// Clamps values within ±[threshold] to zero and rescales the remaining
/// range to eliminate the discontinuity at the dead zone boundary.
class DeadZone {
  /// Magnitude below which input is treated as zero. Range: 0.0–1.0.
  final double threshold;

  const DeadZone(this.threshold);

  /// Applies an axial dead zone to a single axis value.
  ///
  /// Input range: -1.0 to 1.0 (sticks) or 0.0 to 1.0 (triggers).
  /// Returns 0.0 if the absolute value is within [threshold], otherwise
  /// rescales to fill the remaining range.
  double apply(double raw) {
    if (threshold >= 1.0) return 0.0;

    final magnitude = raw.abs();
    if (magnitude <= threshold) return 0.0;

    final rescaled = (magnitude - threshold) / (1.0 - threshold);
    return raw.sign * rescaled.clamp(0.0, 1.0);
  }

  /// Applies a circular (magnitude-based) dead zone to a stick's X/Y pair.
  ///
  /// Prevents the diagonal bias that per-axis dead zones introduce.
  /// Returns (0.0, 0.0) if the magnitude is within [threshold], otherwise
  /// rescales the magnitude and preserves direction.
  (double, double) applyCircular(double x, double y) {
    if (threshold >= 1.0) return (0.0, 0.0);

    final magnitude = math.sqrt(x * x + y * y);
    if (magnitude <= threshold) return (0.0, 0.0);

    final clampedMag = magnitude.clamp(0.0, 1.0);
    final rescaled = (clampedMag - threshold) / (1.0 - threshold);
    final scale = rescaled / magnitude;

    return (x * scale, y * scale);
  }
}
