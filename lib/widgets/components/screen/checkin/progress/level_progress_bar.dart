// lib/widgets/components/screen/checkin/progress/level_progress_bar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';


import 'package:suxingchahui/models/user/user/enrich_level.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class LevelProgressBar extends StatelessWidget {
  final EnrichLevel enrichLevel;
  final int current;
  final int total;
  final double percentage;

  const LevelProgressBar({
    super.key,
    required this.enrichLevel,
    required this.current,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    // 根据等级选择颜色
    Color levelColor = enrichLevel.backgroundColor;
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
                      levelColor.withSafeOpacity(0.7),
                      levelColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withSafeOpacity(0.3),
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
