// lib/layouts/background/app_background.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import '../effects/particle_effect.dart';

const List<String> backgroundImages = [
  'assets/images/bg-1.jpg',
  'assets/images/bg-2.jpg'
];
const List<String> backgroundImagesRotated = [
  'assets/images/bg-1rotate.jpg',
  'assets/images/bg-2rotate.jpg'
];

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  Timer? _imageTimer; // 改为 nullable，在需要时初始化
  int _currentImageIndex = 0;
  bool _isAndroidPortrait = false;

  // 标志位，确保效果的初始化只在非 resizing 状态下进行一次
  bool _backgroundEffectsInitialized = false;

  @override
  void initState() {
    super.initState();
    // initState 中不执行依赖 windowState 的初始化
  }

  Future<void> _initBackgroundEffects() async {
    if (!mounted || _backgroundEffectsInitialized) return;

    _setupImageRotation(); // 初始化并启动 Timer
    await _checkDeviceOrientation(); // 检查初始方向

    _backgroundEffectsInitialized = true; // 标记已初始化
  }

  Future<void> _checkDeviceOrientation() async {
    if (kIsWeb || !mounted) return;

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (!mounted) return;
      try {
        Orientation orientation = MediaQuery.of(context).orientation;
        if (mounted &&
            _isAndroidPortrait != (orientation == Orientation.portrait)) {
          setState(() {
            _isAndroidPortrait = orientation == Orientation.portrait;
          });
        }
      } catch (e) {
        debugPrint('AppBackground: Error getting orientation: $e');
      }
    } else if (mounted) {
      if (_isAndroidPortrait) {
        // 如果之前是 true (不太可能，但为了完备性)
        setState(() {
          _isAndroidPortrait = false;
        });
      }
    }
  }

  void _setupImageRotation() {
    // 如果之前的 Timer 存在且活动，先取消
    _imageTimer?.cancel();
    // 创建新的 Timer
    _imageTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // 确保在回调时 widget 仍然 mounted
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % backgroundImages.length;
        });
      } else {
        timer.cancel(); // 如果 widget unmounted，取消 timer
      }
    });
  }

  void _cancelImageRotation() {
    _imageTimer?.cancel();
    _imageTimer = null;
    _backgroundEffectsInitialized = false; // 允许在下次非 resizing 时重新初始化
  }

  @override
  void dispose() {
    _imageTimer?.cancel(); // 确保 Timer 在 dispose 时被取消
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final windowState = context.watch<WindowStateProvider>();

    if (windowState.isResizingWindow) {
      // 如果正在调整大小，取消图片旋转并标记效果未初始化
      if (_backgroundEffectsInitialized) {
        // 只有当效果已初始化时才取消
        _cancelImageRotation();
      }
      // 直接返回 child，不渲染任何背景效果
      return widget.child;
    } else {
      // 如果不是正在调整大小，并且效果尚未初始化，则初始化它们
      if (!_backgroundEffectsInitialized) {
        // 使用 addPostFrameCallback 确保在 build 完成后再执行异步初始化
        // 避免在 build 过程中 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !windowState.isResizingWindow) {
            // 再次检查状态，防止回调时状态已变
            _initBackgroundEffects();
          }
        });
      } else {
        // 如果效果已初始化，确保 Timer 是活动的 (例如从 resizing 状态恢复)
        if (_imageTimer == null || !_imageTimer!.isActive) {
          _setupImageRotation();
        }
        // 并且在每次 build 时（如果不是 resizing），都可能需要检查方向
        // （或者更优：只在特定条件下检查，比如路由变化或应用恢复）
        // 为了简单，这里每次非 resizing 的 build 都检查一次，但用 addPostFrameCallback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !windowState.isResizingWindow) {
            _checkDeviceOrientation();
          }
        });
      }

      // --- 正常渲染 AppBackground 的完整效果 ---
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

      // 如果 imagesToUse 为空（不太可能，但作为防御性编程）或者 _currentImageIndex 超出范围
      if (imagesToUse.isEmpty || _currentImageIndex >= imagesToUse.length) {
        // 可以返回一个占位符或者默认背景，避免崩溃
        // 这里简单返回 child，表示背景加载失败或无背景
        if (imagesToUse.isEmpty) return widget.child;
        _currentImageIndex = 0; // 重置索引
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Image.asset(
                  imagesToUse[_currentImageIndex], // 使用当前索引
                  key: ValueKey<int>(_currentImageIndex),
                  fit: BoxFit.cover,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
              ),
              BackdropFilter(
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
              ParticleEffect(particleCount: 50),
              widget.child,
            ],
          );
        },
      );
    }
  }
}
