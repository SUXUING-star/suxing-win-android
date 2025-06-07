// lib/providers/initialize/initialization_provider.dart

/// 该文件定义了 InitializationProvider，一个管理应用初始化状态的 ChangeNotifier。
/// InitializationProvider 跟踪应用的初始化进度、消息和最终状态。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/initialize/initialization_status.dart'; // 导入初始化状态枚举
import 'package:suxingchahui/services/error/app_error_formatter.dart'; // 导入错误消息格式化工具

/// `InitializationProvider` 类：管理应用初始化状态的 Provider。
///
/// 该类提供应用初始化过程中的状态、消息和进度更新。
class InitializationProvider extends ChangeNotifier {
  InitializationStatus _status = InitializationStatus.inProgress; // 当前初始化状态
  String _message = '正在初始化...'; // 当前初始化消息
  double _progress = 0.0; // 当前初始化进度 (0.0 到 1.0)
  bool _isDisposed = false; // 标识该 Provider 是否已销毁

  /// 获取当前初始化状态。
  InitializationStatus get status => _status;

  /// 获取当前初始化消息。
  String get message => _message;

  /// 获取当前初始化进度。
  double get progress => _progress;

  /// 更新初始化进度和消息。
  ///
  /// [message]：新的初始化消息。
  /// [progress]：新的初始化进度。
  /// 进度值只允许前进，不能后退。
  void updateProgress(String message, double progress) {
    if (_isDisposed) return;

    if (progress >= _progress) {
      // 进度只能前进
      _message = message; // 更新消息
      _progress = progress; // 更新进度
      _status = InitializationStatus.inProgress; // 设置状态为进行中
      notifyListeners(); // 通知监听者状态已更新
    }
  }

  /// 设置初始化状态为错误。
  ///
  /// [error]：原始错误信息。
  /// 错误信息将被格式化后显示。
  void setError(String error) {
    if (_isDisposed) return;
    _message = AppErrorFormatter.formatErrorMessage(error); // 格式化错误消息
    _status = InitializationStatus.error; // 设置状态为错误
    notifyListeners(); // 通知监听者状态已更新
  }

  /// 设置初始化状态为完成。
  ///
  /// 进度将被设置为 1.0。
  void setCompleted() {
    if (_isDisposed) return;
    _progress = 1.0; // 设置进度为完成
    _status = InitializationStatus.completed; // 设置状态为完成
    notifyListeners(); // 通知监听者状态已更新
  }

  /// 重置初始化状态。
  ///
  /// 将状态重置为进行中，消息重置为默认，进度重置为 0.0。
  void reset() {
    if (_isDisposed) return;
    _status = InitializationStatus.inProgress; // 重置为进行中状态
    _message = '正在初始化...'; // 重置默认消息
    _progress = 0.0; // 重置进度为 0.0
    notifyListeners(); // 通知监听者状态已更新
  }

  /// 销毁 Provider。
  ///
  /// 设置销毁标记，阻止进一步的状态更新。
  @override
  void dispose() {
    _isDisposed = true; // 设置销毁标记
    super.dispose(); // 调用父类销毁方法
  }
}
