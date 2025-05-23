// lib/layouts/background/app_background.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'dart:async';
import 'dart:io'; // For Platform
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:suxingchahui/providers/windows/window_state_provider.dart'; // 必须导入
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../effects/particle_effect.dart';

// 背景图片列表
const List<String> backgroundImages = [
  'assets/images/bg-1.jpg',
  'assets/images/bg-2.jpg'
];
const List<String> backgroundImagesRotated = [
  'assets/images/bg-1rotate.jpg',
  'assets/images/bg-2rotate.jpg'
];

// ⭐ 给 ParticleEffect 一个固定的 Key
const Key _particleEffectKey = ValueKey('global_particle_effect');

class AppBackground extends StatefulWidget {
  final Widget child;
  final WindowStateProvider windowStateProvider;

  const AppBackground({
    super.key,
    required this.child,
    required this.windowStateProvider,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
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
    if (!mounted || _backgroundEffectsInitialized || _isCurrentlyResizing)
      return;

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
          _currentImageIndex =
              (_currentImageIndex + 1) % backgroundImages.length;
        });
      } else if (!mounted) {
        // 如果 unmounted 则取消
        timer.cancel();
      }
      // 如果正在 resizing，timer 依然运行，但不会 setState 切换图片
      // 或者在 _cancelBackgroundEffects 里直接取消 timer
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> gradientColors = isDark
        ? [
            const Color.fromRGBO(0, 0, 0, 0.6),
            const Color.fromRGBO(0, 0, 0, 0.4)
          ]
        : [
            const Color.fromRGBO(255, 255, 255, 0.7),
            const Color.fromRGBO(255, 255, 255, 0.5)
          ];

    List<String> imagesToUse =
        _isAndroidPortrait ? backgroundImagesRotated : backgroundImages;

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
            // 背景图片切换动画
            // 当 resizing 时，不显示 AnimatedSwitcher，可以显示一个静态占位或透明
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
                // 根据主题给一个非常简单的背景色，避免完全透明导致内容“浮”在最底层
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withSafeOpacity(0.5),
              ),

            // 模糊和渐变叠加层
            Offstage(
              offstage: _isCurrentlyResizing,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // ⭐ 粒子效果：使用 Offstage 控制显隐，并给一个固定的 Key
            Offstage(
              offstage: _isCurrentlyResizing,
              child: ParticleEffect(
                key: _particleEffectKey, // 使用之前定义的 Key
                particleCount: 50,
              ),
            ),

            // 应用主内容
            widget.child,
          ],
        );
      },
    );
  }
}
