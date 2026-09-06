/// macOS/iOS [GamepadBackend] implementation using IOKit HID.
///
/// Uses IOKit HID Manager to discover and read gamepad-class devices.
/// Works in CLI apps without an app bundle or Info.plist.
library;

import 'dart:ffi';

import '../backend.dart';
import '../raw_gamepad_info.dart';
import '../state.dart';
import 'iokit_gamepad.dart';
import 'objc.dart';

/// IOKit HID backend for macOS and iOS.
///
/// Creates an IOHIDManager on construction. Polls connected devices
/// on each [enumerate] call and caches device pointers for [poll].
class DarwinBackend implements GamepadBackend {
  final Pointer<Void> _manager;
  final Map<int, Pointer<Void>> _devices = {};

  DarwinBackend() : _manager = createHIDManager();

  @override
  List<RawGamepadInfo> enumerate() {
    // Tick the run loop so IOKit processes connect/disconnect events.
    cfRunLoopRunInMode(kCFRunLoopDefaultMode, 0.001, false);

    final devices = hidEnumerateDevices(_manager);
    _devices.clear();

    final results = <RawGamepadInfo>[];
    for (final d in devices) {
      _devices[d.index] = d.device;
      results.add(RawGamepadInfo(index: d.index, name: d.name));
    }
    return results;
  }

  @override
  GamepadState poll(int index) {
    final device = _devices[index];
    if (device == null) return GamepadState();
    return hidReadState(device);
  }

  @override
  void dispose() {
    _devices.clear();
    closeHIDManager(_manager);
  }
}
