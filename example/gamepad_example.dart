/// ANSI terminal gamepad poller.
///
/// Polls a connected gamepad at ~30 Hz and renders its state using ANSI
/// escape codes. Requires macOS with a paired game controller.
///
/// Run: `dart run example/gamepad_example.dart`
library;

import 'dart:async';
import 'dart:io';

import 'package:gamepad/gamepad.dart';
import 'package:gamepad/src/darwin/darwin_backend.dart';

void main() {
  if (!Platform.isMacOS) {
    stderr.writeln('This example requires macOS.');
    exit(1);
  }

  final manager = GamepadManager(backend: DarwinBackend());

  // Clean shutdown on Ctrl-C.
  late StreamSubscription<ProcessSignal> sigint;
  sigint = ProcessSignal.sigint.watch().listen((_) {
    _showCursor();
    manager.dispose();
    sigint.cancel();
    exit(0);
  });

  manager.connectionEvents.listen((event) {
    switch (event) {
      case GamepadConnected(:final gamepad):
        stderr.writeln('Connected: ${gamepad.name} [${gamepad.index}]');
      case GamepadDisconnected(:final gamepad):
        stderr.writeln('Disconnected: ${gamepad.name} [${gamepad.index}]');
    }
  });

  _hideCursor();
  stderr.writeln('Waiting for gamepad... (press Ctrl-C to exit)\n');

  // Poll at ~30 Hz.
  Timer.periodic(const Duration(milliseconds: 33), (_) {
    manager.poll();

    final pads = manager.gamepads;
    if (pads.isEmpty) return;

    // Render first connected gamepad.
    final pad = pads.values.first;
    _render(pad);
  });
}

void _render(Gamepad pad) {
  final buf = StringBuffer();

  // Move cursor to line 3, column 1 (below the "Waiting..." message).
  buf.write('\x1B[3;1H');
  buf.write('\x1B[J'); // Clear from cursor to end of screen.

  buf.writeln('${pad.name} [${pad.index}]');
  buf.writeln();

  // Axes
  final axes = pad.state.axes;
  buf.writeln(
    'L Stick: '
    'X=${axes[GamepadAxis.leftStickX]!.toStringAsFixed(2).padLeft(6)}  '
    'Y=${axes[GamepadAxis.leftStickY]!.toStringAsFixed(2).padLeft(6)}',
  );
  buf.writeln(
    'R Stick: '
    'X=${axes[GamepadAxis.rightStickX]!.toStringAsFixed(2).padLeft(6)}  '
    'Y=${axes[GamepadAxis.rightStickY]!.toStringAsFixed(2).padLeft(6)}',
  );
  buf.writeln(
    'Triggers: '
    'L=${axes[GamepadAxis.leftTrigger]!.toStringAsFixed(2).padLeft(5)}  '
    'R=${axes[GamepadAxis.rightTrigger]!.toStringAsFixed(2).padLeft(5)}',
  );
  buf.writeln();

  // Buttons
  final pressed = pad.state.pressed;
  if (pressed.isEmpty) {
    buf.writeln('Buttons: (none)');
  } else {
    buf.writeln('Buttons: ${pressed.map((b) => b.name).join(', ')}');
  }

  stdout.write(buf);
}

void _hideCursor() => stdout.write('\x1B[?25l');
void _showCursor() => stdout.write('\x1B[?25h');
