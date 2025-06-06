// lib/layouts/background/app_background_effect.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/layouts/background/app_blur_effect.dart';
import 'package:suxingchahui/layouts/background/particle_effect.dart';
import 'package:suxingchahui/providers/initialize/initialization_status.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/common/initialization_screen.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/layouts/background/mouse_trail_effect.dart';

const Key _particleEffectKey = ValueKey('global_particle_effect');

class AppBackgroundEffect extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final WindowStateProvider windowStateProvider;

  const AppBackgroundEffect({
    super.key,
    required this.child,
    required this.isDark,
    required this.windowStateProvider,
  });

  @override
  State<AppBackgroundEffect> createState() => _AppBackgroundEffectState();
}

class _AppBackgroundEffectState extends State<AppBackgroundEffect>
    with SingleTickerProviderStateMixin {
  Timer? _imageTimer;
  int _currentImageIndex = 0;
  bool _isAndroidPortrait = false;

  bool _backgroundEffectsInitialized = false;
  bool _isCurrentlyResizing = false; // 由 Stream 更新

  StreamSubscription<bool>? _resizingSubscription;

  @override
  void initState() {
    super.initState();

    _isCurrentlyResizing = widget.windowStateProvider.isResizingWindow;

    _resizingSubscription = widget.windowStateProvider.isResizingWindowStream
        .listen((isResizingFromStream) {
      if (!mounted) return;

      if (_isCurrentlyResizing != isResizingFromStream) {
        setState(() {
          _isCurrentlyResizing = isResizingFromStream;
        });

        if (isResizingFromStream) {
          if (_backgroundEffectsInitialized) {
            _cancelBackgroundEffects(); // 例如，暂停图片轮播 Timer
            // ParticleEffect 的动画会因为 Offstage 自动暂停 Ticker (大部分情况)
            // 或者 ParticleEffectState 内部可以监听 TickerMode 的变化来暂停
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isCurrentlyResizing) {
              _initializeOrRestoreBackgroundEffects(); // 例如，恢复图片轮播
              // ParticleEffect 的动画会因为 Offstage 恢复 Ticker (大部分情况)
            }
          });
        }
      }
    });

    if (!_isCurrentlyResizing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCurrentlyResizing) {
          _initializeOrRestoreBackgroundEffects();
        }
      });
    }
  }

  void _initializeOrRestoreBackgroundEffects() {
    if (!mounted || _isCurrentlyResizing) return;

    if (!_backgroundEffectsInitialized) {
      _initBackgroundEffects();
    } else {
      if (_imageTimer == null || !_imageTimer!.isActive) {
        _setupImageRotationTimer();
      }
      _checkDeviceOrientationIfNeeded();
    }
  }

  Future<void> _initBackgroundEffects() async {
    if (!mounted || _backgroundEffectsInitialized || _isCurrentlyResizing) {
      return;
    }

    _setupImageRotationTimer();
    await _checkDeviceOrientationIfNeeded();
    _backgroundEffectsInitialized = true;
  }

  void _cancelBackgroundEffects() {
    _imageTimer?.cancel();
    _imageTimer = null;
    // 注意：这里不需要手动停止粒子动画，Offstage 会处理 Ticker
    // _backgroundEffectsInitialized = false; // 这个标志根据你的逻辑决定是否重置
    // 如果只是暂停，则不应重置
    // 如果 resizing 时希望效果完全重来，则重置
    // 根据当前代码，它更像是“是否首次初始化完成”的标志
  }

  Future<void> _checkDeviceOrientationIfNeeded() async {
    if (kIsWeb || !Platform.isAndroid || !mounted) return;
    try {
      final orientation = MediaQuery.of(context).orientation;
      if (mounted) {
        final newIsPortrait = orientation == Orientation.portrait;
        if (_isAndroidPortrait != newIsPortrait) {
          setState(() {
            _isAndroidPortrait = newIsPortrait;
          });
        }
      }
    } catch (e) {
      //
    }
  }

  void _setupImageRotationTimer() {
    _imageTimer?.cancel();
    _imageTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isCurrentlyResizing) {
        // 只有非 resizing 状态才切换图片
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) %
              GlobalConstants.defaultBackgroundImages.length;
        });
      } else if (!mounted) {
        // 如果 unmounted 则取消
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _resizingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final particleColor =
        widget.isDark ? const Color(0xFFE0E0E0) : const Color(0xFFB3E5FC);

    final List<Color> gradientColors = widget.isDark
        ? [
            const Color.fromRGBO(0, 0, 0, 0.6),
            const Color.fromRGBO(0, 0, 0, 0.4)
          ]
        : [
            const Color.fromRGBO(255, 255, 255, 0.7),
            const Color.fromRGBO(255, 255, 255, 0.5)
          ];

    List<String> imagesToUse = _isAndroidPortrait
        ? GlobalConstants.defaultBackgroundImagesRotated
        : GlobalConstants.defaultBackgroundImages;

    if (imagesToUse.isEmpty && _isCurrentlyResizing) {
      // 如果没图片且在 resizing，直接返回 child
      return widget.child;
    }
    if (imagesToUse.isNotEmpty && _currentImageIndex >= imagesToUse.length) {
      _currentImageIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // 背景图片
            Offstage(
              offstage: _isCurrentlyResizing,
              child: (imagesToUse.isNotEmpty)
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Image.asset(
                        imagesToUse[_currentImageIndex],
                        key: ValueKey<int>(_currentImageIndex),
                        fit: BoxFit.cover,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[800]); // 深色占位
                        },
                      ),
                    )
                  : Container(color: Colors.transparent), // 没有图片时
            ),
            // 如果 resizing 时也需要一个基础背景色（比如避免闪烁）
            if (_isCurrentlyResizing)
              Container(
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withSafeOpacity(0.5),
              ),

            // 背景模糊
            AppBlurEffect(
                isCurrentlyResizing: _isCurrentlyResizing,
                gradientColors: gradientColors),

            // 背景特效
            ParticleEffect(
              key: _particleEffectKey, // 使用之前定义的 Key
              particleCount: GlobalConstants.defaultParticleCount,
              isCurrentlyResizing: _isCurrentlyResizing,
            ),

            // 主体内容
            widget.child,

            // 鼠标特效
            if (DeviceUtils.isDesktop)
              MouseTrailEffect(
                particleColor: particleColor,
              ),

            // 设置挡板
            if (_isCurrentlyResizing)
              Positioned.fill(
                child: InitializationScreen(
                  status: InitializationStatus.inProgress,
                  message: "正在调整窗口大小...", // 或者 "正在调整窗口大小..."
                  progress: 0.0, // 可以设为 null 如果不显示进度条
                  onRetry: null,
                  onExit: null,
                ),
              ),
          ],
        );
      },
    );
  }
}
