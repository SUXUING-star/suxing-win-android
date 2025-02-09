// lib/widgets/loading/first_load_screen.dart

import 'package:flutter/material.dart';
import '../logo/app_logo.dart';
import '../../utils/font_config.dart';

class FirstLoadScreen extends StatefulWidget {
  final String? message;

  const FirstLoadScreen({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  State<FirstLoadScreen> createState() => _FirstLoadScreenState();
}

class _FirstLoadScreenState extends State<FirstLoadScreen>
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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // 使用优化后的动画序列
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.03)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60.0,
      ),
    ]).animate(_controller);

    _startTextAnimation();
  }

  void _startTextAnimation() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return false;
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _loadingTexts.length;
        _loadingText = widget.message ?? _loadingTexts[_currentTextIndex];
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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // 背景渐变
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
            // 主要内容
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                      Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.blue[100],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                          borderRadius: BorderRadius.circular(2),
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
                            fontFamily: FontConfig.defaultFontFamily,
                            fontFamilyFallback: FontConfig.fontFallback,
                            color: Colors.blue[700],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 欢迎文本
                      Text(
                        '欢迎使用',
                        style: TextStyle(
                          fontFamily: FontConfig.defaultFontFamily,
                          fontFamilyFallback: FontConfig.fontFallback,
                          color: Colors.blue[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '宿星茶会（跨平台版）',
                        style: TextStyle(
                          color: Colors.blue[400],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}