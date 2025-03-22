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
  final int missedDays; // Total missed days in the month
  final int consecutiveMissedDays; // Days since last check-in

  const LevelProgressCard({
    Key? key,
    required this.stats,
    required this.userLevel,
    required this.isLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onCheckIn,
    this.missedDays = 0, // Default missed days to 0
    this.consecutiveMissedDays = 0, // Default check-in gap to 0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelTitle = userLevel?.levelTitle ?? "茶会新人";

    // Calculate correct percentage value, ensure it's a double between 0.0 and 1.0
    double progressPercentage = 0.0;
    if (stats.levelProgress is double) {
      progressPercentage = stats.levelProgress / 100.0;
    } else if (stats.levelProgress is num) {
      progressPercentage = (stats.levelProgress as num).toDouble() / 100.0;
    }

    // Ensure percentage is within reasonable range
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
                    // Add check-in gap display (days since last check-in)
                    if (consecutiveMissedDays > 0)
                      Text(
                        '断签 $consecutiveMissedDays 天',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[400],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Level progress bar with safe percentage value
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

            // Check-in button
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