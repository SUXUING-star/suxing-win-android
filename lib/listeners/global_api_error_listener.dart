// lib/widgets/listeners/global_api_error_listener.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/app.dart';
import 'package:suxingchahui/events/app_events.dart';
import 'package:suxingchahui/models/error/idempotency_error_code.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';

class GlobalApiErrorListener extends StatefulWidget {
  final Widget child;
  const GlobalApiErrorListener({super.key, required this.child});

  @override
  State<GlobalApiErrorListener> createState() => _GlobalApiErrorListenerState();
}

class _GlobalApiErrorListenerState extends State<GlobalApiErrorListener> {
  StreamSubscription? _idempotencyErrorSubscription;
  StreamSubscription? _unauthorizedSubscription; // <--- 添加 401 监听器

  // 用于防止短时间内对*同类型*错误重复弹窗
  DateTime? _lastIdempotencyErrorTimestamp;
  DateTime? _lastUnauthorizedTimestamp; // <--- 添加 401 时间戳
  // 可以为不同错误类型设置不同的防抖时间
  final Duration _idempotencyDebounceDuration =
      const Duration(milliseconds: 500);
  final Duration _unauthorizedDebounceDuration =
      const Duration(seconds: 2); // 2秒内不重复弹401

  // --- 新增：标记是否有 401 对话框正在显示 ---
  bool _isUnauthorizedDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _listenForIdempotencyErrors();
    _listenForUnauthorizedErrors(); // <--- 初始化时开始监听 401
  }

  void _listenForIdempotencyErrors() {
    _idempotencyErrorSubscription?.cancel();
    _idempotencyErrorSubscription = appEventBus
        .on<IdempotencyApiErrorEvent>() // 只精确监听这个类型的事件
        .listen(_handleIdempotencyError, onError: (error) {
      // 处理事件流本身的错误（理论上很少发生）
      print("Error in IdempotencyApiErrorEvent stream: $error");
    }, onDone: () {
      // 事件流关闭时（理论上 App 退出时）
      print("IdempotencyApiErrorEvent stream closed.");
    });
  }

  // --- 新增：监听 UnauthorizedAccessEvent ---
  void _listenForUnauthorizedErrors() {
    _unauthorizedSubscription?.cancel();
    _unauthorizedSubscription = appEventBus
        .on<UnauthorizedAccessEvent>()
        .listen(_handleUnauthorizedAccess, onError: (error) {
      print("Error in UnauthorizedAccessEvent stream: $error");
    }, onDone: () {
      print("UnauthorizedAccessEvent stream closed.");
    });
  }

  void _handleIdempotencyError(IdempotencyApiErrorEvent event) {
    print(
        "Received IdempotencyApiErrorEvent: Code=${event.code.name}, Msg=${event.message}");
    final now = DateTime.now();

    if (_lastIdempotencyErrorTimestamp != null &&
        now.difference(_lastIdempotencyErrorTimestamp!) <
            _idempotencyDebounceDuration) {
      print("Debouncing IdempotencyApiErrorEvent (too close to last one).");
      return;
    }

    if (mounted) {
      _lastIdempotencyErrorTimestamp = now;
      _showIdempotencyErrorDialog(context, event); // <--- 改用专门的方法显示
    } else {
      print(
          "Listener is not mounted, cannot show dialog for idempotency error.");
    }
  }

  // --- 新增：处理 UnauthorizedAccessEvent ---
  void _handleUnauthorizedAccess(UnauthorizedAccessEvent event) {
    print("Received UnauthorizedAccessEvent: Msg=${event.message}");
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

  // 保持原来的 Idempotency 弹窗逻辑
  void _showIdempotencyErrorDialog(
      BuildContext _, IdempotencyApiErrorEvent event) {
    final navigatorContext = mainNavigatorKey.currentContext;
    if (navigatorContext == null) {
      print("Error: mainNavigatorKey.currentContext is null. Cannot show idempotency dialog.");
      // 这里可以考虑加个日志或者备用方案，但通常不应该为 null
      return;
    }

    String title;
    IconData icon;
    Color iconColor;
    switch (event.code) {
      case IdempotencyExceptionCode.alreadyProcessed:
        title = '操作已完成';
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case IdempotencyExceptionCode.inProgress:
        title = '请求处理中';
        icon = Icons.hourglass_empty_rounded;
        iconColor = Colors.orange;
        break;
      case IdempotencyExceptionCode.dbReadError:
      case IdempotencyExceptionCode.lockError:
      case IdempotencyExceptionCode.dbUpdateError:
        title = '服务器繁忙';
        icon = Icons.error_outline;
        iconColor = Colors.redAccent;
        break;
      case IdempotencyExceptionCode.unknown:
        title = '请求冲突';
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.deepOrange;
        break;
    }

    CustomInfoDialog.show(
      context: navigatorContext,
      title: title,
      message: event.message,
      iconData: icon,
      iconColor: iconColor,
      closeButtonText: '知道了',
      barrierDismissible: true,
      // onClose 是可选的
      onClose: () {
        print("Idempotency error dialog closed.");
      },
    );
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
        print("Unauthorized dialog closed by button, navigating to login.");
        _isUnauthorizedDialogShowing = false; // 关闭对话框时重置标记

        NavigationUtils.navigateToLogin(context);
      },
    );
  }

  @override
  void dispose() {
    print("Disposing GlobalApiErrorListener, cancelling subscriptions.");
    _idempotencyErrorSubscription?.cancel();
    _unauthorizedSubscription?.cancel(); // <--- 别忘了取消 401 监听
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
