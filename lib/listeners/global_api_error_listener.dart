// lib/widgets/listeners/global_api_error_listener.dart

/// 该文件定义了 GlobalApiErrorListener，一个全局监听 API 错误的 StatefulWidget。
/// GlobalApiErrorListener 负责在接收到未授权访问事件时，显示相应的提示对话框。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/app.dart'; // 导入主应用入口，获取 NavigatorKey
import 'package:suxingchahui/events/app_events.dart'; // 导入应用事件总线
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart'; // 信息对话框组件

/// `GlobalApiErrorListener` 类：全局 API 错误监听器。
///
/// 该 Widget 负责监听 `UnauthorizedAccessEvent` 事件，并在收到该事件时，
/// 阻止重复弹窗，然后显示一个强制用户重新登录的对话框。
class GlobalApiErrorListener extends StatefulWidget {
  final Widget child; // 子 Widget
  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [child]：要渲染的子 Widget。
  const GlobalApiErrorListener({
    super.key,
    required this.child,
  });

  @override
  State<GlobalApiErrorListener> createState() => _GlobalApiErrorListenerState();
}

/// `_GlobalApiErrorListenerState` 类：`GlobalApiErrorListener` 的状态管理。
class _GlobalApiErrorListenerState extends State<GlobalApiErrorListener> {
  StreamSubscription? _unauthorizedSubscription; // 未授权事件的订阅器

  DateTime? _lastUnauthorizedTimestamp; // 上一次未授权事件发生的时间戳
  final Duration _unauthorizedDebounceDuration =
      const Duration(seconds: 2); // 未授权事件的防抖时长

  bool _isUnauthorizedDialogShowing = false; // 标记是否有 401 对话框正在显示

  /// 初始化状态。
  ///
  /// 订阅未授权错误事件。
  @override
  void initState() {
    super.initState();
    _listenForUnauthorizedErrors(); // 监听未授权错误事件
  }

  /// 监听 `UnauthorizedAccessEvent` 事件。
  ///
  /// 重新订阅事件流。
  void _listenForUnauthorizedErrors() {
    _unauthorizedSubscription?.cancel(); // 取消现有订阅
    _unauthorizedSubscription = appEventBus
        .on<UnauthorizedAccessEvent>()
        .listen(_handleUnauthorizedAccess); // 监听并处理未授权访问事件
  }

  /// 处理 `UnauthorizedAccessEvent` 事件。
  ///
  /// [event]：未授权访问事件。
  /// 实现防抖逻辑，避免短时间内重复显示对话框。
  void _handleUnauthorizedAccess(UnauthorizedAccessEvent event) {
    final now = DateTime.now(); // 获取当前时间

    if (_isUnauthorizedDialogShowing || // 对话框已显示
        (_lastUnauthorizedTimestamp != null &&
            now.difference(_lastUnauthorizedTimestamp!) <
                _unauthorizedDebounceDuration)) {
      // 未到防抖时间
      return; // 忽略事件
    }

    if (mounted) {
      // 检查 Widget 是否已挂载
      _lastUnauthorizedTimestamp = now; // 更新时间戳
      _isUnauthorizedDialogShowing = true; // 标记对话框即将显示
      _showUnauthorizedDialog(context, event); // 显示对话框
    }
  }

  /// 显示 401 未授权对话框。
  ///
  /// [context]：Build 上下文。
  /// [event]：未授权访问事件。
  /// 使用 `CustomInfoDialog` 显示认证失效提示，并强制用户重新登录。
  void _showUnauthorizedDialog(BuildContext _, UnauthorizedAccessEvent event) {
    final navigatorContext = mainNavigatorKey.currentContext; // 获取主导航器的上下文
    if (navigatorContext == null) {
      return; // 导航器上下文为空时直接返回
    }

    CustomInfoDialog.show(
      context: navigatorContext, // 对话框上下文
      title: '认证失效', // 对话框标题
      message: event.message ?? '您的登录状态已过期或无效，请重新登录以继续操作。', // 对话框消息
      iconData: Icons.lock_person_outlined, // 对话框图标
      iconColor: Colors.orangeAccent, // 图标颜色
      closeButtonText: '前往登录', // 关闭按钮文本
      barrierDismissible: false, // 强制用户交互
      onClose: () {
        // 关闭对话框时的回调
        _isUnauthorizedDialogShowing = false; // 重置对话框显示标记
        NavigationUtils.navigateToLogin(context); // 导航到登录页面
      },
    );
  }

  /// 销毁状态。
  ///
  /// 取消所有订阅。
  @override
  void dispose() {
    _unauthorizedSubscription?.cancel(); // 取消订阅
    super.dispose(); // 调用父类销毁方法
  }

  /// 构建 Widget。
  ///
  /// 返回 Widget 的子 Widget。
  @override
  Widget build(BuildContext context) {
    return widget.child; // 渲染子 Widget
  }
}
