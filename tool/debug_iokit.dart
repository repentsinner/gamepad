/// Debug script to test IOKit HID gamepad discovery.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

// IOKit HID types
typedef IOHIDManagerRef = Pointer<Void>;
typedef IOHIDDeviceRef = Pointer<Void>;

void main() {
  final iokit = DynamicLibrary.open(
    '/System/Library/Frameworks/IOKit.framework/IOKit',
  );
  final cf = DynamicLibrary.open(
    '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
  );

  // CFDictionary helpers
  final cfDictionaryCreateMutable = cf.lookupFunction<
      Pointer<Void> Function(Pointer<Void>, IntPtr, Pointer<Void>,
          Pointer<Void>),
      Pointer<Void> Function(Pointer<Void>, int, Pointer<Void>,
          Pointer<Void>)>('CFDictionaryCreateMutable');
  final cfDictionarySetValue = cf.lookupFunction<
      Void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>),
      void Function(
          Pointer<Void>, Pointer<Void>, Pointer<Void>)>('CFDictionarySetValue');
  final cfNumberCreate = cf.lookupFunction<
      Pointer<Void> Function(Pointer<Void>, Int32, Pointer<Void>),
      Pointer<Void> Function(
          Pointer<Void>, int, Pointer<Void>)>('CFNumberCreate');
  final cfArrayCreate = cf.lookupFunction<
      Pointer<Void> Function(
          Pointer<Void>, Pointer<Pointer<Void>>, IntPtr, Pointer<Void>),
      Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>, int,
          Pointer<Void>)>('CFArrayCreate');
  final cfSetGetCount = cf.lookupFunction<IntPtr Function(Pointer<Void>),
      int Function(Pointer<Void>)>('CFSetGetCount');
  final cfSetGetValues = cf.lookupFunction<
      Void Function(Pointer<Void>, Pointer<Pointer<Void>>),
      void Function(
          Pointer<Void>, Pointer<Pointer<Void>>)>('CFSetGetValues');
  final cfRelease = cf.lookupFunction<Void Function(Pointer<Void>),
      void Function(Pointer<Void>)>('CFRelease');

  // CFString for property keys
  final cfStringCreateWithCString = cf.lookupFunction<
      Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>, Uint32),
      Pointer<Void> Function(
          Pointer<Void>, Pointer<Utf8>, int)>('CFStringCreateWithCString');
  final cfStringGetCString = cf.lookupFunction<
      Bool Function(Pointer<Void>, Pointer<Utf8>, IntPtr, Uint32),
      bool Function(
          Pointer<Void>, Pointer<Utf8>, int, int)>('CFStringGetCString');

  // kCFTypeDictionary callbacks
  final kCFTypeDictionaryKeyCallBacks =
      cf.lookup<Void>('kCFTypeDictionaryKeyCallBacks');
  final kCFTypeDictionaryValueCallBacks =
      cf.lookup<Void>('kCFTypeDictionaryValueCallBacks');
  final kCFTypeArrayCallBacks = cf.lookup<Void>('kCFTypeArrayCallBacks');

  // IOKit HID functions
  final ioHIDManagerCreate = iokit.lookupFunction<
      IOHIDManagerRef Function(Pointer<Void>, Uint32),
      IOHIDManagerRef Function(Pointer<Void>, int)>('IOHIDManagerCreate');
  final ioHIDManagerSetDeviceMatchingMultiple = iokit.lookupFunction<
      Void Function(IOHIDManagerRef, Pointer<Void>),
      void Function(
          IOHIDManagerRef, Pointer<Void>)>(
      'IOHIDManagerSetDeviceMatchingMultiple');
  final ioHIDManagerScheduleWithRunLoop = iokit.lookupFunction<
      Void Function(IOHIDManagerRef, Pointer<Void>, Pointer<Void>),
      void Function(IOHIDManagerRef, Pointer<Void>,
          Pointer<Void>)>('IOHIDManagerScheduleWithRunLoop');
  final ioHIDManagerOpen = iokit.lookupFunction<
      Int32 Function(IOHIDManagerRef, Uint32),
      int Function(IOHIDManagerRef, int)>('IOHIDManagerOpen');
  final ioHIDManagerCopyDevices = iokit.lookupFunction<
      Pointer<Void> Function(IOHIDManagerRef),
      Pointer<Void> Function(IOHIDManagerRef)>('IOHIDManagerCopyDevices');

  // IOHIDDevice property
  final ioHIDDeviceGetProperty = iokit.lookupFunction<
      Pointer<Void> Function(IOHIDDeviceRef, Pointer<Void>),
      Pointer<Void> Function(
          IOHIDDeviceRef, Pointer<Void>)>('IOHIDDeviceGetProperty');

  // CFRunLoop
  final cfRunLoopGetCurrent = cf.lookupFunction<Pointer<Void> Function(),
      Pointer<Void> Function()>('CFRunLoopGetCurrent');
  final kCFRunLoopDefaultMode =
      cf.lookup<Pointer<Void>>('kCFRunLoopDefaultMode').value;
  final cfRunLoopRunInMode = cf.lookupFunction<
      Int32 Function(Pointer<Void>, Double, Bool),
      int Function(Pointer<Void>, double, bool)>('CFRunLoopRunInMode');

  // --- Setup ---

  // Create HID manager
  final manager = ioHIDManagerCreate(nullptr, 0);
  print('HID Manager: $manager');

  // Match gamepad-class devices: usage page 0x01 (Generic Desktop),
  // usages 0x04 (Joystick), 0x05 (Gamepad), 0x08 (Multi-axis)
  // kIOHIDDeviceUsagePageKey = "DeviceUsagePage"
  // kIOHIDDeviceUsageKey = "DeviceUsage"
  final usagePageKey =
      cfStringCreateWithCString(nullptr, 'DeviceUsagePage'.toNativeUtf8(), 0x0600);
  final usageKey =
      cfStringCreateWithCString(nullptr, 'DeviceUsage'.toNativeUtf8(), 0x0600);

  // kCFNumberSInt32Type = 3
  Pointer<Void> createMatchDict(int usagePage, int usage) {
    final dict = cfDictionaryCreateMutable(nullptr, 2,
        kCFTypeDictionaryKeyCallBacks, kCFTypeDictionaryValueCallBacks);
    final pageNum = calloc<Int32>()..value = usagePage;
    final usageNum = calloc<Int32>()..value = usage;
    final cfPage = cfNumberCreate(nullptr, 3, pageNum.cast());
    final cfUsage = cfNumberCreate(nullptr, 3, usageNum.cast());
    cfDictionarySetValue(dict, usagePageKey, cfPage);
    cfDictionarySetValue(dict, usageKey, cfUsage);
    cfRelease(cfPage);
    cfRelease(cfUsage);
    calloc.free(pageNum);
    calloc.free(usageNum);
    return dict;
  }

  final joystickDict = createMatchDict(0x01, 0x04);
  final gamepadDict = createMatchDict(0x01, 0x05);
  final multiAxisDict = createMatchDict(0x01, 0x08);

  // Create CFArray of matching dicts
  final matchArray = calloc<Pointer<Void>>(3);
  matchArray[0] = joystickDict;
  matchArray[1] = gamepadDict;
  matchArray[2] = multiAxisDict;
  final cfMatchArray =
      cfArrayCreate(nullptr, matchArray, 3, kCFTypeArrayCallBacks);

  ioHIDManagerSetDeviceMatchingMultiple(manager, cfMatchArray);

  // Schedule with run loop and open
  final runLoop = cfRunLoopGetCurrent();
  ioHIDManagerScheduleWithRunLoop(manager, runLoop, kCFRunLoopDefaultMode);
  final openResult = ioHIDManagerOpen(manager, 0);
  print('IOHIDManagerOpen result: $openResult (0 = success)');

  // Tick run loop to let it discover
  cfRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);

  // Check devices
  final deviceSet = ioHIDManagerCopyDevices(manager);
  if (deviceSet == nullptr) {
    print('No devices found.');
  } else {
    final count = cfSetGetCount(deviceSet);
    print('Found $count device(s).');

    if (count > 0) {
      final values = calloc<Pointer<Void>>(count);
      cfSetGetValues(deviceSet, values);

      final productKey = cfStringCreateWithCString(
          nullptr, 'Product'.toNativeUtf8(), 0x0600);
      for (var i = 0; i < count; i++) {
        final device = values[i];
        final name = ioHIDDeviceGetProperty(device, productKey);
        if (name != nullptr) {
          final buf = calloc<Uint8>(256).cast<Utf8>();
          if (cfStringGetCString(name, buf, 256, 0x0600)) {
            print('  Device $i: ${buf.toDartString()}');
          } else {
            print('  Device $i: (could not read name)');
          }
          calloc.free(buf);
        } else {
          print('  Device $i: (no product name)');
        }
      }
      calloc.free(values);
      cfRelease(productKey);
    }
    cfRelease(deviceSet);
  }

  // Cleanup
  cfRelease(cfMatchArray);
  cfRelease(joystickDict);
  cfRelease(gamepadDict);
  cfRelease(multiAxisDict);
  calloc.free(matchArray);
  cfRelease(usagePageKey);
  cfRelease(usageKey);

  print('Done.');
}
