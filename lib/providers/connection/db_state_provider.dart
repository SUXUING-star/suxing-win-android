// // lib/providers/connection/db_state_provider.dart
// import 'package:flutter/material.dart';
// import '../../services/main/restart/restart_service.dart';
// import 'dart:async';
//
// class DBStateProvider with ChangeNotifier {
//   bool _isConnected = false;
//   String? _errorMessage;
//   bool _needsReset = false;
//   Timer? _autoRestartTimer;
//
//   bool get isConnected => _isConnected;
//   String? get errorMessage => _errorMessage;
//   bool get needsReset => _needsReset;
//
//   void setConnectionState(bool connected, {String? error}) {
//     _isConnected = connected;
//     _errorMessage = error;
//
//     if (!connected) {
//       _handleConnectionFailure(error ?? '数据库连接已断开');
//     } else {
//       _cancelAutoRestart();
//       _needsReset = false;
//     }
//
//     notifyListeners();
//   }
//
//   void _handleConnectionFailure(String error) {
//     _errorMessage = error;
//
//     // 取消之前的定时器（如果存在）
//     _cancelAutoRestart();
//
//     // 设置2秒后自动重启
//     _autoRestartTimer = Timer(const Duration(seconds: 2), () {
//       _performAutoRestart();
//     });
//
//     notifyListeners();
//   }
//
//   void triggerReset(String error) {
//     _needsReset = true;
//     _errorMessage = error;
//
//     // 当触发重置时也启动自动重启定时器
//     _handleConnectionFailure(error);
//   }
//
//   void _performAutoRestart() async {
//     try {
//       await RestartService().restartApp();
//     } catch (e) {
//       print('Auto restart failed: $e');
//       // 如果自动重启失败，可以在这里添加额外的处理逻辑
//     }
//   }
//
//   void _cancelAutoRestart() {
//     _autoRestartTimer?.cancel();
//     _autoRestartTimer = null;
//   }
//
//   @override
//   void dispose() {
//     _cancelAutoRestart();
//     super.dispose();
//   }
// }