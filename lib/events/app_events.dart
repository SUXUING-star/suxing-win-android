// lib/events/app_events.dart

/// 该文件定义了应用中使用的各种事件类型和全局事件总线。
/// 事件总线用于在应用的不同部分之间进行解耦通信。
library;

import 'dart:async'; // 异步操作所需

/// `UserSignedOutEvent` 类：表示用户登出事件。
class UserSignedOutEvent {
  final String? userId; // 登出的用户 ID

  /// 构造函数。
  ///
  /// [userId]：可选的登出用户 ID。
  UserSignedOutEvent({this.userId});
}

/// `UnauthorizedAccessEvent` 类：表示发生了未授权访问事件。
///
/// 通常是 JWT Token 失效或过期导致。
class UnauthorizedAccessEvent {
  final String? message; // 错误信息

  /// 构造函数。
  ///
  /// [message]：可选的错误信息。
  UnauthorizedAccessEvent({this.message});
}

/// `NetworkEnvironmentChangedEvent` 类：表示网络环境发生变化事件。
///
/// 可能需要 API 客户端重置。
class NetworkEnvironmentChangedEvent {
  final String? newIpAddress; // 新的 IP 地址
  final String? newConnectionType; // 新的连接类型

  /// 构造函数。
  ///
  /// [newIpAddress]：可选的新 IP 地址。
  /// [newConnectionType]：可选的新连接类型。
  NetworkEnvironmentChangedEvent({this.newIpAddress, this.newConnectionType});
}

/// `AppEventBus` 类：全局事件流控制器。
///
/// 该类以单例模式提供事件发布和订阅功能。
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal(); // 单例实例
  /// 获取 `AppEventBus` 实例。
  factory AppEventBus() => _instance;

  /// 私有内部构造函数。
  AppEventBus._internal();

  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast(); // 广播型事件流控制器

  /// 获取指定类型的事件流。
  ///
  /// [T]：事件类型。
  /// 返回过滤并转换为指定类型的事件流。
  Stream<T> on<T>() {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>(); // 过滤并转换事件类型
  }

  /// 发布事件。
  ///
  /// [event]：要发布的事件对象。
  /// 如果事件流未关闭，则添加事件到流中。
  void fire(dynamic event) {
    if (!_controller.isClosed) {
      // 检查事件流是否已关闭
      _controller.add(event); // 添加事件
    }
  }

  /// 关闭事件流。
  ///
  /// 通常在应用退出时调用。
  void dispose() {
    _controller.close(); // 关闭事件流控制器
  }
}

/// 全局事件总线实例。
final appEventBus = AppEventBus();
