// lib/main.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'app.dart';
import 'services/restart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 如果是桌面平台，初始化窗口管理器
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      title: "宿星茶会（windows版）",  // 这里设置中文标题
      minimumSize: Size(800, 600),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const RestartWrapper(child: App())); // 添加 RestartWrapper
}