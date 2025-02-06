// lib/widgets/common/loading_screen.dart
import 'package:flutter/material.dart';
import '../logo/app_logo.dart';
import 'package:suxingchahui/widgets/logo/app_logo.dart';

class LoadingScreen extends StatefulWidget {
  final bool isLoading;
  final bool isFirstLoad;
  final String? message;

  const LoadingScreen({
    Key? key,
    required this.isLoading,
    this.isFirstLoad = false,
    this.message,
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  String _loadingText = '初始化应用...';
  int _currentTextIndex = 0;
  final List<String> _loadingTexts = ['初始化应用...', '加载资源...', '准备就绪...'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isFirstLoad) {
      _startTextAnimation();
    }
  }

  void _startTextAnimation() {
    Future.doWhile(() async {
      if (!mounted || !widget.isLoading) return false;
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return false;
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _loadingTexts.length;
        _loadingText = _loadingTexts[_currentTextIndex];
      });
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();

    return widget.isFirstLoad ? _buildFirstLoadScreen() : _buildNormalLoadingScreen();
  }

  Widget _buildFirstLoadScreen() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: widget.isLoading ? 1.0 : 0.0,
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // 背景装饰
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[50]!,
                      Colors.blue[100]!,
                    ],
                  ),
                ),
              ),
            ),
            // 主要加载内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 动画
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          child: AppLogo(size: 48),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // 进度条
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.blue[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 加载文本
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _loadingText,
                      key: ValueKey<String>(_loadingText),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 欢迎文本
                  Text(
                    '欢迎使用',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalLoadingScreen() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 自定义进度指示器
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor.withOpacity(0.2),
                                ),
                              ),
                            ),
                            SizedBox.expand(
                              child: RotationTransition(
                                turns: _controller,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 加载文本
                      DefaultTextStyle(
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8) ?? Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        child: Text(widget.message ?? '加载中...'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}