// lib/widgets/components/screen/profile/experience/exp_badge_widget.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class ExpBadgeWidget extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final int earnedToday;
  final double completionPercentage;
  final VoidCallback onTap;

  const ExpBadgeWidget({
    super.key,
    required this.size,
    required this.backgroundColor,
    required this.textColor,
    required this.earnedToday,
    required this.completionPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 进度圆环
              SizedBox(
                width: size * 0.8,
                height: size * 0.8,
                child: const LoadingWidget()
              ),
              // 经验值文本
              AppText(
                '$earnedToday',
                style: TextStyle(
                  color: textColor,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}