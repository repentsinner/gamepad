/// Debug script to test GameController.framework discovery.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

void main() {
  final objcLib = DynamicLibrary.open('/usr/lib/libobjc.A.dylib');
  final cfLib = DynamicLibrary.open(
    '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
  );

  // Load GameController.framework
  DynamicLibrary.open(
    '/System/Library/Frameworks/GameController.framework/GameController',
  );
  print('Framework loaded.');

  // Runtime functions
  final objcGetClass = objcLib.lookupFunction<
      Pointer<Void> Function(Pointer<Utf8>),
      Pointer<Void> Function(Pointer<Utf8>)>('objc_getClass');
  final selRegisterName = objcLib.lookupFunction<
      Pointer<Void> Function(Pointer<Utf8>),
      Pointer<Void> Function(Pointer<Utf8>)>('sel_registerName');
  final msgSendPtr = objcLib.lookupFunction<
      Pointer<Void> Function(Pointer<Void>, Pointer<Void>),
      Pointer<Void> Function(
          Pointer<Void>, Pointer<Void>)>('objc_msgSend');
  final msgSendInt = objcLib.lookupFunction<
      UnsignedLong Function(Pointer<Void>, Pointer<Void>),
      int Function(Pointer<Void>, Pointer<Void>)>('objc_msgSend');

  // CFRunLoop
  final cfRunLoopRunInMode = cfLib.lookupFunction<
      Int32 Function(Pointer<Void>, Double, Bool),
      int Function(Pointer<Void>, double, bool)>('CFRunLoopRunInMode');
  final kCFRunLoopDefaultMode = cfLib
      .lookup<Pointer<Void>>('kCFRunLoopDefaultMode')
      .value;

  // Initialize NSApplication — required for GameController to register
  // its HID/Bluetooth run loop sources.
  DynamicLibrary.open(
    '/System/Library/Frameworks/AppKit.framework/AppKit',
  );
  final nsAppClass = objcGetClass('NSApplication'.toNativeUtf8());
  final selSharedApp = selRegisterName('sharedApplication'.toNativeUtf8());
  final app = msgSendPtr(nsAppClass, selSharedApp);
  print('NSApplication.sharedApplication: $app');

  // finishLaunching sets up AppKit run loop sources
  final selFinishLaunching = selRegisterName('finishLaunching'.toNativeUtf8());
  msgSendPtr(app, selFinishLaunching);
  print('finishLaunching called.');

  // Inject GCSupportsControllerUserInteraction into main bundle's Info.plist.
  // macOS 13+ requires this key for GameController to report controllers.
  final nsBundle = objcGetClass('NSBundle'.toNativeUtf8());
  final selMainBundle = selRegisterName('mainBundle'.toNativeUtf8());
  final mainBundle = msgSendPtr(nsBundle, selMainBundle);
  print('mainBundle: $mainBundle');

  // Get the mutable infoDictionary (NSBundle returns NSMutableDictionary)
  final selInfoDict = selRegisterName('infoDictionary'.toNativeUtf8());
  final infoDict = msgSendPtr(mainBundle, selInfoDict);
  print('infoDictionary: $infoDict');

  if (infoDict != nullptr) {
    // Create NSString key and NSNumber(YES) value
    final nsString = objcGetClass('NSString'.toNativeUtf8());
    final selStringWith = selRegisterName(
        'stringWithUTF8String:'.toNativeUtf8());
    final msgSendPtrUtf8 = objcLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Utf8>),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Void>, Pointer<Utf8>)>('objc_msgSend');
    final key = msgSendPtrUtf8(nsString, selStringWith,
        'GCSupportsControllerUserInteraction'.toNativeUtf8());

    final nsNumber = objcGetClass('NSNumber'.toNativeUtf8());
    final selNumberWithBool = selRegisterName('numberWithBool:'.toNativeUtf8());
    final msgSendPtrBool = objcLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Bool),
        Pointer<Void> Function(
            Pointer<Void>, Pointer<Void>, bool)>('objc_msgSend');
    final yes = msgSendPtrBool(nsNumber, selNumberWithBool, true);

    // setObject:forKey:
    final selSetObjectForKey = selRegisterName('setObject:forKey:'.toNativeUtf8());
    final msgSend3 = objcLib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>,
            Pointer<Void>, Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>,
            Pointer<Void>, Pointer<Void>)>('objc_msgSend');
    msgSend3(infoDict, selSetObjectForKey, yes, key);
    print('Injected GCSupportsControllerUserInteraction=YES');
  }

  final gcClass = objcGetClass('GCController'.toNativeUtf8());

  // Start wireless controller discovery
  final selStartDiscovery = selRegisterName(
    'startWirelessControllerDiscoveryWithCompletionHandler:'.toNativeUtf8(),
  );
  final msgSendPtrArg = objcLib.lookupFunction<
      Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>),
      Pointer<Void> Function(
          Pointer<Void>, Pointer<Void>, Pointer<Void>)>('objc_msgSend');
  msgSendPtrArg(gcClass, selStartDiscovery, nullptr);
  print('startWirelessControllerDiscovery called.');
  final selControllers = selRegisterName('controllers'.toNativeUtf8());
  final selCount = selRegisterName('count'.toNativeUtf8());

  print('GCController class: $gcClass');
  print('');

  // Try multiple ticks with increasing wait
  for (var i = 0; i < 20; i++) {
    // Tick run loop
    final result = cfRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);

    final array = msgSendPtr(gcClass, selControllers);
    final count = array == nullptr ? 0 : msgSendInt(array, selCount);
    print('Tick $i (runloop result=$result): controllers=$count');

    if (count > 0) {
      print('Found controllers!');
      exit(0);
    }

    sleep(const Duration(milliseconds: 100));
  }

  print('');
  print('No controllers found after 20 ticks.');
  print('This may mean GameController.framework needs NSApplication.');
}
