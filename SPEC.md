# Gamepad — Pure Dart Gamepad Input

## 0. Problem Statement

Status: complete

No production-ready, pure Dart package exists for cross-platform
gamepad input. The Flame Engine `gamepads` package wraps deprecated
APIs on Windows (WinMM) and Linux (legacy joystick), uses stringly
typed input identifiers, and requires Flutter. Other packages are
abandoned, GPL-licensed, or single-platform.

CNC controllers, games, and robotics projects need a package that:

- Works without Flutter (pure Dart, usable from CLI or any framework).
- Wraps the correct modern platform APIs.
- Provides a type-safe, exhaustive input model identical on all
  platforms.
- Supports multiple simultaneous controllers.
- Ships with zero external dependencies via Dart Native Assets /
  Build Hooks.

## 1. Package Identity

Status: not started

- **Name:** `gamepad` (available on pub.dev).
- **License:** BSD-3-Clause.
- **Minimum Dart SDK:** 3.10 (Native Assets stable).
- **Dependencies:** `dart:ffi`, `package:ffi`. No Flutter dependency.
- **Build:** Build Hooks (`hook/build.dart`) via `package:native_toolchain_c`
  for any platform that requires compiled native code.
- **Platforms:** macOS, iOS, Windows, Linux, Android. Web deferred
  (§8).

## 2. Platform Backends

Status: not started

Each platform uses the OS-provided gamepad API. No third-party
native libraries are bundled or linked.

### 2.1 Windows — XInput

The package calls `XInputGetState` and `XInputGetCapabilities` from
`xinput1_4.dll` (ships with Windows). XInput models exactly four
controller slots (0–3). An empty slot returns
`ERROR_DEVICE_NOT_CONNECTED`.

XInput was chosen over the deprecated WinMM joystick API and over
DirectInput. XInput understands Xbox-style controllers natively,
reports triggers as independent axes, and is the API Microsoft
recommends. DirectInput merges both triggers into a single axis
and lacks vibration support for Xbox controllers.

Hotplug detection: poll all four slots; no callback mechanism
exists in XInput.

### 2.2 Linux — evdev

The package reads `/dev/input/eventN` device files using the evdev
protocol (`struct input_event`, `EV_KEY` for buttons, `EV_ABS` for
axes). Device capabilities are queried via `ioctl` (`EVIOCGBIT`,
`EVIOCGABS`, `EVIOCGNAME`).

evdev was chosen over the legacy joystick API (`/dev/input/jsN`),
which is being phased out and lacks features evdev provides
(capability queries, force feedback, per-axis metadata).

Hotplug detection: `inotify` watch on `/dev/input/` for
`IN_CREATE` / `IN_DELETE` events matching `event*`.

No slot limit — the kernel assigns device nodes dynamically.

### 2.3 macOS / iOS — GameController.framework

The package binds to Apple's `GameController.framework` via
`dart:ffi` Objective-C interop (ffigen in ObjC mode). Key classes:
`GCController`, `GCExtendedGamepad`, `GCControllerButtonInput`,
`GCControllerAxisInput`.

GameController.framework was chosen because Apple recommends it
over IOKit HID for standard gamepads. It handles MFi, Xbox
Wireless, DualShock 4, and DualSense controllers. Bluetooth
pairing and input mapping are managed by the OS.

Hotplug detection: `NSNotificationCenter` observing
`.GCControllerDidConnect` / `.GCControllerDidDisconnect`.

macOS and iOS share the same framework and the same Dart binding
code.

### 2.4 Android — JNI via jnigen

The package binds to `android.hardware.input.InputManager` and
reads `android.view.MotionEvent` / `android.view.KeyEvent` via
`package:jnigen`-generated Dart bindings. This keeps the package
pure Dart (no Flutter plugin, no method channels).

jnigen was chosen over a Flutter platform channel to avoid a
Flutter dependency. It was chosen over NDK `AInputEvent` because
the NDK path requires `ALooper` integration with the native
activity, which adds threading complexity disproportionate to the
API surface.

Hotplug detection: `InputManager.registerInputDeviceListener`.

### 2.5 Build Hooks

Each platform backend compiles or links via `hook/build.dart`.
XInput, evdev, and GameController.framework are system-provided —
no native source compilation is needed for those targets. The
build hook handles platform detection and library resolution.
Android's jnigen output may require build hook integration for
the generated JNI bindings.

## 3. Input Model

Status: not started

The input model maps all modern standard gamepads (Xbox, PlayStation,
Switch Pro, 8BitDo, etc.) onto a single canonical layout. Platform-
specific identifiers are translated at the FFI boundary. Consumer
code never sees platform strings.

### 3.1 Axes

```dart
enum GamepadAxis {
  leftStickX,
  leftStickY,
  rightStickX,
  rightStickY,
  leftTrigger,
  rightTrigger,
}
```

Stick axes range from `-1.0` to `1.0`. Trigger axes range from
`0.0` to `1.0`. Values are raw — no dead zone applied.

Controllers with physically digital triggers (e.g., Nintendo Switch
Pro, 8BitDo SN30 Pro) report `0.0` or `1.0` on the trigger axes.
The API is uniform regardless of hardware capability.

### 3.2 Buttons

```dart
enum GamepadButton {
  a, b, x, y,
  leftBumper, rightBumper,
  leftStick, rightStick,
  dpadUp, dpadDown, dpadLeft, dpadRight,
  start, select, guide,
}
```

All buttons are digital (pressed or not). Pressure-sensitive face
buttons existed on DualShock 2/3 and original Xbox but no
controller manufactured since 2013 ships them. The model does not
include analog button pressure.

### 3.3 State

```dart
class GamepadState {
  final Map<GamepadAxis, double> axes;
  final Set<GamepadButton> pressed;
}
```

`GamepadState` is a snapshot of all inputs at the time of the most
recent `poll()` call. It is an immutable value type.

### 3.4 Platform Mapping

Each backend translates platform-specific identifiers to the
canonical enums:

| Canonical | XInput | evdev | GameController | Android |
|---|---|---|---|---|
| `a` | `XINPUT_GAMEPAD_A` | `BTN_SOUTH` | `buttonA` | `KEYCODE_BUTTON_A` |
| `leftStickX` | `sThumbLX` | `ABS_X` | `leftThumbstick.xAxis` | `AXIS_X` |
| `leftTrigger` | `bLeftTrigger` | `ABS_Z` or `ABS_HAT2Y` | `leftTrigger` | `AXIS_LTRIGGER` |

(Full mapping table maintained in source, not spec.)

The mapping follows the Xbox physical layout convention (bottom
button = A, right = B), which is the de facto standard in SDL's
GameControllerDB, XInput, and the W3C Gamepad API's "standard"
mapping. Nintendo's swapped A/B labeling is a label difference,
not a physical position difference — the package maps by position.

## 4. Multi-Controller Support

Status: not started

### 4.1 GamepadManager

```dart
class GamepadManager {
  Map<int, Gamepad> get gamepads;
  Stream<GamepadConnectionEvent> get connectionEvents;
  void poll();
  void dispose();
}
```

`GamepadManager` is the entry point. It enumerates connected
controllers, tracks hotplug events, and polls state.

### 4.2 Gamepad

```dart
class Gamepad {
  final int index;
  final String name;
  GamepadState get state;
}
```

`index` is an integer assigned by the platform. On XInput, it
maps to slot 0–3. On evdev, it derives from the device node
number. On macOS/iOS, it maps to the `GCControllerPlayerIndex`
ordinal. On Android, it comes from `InputDevice.getId()`.

The index is stable for the lifetime of a connection. If a
controller disconnects and reconnects, it may receive a
different index.

`name` is the human-readable device name reported by the OS
(e.g., "Xbox Wireless Controller", "8BitDo SN30 Pro").

### 4.3 Connection Events

```dart
sealed class GamepadConnectionEvent {
  final Gamepad gamepad;
}
class GamepadConnected extends GamepadConnectionEvent {}
class GamepadDisconnected extends GamepadConnectionEvent {}
```

The `connectionEvents` stream fires on hotplug. Consumers use it
to update UI (player join/leave) or reassign controller bindings.

### 4.4 Polling Model

The package uses a polling model, not an event stream for input
state. Consumers call `manager.poll()` on their frame tick or
control loop, then read `gamepad.state`. This matches CNC jog
loops and game update loops, which both want "current state now"
semantics.

Polling was chosen over event streaming because:

- CNC jogging and game loops read state once per frame. Events
  require buffering and deduplication to reach the same result.
- XInput is inherently polling (no event callback). evdev is
  inherently event-based. Polling normalizes the two.
- Eliminates backpressure concerns on high-frequency analog
  stick movement.

Connection events remain event-driven because connect/disconnect
is inherently asynchronous and infrequent.

## 5. Dead Zones

Status: not started

No platform API applies dead zones. XInput, evdev,
GameController.framework, and the Web Gamepad API all deliver raw
normalized values. Dead zones are a user-space concern.

The package provides a `DeadZone` utility as a convenience:

```dart
class DeadZone {
  final double threshold;
  const DeadZone(this.threshold);
  double apply(double raw);
  (double, double) applyCircular(double x, double y);
}
```

`apply` clamps values within `±threshold` to zero and rescales the
remaining range to `0.0–1.0` (or `-1.0–1.0` for stick axes) to
eliminate the discontinuity at the dead zone boundary.

`applyCircular` applies a magnitude-based dead zone to a stick's
X/Y pair. Circular dead zones prevent diagonal bias that per-axis
dead zones introduce. This is the approach Microsoft recommends in
their XInput documentation.

`DeadZone` is a pure function over values. It does not modify
`GamepadState`. Consumers compose it into their input pipeline.

Typical dead zone thresholds: 15–25% for sticks, 10–15% for
triggers. XInput's suggested constants are ~24% (left stick),
~27% (right stick), ~12% (triggers).

## 6. Rumble / Haptics

Status: not started

The rumble abstraction models dual-motor vibration:

```dart
class RumbleEffect {
  final double strongMagnitude;  // 0.0–1.0, low-frequency motor
  final double weakMagnitude;    // 0.0–1.0, high-frequency motor
  final Duration duration;
}
```

All platforms converge on two motors (strong/weak) with independent
magnitudes. Platform complexity varies:

- **XInput:** One function call (`XInputSetState`), two `u16` fields.
- **evdev:** Upload `FF_RUMBLE` effect via `ioctl`, play via `write`.
  More ceremony but the same two-magnitude model.
- **GameController.framework:** Requires Core Haptics
  (`CHHapticEngine`). The API models rich haptic patterns; the
  package maps the two-motor abstraction onto continuous haptic
  events. This is the most complex backend.
- **Android:** `Vibrator` service or `InputDevice.getVibratorManager()`.

Rumble is not a v1 requirement. The API surface is specified here
for completeness. Implementation is deferred until the input model
and multi-controller support are stable.

## 7. Scope Boundaries

Status: not started

The package provides raw gamepad input and controller lifecycle
management. It does not provide:

- **Input remapping.** Button-to-action mapping is application
  logic. The package delivers canonical button/axis identifiers;
  the consumer decides what they mean.
- **Gyroscope / accelerometer.** DualSense and Switch controllers
  expose motion sensors. The API surface is large and
  controller-specific. Deferred.
- **Touchpad.** DualSense has a touchpad. Niche, deferred.
- **Audio.** Some controllers have headset jacks or microphones.
  Out of scope.
- **LED control.** Xbox and DualSense have programmable LEDs.
  Out of scope for input.
- **Controller database / mapping overrides.** SDL ships a
  community-maintained controller database for devices that don't
  self-identify correctly. The package relies on OS-level mapping
  (which is correct for GameController.framework, XInput, and
  standard evdev). If edge cases arise, a mapping override
  mechanism can be added later.

## 8. Web (Deferred)

Status: not started

The W3C Gamepad API (`navigator.getGamepads()`) provides a
standardized interface across browsers. When `mapping === "standard"`,
the browser normalizes to 17 buttons and 4 axes matching the Xbox
layout — the same canonical layout this package uses.

Dart can access the Web Gamepad API via `package:web`
(`dart:js_interop`). Implementation is straightforward because the
browser handles the cross-platform abstraction.

Web support is deferred from v1. The platform backend architecture
(§2) accommodates it without structural changes.
