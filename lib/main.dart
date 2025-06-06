import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'app.dart';
import 'constants/global_constants.dart'; // 引入 GlobalConstants

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const platform =
      MethodChannel('com.example.suxingchahui/flutter_ready_signal');

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      if (Platform.isAndroid){
        await platform.invokeMethod('flutterFirstFrameReady');
      }

    } catch (e) {
      // debugPrint('Error sending flutterFirstFrameReady signal: $e');
    }
  });

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      title: GlobalConstants.appNameWindows,
      minimumSize: Size(800, 600),
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const App());
}
