/// Low-level IOKit HID and CoreFoundation FFI bindings for dart:ffi.
///
/// Provides typed function pointers for the IOKit HID Manager API and
/// CoreFoundation helpers needed by the macOS/iOS gamepad backend.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Libraries
// ---------------------------------------------------------------------------

final DynamicLibrary _iokitLib =
    DynamicLibrary.open('/System/Library/Frameworks/IOKit.framework/IOKit');

final DynamicLibrary _cfLib = DynamicLibrary.open(
  '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
);

// ---------------------------------------------------------------------------
// CoreFoundation helpers
// ---------------------------------------------------------------------------

/// `CFRunLoopRef CFRunLoopGetCurrent(void)`
final Pointer<Void> Function() cfRunLoopGetCurrent = _cfLib.lookupFunction<
    Pointer<Void> Function(), Pointer<Void> Function()>('CFRunLoopGetCurrent');

/// `SInt32 CFRunLoopRunInMode(CFStringRef mode, CFTimeInterval seconds,
///     Boolean returnAfterSourceHandled)`
final int Function(Pointer<Void>, double, bool) cfRunLoopRunInMode =
    _cfLib.lookupFunction<Int32 Function(Pointer<Void>, Double, Bool),
        int Function(Pointer<Void>, double, bool)>('CFRunLoopRunInMode');

/// `CFStringRef kCFRunLoopDefaultMode`
final Pointer<Void> kCFRunLoopDefaultMode =
    _cfLib.lookup<Pointer<Void>>('kCFRunLoopDefaultMode').value;

/// `CFMutableDictionaryRef CFDictionaryCreateMutable(...)`
final Pointer<Void> Function(
        Pointer<Void>, int, Pointer<Void>, Pointer<Void>)
    cfDictionaryCreateMutable = _cfLib.lookupFunction<
        Pointer<Void> Function(
            Pointer<Void>, IntPtr, Pointer<Void>, Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>, int, Pointer<Void>,
            Pointer<Void>)>('CFDictionaryCreateMutable');

/// `void CFDictionarySetValue(CFMutableDictionaryRef, key, value)`
final void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
    cfDictionarySetValue = _cfLib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<Void>,
            Pointer<Void>)>('CFDictionarySetValue');

/// `CFNumberRef CFNumberCreate(allocator, type, valuePtr)`
final Pointer<Void> Function(Pointer<Void>, int, Pointer<Void>)
    cfNumberCreate = _cfLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int32, Pointer<Void>),
        Pointer<Void> Function(
            Pointer<Void>, int, Pointer<Void>)>('CFNumberCreate');

/// `CFArrayRef CFArrayCreate(allocator, values, count, callbacks)`
final Pointer<Void> Function(
        Pointer<Void>, Pointer<Pointer<Void>>, int, Pointer<Void>)
    cfArrayCreate = _cfLib.lookupFunction<
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Pointer<Void>>, IntPtr, Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>, int,
            Pointer<Void>)>('CFArrayCreate');

/// `CFIndex CFArrayGetCount(CFArrayRef)`
final int Function(Pointer<Void>) cfArrayGetCount = _cfLib.lookupFunction<
    IntPtr Function(Pointer<Void>),
    int Function(Pointer<Void>)>('CFArrayGetCount');

/// `const void* CFArrayGetValueAtIndex(CFArrayRef, CFIndex)`
final Pointer<Void> Function(Pointer<Void>, int) cfArrayGetValueAtIndex =
    _cfLib.lookupFunction<Pointer<Void> Function(Pointer<Void>, IntPtr),
        Pointer<Void> Function(Pointer<Void>, int)>('CFArrayGetValueAtIndex');

/// `CFIndex CFSetGetCount(CFSetRef)`
final int Function(Pointer<Void>) cfSetGetCount = _cfLib.lookupFunction<
    IntPtr Function(Pointer<Void>),
    int Function(Pointer<Void>)>('CFSetGetCount');

/// `void CFSetGetValues(CFSetRef, const void **values)`
final void Function(Pointer<Void>, Pointer<Pointer<Void>>) cfSetGetValues =
    _cfLib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<Pointer<Void>>),
        void Function(
            Pointer<Void>, Pointer<Pointer<Void>>)>('CFSetGetValues');

/// `void CFRelease(CFTypeRef)`
final void Function(Pointer<Void>) cfRelease = _cfLib.lookupFunction<
    Void Function(Pointer<Void>), void Function(Pointer<Void>)>('CFRelease');

/// `CFStringRef CFStringCreateWithCString(allocator, cStr, encoding)`
final Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>, int)
    cfStringCreateWithCString = _cfLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>, Uint32),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Utf8>, int)>('CFStringCreateWithCString');

/// `Boolean CFStringGetCString(str, buffer, bufferSize, encoding)`
final bool Function(Pointer<Void>, Pointer<Utf8>, int, int)
    cfStringGetCString = _cfLib.lookupFunction<
        Bool Function(Pointer<Void>, Pointer<Utf8>, IntPtr, Uint32),
        bool Function(
            Pointer<Void>, Pointer<Utf8>, int, int)>('CFStringGetCString');

/// Callback struct pointers for CF collections.
final Pointer<Void> kCFTypeDictionaryKeyCallBacks =
    _cfLib.lookup('kCFTypeDictionaryKeyCallBacks');
final Pointer<Void> kCFTypeDictionaryValueCallBacks =
    _cfLib.lookup('kCFTypeDictionaryValueCallBacks');
final Pointer<Void> kCFTypeArrayCallBacks =
    _cfLib.lookup('kCFTypeArrayCallBacks');

/// kCFStringEncodingUTF8 = 0x08000100
const int kCFStringEncodingUTF8 = 0x08000100;

/// kCFNumberSInt32Type = 3
const int kCFNumberSInt32Type = 3;

// ---------------------------------------------------------------------------
// IOKit HID
// ---------------------------------------------------------------------------

/// `IOHIDManagerRef IOHIDManagerCreate(allocator, options)`
final Pointer<Void> Function(Pointer<Void>, int) ioHIDManagerCreate =
    _iokitLib.lookupFunction<Pointer<Void> Function(Pointer<Void>, Uint32),
        Pointer<Void> Function(Pointer<Void>, int)>('IOHIDManagerCreate');

/// `void IOHIDManagerSetDeviceMatchingMultiple(manager, multiple)`
final void Function(Pointer<Void>, Pointer<Void>)
    ioHIDManagerSetDeviceMatchingMultiple = _iokitLib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<Void>),
        void Function(
            Pointer<Void>, Pointer<Void>)>(
        'IOHIDManagerSetDeviceMatchingMultiple');

/// `void IOHIDManagerScheduleWithRunLoop(manager, runLoop, runLoopMode)`
final void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
    ioHIDManagerScheduleWithRunLoop = _iokitLib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<Void>,
            Pointer<Void>)>('IOHIDManagerScheduleWithRunLoop');

/// `IOReturn IOHIDManagerOpen(manager, options)`
final int Function(Pointer<Void>, int) ioHIDManagerOpen = _iokitLib
    .lookupFunction<Int32 Function(Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int)>('IOHIDManagerOpen');

/// `IOReturn IOHIDManagerClose(manager, options)`
final int Function(Pointer<Void>, int) ioHIDManagerClose = _iokitLib
    .lookupFunction<Int32 Function(Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int)>('IOHIDManagerClose');

/// `CFSetRef IOHIDManagerCopyDevices(manager)`
final Pointer<Void> Function(Pointer<Void>) ioHIDManagerCopyDevices =
    _iokitLib.lookupFunction<Pointer<Void> Function(Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>)>('IOHIDManagerCopyDevices');

/// `CFArrayRef IOHIDDeviceCopyMatchingElements(device, matching, options)`
final Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int)
    ioHIDDeviceCopyMatchingElements = _iokitLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Uint32),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Void>, int)>(
        'IOHIDDeviceCopyMatchingElements');

/// `CFTypeRef IOHIDDeviceGetProperty(device, key)`
final Pointer<Void> Function(Pointer<Void>, Pointer<Void>)
    ioHIDDeviceGetProperty = _iokitLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Void>)>('IOHIDDeviceGetProperty');

/// `IOReturn IOHIDDeviceGetValue(device, element, pValue)`
final int Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Void>>)
    ioHIDDeviceGetValue = _iokitLib.lookupFunction<
        Int32 Function(
            Pointer<Void>, Pointer<Void>, Pointer<Pointer<Void>>),
        int Function(Pointer<Void>, Pointer<Void>,
            Pointer<Pointer<Void>>)>('IOHIDDeviceGetValue');

/// `uint32_t IOHIDElementGetUsagePage(element)`
final int Function(Pointer<Void>) ioHIDElementGetUsagePage = _iokitLib
    .lookupFunction<Uint32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('IOHIDElementGetUsagePage');

/// `uint32_t IOHIDElementGetUsage(element)`
final int Function(Pointer<Void>) ioHIDElementGetUsage = _iokitLib
    .lookupFunction<Uint32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('IOHIDElementGetUsage');

/// `IOHIDElementType IOHIDElementGetType(element)`
final int Function(Pointer<Void>) ioHIDElementGetType = _iokitLib
    .lookupFunction<Uint32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('IOHIDElementGetType');

/// `CFIndex IOHIDElementGetLogicalMin(element)`
final int Function(Pointer<Void>) ioHIDElementGetLogicalMin = _iokitLib
    .lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>('IOHIDElementGetLogicalMin');

/// `CFIndex IOHIDElementGetLogicalMax(element)`
final int Function(Pointer<Void>) ioHIDElementGetLogicalMax = _iokitLib
    .lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>('IOHIDElementGetLogicalMax');

/// `CFIndex IOHIDValueGetIntegerValue(value)`
final int Function(Pointer<Void>) ioHIDValueGetIntegerValue = _iokitLib
    .lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>('IOHIDValueGetIntegerValue');

// ---------------------------------------------------------------------------
// HID constants
// ---------------------------------------------------------------------------

/// Generic Desktop usage page.
const int kHIDUsagePageGenericDesktop = 0x01;

/// Button usage page.
const int kHIDUsagePageButton = 0x09;

// Generic Desktop usages
const int kHIDUsageJoystick = 0x04;
const int kHIDUsageGamePad = 0x05;
const int kHIDUsageMultiAxisController = 0x08;
const int kHIDUsageX = 0x30;
const int kHIDUsageY = 0x31;
const int kHIDUsageZ = 0x32;
const int kHIDUsageRx = 0x33;
const int kHIDUsageRy = 0x34;
const int kHIDUsageRz = 0x35;
const int kHIDUsageHatSwitch = 0x39;

/// IOHIDElement input types.
const int kIOHIDElementTypeInputMisc = 1;
const int kIOHIDElementTypeInputButton = 2;
const int kIOHIDElementTypeInputAxis = 3;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a CFString from a Dart string. Caller must CFRelease.
Pointer<Void> createCFString(String s) {
  final native = s.toNativeUtf8();
  final result = cfStringCreateWithCString(nullptr, native, kCFStringEncodingUTF8);
  calloc.free(native);
  return result;
}

/// Reads a CFStringRef into a Dart string. Returns null if conversion fails.
String? cfStringToDart(Pointer<Void> cfStr) {
  if (cfStr == nullptr) return null;
  final buf = calloc<Uint8>(256).cast<Utf8>();
  final ok = cfStringGetCString(cfStr, buf, 256, kCFStringEncodingUTF8);
  final result = ok ? buf.toDartString() : null;
  calloc.free(buf);
  return result;
}

/// Creates a CFNumber from a 32-bit integer. Caller must CFRelease.
Pointer<Void> createCFNumber(int value) {
  final ptr = calloc<Int32>()..value = value;
  final result = cfNumberCreate(nullptr, kCFNumberSInt32Type, ptr.cast());
  calloc.free(ptr);
  return result;
}
