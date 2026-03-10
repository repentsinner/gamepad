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

Status: complete

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

Status: complete

The input model maps all modern standard gamepads onto a single
canonical layout. Platform-specific identifiers are translated at
the FFI boundary. Consumer code never sees platform strings.

`GamepadAxis` (6 values): two stick X/Y pairs (-1.0–1.0) and two
triggers (0.0–1.0). `GamepadButton` (15 values): a/b/x/y, bumpers,
sticks, d-pad, start/select/guide. All digital.

`GamepadState` is an immutable value type carrying `axes` (Map) and
`pressed` (Set), with equality semantics.

**Why Xbox layout convention:** de facto standard across SDL
GameControllerDB, XInput, and W3C Gamepad API. Nintendo's swapped
A/B labeling is a label difference, not positional — the package
maps by physical position.

### 3.4 Platform Mapping

Each backend translates platform identifiers to canonical enums.
Full mapping table maintained in source, not spec.

## 4. Multi-Controller Support

Status: complete

`GamepadManager` is the entry point. It takes a `GamepadBackend`
via constructor injection, enumerates controllers, tracks hotplug
via a `connectionEvents` broadcast stream, and polls state.

`Gamepad` holds a platform-assigned `index` (stable per connection)
and OS-reported `name`. `GamepadState` is updated on each `poll()`.

`GamepadConnectionEvent` is a sealed class with `GamepadConnected`
and `GamepadDisconnected` subtypes.

**Why polling over events:** CNC jog loops and game update loops
want "current state now" semantics. XInput is inherently polling;
evdev is event-based. Polling normalizes both. Connection events
remain event-driven — connect/disconnect is asynchronous and
infrequent.

## 5. Dead Zones

Status: complete

`DeadZone` is a pure utility — it does not modify `GamepadState`.
Consumers compose it into their input pipeline.

`apply` performs axial dead zone with rescaling to eliminate the
boundary discontinuity. `applyCircular` applies magnitude-based
dead zone to an X/Y stick pair, preventing diagonal bias.

**Why user-space:** No platform API applies dead zones. All deliver
raw normalized values. **Why circular:** Per-axis dead zones create
a diamond-shaped dead zone that biases diagonals. Microsoft's
XInput docs recommend circular. Typical thresholds: 15–25% sticks,
10–15% triggers.

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
