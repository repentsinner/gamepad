import 'dart:collection';

import 'axis.dart';
import 'button.dart';

/// Immutable snapshot of all gamepad inputs at a point in time.
class GamepadState {
  /// Axis values keyed by [GamepadAxis].
  ///
  /// Stick axes range from -1.0 to 1.0. Trigger axes range from 0.0 to 1.0.
  /// Unspecified axes default to 0.0.
  final Map<GamepadAxis, double> axes;

  /// The set of buttons currently pressed.
  final Set<GamepadButton> pressed;

  /// Creates a [GamepadState].
  ///
  /// Missing axis entries default to 0.0. Both [axes] and [pressed] are
  /// copied into unmodifiable collections.
  GamepadState({
    Map<GamepadAxis, double> axes = const {},
    Set<GamepadButton> pressed = const {},
  })  : axes = UnmodifiableMapView({
          for (final a in GamepadAxis.values) a: axes[a] ?? 0.0,
        }),
        pressed = UnmodifiableSetView(Set.of(pressed));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamepadState &&
          _mapsEqual(axes, other.axes) &&
          _setsEqual(pressed, other.pressed);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(
          axes.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAllUnordered(pressed),
      );

  @override
  String toString() => 'GamepadState(axes: $axes, pressed: $pressed)';

  static bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _setsEqual<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
