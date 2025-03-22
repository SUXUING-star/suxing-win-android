// lib/widgets/components/screen/profile/experience/exp_today_progress_card.dart

import 'package:flutter/material.dart';
import '../../../../../../../../utils/font/font_config.dart';

class ExpTodayProgressCard extends StatelessWidget {
  final int earnedToday;
  final int possibleToday;
  final int remainingToday;
  final dynamic completionPercentage;

  const ExpTodayProgressCard({
    Key? key,
    required this.earnedToday,
    required this.possibleToday,
    required this.remainingToday,
    required this.completionPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和进度值
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                      Icons.date_range,
                      size: 16,
                      color: Theme.of(context).primaryColor
                  ),
                  SizedBox(width: 8),
                  Text(
                    '今日进度',
                    style: TextStyle(
                      fontFamily: FontConfig.defaultFontFamily,
                      fontFamilyFallback: FontConfig.fontFallback,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Text(
                '$earnedToday/$possibleToday',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 进度条
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (completionPercentage as num).toDouble() / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor
                ),
                minHeight: 8,
              ),
            ),
          ),

          SizedBox(height: 8),

          // 剩余经验和完成百分比
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '还可获得: $remainingToday',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              Text(
                '${completionPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}