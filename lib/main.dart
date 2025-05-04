import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'app.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 如果是桌面平台，初始化窗口管理器
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

  // 在主线程中运行应用
  runApp(const App());
}
