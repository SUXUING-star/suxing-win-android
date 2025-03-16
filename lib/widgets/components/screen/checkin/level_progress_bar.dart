// lib/widgets/components/screen/checkin/level_progress_bar.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LevelProgressBar extends StatelessWidget {
  final int level;
  final int current;
  final int total;
  final double percentage;

  const LevelProgressBar({
    Key? key,
    required this.level,
    required this.current,
    required this.total,
    required this.percentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根据等级选择颜色
    Color levelColor = theme.primaryColor;
    if (level > 20) {
      levelColor = Colors.amberAccent.shade700;
    } else if (level > 15) {
      levelColor = Colors.orangeAccent.shade700;
    } else if (level > 10) {
      levelColor = Colors.purpleAccent.shade700;
    } else if (level > 5) {
      levelColor = Colors.greenAccent.shade700;
    }

    // 安全的百分比值
    final widthFactor = percentage.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '当前经验: $current/$total',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '进度: ${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 进度条
        Stack(
          children: [
            // 背景
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // 进度
            FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      levelColor.withOpacity(0.7),
                      levelColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}