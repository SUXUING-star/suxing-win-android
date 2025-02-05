// lib/layouts/app_background.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        Image.asset(
          'images/bg.jpg',
          fit: BoxFit.cover,
        ),
        // 毛玻璃效果层
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10.0,
            sigmaY: 10.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark ? [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.4),
                ] : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        // 内容层
        child,
      ],
    );
  }
}