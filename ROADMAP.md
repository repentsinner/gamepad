# Roadmap

Derived from SPEC.md. Sections are in build-dependency order.

## Project Scaffold & Input Model

Foundation that all subsequent work depends on.

- **scaffold-package**: Create pubspec.yaml (SDK ≥3.10, `dart:ffi` +
  `package:ffi` deps), directory structure (`lib/`, `src/`, `test/`,
  `hook/`), empty `hook/build.dart`, analysis_options.yaml, CI workflow.
  Covers §1.
- **input-model**: Implement `GamepadAxis`, `GamepadButton` enums and
  immutable `GamepadState` value type. Covers §3.1–§3.3.

## Public API & Backend Interface

Defines the consumer-facing API and the internal contract backends
must satisfy. Depends on input-model.

- **public-api**: Implement `GamepadManager`, `Gamepad`,
  `GamepadConnectionEvent` / `GamepadConnected` /
  `GamepadDisconnected`, and the polling entry point. Covers §4.
- **backend-interface**: Define the internal platform backend
  abstraction that each platform implements (enumerate, poll, hotplug).
  Platform selection logic in the manager. Not spec'd externally —
  internal architecture to support §2.

## Platform Backends

Each backend is independent once the interface exists. Ordered by
developer access (macOS first — current dev platform), then by
community reach.

- **backend-macos-ios**: Bind `GameController.framework` via ffigen
  ObjC mode. Implement hotplug via `NSNotificationCenter`. Wire
  `GCExtendedGamepad` to canonical input model. Build hook for
  framework linking. Covers §2.3, §2.5, §3.4 (GameController column).
  Depends on backend-interface.
- **backend-linux**: Read `/dev/input/eventN` via evdev protocol
  (`struct input_event`, `ioctl` capability queries). Implement
  hotplug via `inotify`. Covers §2.2, §2.5, §3.4 (evdev column).
  Depends on backend-interface.
- **backend-windows**: Call `XInputGetState` / `XInputGetCapabilities`
  from `xinput1_4.dll`. Poll four slots for hotplug. Covers §2.1,
  §2.5, §3.4 (XInput column). Depends on backend-interface.
- **backend-android**: Generate JNI bindings via jnigen for
  `InputManager`, `MotionEvent`, `KeyEvent`. Implement hotplug via
  `registerInputDeviceListener`. Covers §2.4, §2.5, §3.4 (Android
  column). Depends on backend-interface.

## Dead Zones

Standalone utility. Depends only on input-model.

- **dead-zone-utility**: Implement `DeadZone` class with per-axis
  `apply` and circular `applyCircular` methods, including rescaling
  to eliminate boundary discontinuity. Covers §5.

## Post-v1

Deferred per spec. Listed for visibility, not scheduled.

- **rumble-haptics**: `RumbleEffect` and per-platform motor control.
  Covers §6. Blocked — deferred until input model and multi-controller
  support are stable (§6 rationale).
- **backend-web**: W3C Gamepad API via `package:web`. Covers §8.
  Blocked — deferred from v1 (§8 rationale).
