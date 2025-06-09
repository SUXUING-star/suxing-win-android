// lib/layouts/background/app_background_effect.dart

/// 该文件定义了 AppBackgroundEffect 组件，用于管理应用背景的视觉效果。
/// AppBackgroundEffect 根据窗口状态应用背景图片轮播、模糊、粒子效果和鼠标拖尾效果。
library;

import 'dart:async'; // 异步操作所需
import 'dart:io'; // 平台检测所需

import 'package:flutter/foundation.dart'; // Flutter 基础工具
import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/constants/global_constants.dart'; // 全局常量
import 'package:suxingchahui/layouts/background/app_blur_effect.dart'; // 应用模糊效果
import 'package:suxingchahui/layouts/background/particle_effect.dart'; // 粒子效果
import 'package:suxingchahui/providers/initialize/initialization_status.dart'; // 初始化状态
import 'package:suxingchahui/providers/windows/window_state_provider.dart'; // 窗口状态 Provider
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类
import 'package:suxingchahui/widgets/ui/common/initialization_screen.dart'; // 初始化屏幕
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展
import 'package:suxingchahui/layouts/background/mouse_trail_effect.dart'; // 鼠标拖尾效果

const Key _particleEffectKey =
    ValueKey('global_particle_effect'); // 粒子效果的全局 Key

/// `AppBackgroundEffect` 类：应用背景效果组件。
///
/// 该组件根据窗口调整大小状态、设备方向和主题，
/// 动态显示背景图片、模糊效果、粒子效果和鼠标拖尾效果。
class AppBackgroundEffect extends StatefulWidget {
  final Widget child; // 子组件
  final List<Color> backgroundGradientColor;
  final Color particleColor;
  final WindowStateProvider windowStateProvider; // 窗口状态 Provider 实例

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [child]：子组件。
  /// [isDark]：是否为深色模式。
  /// [windowStateProvider]：窗口状态 Provider 实例。
  const AppBackgroundEffect({
    super.key,
    required this.backgroundGradientColor,
    required this.particleColor,
    required this.windowStateProvider,
    required this.child,
  });

  /// 创建 `_AppBackgroundEffectState` 状态。
  @override
  State<AppBackgroundEffect> createState() => _AppBackgroundEffectState();
}

/// `_AppBackgroundEffectState` 类：`AppBackgroundEffect` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class _AppBackgroundEffectState extends State<AppBackgroundEffect>
    with SingleTickerProviderStateMixin {
  Timer? _imageTimer; // 图片轮播定时器
  int _currentImageIndex = 0; // 当前背景图片索引
  bool _isAndroidPortrait = false; // 标识是否为 Android 竖屏

  bool _backgroundEffectsInitialized = false; // 背景效果是否已初始化
  bool _isCurrentlyResizing = false; // 标识窗口是否正在调整大小

  StreamSubscription<bool>? _resizingSubscription; // 窗口调整大小状态变化的订阅器

  /// 初始化状态。
  ///
  /// 监听窗口调整大小状态，并根据状态暂停或恢复背景效果。
  /// 在组件首次渲染后初始化或恢复背景效果。
  @override
  void initState() {
    super.initState();

    _isCurrentlyResizing =
        widget.windowStateProvider.isResizingWindow; // 获取初始调整大小状态

    _resizingSubscription = widget.windowStateProvider.isResizingWindowStream
        .listen((isResizingFromStream) {
      // 监听窗口调整大小状态变化
      if (!mounted) return; // 组件未挂载时返回

      if (_isCurrentlyResizing != isResizingFromStream) {
        // 状态发生变化时
        setState(() {
          _isCurrentlyResizing = isResizingFromStream; // 更新调整大小状态
        });

        if (isResizingFromStream) {
          // 正在调整大小
          if (_backgroundEffectsInitialized) {
            _cancelBackgroundEffects(); // 取消背景效果，例如暂停图片轮播
          }
        } else {
          // 停止调整大小
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 在下一帧回调中
            if (mounted && !_isCurrentlyResizing) {
              // 组件已挂载且未调整大小时
              _initializeOrRestoreBackgroundEffects(); // 初始化或恢复背景效果
            }
          });
        }
      }
    });

    if (!_isCurrentlyResizing) {
      // 初始未调整大小时
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 在下一帧回调中
        if (mounted && !_isCurrentlyResizing) {
          // 组件已挂载且未调整大小时
          _initializeOrRestoreBackgroundEffects(); // 初始化或恢复背景效果
        }
      });
    }
  }

  /// 初始化或恢复背景效果。
  ///
  /// 如果未初始化，则进行初始化；否则，如果图片轮播未激活，则恢复轮播。
  void _initializeOrRestoreBackgroundEffects() {
    if (!mounted || _isCurrentlyResizing) return; // 组件未挂载或正在调整大小时返回

    if (!_backgroundEffectsInitialized) {
      // 未初始化时
      _initBackgroundEffects(); // 初始化背景效果
    } else {
      // 已初始化时
      if (_imageTimer == null || !_imageTimer!.isActive) {
        // 图片轮播未激活
        _setupImageRotationTimer(); // 设置图片轮播定时器
      }
      _checkDeviceOrientationIfNeeded(); // 检查设备方向
    }
  }

  /// 初始化背景效果。
  ///
  /// 设置图片轮播定时器并检查设备方向。
  void _initBackgroundEffects() async {
    if (!mounted || _backgroundEffectsInitialized || _isCurrentlyResizing) {
      // 检查条件
      return;
    }

    _setupImageRotationTimer(); // 设置图片轮播定时器
    await _checkDeviceOrientationIfNeeded(); // 检查设备方向
    _backgroundEffectsInitialized = true; // 标记为已初始化
  }

  /// 取消背景效果。
  ///
  /// 取消图片轮播定时器。
  void _cancelBackgroundEffects() {
    _imageTimer?.cancel(); // 取消图片轮播定时器
    _imageTimer = null; // 清除定时器引用
  }

  /// 检查设备方向。
  ///
  /// 仅在 Android 平台检查设备方向，并更新 `_isAndroidPortrait` 状态。
  Future<void> _checkDeviceOrientationIfNeeded() async {
    if (kIsWeb || !Platform.isAndroid || !mounted) return; // 仅在 Android 平台检查
    try {
      final orientation = MediaQuery.of(context).orientation; // 获取设备方向
      if (mounted) {
        // 组件已挂载时
        final newIsPortrait = orientation == Orientation.portrait; // 判断是否为竖屏
        if (_isAndroidPortrait != newIsPortrait) {
          // 方向发生变化时
          setState(() {
            _isAndroidPortrait = newIsPortrait; // 更新竖屏状态
          });
        }
      }
    } catch (e) {
      // 捕获错误
    }
  }

  /// 设置图片轮播定时器。
  ///
  /// 定期切换背景图片。
  void _setupImageRotationTimer() {
    _imageTimer?.cancel(); // 取消旧定时器
    _imageTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // 启动新定时器
      if (mounted && !_isCurrentlyResizing) {
        // 组件已挂载且未调整大小时
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) %
              GlobalConstants.defaultBackgroundImages.length; // 切换到下一张图片
        });
      } else if (!mounted) {
        // 组件未挂载时
        timer.cancel(); // 取消定时器
      }
    });
  }

  /// 销毁状态。
  ///
  /// 销毁图片轮播定时器和窗口调整大小订阅器。
  @override
  void dispose() {
    _imageTimer?.cancel(); // 销毁图片轮播定时器
    _resizingSubscription?.cancel(); // 销毁窗口调整大小订阅器
    super.dispose();
  }

  /// 构建应用背景效果 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `Stack` 组件，包含背景图片、模糊效果、粒子效果、主内容和鼠标拖尾效果。
  @override
  Widget build(BuildContext context) {
    List<String> imagesToUse = _isAndroidPortrait // 根据设备方向选择背景图片
        ? GlobalConstants.defaultBackgroundImagesRotated
        : GlobalConstants.defaultBackgroundImages;

    if (imagesToUse.isEmpty || _isCurrentlyResizing) {
      // 无图片且正在调整大小时
      return Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: InitializationScreen(
              status: InitializationStatus.inProgress,
              message: "正在调整窗口大小...",
              progress: 0.0,
              onRetry: null,
              onExit: null,
            ),
          ),
        ],
      );
    }
    if (imagesToUse.isNotEmpty && _currentImageIndex >= imagesToUse.length) {
      // 图片索引超出范围时
      _currentImageIndex = 0; // 重置索引
    }

    return LayoutBuilder(
      // 布局构建器
      builder: (context, constraints) {
        final Widget backgroundImage = Offstage(
          // 背景图片
          offstage: _isCurrentlyResizing, // 窗口调整大小时隐藏
          child: (imagesToUse.isNotEmpty)
              ? AnimatedSwitcher(
                  // 动画切换器
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                        opacity: animation, child: child); // 淡入过渡
                  },
                  child: Image.asset(
                    // 图片资源
                    imagesToUse[_currentImageIndex],
                    key: ValueKey<int>(_currentImageIndex),
                    fit: BoxFit.cover, // 覆盖填充
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    errorBuilder: (context, error, stackTrace) {
                      // 图片加载错误时
                      return Container(color: Colors.grey[800]); // 显示深色占位
                    },
                  ),
                )
              : Container(color: Colors.transparent), // 无图片时显示透明容器
        );
        return Stack(
          // 堆叠布局
          fit: StackFit.expand, // 填充父组件
          children: [
            backgroundImage,
            if (_isCurrentlyResizing) // 窗口调整大小时显示背景色
              Container(
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withSafeOpacity(0.5),
              ),

            AppBlurEffect(
              // 背景模糊
              isCurrentlyResizing: _isCurrentlyResizing,
              gradientColors: widget.backgroundGradientColor,
            ),

            ParticleEffect(
              // 背景粒子特效
              key: _particleEffectKey,
              particleCount: GlobalConstants.defaultParticleCount,
              isCurrentlyResizing: _isCurrentlyResizing,
            ),

            widget.child, // 主体内容

            if (DeviceUtils.isDesktop) // 桌面端显示鼠标特效
              MouseTrailEffect(
                particleColor: widget.particleColor,
              ),
          ],
        );
      },
    );
  }
}
