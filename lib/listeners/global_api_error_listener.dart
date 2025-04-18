// lib/widgets/listeners/global_api_error_listener.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/events/app_events.dart'; // 导入全局 EventBus
import 'package:suxingchahui/models/error/idempotency_error_code.dart'; // 导入错误码枚举/类
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart'; // 导入你的弹窗 Dialog

class GlobalApiErrorListener extends StatefulWidget {
  final Widget child;
  const GlobalApiErrorListener({Key? key, required this.child}) : super(key: key);

  @override
  State<GlobalApiErrorListener> createState() => _GlobalApiErrorListenerState();
}

class _GlobalApiErrorListenerState extends State<GlobalApiErrorListener> {
  StreamSubscription? _idempotencyErrorSubscription;
  // 用于防止短时间内对完全相同的事件重复弹窗 (基于时间戳去重更可靠)
  DateTime? _lastErrorTimestamp;
  final Duration _debounceDuration = const Duration(milliseconds: 500); // 500毫秒内同一个错误不再弹

  @override
  void initState() {
    super.initState();
    _listenForErrors();
    print("GlobalApiErrorListener initialized and listening...");
  }

  void _listenForErrors() {
    _idempotencyErrorSubscription?.cancel(); // 先取消旧的监听，以防万一
    _idempotencyErrorSubscription = appEventBus
        .on<IdempotencyApiErrorEvent>() // 只精确监听这个类型的事件
        .listen(
        _handleIdempotencyError,
        onError: (error) {
          // 处理事件流本身的错误（理论上很少发生）
          print("Error in IdempotencyApiErrorEvent stream: $error");
        },
        onDone: () {
          // 事件流关闭时（理论上 App 退出时）
          print("IdempotencyApiErrorEvent stream closed.");
        }
    );
  }

  void _handleIdempotencyError(IdempotencyApiErrorEvent event) {
    print("Received IdempotencyApiErrorEvent: Code=${event.code.name}, Msg=${event.message}");
    final now = DateTime.now();

    // 防抖：如果上一个错误的时间戳存在，并且当前事件时间戳与上一个非常接近，则忽略
    if (_lastErrorTimestamp != null && now.difference(_lastErrorTimestamp!) < _debounceDuration) {
      print("Debouncing IdempotencyApiErrorEvent (too close to last one).");
      return;
    }

    // 检查 Widget 是否还在树上，只有 mounted 状态才能安全地使用 context
    if (mounted) {
      // 更新最后处理的时间戳
      _lastErrorTimestamp = now;
      // 显示弹窗
      _showErrorDialog(context, event);
    } else {
      print("Listener is not mounted, cannot show dialog for idempotency error.");
    }
  }


  void _showErrorDialog(BuildContext context, IdempotencyApiErrorEvent event) {
    String title;
    IconData icon;
    Color iconColor;

    // 根据错误码设置弹窗样式
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
    // 添加对其他可能错误码的处理（来自后端的特定错误）
      case IdempotencyExceptionCode.dbReadError:
      case IdempotencyExceptionCode.lockError:
      case IdempotencyExceptionCode.dbUpdateError:
        title = '服务器繁忙';
        icon = Icons.error_outline;
        iconColor = Colors.redAccent;
        break;
      case IdempotencyExceptionCode.unknown:
      default:
        title = '请求冲突';
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.deepOrange;
        break;
    }

    // 调用你的 CustomInfoDialog 显示
    CustomInfoDialog.show(
      context: context, // 使用当前 Widget 的 context
      title: title,
      message: event.message, // 使用事件中携带的消息
      iconData: icon,
      iconColor: iconColor,
      closeButtonText: '知道了',
      barrierDismissible: true, // 允许点击外部关闭
      // onClose 回调现在是可选的，因为我们不需要在关闭时清除 Provider 状态了
      // onClose: () { print("Idempotency error dialog closed."); },
    );
  }

  @override
  void dispose() {
    print("Disposing GlobalApiErrorListener, cancelling subscription.");
    _idempotencyErrorSubscription?.cancel(); // 非常重要：在 Widget 销毁时取消监听，防止内存泄漏
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 这个 Widget 本身不渲染任何东西，只是一个监听器容器
    // 它直接返回子 Widget
    return widget.child;
  }
}