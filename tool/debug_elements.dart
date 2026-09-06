/// Dumps all HID elements and their current values for the first gamepad.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:gamepad/src/darwin/objc.dart';

void main() {
  final manager = ioHIDManagerCreate(nullptr, 0);

  // Match gamepad devices
  final matchArray = calloc<Pointer<Void>>(3);
  matchArray[0] = _createMatchDict(0x01, 0x04); // Joystick
  matchArray[1] = _createMatchDict(0x01, 0x05); // Gamepad
  matchArray[2] = _createMatchDict(0x01, 0x08); // Multi-axis
  final cfArray = cfArrayCreate(nullptr, matchArray, 3, kCFTypeArrayCallBacks);
  ioHIDManagerSetDeviceMatchingMultiple(manager, cfArray);

  ioHIDManagerScheduleWithRunLoop(
      manager, cfRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  ioHIDManagerOpen(manager, 0);
  cfRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);

  final deviceSet = ioHIDManagerCopyDevices(manager);
  if (deviceSet == nullptr) {
    print('No devices found.');
    exit(1);
  }

  final count = cfSetGetCount(deviceSet);
  print('Found $count device(s).\n');

  final values = calloc<Pointer<Void>>(count);
  cfSetGetValues(deviceSet, values);

  for (var d = 0; d < count; d++) {
    final device = values[d];
    final productKey = createCFString('Product');
    final prop = ioHIDDeviceGetProperty(device, productKey);
    final name = cfStringToDart(prop) ?? 'Unknown';
    cfRelease(productKey);
    print('=== Device $d: $name ===\n');

    // Dump all elements
    final elements = ioHIDDeviceCopyMatchingElements(device, nullptr, 0);
    if (elements == nullptr) {
      print('  No elements.\n');
      continue;
    }

    final elemCount = cfArrayGetCount(elements);
    print('  $elemCount elements total.\n');

    print('  Press some buttons / move sticks now...');
    // Tick the run loop to process HID input reports.
    for (var t = 0; t < 20; t++) {
      cfRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }
    print('  Reading values:\n');

    final pValue = calloc<Pointer<Void>>();

    for (var i = 0; i < elemCount; i++) {
      final element = cfArrayGetValueAtIndex(elements, i);
      final type = ioHIDElementGetType(element);
      final usagePage = ioHIDElementGetUsagePage(element);
      final usage = ioHIDElementGetUsage(element);
      final logMin = ioHIDElementGetLogicalMin(element);
      final logMax = ioHIDElementGetLogicalMax(element);

      // Only input elements
      if (type < 1 || type > 3) continue;

      final result = ioHIDDeviceGetValue(device, element, pValue);
      if (result != 0) continue;
      final raw = ioHIDValueGetIntegerValue(pValue.value);

      final typeName = switch (type) {
        1 => 'Misc',
        2 => 'Button',
        3 => 'Axis',
        _ => 'Type$type',
      };

      final pageName = switch (usagePage) {
        0x01 => 'GenDesktop',
        0x09 => 'Button',
        _ => 'Page(0x${usagePage.toRadixString(16)})',
      };

      final usageName = switch ((usagePage, usage)) {
        (0x01, 0x30) => 'X',
        (0x01, 0x31) => 'Y',
        (0x01, 0x32) => 'Z',
        (0x01, 0x33) => 'Rx',
        (0x01, 0x34) => 'Ry',
        (0x01, 0x35) => 'Rz',
        (0x01, 0x39) => 'Hat',
        (0x09, _) => 'Btn$usage',
        _ => '0x${usage.toRadixString(16)}',
      };

      print('  [$typeName] $pageName/$usageName '
          'raw=$raw min=$logMin max=$logMax');
    }

    calloc.free(pValue);
    cfRelease(elements);
    print('');
  }

  calloc.free(values);
  cfRelease(deviceSet);
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
