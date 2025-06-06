// lib/widgets/listeners/global_api_error_listener.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/app.dart';
import 'package:suxingchahui/events/app_events.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';

class GlobalApiErrorListener extends StatefulWidget {
  final Widget child;
  const GlobalApiErrorListener({super.key, required this.child});

  @override
  State<GlobalApiErrorListener> createState() => _GlobalApiErrorListenerState();
}

class _GlobalApiErrorListenerState extends State<GlobalApiErrorListener> {
  StreamSubscription? _unauthorizedSubscription;

  // 用于防止短时间内对*同类型*错误重复弹窗
  DateTime? _lastUnauthorizedTimestamp;
  final Duration _unauthorizedDebounceDuration = const Duration(seconds: 2);

  // --- 新增：标记是否有 401 对话框正在显示 ---
  bool _isUnauthorizedDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _listenForUnauthorizedErrors();
  }

  // --- 监听 UnauthorizedAccessEvent ---
  void _listenForUnauthorizedErrors() {
    _unauthorizedSubscription?.cancel();
    _unauthorizedSubscription = appEventBus
        .on<UnauthorizedAccessEvent>()
        .listen(_handleUnauthorizedAccess, onError: (error) {
      // print("Error in UnauthorizedAccessEvent stream: $error");
    }, onDone: () {
      // print("UnauthorizedAccessEvent stream closed.");
    });
  }

  // --- 新增：处理 UnauthorizedAccessEvent ---
  void _handleUnauthorizedAccess(UnauthorizedAccessEvent event) {
    final now = DateTime.now();

    // 如果已经有一个 401 对话框在显示，或者离上次太近，就忽略
    if (_isUnauthorizedDialogShowing ||
        (_lastUnauthorizedTimestamp != null &&
            now.difference(_lastUnauthorizedTimestamp!) <
                _unauthorizedDebounceDuration)) {
      //print("Debouncing UnauthorizedAccessEvent (dialog already showing or too close to last one).");
      return;
    }

    if (mounted) {
      _lastUnauthorizedTimestamp = now;
      _isUnauthorizedDialogShowing = true; // 标记对话框即将显示
      _showUnauthorizedDialog(context, event);
    } else {
      //print("Listener is not mounted, cannot show dialog for unauthorized access.");
    }
  }

  // --- 新增：显示 401 未授权对话框 ---
  void _showUnauthorizedDialog(BuildContext _, UnauthorizedAccessEvent event) {
    final navigatorContext = mainNavigatorKey.currentContext;
    if (navigatorContext == null) {
      //print("Error: mainNavigatorKey.currentContext is null. Cannot show idempotency dialog.");
      // 这里可以考虑加个日志或者备用方案，但通常不应该为 null
      return;
    }

    CustomInfoDialog.show(
      context: navigatorContext,
      title: '认证失效',
      message: event.message ?? '您的登录状态已过期或无效，请重新登录以继续操作。', // 友好的提示信息
      iconData: Icons.lock_person_outlined, // 或者 Icons.security_outlined
      iconColor: Colors.orangeAccent, // 醒目但不过于刺眼的颜色
      closeButtonText: '前往登录', // 清晰的行动指引
      barrierDismissible: false, // 强制用户交互
      onClose: () {
        _isUnauthorizedDialogShowing = false; // 关闭对话框时重置标记

        NavigationUtils.navigateToLogin(context);
      },
    );
  }

  @override
  void dispose() {
    _unauthorizedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
