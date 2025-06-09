// lib/wrapper/initialization_wrapper.dart

/// 该文件定义了 InitializationWrapper，一个管理应用初始化流程的 StatefulWidget。
/// InitializationWrapper 负责显示初始化进度、处理初始化错误，并在初始化成功后渲染主应用界面。
library;

import 'dart:io'; // 导入 Platform 和 exit 函数
import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:flutter/services.dart'; // 导入 SystemNavigator
import 'package:provider/single_child_widget.dart'; // 导入 Provider 列表类型
import 'package:suxingchahui/providers/initialize/initialization_status.dart'; // 初始化状态枚举

// 相关的 Provider 和服务
import 'package:suxingchahui/initialization/app_initializer.dart'; // 应用初始化器
import 'package:suxingchahui/providers/initialize/initialization_provider.dart'; // 初始化状态 Provider

// 初始化界面 Widget
import 'package:suxingchahui/widgets/ui/common/initialization_screen.dart'; // 初始化屏幕组件

/// `InitializationWrapper` 类：应用初始化包装器。
///
/// 该 Widget 负责管理应用启动时的初始化过程，根据初始化状态显示不同的界面。
class InitializationWrapper extends StatefulWidget {
  /// 初始化成功后调用的回调函数。
  ///
  /// 该函数接收一个创建好的 Provider 列表作为参数。
  final Widget Function(List<SingleChildWidget> providers) onInitialized;

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [onInitialized]：初始化成功后的回调函数。
  const InitializationWrapper({
    super.key,
    required this.onInitialized,
  });

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

/// `_InitializationWrapperState` 类：`InitializationWrapper` 的状态管理。
class _InitializationWrapperState extends State<InitializationWrapper> {
  late final InitializationProvider _initProvider; // 管理初始化状态和进度的 Provider
  Map<String, dynamic>? _services; // 保存初始化成功后的服务实例 Map
  String? _initializationError; // 保存具体的初始化错误信息
  bool _networkOrAuthErrorOccurred = false; // 标记是否发生过网络或认证相关错误
  bool _hasAttemptedInit = false; // 标记是否已尝试过初始化
  bool _isMounted = true; // 标记组件是否仍在 Widget 树中

  /// 获取初始化错误信息。
  String? get initializationError => _initializationError;

  /// 获取网络或认证错误是否发生标记。
  bool get networkOrAuthErrorOccurred => _networkOrAuthErrorOccurred;

  /// 初始化状态。
  ///
  /// 创建 `InitializationProvider` 实例，添加监听器，并调度初始化流程。
  @override
  void initState() {
    super.initState();
    _isMounted = true; // 设置组件挂载标记
    _initProvider = InitializationProvider(); // 实例化初始化 Provider
    _initProvider.addListener(_onProviderUpdate); // 添加监听器以刷新 UI

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 在当前帧渲染完成后回调
      if (_isMounted && !_hasAttemptedInit) {
        // 检查组件挂载状态和是否已尝试初始化
        _startInitialization(); // 启动初始化流程
      }
    });
  }

  /// Provider 状态更新时的回调。
  ///
  /// 当组件还在 Widget 树中时，调用 `setState` 刷新 UI。
  void _onProviderUpdate() {
    if (_isMounted) {
      // 检查组件是否已挂载
      setState(() {
        // UI 将根据 _initProvider 的最新状态刷新
      });
    }
  }

  /// 启动初始化流程。
  ///
  /// 重置状态变量，调用 `AppInitializer` 执行初始化步骤，并处理成功或失败状态。
  Future<void> _startInitialization() async {
    if (_hasAttemptedInit &&
        _initProvider.status == InitializationStatus.inProgress) {
      return; // 正在初始化中，阻止重复调用
    }

    _hasAttemptedInit = true; // 标记已尝试初始化

    _initializationError = null; // 清空错误信息
    _networkOrAuthErrorOccurred = false; // 重置错误标记
    _services = null; // 清空旧服务实例
    _initProvider.reset(); // 重置 Provider 状态为 InProgress

    try {
      final initializedServices =
          await AppInitializer.initializeServices(_initProvider); // 调用应用初始化器

      if (_isMounted) {
        // 检查组件是否已挂载
        _services = initializedServices; // 保存初始化成功的服务实例
        _initProvider.setCompleted(); // 设置初始化状态为完成
      }
    } catch (e) {
      // 捕获初始化过程中的异常
      if (_isMounted) {
        // 检查组件是否已挂载
        final errorMessage = '初始化失败: ${e.toString()}'; // 格式化错误信息
        _initializationError = errorMessage; // 保存错误信息

        final errorStringLower = e.toString().toLowerCase(); // 将错误信息转为小写
        if (errorStringLower.contains('network') ||
            errorStringLower.contains('connection') ||
            errorStringLower.contains('timeout') ||
            errorStringLower.contains('socket') ||
            errorStringLower.contains('handshake') ||
            errorStringLower.contains('certificate') ||
            errorStringLower.contains('http')) {
          _networkOrAuthErrorOccurred = true; // 标记为网络或认证错误
        } else {
          _networkOrAuthErrorOccurred = false; // 标记为非网络或认证错误
        }

        _initProvider.setError(errorMessage); // 设置初始化状态为错误
      }
    } finally {
      if (_initProvider.status == InitializationStatus.error) {
        _hasAttemptedInit = false; // 错误状态下重置尝试标志，允许用户重试
      }
    }
  }

  /// 处理“重试”按钮的点击事件。
  ///
  /// 重新开始完整的初始化流程。
  void _handleRetry() {
    if (!_isMounted) {
      // 检查组件是否已挂载
      return;
    }
    _startInitialization(); // 重新启动初始化流程
  }

  /// 处理“退出”按钮的点击事件。
  ///
  /// 根据不同平台执行退出操作。
  void _handleExit() {
    if (Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS ||
        Platform.isFuchsia) {
      exit(0); // 桌面平台直接退出进程
    } else {
      SystemNavigator.pop(); // 移动平台尝试弹出当前 Activity/View Controller
    }
  }

  /// 销毁状态。
  ///
  /// 移除 Provider 的监听器，并销毁 Provider 自身。
  @override
  void dispose() {
    _isMounted = false; // 设置组件已卸载标记
    _initProvider.removeListener(_onProviderUpdate); // 移除 Provider 监听器
    _initProvider.dispose(); // 销毁 Provider

    super.dispose(); // 调用父类销毁方法
  }

  /// 构建 Widget。
  ///
  /// 根据初始化状态显示不同的界面。
  @override
  Widget build(BuildContext context) {
    switch (_initProvider.status) {
      case InitializationStatus.inProgress:
      case InitializationStatus.idle:
        return InitializationScreen(
          status: _initProvider.status, // 显示当前初始化状态
          message: _initProvider.message, // 显示当前加载消息
          progress: _initProvider.progress, // 显示加载进度
          onRetry: null, // 加载中不允许重试
          onExit: _handleExit, // 允许用户在加载时退出
        );

      case InitializationStatus.error:
        return InitializationScreen(
          status: _initProvider.status, // 显示错误状态
          message: _initProvider.message, // 显示错误消息
          progress: _initProvider.progress, // 显示失败时的进度
          onRetry: _handleRetry, // 提供重试按钮
          onExit: _handleExit, // 提供退出按钮
        );

      case InitializationStatus.completed:
        if (_services != null) {
          // 检查服务实例是否存在
          return widget.onInitialized(
              AppInitializer.createProviders(_services!)); // 构建主应用界面
        } else {
          return InitializationScreen(
            status: InitializationStatus.error, // 强制显示为错误状态
            message: "发生意外错误：初始化状态异常。请尝试退出并重新启动应用。", // 紧急错误消息
            progress: 0,
            onRetry: _handleRetry, // 仍然提供重试选项
            onExit: _handleExit, // 提供退出按钮
          );
        }
    }
  }
}
