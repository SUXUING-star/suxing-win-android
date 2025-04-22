// lib/widgets/components/level/level_progress_bar.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LevelProgressBar extends StatelessWidget {
  final int level;
  final int current;
  final int total;
  final double percentage;

  const LevelProgressBar({
    super.key,
    required this.level,
    required this.current,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根据等级选择颜色
    Color levelColor = theme.colorScheme.primary;
    switch (level % 5) {
      case 0: // 5, 10, 15, ...
        levelColor = Colors.amberAccent.shade700;
        break;
      case 1: // 1, 6, 11, ...
        levelColor = theme.colorScheme.primary;
        break;
      case 2: // 2, 7, 12, ...
        levelColor = Colors.greenAccent.shade700;
        break;
      case 3: // 3, 8, 13, ...
        levelColor = Colors.purpleAccent.shade700;
        break;
      case 4: // 4, 9, 14, ...
        levelColor = Colors.orangeAccent.shade700;
        break;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '当前经验: $current/$total',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '进度: ${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall,
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
              widthFactor: math.min(percentage, 1.0),
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