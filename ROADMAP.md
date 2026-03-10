# Roadmap

Derived from SPEC.md. Sections are in build-dependency order.

## Platform Backends

Each backend is independent once the interface exists. Ordered by
developer access (macOS first — current dev platform), then by
community reach.

- **backend-macos-ios**: Bind `GameController.framework` via direct
  `dart:ffi` ObjC runtime calls. Implement hotplug via
  `NSNotificationCenter`. Wire `GCExtendedGamepad` to canonical input
  model. No build hook needed — framework loaded at runtime. Covers
  §2.3, §3.4 (GameController column).
- **example-cli**: ANSI terminal example (`example/example.dart`)
  that polls a connected gamepad and mirrors state in a fixed-position
  box (modeled on mpg_pendant's example). Depends on backend-macos-ios.
- **backend-linux**: Read `/dev/input/eventN` via evdev protocol
  (`struct input_event`, `ioctl` capability queries). Implement
  hotplug via `inotify`. Covers §2.2, §2.5, §3.4 (evdev column).
- **backend-windows**: Call `XInputGetState` / `XInputGetCapabilities`
  from `xinput1_4.dll`. Poll four slots for hotplug. Covers §2.1,
  §2.5, §3.4 (XInput column).
- **backend-android**: Generate JNI bindings via jnigen for
  `InputManager`, `MotionEvent`, `KeyEvent`. Implement hotplug via
  `registerInputDeviceListener`. Covers §2.4, §2.5, §3.4 (Android
  column).

## Post-v1

Deferred per spec. Listed for visibility, not scheduled.

- **rumble-haptics**: `RumbleEffect` and per-platform motor control.
  Covers §6. Blocked — deferred until input model and multi-controller
  support are stable (§6 rationale).
- **backend-web**: W3C Gamepad API via `package:web`. Covers §8.
  Blocked — deferred from v1 (§8 rationale).
