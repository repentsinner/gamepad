# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- macOS/iOS backend via direct `dart:ffi` calls to the IOKit HID
  Manager (`DarwinBackend`). Not yet verified against a physical
  controller.
- ANSI terminal example (`example/gamepad_example.dart`) polling a
  connected gamepad at ~30 Hz.
