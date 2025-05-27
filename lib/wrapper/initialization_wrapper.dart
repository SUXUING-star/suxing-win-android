import 'dart:io'; // 用于 Platform 和 exit
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于 SystemNavigator
import 'package:provider/single_child_widget.dart';
import 'package:suxingchahui/providers/initialize/initialization_status.dart';

// 相关的 Provider 和服务
import 'package:suxingchahui/initialization/app_initializer.dart';
import 'package:suxingchahui/providers/initialize/initialization_provider.dart'; // 初始化状态 Provider
import 'package:suxingchahui/services/main/network/network_manager.dart'; // 网络管理器
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 用户认证 Provider

// 初始化界面 Widget
import 'package:suxingchahui/widgets/ui/common/initialization_screen.dart';

class InitializationWrapper extends StatefulWidget {
  /// 初始化成功后调用的回调函数，传入创建好的 Provider 列表
  final Widget Function(List<SingleChildWidget> providers) onInitialized;

  const InitializationWrapper({
    super.key,
    required this.onInitialized,
  });

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  // 用于管理初始化状态和进度的 Provider
  late final InitializationProvider _initProvider;
  // 保存初始化成功后的服务实例 Map
  Map<String, dynamic>? _services;
  // 保存具体的初始化错误信息，用于可能更详细的显示
  String? _initializationError;
  String? get initializationError => _initializationError;
  // 标记是否发生过网络相关或认证失败的错误（用于网络恢复时的逻辑判断）
  bool _networkOrAuthErrorOccurred = false;
  bool get networkOrAuthErrorOccurred => _networkOrAuthErrorOccurred;
  // 防止在 initState 完成前或初始化进行中重复调用 _startInitialization
  bool _hasAttemptedInit = false;
  // 标记组件是否仍在 Widget 树中
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    //print("InitializationWrapper: initState called.");
    _initProvider = InitializationProvider();
    // 添加监听器，当 _initProvider 状态改变时，调用 setState 刷新 UI
    _initProvider.addListener(_onProviderUpdate);

    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保 initState 完成后再开始初始化
    // 这样可以安全地访问 BuildContext (虽然这里没直接用，但这是好习惯)
    // 并且避免在 build 过程中触发可能导致状态问题的初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 再次检查 mounted 状态，因为回调可能在 dispose 之后执行
      if (_isMounted && !_hasAttemptedInit) {
        _startInitialization();
      } else if (!_isMounted) {
      } else if (_hasAttemptedInit) {}
    });
  }

  // Provider 状态更新时的回调
  void _onProviderUpdate() {
    // 只有当组件还在 Widget 树中时才调用 setState
    if (_isMounted) {
      setState(() {
        // 这个 setState 调用会触发 build 方法，
        // build 方法会根据 _initProvider 的最新状态来决定显示哪个界面
      });
    } else {
      //print("InitializationWrapper: Provider updated but widget is disposed, skipping setState.");
    }
  }

  // 开始执行初始化流程
  Future<void> _startInitialization() async {
    // 防止重复或并发调用
    if (_hasAttemptedInit &&
        _initProvider.status == InitializationStatus.inProgress) {
      //print("InitializationWrapper: Initialization already in progress, skipping call.");
      return;
    }

    _hasAttemptedInit = true; // 标记已尝试初始化
    //print("InitializationWrapper: Starting initialization process...");

    // 重置所有状态变量
    _initializationError = null;
    _networkOrAuthErrorOccurred = false;
    _services = null; // 清空旧的服务实例
    _initProvider
        .reset(); // 将 Provider 状态重置为 InProgress (这会触发 _onProviderUpdate -> setState)

    try {
      // *** 调用 AppInitializer 来执行所有初始化步骤 ***
      // AppInitializer 内部会更新 _initProvider 的进度和消息
      // 如果任何关键步骤失败 (特别是 AuthProvider)，AppInitializer 会抛出异常
      final initializedServices =
          await AppInitializer.initializeServices(_initProvider);

      // *** 初始化成功 ***
      // 再次检查 mounted 状态，因为异步操作可能在 Widget dispose 后才完成
      if (_isMounted) {
        _services = initializedServices; // 保存初始化成功的服务实例

        final networkManager = _services!['networkManager'] as NetworkManager?;
        final authProvider = _services!['authProvider'] as AuthProvider?;

        // *** 设置网络恢复回调 ***
        if (networkManager != null && authProvider != null) {
          //print("InitializationWrapper: Setting up onNetworkRestored callback.");
          // 先清除可能存在的旧回调（例如在重试后）
          networkManager.onNetworkRestored = null;
          // 设置新的回调，指向 _handleNetworkRestored 方法
          networkManager.onNetworkRestored =
              () => _handleNetworkRestored(authProvider);
        } else {
          // 如果关键服务没找到，这是一个严重问题，记录日志
          // print(
          //     "InitializationWrapper: WARNING - NetworkManager or AuthProvider instance not found after successful initialization!");
        }

        // 这会触发 _onProviderUpdate -> setState -> build，最终显示主应用界面
        _initProvider.setCompleted();
        //print("InitializationWrapper: Initialization status set to Completed.");
      } else {
        // print(
        //     "InitializationWrapper: Initialization successful, but widget disposed before completion handling.");
      }
    } catch (e) {
      // 检查组件是否还在树中
      if (_isMounted) {
        // 格式化错误信息
        // final errorMessage = '初始化失败: ${ErrorFormatter.formatErrorMessage(e)}'; // 可选的格式化
        final errorMessage =
            '初始化失败: ${e.toString()}'; // 直接使用异常的 toString() 通常足够
        _initializationError = errorMessage; // 保存错误信息

        // 检查错误是否与网络或认证相关
        final errorStringLower = e.toString().toLowerCase();
        if (errorStringLower.contains('network') ||
            errorStringLower.contains('connection') ||
            errorStringLower.contains('timeout') ||
            errorStringLower.contains('socket') ||
            errorStringLower.contains('handshake') ||
            errorStringLower.contains('certificate') ||
            errorStringLower.contains('http')) {
          _networkOrAuthErrorOccurred = true;
        } else {
          _networkOrAuthErrorOccurred = false;
          // print("InitializationWrapper: Non-network/auth error detected.");
        }

        // 这会触发 _onProviderUpdate -> setState -> build，显示错误界面
        _initProvider.setError(errorMessage);
      } else {
        // print("InitializationWrapper: Initialization failed, but widget disposed before error handling.");
      }
    } finally {
      // 重置尝试标志，允许用户通过点击“重试”再次启动初始化
      // （如果是在错误状态下）
      if (_initProvider.status == InitializationStatus.error) {
        _hasAttemptedInit = false;
        // print("InitializationWrapper: Resetting _hasAttemptedInit flag due to error.");
      }
    }
  }

  // 网络恢复后的处理逻辑
  void _handleNetworkRestored(AuthProvider authProvider) {
    // 确保组件还在树中，并且服务已成功初始化
    if (!_isMounted || _services == null) {
      return;
    }

    authProvider.refreshUserState();
  }

  // 处理“重试”按钮的点击事件
  void _handleRetry() {
    // 确保组件还在树中
    if (!_isMounted) {
      return;
    }
    // 直接重新开始完整的初始化流程
    // _startInitialization 会重置所有相关状态
    _startInitialization();
  }

  // 处理“退出”按钮的点击事件
  void _handleExit() {
    // 根据不同平台执行退出操作
    if (Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS ||
        Platform.isFuchsia) {
      exit(0); // 桌面平台直接退出进程
    } else {
      // 移动平台 (Android/iOS) 尝试弹出当前 Activity/View Controller
      SystemNavigator.pop();
      // 注意：SystemNavigator.pop() 可能并不总是符合预期，取决于应用结构
    }
  }

  @override
  void dispose() {
    //print("InitializationWrapper: dispose called.");
    _isMounted = false; // 标记组件已卸载
    // 移除 Provider 的监听器，防止内存泄漏
    _initProvider.removeListener(_onProviderUpdate);
    // Dispose Provider 自身
    _initProvider.dispose();

    // *** 清理可能设置的网络恢复回调 ***
    try {
      if (_services != null) {
        final networkManager = _services!['networkManager'] as NetworkManager?;
        if (networkManager?.onNetworkRestored != null) {
          networkManager!.onNetworkRestored = null; // 解除引用
        }
      }
    } catch (e) {
      // 捕获清理过程中的任何异常
      // print(
      //     "InitializationWrapper: Error during cleanup of network callback: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_initProvider.status) {
      case InitializationStatus.inProgress:
      case InitializationStatus.idle: // Idle 状态也视为正在加载/准备中
        // 显示初始化加载界面
        return InitializationScreen(
          status: _initProvider.status,
          message: _initProvider.message, // 显示当前加载消息
          progress: _initProvider.progress, // 显示加载进度
          onRetry: null, // 加载中不允许重试
          onExit: _handleExit, // 允许用户在加载时退出
        );

      case InitializationStatus.error:
        // 显示初始化错误界面
        return InitializationScreen(
          status: _initProvider.status,
          // 显示具体的错误信息
          message: _initProvider.message, // _initProvider.message 包含了错误信息
          // 可以考虑附加 _initializationError 获取更详细的信息，如果需要的话
          // message: "${_initProvider.message}\n${_initializationError ?? ''}",
          progress: _initProvider.progress, // 显示失败时的进度（可能无意义）
          onRetry: _handleRetry, // *** 提供重试按钮 ***
          onExit: _handleExit, // 提供退出按钮
        );

      case InitializationStatus.completed:
        // *** 初始化成功完成 ***
        // 必须确保 _services 不为 null (理论上此时它应该已经被赋值)
        if (_services != null) {
          // 调用 widget 的 onInitialized 回调，传入创建好的 Provider 列表，构建主应用界面
          return widget
              .onInitialized(AppInitializer.createProviders(_services!));
        } else {
          // *** 异常状态：状态为 completed 但服务实例丢失 ***
          // 这种情况理论上不应发生，但作为保险处理
          // 显示一个紧急错误界面，提示用户可能需要重启
          return InitializationScreen(
            status: InitializationStatus.error, // 强制显示为错误状态
            message:
                "发生意外错误：初始化状态异常 (completed but no services)。\n请尝试退出并重新启动应用。",
            progress: 0,
            onRetry: _handleRetry, // 仍然提供重试选项，虽然可能无效
            onExit: _handleExit,
          );
        }
    }
  }
}
