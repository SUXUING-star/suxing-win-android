// lib/wrapper/initialization_wrapper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // 保留这个 import，虽然下面可能不用 Provider.of
import 'package:provider/single_child_widget.dart';
import '../initialization/app_initializer.dart';
import '../widgets/common/startup/initialization_screen.dart';
import '../providers/initialize/initialization_provider.dart';
import '../services/main/network/network_manager.dart';
import '../providers/auth/auth_provider.dart';

class InitializationWrapper extends StatefulWidget {
  final Widget Function(List<SingleChildWidget> providers) onInitialized;

  const InitializationWrapper({
    Key? key,
    required this.onInitialized,
  }) : super(key: key);

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  late final InitializationProvider _initProvider;
  bool _isInitialized = false;
  Map<String, dynamic>? _services;
  bool _needsNetworkReinitialization = false;

  @override
  void initState() {
    super.initState();
    _initProvider = InitializationProvider();
    // *** 添加监听器 ***
    _initProvider.addListener(_onProviderUpdate);
    _startInitialization();
  }

  // *** Provider 更新时的回调 ***
  void _onProviderUpdate() {
    // 检查 widget 是否还在树中，并且状态不是已完成 (避免初始化完成后还触发重建)
    // 或者即使完成了，如果 isInitialized 状态还没更新，也需要重建一次来切换到主App
    if (mounted && (_initProvider.status != InitializationStatus.completed || !_isInitialized)) {
      setState(() {
        // 调用 setState 会触发 build 方法重新执行
        // 这样 InitializationScreen 就能获取到最新的 provider 状态
      });
    }
    // 如果初始化已经完成，并且 _isInitialized 也已经是 true，就不再需要因为 provider 更新而重建了
    // 但是检查一下，如果 status 是 completed 但 isInitialized 还没置 true，需要处理
    if (mounted && _initProvider.status == InitializationStatus.completed && !_isInitialized) {
      setState(() {
        _isInitialized = true; // 确保状态同步
      });
    }
  }


  Future<void> _startInitialization() async {
    // 注意：这里不再需要检查 _isInitialized，因为 build 方法会根据 provider 状态决定显示什么
    // if (_isInitialized) return;

    try {
      _services = await AppInitializer.initializeServices(_initProvider);

      final networkManager = _services?['networkManager'] as NetworkManager?;
      if (networkManager != null) {
        networkManager.onNetworkRestored = _reinitializeNetworkServices;
      }
      _initProvider.setCompleted(); // 在这里设置完成状态

    } catch (e) {
      if (mounted) {
        if (e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('timeout') ||
            e.toString().toLowerCase().contains('socket')) {
          _needsNetworkReinitialization = true;
        }
        // 设置错误状态，_onProviderUpdate 会监听到并触发 setState
        _initProvider.setError(e.toString());
      }
    }
  }


  Future<void> _reinitializeNetworkServices() async {
    if (!_needsNetworkReinitialization || _services == null) return;

    try {
      _initProvider.reset(); // 重置状态，会触发 setState
      _initProvider.updateProgress('网络已恢复，正在重新初始化服务...', 0.3); // 更新进度，会触发 setState

      final newServices = await AppInitializer.reinitializeNetworkServices(_initProvider);

      if (_services != null && newServices.isNotEmpty) {
        _services = AppInitializer.updateServices(_services!, newServices);
        final authProvider = _services!['authProvider'] as AuthProvider?;
        authProvider?.refreshUserState();
      }

      if (mounted) {
        _needsNetworkReinitialization = false;
        _initProvider.setCompleted(); // 设置完成状态
      }
    } catch (e) {
      print('无法重新初始化网络服务: $e');
      if(mounted){
        _initProvider.setError('重新初始化网络服务失败: $e'); // 设置错误状态
      }
    }
  }

  void _handleRetry() {
    if (!mounted) return;
    // *** 重置状态，让 build 方法重新显示 Loading ***
    setState(() {
      // _isInitialized = false; // isInitialized 由 provider 状态决定
      _services = null;
      _needsNetworkReinitialization = false;
      _initProvider.reset(); // 重置 provider 状态，会触发监听器->setState
      // 不需要手动调用 _startInitialization，因为 reset 会触发 setState，
      // build 方法会根据新的 state (inProgress) 决定是否显示 loading
      // 但我们需要重新开始初始化过程
    });
    // 需要延迟一下确保UI更新后再开始，或者直接开始也行
    _startInitialization();
  }

  void _handleExit() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    // *** 移除监听器 ***
    _initProvider.removeListener(_onProviderUpdate);
    _initProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // *** 根据 provider 的状态来决定显示什么 ***
    if (_initProvider.status == InitializationStatus.completed && _services != null) {
      // 确保 _isInitialized 也同步更新了 (虽然理论上 _onProviderUpdate 会处理)
      if (!_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() { _isInitialized = true; });
          }
        });
        // 在下一帧更新前，先显示加载（或一个空的 SizedBox）避免错误
        return const SizedBox.shrink();
      }
      // 初始化完成，显示主 App
      return widget.onInitialized(AppInitializer.createProviders(_services!));
    }

    // 初始化未完成或出错，显示 InitializationScreen
    // 它会从 _initProvider 获取最新的状态信息，因为 setState 被调用了
    return Directionality(
      textDirection: TextDirection.ltr,
      child: InitializationScreen(
        status: _initProvider.status,
        message: _initProvider.message,
        progress: _initProvider.progress,
        onRetry: _initProvider.status == InitializationStatus.error ? _handleRetry : null,
        onExit: _handleExit,
      ),
    );
  }
}