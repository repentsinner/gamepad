/// Minimal data returned by a backend when enumerating connected gamepads.
class RawGamepadInfo {
  /// Platform-assigned device index.
  final int index;

  /// Human-readable device name reported by the OS.
  final String name;

  const RawGamepadInfo({required this.index, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawGamepadInfo && index == other.index && name == other.name;

  @override
  int get hashCode => Object.hash(index, name);

  @override
  String toString() => 'RawGamepadInfo(index: $index, name: $name)';
}
