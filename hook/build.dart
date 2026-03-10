import 'package:hooks/hooks.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    // Platform-specific native builds will be added here.
    // Each backend (XInput, evdev, GameController.framework)
    // links to system-provided libraries — no source compilation
    // needed for those targets.
  });
}
