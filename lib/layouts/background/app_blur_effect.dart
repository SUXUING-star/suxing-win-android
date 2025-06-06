// lib/layouts/background/app_blur_effect.dart

import 'dart:ui';
import 'package:flutter/cupertino.dart';

class AppBlurEffect extends StatelessWidget {
  final bool isCurrentlyResizing;
  final List<Color> gradientColors;
  const AppBlurEffect({
    required this.isCurrentlyResizing,
    required this.gradientColors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 模糊和渐变叠加层
    return Offstage(
      offstage: isCurrentlyResizing,
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
    );
  }
}
