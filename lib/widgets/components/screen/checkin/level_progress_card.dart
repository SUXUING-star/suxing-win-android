// lib/widgets/components/screen/checkin/level_progress_card.dart
import 'package:flutter/material.dart';
import '../../../../models/user/user_checkin.dart';
import '../../../../models/user/user_level.dart';
import 'checkin_button.dart';
import 'level_progress_bar.dart';

class LevelProgressCard extends StatelessWidget {
  final CheckInStats stats;
  final UserLevel? userLevel;
  final bool isLoading;
  final bool hasCheckedToday;
  final AnimationController animationController;
  final VoidCallback onCheckIn;

  const LevelProgressCard({
    Key? key,
    required this.stats,
    required this.userLevel,
    required this.isLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onCheckIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelTitle = userLevel?.levelTitle ?? "茶会新人";

    // 计算正确的百分比值，确保它是0.0到1.0之间的一个double
    double progressPercentage = 0.0;
    if (stats.levelProgress is double) {
      progressPercentage = stats.levelProgress / 100.0;
    } else if (stats.levelProgress is num) {
      progressPercentage = (stats.levelProgress as num).toDouble() / 100.0;
    }

    // 确保百分比在合理范围内
    progressPercentage = progressPercentage.clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '等级 ${stats.level}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      levelTitle,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '累计签到 ${stats.totalCheckIns} 天',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '连续签到 ${stats.continuousDays} 天',
                      style: TextStyle(
                        fontSize: 14,
                        color: stats.continuousDays > 0
                            ? theme.primaryColor
                            : Colors.grey[700],
                        fontWeight: stats.continuousDays > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 等级进度条 - 使用安全的百分比值
            LevelProgressBar(
              level: stats.level,
              current: stats.currentExp,
              total: stats.requiredExp,
              percentage: progressPercentage,
            ),

            const SizedBox(height: 8),

            Text(
              '还需 ${stats.requiredExp - stats.currentExp} 经验升级',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // 签到按钮
            CheckInButton(
              hasCheckedToday: hasCheckedToday,
              isLoading: isLoading,
              animationController: animationController,
              nextReward: stats.nextRewardExp,
              onPressed: onCheckIn,
            ),
          ],
        ),
      ),
    );
  }
}