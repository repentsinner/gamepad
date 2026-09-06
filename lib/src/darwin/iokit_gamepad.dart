/// IOKit HID gamepad reading — maps HID elements to [GamepadState].
///
/// Provides two entry points:
/// - [hidEnumerateDevices] — lists connected gamepad-class HID devices.
/// - [hidReadState] — reads current input from a device into [GamepadState].
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../axis.dart';
import '../button.dart';
import '../state.dart';
import 'objc.dart';

// ---------------------------------------------------------------------------
// Device info
// ---------------------------------------------------------------------------

/// Info about a connected HID gamepad device.
typedef HIDDeviceInfo = ({Pointer<Void> device, String name, int index});

/// Cached product-name CFString key, created once.
final Pointer<Void> _kProductKey = createCFString('Product');

/// Returns the product name for an IOHIDDevice, or a fallback string.
String _deviceName(Pointer<Void> device) {
  final prop = ioHIDDeviceGetProperty(device, _kProductKey);
  return cfStringToDart(prop) ?? 'Unknown Controller';
}

// ---------------------------------------------------------------------------
// Device enumeration
// ---------------------------------------------------------------------------

/// Queries the HID manager for all connected gamepad-class devices.
///
/// [manager] must be a valid, open IOHIDManagerRef.
List<HIDDeviceInfo> hidEnumerateDevices(Pointer<Void> manager) {
  final deviceSet = ioHIDManagerCopyDevices(manager);
  if (deviceSet == nullptr) return const [];

  final count = cfSetGetCount(deviceSet);
  if (count == 0) {
    cfRelease(deviceSet);
    return const [];
  }

  final values = calloc<Pointer<Void>>(count);
  cfSetGetValues(deviceSet, values);

  final results = <HIDDeviceInfo>[];
  for (var i = 0; i < count; i++) {
    final device = values[i];
    results.add((device: device, name: _deviceName(device), index: i));
  }

  calloc.free(values);
  cfRelease(deviceSet);
  return results;
}

// ---------------------------------------------------------------------------
// State reading
// ---------------------------------------------------------------------------

/// Reads the current input state from an IOHIDDevice.
///
/// Enumerates all HID elements, reads their current values, and maps
/// them to the canonical [GamepadAxis] / [GamepadButton] model.
GamepadState hidReadState(Pointer<Void> device) {
  final elements = ioHIDDeviceCopyMatchingElements(device, nullptr, 0);
  if (elements == nullptr) return GamepadState();

  final count = cfArrayGetCount(elements);
  final axes = <GamepadAxis, double>{};
  final pressed = <GamepadButton>{};
  final pValue = calloc<Pointer<Void>>();

  for (var i = 0; i < count; i++) {
    final element = cfArrayGetValueAtIndex(elements, i);
    final type = ioHIDElementGetType(element);

    // Only process input elements.
    if (type != kIOHIDElementTypeInputMisc &&
        type != kIOHIDElementTypeInputButton &&
        type != kIOHIDElementTypeInputAxis) {
      continue;
    }

    final usagePage = ioHIDElementGetUsagePage(element);
    final usage = ioHIDElementGetUsage(element);

    // Read current value.
    final result = ioHIDDeviceGetValue(device, element, pValue);
    if (result != 0) continue; // kIOReturnSuccess = 0
    final raw = ioHIDValueGetIntegerValue(pValue.value);

    if (usagePage == kHIDUsagePageGenericDesktop) {
      _processDesktopElement(element, usage, raw, axes, pressed);
    } else if (usagePage == kHIDUsagePageButton) {
      _processButtonElement(usage, raw, pressed);
    }
  }

  calloc.free(pValue);
  cfRelease(elements);

  return GamepadState(axes: axes, pressed: pressed);
}

// ---------------------------------------------------------------------------
// Generic Desktop element processing
// ---------------------------------------------------------------------------

void _processDesktopElement(
  Pointer<Void> element,
  int usage,
  int raw,
  Map<GamepadAxis, double> axes,
  Set<GamepadButton> pressed,
) {
  switch (usage) {
    case kHIDUsageX:
      axes[GamepadAxis.leftStickX] = _normalizeAxis(element, raw);
    case kHIDUsageY:
      axes[GamepadAxis.leftStickY] = -_normalizeAxis(element, raw);
    case kHIDUsageZ:
      axes[GamepadAxis.rightStickX] = _normalizeAxis(element, raw);
    case kHIDUsageRx:
      // Some controllers use Rx/Ry for right stick instead of Z/Rz.
      axes.putIfAbsent(
          GamepadAxis.rightStickX, () => _normalizeAxis(element, raw));
    case kHIDUsageRy:
      axes.putIfAbsent(
          GamepadAxis.rightStickY, () => -_normalizeAxis(element, raw));
    case kHIDUsageRz:
      axes[GamepadAxis.rightStickY] = -_normalizeAxis(element, raw);
    case kHIDUsageHatSwitch:
      _processHatSwitch(element, raw, pressed);
  }
}

/// Normalizes a raw HID value to -1.0..1.0 using logical min/max.
double _normalizeAxis(Pointer<Void> element, int raw) {
  final min = ioHIDElementGetLogicalMin(element);
  final max = ioHIDElementGetLogicalMax(element);
  if (max == min) return 0.0;
  return (2.0 * (raw - min) / (max - min)) - 1.0;
}

/// Maps hat switch value to d-pad buttons.
///
/// Standard HID hat values (0-7): N, NE, E, SE, S, SW, W, NW.
/// Value at logical max (usually 8 or 15) means centered / released.
void _processHatSwitch(
    Pointer<Void> element, int raw, Set<GamepadButton> pressed) {
  final min = ioHIDElementGetLogicalMin(element);
  final max = ioHIDElementGetLogicalMax(element);

  // Hat value outside 0–7 means centered.
  final hat = raw - min;
  if (hat < 0 || hat > 7 || raw == max && max > 7) return;

  // N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7
  if (hat == 0 || hat == 1 || hat == 7) pressed.add(GamepadButton.dpadUp);
  if (hat >= 1 && hat <= 3) pressed.add(GamepadButton.dpadRight);
  if (hat >= 3 && hat <= 5) pressed.add(GamepadButton.dpadDown);
  if (hat >= 5 && hat <= 7) pressed.add(GamepadButton.dpadLeft);
}

// ---------------------------------------------------------------------------
// Button element processing
//
// HID button usages are 1-based. The mapping below follows the standard
// gamepad layout (Xbox convention). Controller-specific quirks may need
// a per-vendor table in the future.
// ---------------------------------------------------------------------------

/// Standard HID button-to-GamepadButton mapping.
///
/// This covers the common mapping used by most controllers via IOKit HID.
/// Button numbering is 1-based per HID spec.
const _buttonMap = <int, GamepadButton>{
  1: GamepadButton.b, // East (B on Xbox, Circle on PS)
  2: GamepadButton.a, // South (A on Xbox, Cross on PS)
  3: GamepadButton.y, // North (Y on Xbox, Triangle on PS)
  4: GamepadButton.x, // West (X on Xbox, Square on PS)
  5: GamepadButton.leftBumper,
  6: GamepadButton.rightBumper,
  7: GamepadButton.leftStick, // Left trigger as button (some controllers)
  8: GamepadButton.rightStick, // Right trigger as button (some controllers)
  9: GamepadButton.select,
  10: GamepadButton.start,
  11: GamepadButton.guide,
  12: GamepadButton.leftStick, // Alternate: left stick click
  13: GamepadButton.rightStick, // Alternate: right stick click
  14: GamepadButton.guide, // Alternate: home/guide
};

void _processButtonElement(int usage, int raw, Set<GamepadButton> pressed) {
  if (raw == 0) return; // Not pressed.
  final button = _buttonMap[usage];
  if (button != null) pressed.add(button);
}

// ---------------------------------------------------------------------------
// HID Manager setup
// ---------------------------------------------------------------------------

/// Creates and opens an IOHIDManager matching gamepad-class devices.
///
/// Schedules the manager with the current thread's run loop. The caller
/// must call [closeHIDManager] when done.
Pointer<Void> createHIDManager() {
  final manager = ioHIDManagerCreate(nullptr, 0);

  // Match joystick, gamepad, and multi-axis controller usage types.
  final matchArray = calloc<Pointer<Void>>(3);
  matchArray[0] = _createMatchDict(kHIDUsagePageGenericDesktop, kHIDUsageJoystick);
  matchArray[1] = _createMatchDict(kHIDUsagePageGenericDesktop, kHIDUsageGamePad);
  matchArray[2] =
      _createMatchDict(kHIDUsagePageGenericDesktop, kHIDUsageMultiAxisController);

  final cfArray = cfArrayCreate(nullptr, matchArray, 3, kCFTypeArrayCallBacks);
  ioHIDManagerSetDeviceMatchingMultiple(manager, cfArray);

  // Clean up match dicts and array.
  for (var i = 0; i < 3; i++) {
    cfRelease(matchArray[i]);
  }
  calloc.free(matchArray);
  cfRelease(cfArray);

  // Schedule with run loop and open.
  ioHIDManagerScheduleWithRunLoop(
      manager, cfRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  ioHIDManagerOpen(manager, 0);

  // Initial tick to let IOKit discover devices.
  cfRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);

  return manager;
}

/// Closes an IOHIDManager.
void closeHIDManager(Pointer<Void> manager) {
  ioHIDManagerClose(manager, 0);
}

Pointer<Void> _createMatchDict(int usagePage, int usage) {
  final dict = cfDictionaryCreateMutable(
      nullptr, 2, kCFTypeDictionaryKeyCallBacks, kCFTypeDictionaryValueCallBacks);
  final pageKey = createCFString('DeviceUsagePage');
  final usageKey = createCFString('DeviceUsage');
  final cfPage = createCFNumber(usagePage);
  final cfUsage = createCFNumber(usage);

  cfDictionarySetValue(dict, pageKey, cfPage);
  cfDictionarySetValue(dict, usageKey, cfUsage);

  cfRelease(pageKey);
  cfRelease(usageKey);
  cfRelease(cfPage);
  cfRelease(cfUsage);
  return dict;
}
