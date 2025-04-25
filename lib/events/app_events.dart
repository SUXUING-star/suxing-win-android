import 'dart:async';

import 'package:suxingchahui/models/error/idempotency_error_code.dart';

// 定义事件类型
class UserSignedOutEvent {
  final String? userId; // 可以选择传递登出的用户 ID
  UserSignedOutEvent({this.userId});
}
class IdempotencyApiErrorEvent {
  final IdempotencyExceptionCode code;
  final String message;
  final DateTime timestamp;

  IdempotencyApiErrorEvent({
    required this.code,
    required this.message,
  }) : timestamp = DateTime.now();
}

/// 表示发生了未授权访问（通常是 JWT Token 失效/过期）
class UnauthorizedAccessEvent {
  final String? message; // 可以选择性地携带错误信息
  UnauthorizedAccessEvent({this.message});
}


// 全局事件流控制器
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  // 使用 broadcast 允许多个监听者
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();

  /// 获取事件流
  Stream<T> on<T>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  /// 发布事件
  void fire(dynamic event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// 关闭事件流 (应用退出时调用)
  void dispose() {
    _controller.close();
  }
}

// 提供一个全局实例
final appEventBus = AppEventBus();