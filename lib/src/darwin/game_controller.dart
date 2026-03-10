/// GameController.framework bindings via ObjC runtime FFI.
///
/// Provides two entry points:
/// - [gcEnumerateControllers] — lists connected GCControllers.
/// - [gcReadState] — reads GCExtendedGamepad inputs into [GamepadState].
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../axis.dart';
import '../button.dart';
import '../state.dart';
import 'objc.dart';

// ---------------------------------------------------------------------------
// Framework loading
// ---------------------------------------------------------------------------

/// Loads GameController.framework so its classes are registered with the
/// ObjC runtime. Called once; subsequent calls are no-ops (dyld caches).
void ensureFrameworkLoaded() {
  if (_frameworkLoaded) return;
  DynamicLibrary.open(
    '/System/Library/Frameworks/GameController.framework/GameController',
  );
  _frameworkLoaded = true;
}

bool _frameworkLoaded = false;

// ---------------------------------------------------------------------------
// Cached selectors
// ---------------------------------------------------------------------------

// GCController / NSArray
final _selControllers = sel('controllers');
final _selCount = sel('count');
final _selObjectAtIndex = sel('objectAtIndex:');

// Controller identity
final _selVendorName = sel('vendorName');
final _selUtf8String = sel('UTF8String');

// Gamepad profile
final _selExtendedGamepad = sel('extendedGamepad');

// Buttons
final _selButtonA = sel('buttonA');
final _selButtonB = sel('buttonB');
final _selButtonX = sel('buttonX');
final _selButtonY = sel('buttonY');
final _selLeftShoulder = sel('leftShoulder');
final _selRightShoulder = sel('rightShoulder');
final _selLeftTrigger = sel('leftTrigger');
final _selRightTrigger = sel('rightTrigger');
final _selLeftThumbstickButton = sel('leftThumbstickButton');
final _selRightThumbstickButton = sel('rightThumbstickButton');
final _selButtonMenu = sel('buttonMenu');
final _selButtonOptions = sel('buttonOptions');
final _selButtonHome = sel('buttonHome');

// Sticks & d-pad
final _selLeftThumbstick = sel('leftThumbstick');
final _selRightThumbstick = sel('rightThumbstick');
final _selDpad = sel('dpad');

// Axis / direction
final _selXAxis = sel('xAxis');
final _selYAxis = sel('yAxis');
final _selUp = sel('up');
final _selDown = sel('down');
final _selLeft = sel('left');
final _selRight = sel('right');

// Value / pressed
final _selValue = sel('value');
final _selIsPressed = sel('isPressed');

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Info about a connected GCController, including its native pointer.
typedef GCControllerInfo = ({Pointer<Void> ptr, String name, int index});

/// Queries `[GCController controllers]` and returns info for each.
///
/// Caller must wrap in an autorelease pool.
List<GCControllerInfo> gcEnumerateControllers() {
  ensureFrameworkLoaded();

  final gcControllerClass = cls('GCController');
  final array = msgSendPtr(gcControllerClass, _selControllers);
  if (array == nullptr) return const [];

  final count = msgSendInt(array, _selCount);
  final results = <GCControllerInfo>[];

  for (var i = 0; i < count; i++) {
    final controller = msgSendPtrInt(array, _selObjectAtIndex, i);
    if (controller == nullptr) continue;

    final name = _readVendorName(controller);
    results.add((ptr: controller, name: name, index: i));
  }

  return results;
}

/// Reads the current input state from a GCController's extendedGamepad.
///
/// Returns a default (zeroed) [GamepadState] if the controller lacks
/// an extended gamepad profile. Caller must wrap in an autorelease pool.
GamepadState gcReadState(Pointer<Void> controller) {
  final gamepad = msgSendPtr(controller, _selExtendedGamepad);
  if (gamepad == nullptr) return GamepadState();

  return GamepadState(
    axes: _readAxes(gamepad),
    pressed: _readButtons(gamepad),
  );
}

// ---------------------------------------------------------------------------
// Internals
// ---------------------------------------------------------------------------

String _readVendorName(Pointer<Void> controller) {
  final nsString = msgSendPtr(controller, _selVendorName);
  if (nsString == nullptr) return 'Unknown Controller';
  final utf8 = msgSendUtf8(nsString, _selUtf8String);
  if (utf8 == nullptr) return 'Unknown Controller';
  return utf8.toDartString();
}

Map<GamepadAxis, double> _readAxes(Pointer<Void> gamepad) {
  final leftStick = msgSendPtr(gamepad, _selLeftThumbstick);
  final rightStick = msgSendPtr(gamepad, _selRightThumbstick);
  final leftTrig = msgSendPtr(gamepad, _selLeftTrigger);
  final rightTrig = msgSendPtr(gamepad, _selRightTrigger);

  return {
    GamepadAxis.leftStickX: _axisValue(leftStick, _selXAxis),
    GamepadAxis.leftStickY: _axisValue(leftStick, _selYAxis),
    GamepadAxis.rightStickX: _axisValue(rightStick, _selXAxis),
    GamepadAxis.rightStickY: _axisValue(rightStick, _selYAxis),
    GamepadAxis.leftTrigger: _axisValue(leftTrig, null),
    GamepadAxis.rightTrigger: _axisValue(rightTrig, null),
  };
}

/// Reads axis value. If [axisSel] is null, reads `value` directly from
/// [element] (for triggers, which are GCControllerButtonInput, not
/// GCControllerDirectionPad).
double _axisValue(Pointer<Void> element, Pointer<Void>? axisSel) {
  if (element == nullptr) return 0.0;
  if (axisSel != null) {
    final axis = msgSendPtr(element, axisSel);
    if (axis == nullptr) return 0.0;
    return msgSendFloat(axis, _selValue);
  }
  return msgSendFloat(element, _selValue);
}

Set<GamepadButton> _readButtons(Pointer<Void> gamepad) {
  final pressed = <GamepadButton>{};

  void check(Pointer<Void> sel, GamepadButton button) {
    final btn = msgSendPtr(gamepad, sel);
    if (btn != nullptr && msgSendBool(btn, _selIsPressed)) {
      pressed.add(button);
    }
  }

  check(_selButtonA, GamepadButton.a);
  check(_selButtonB, GamepadButton.b);
  check(_selButtonX, GamepadButton.x);
  check(_selButtonY, GamepadButton.y);
  check(_selLeftShoulder, GamepadButton.leftBumper);
  check(_selRightShoulder, GamepadButton.rightBumper);
  check(_selButtonMenu, GamepadButton.start);

  // Nullable properties — check pointer before reading.
  _checkNullable(gamepad, _selLeftThumbstickButton, GamepadButton.leftStick,
      pressed);
  _checkNullable(gamepad, _selRightThumbstickButton, GamepadButton.rightStick,
      pressed);
  _checkNullable(gamepad, _selButtonOptions, GamepadButton.select, pressed);
  _checkNullable(gamepad, _selButtonHome, GamepadButton.guide, pressed);

  // D-pad directions
  final dpad = msgSendPtr(gamepad, _selDpad);
  if (dpad != nullptr) {
    void checkDir(Pointer<Void> dirSel, GamepadButton button) {
      final dir = msgSendPtr(dpad, dirSel);
      if (dir != nullptr && msgSendBool(dir, _selIsPressed)) {
        pressed.add(button);
      }
    }

    checkDir(_selUp, GamepadButton.dpadUp);
    checkDir(_selDown, GamepadButton.dpadDown);
    checkDir(_selLeft, GamepadButton.dpadLeft);
    checkDir(_selRight, GamepadButton.dpadRight);
  }

  return pressed;
}

void _checkNullable(Pointer<Void> gamepad, Pointer<Void> sel,
    GamepadButton button, Set<GamepadButton> pressed) {
  final btn = msgSendPtr(gamepad, sel);
  if (btn != nullptr && msgSendBool(btn, _selIsPressed)) {
    pressed.add(button);
  }
}
