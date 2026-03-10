/// Low-level ObjC runtime FFI bindings for dart:ffi.
///
/// Loads `libobjc.A.dylib` and exposes typed `objc_msgSend` variants
/// for the small set of return/argument combinations needed by the
/// GameController.framework bindings.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Runtime library
// ---------------------------------------------------------------------------

final DynamicLibrary _objcLib = DynamicLibrary.open('/usr/lib/libobjc.A.dylib');

// ---------------------------------------------------------------------------
// Core runtime functions
// ---------------------------------------------------------------------------

/// `Class objc_getClass(const char *name)`
final Pointer<Void> Function(Pointer<Utf8>) objcGetClass = _objcLib
    .lookupFunction<Pointer<Void> Function(Pointer<Utf8>),
        Pointer<Void> Function(Pointer<Utf8>)>('objc_getClass');

/// `SEL sel_registerName(const char *str)`
final Pointer<Void> Function(Pointer<Utf8>) selRegisterName = _objcLib
    .lookupFunction<Pointer<Void> Function(Pointer<Utf8>),
        Pointer<Void> Function(Pointer<Utf8>)>('sel_registerName');

// ---------------------------------------------------------------------------
// objc_msgSend variants
//
// Each variant corresponds to a specific (return type, argument list)
// combination used by the GameController bindings.
// ---------------------------------------------------------------------------

/// `id objc_msgSend(id self, SEL op)` — property getters returning objects.
final Pointer<Void> Function(Pointer<Void>, Pointer<Void>) msgSendPtr =
    _objcLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Void>)>('objc_msgSend');

/// `id objc_msgSend(id self, SEL op, NSUInteger index)` — `objectAtIndex:`.
final Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int)
    msgSendPtrInt = _objcLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, UnsignedLong),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Void>, int)>('objc_msgSend');

/// `NSUInteger objc_msgSend(id self, SEL op)` — `count`.
final int Function(Pointer<Void>, Pointer<Void>) msgSendInt = _objcLib
    .lookupFunction<UnsignedLong Function(Pointer<Void>, Pointer<Void>),
        int Function(Pointer<Void>, Pointer<Void>)>('objc_msgSend');

/// `float objc_msgSend(id self, SEL op)` — axis `value`.
///
/// On arm64 Darwin, float returns use `objc_msgSend` (not the fpret
/// variant, which is x86_64-only for `long double`).
final double Function(Pointer<Void>, Pointer<Void>) msgSendFloat = _objcLib
    .lookupFunction<Float Function(Pointer<Void>, Pointer<Void>),
        double Function(Pointer<Void>, Pointer<Void>)>('objc_msgSend');

/// `BOOL objc_msgSend(id self, SEL op)` — button `isPressed`.
final bool Function(Pointer<Void>, Pointer<Void>) msgSendBool = _objcLib
    .lookupFunction<Bool Function(Pointer<Void>, Pointer<Void>),
        bool Function(Pointer<Void>, Pointer<Void>)>('objc_msgSend');

/// `const char* objc_msgSend(id self, SEL op)` — `UTF8String`.
final Pointer<Utf8> Function(Pointer<Void>, Pointer<Void>) msgSendUtf8 =
    _objcLib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Void>, Pointer<Void>),
        Pointer<Utf8> Function(
            Pointer<Void>, Pointer<Void>)>('objc_msgSend');

// ---------------------------------------------------------------------------
// Autorelease pool
// ---------------------------------------------------------------------------

/// `void *objc_autoreleasePoolPush(void)`
final Pointer<Void> Function() autoreleasePoolPush = _objcLib.lookupFunction<
    Pointer<Void> Function(), Pointer<Void> Function()>(
    'objc_autoreleasePoolPush');

/// `void objc_autoreleasePoolPop(void *pool)`
final void Function(Pointer<Void>) autoreleasePoolPop = _objcLib
    .lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('objc_autoreleasePoolPop');

// ---------------------------------------------------------------------------
// Selector cache
//
// Native UTF-8 strings are allocated once. SEL pointers are resolved
// lazily on first access and cached for the process lifetime.
// ---------------------------------------------------------------------------

/// Registers a selector and caches the result.
Pointer<Void> sel(String name) {
  return _selCache.putIfAbsent(name, () {
    final nativeName = name.toNativeUtf8();
    return selRegisterName(nativeName);
    // nativeName is intentionally leaked — selectors are process-lifetime.
  });
}

final Map<String, Pointer<Void>> _selCache = {};

/// Looks up an ObjC class by name. Returns `nullptr` if not found.
Pointer<Void> cls(String name) {
  return _clsCache.putIfAbsent(name, () {
    final nativeName = name.toNativeUtf8();
    return objcGetClass(nativeName);
    // nativeName is intentionally leaked — class names are process-lifetime.
  });
}

final Map<String, Pointer<Void>> _clsCache = {};
