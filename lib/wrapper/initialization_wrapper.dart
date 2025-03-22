// lib/wrapper/initialization_wrapper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../initialization/app_initializer.dart';
import '../widgets/common/startup/initialization_screen.dart';
import '../providers/initialize/initialization_provider.dart';
import '../services/main/network/network_manager.dart';
import '../providers/auth/auth_provider.dart';

class InitializationWrapper extends StatefulWidget {
  // 修改为接收 SingleChildWidget 列表而不是 ChangeNotifierProvider 列表
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
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    if (_isInitialized) return;

    try {
      _services = await AppInitializer.initializeServices(_initProvider);

      // 获取NetworkManager实例并设置网络恢复回调
      final networkManager = _services?['networkManager'] as NetworkManager?;
      if (networkManager != null) {
        networkManager.onNetworkRestored = _reinitializeNetworkServices;
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initProvider.setCompleted();
        });
      }
    } catch (e) {
      if (mounted) {
        // 检查是否为网络相关错误
        if (e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('timeout') ||
            e.toString().toLowerCase().contains('socket')) {
          _needsNetworkReinitialization = true;
        }
        _initProvider.setError(e.toString());
      }
    }
  }

  // 重新初始化网络依赖的服务
// 在 initialization_wrapper.dart 中

  Future<void> _reinitializeNetworkServices() async {
    if (!_needsNetworkReinitialization || _services == null) return;

    try {
      _initProvider.reset();
      _initProvider.updateProgress('网络已恢复，正在重新初始化服务...', 0.3);

      // 重新初始化网络依赖服务
      final newServices = await AppInitializer.reinitializeNetworkServices(_initProvider);

      // 更新服务映射
      if (_services != null && newServices.isNotEmpty) {
        _services = AppInitializer.updateServices(_services!, newServices);

        // 通知 AuthProvider
        final authProvider = _services!['authProvider'] as AuthProvider?;
        if (authProvider != null) {
          // 尝试重新登录或刷新状态
          authProvider.refreshUserState();
        }
      }

      if (mounted) {
        setState(() {
          _needsNetworkReinitialization = false;
          _isInitialized = true;
          _initProvider.setCompleted();
        });
      }
    } catch (e) {
      print('无法重新初始化网络服务: $e');
    }
  }

  void _handleRetry() {
    if (!mounted) return;
    setState(() {
      _isInitialized = false;
      _services = null;
      _needsNetworkReinitialization = false;
      _initProvider.reset();
      _startInitialization();
    });
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
    _initProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _services != null) {
      // 使用新的 createProviders 方法，该方法返回合并后的 SingleChildWidget 列表
      return widget.onInitialized(AppInitializer.createProviders(_services!));
    }

    // 添加Directionality以避免错误
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