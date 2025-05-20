// lib/widgets/components/screen/checkin/progress/level_progress_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/models/user/user.dart'; // **导入 User 模型**
import '../../../../../models/user/user_checkin.dart'; // 导入修改后的 CheckInStats
// import '../../../../../models/user/user_level.dart'; // <--- 删除 UserLevel 导入
import '../checkin_button.dart'; // 导入签到按钮
import 'level_progress_bar.dart'; // 导入进度条

class LevelProgressCard extends StatelessWidget {
  final CheckInStats stats;
  final User currentUser;
  final bool isLoading; // 签到按钮的加载状态
  final bool hasCheckedToday;
  final AnimationController animationController;
  final VoidCallback onCheckIn;
  final int missedDays;
  final int consecutiveMissedDays; // 这个卡片会用到

  const LevelProgressCard({
    super.key,
    required this.stats,
    required this.currentUser,
    required this.isLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onCheckIn,
    this.missedDays = 0,
    this.consecutiveMissedDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- 直接从 currentUser 获取等级/经验信息 ---
    final int level = currentUser.level;
    final int currentExp = currentUser.experience; // 用户总经验
    final int requiredExp = currentUser.nextLevelExp; // 下一级所需总经验
    // 使用后端算好的进度百分比，并确保范围
    final double progressPercentage =
        (currentUser.levelProgress / 100.0).clamp(0.0, 1.0);
    final int expToNextLevel = currentUser.expToNextLevel;
    final bool isMaxLevel = currentUser.isMaxLevel; // 获取是否满级状态

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
              // 顶部信息区域
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  // 左侧：等级信息
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '等级 $level', // **使用 currentUser.level**
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold), // 加粗
                    ),
                    Text(
                      LevelUtils.getLevelDescription(level), // **使用计算出的 title**
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  // 右侧：签到天数 (从 CheckInStats 获取)
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '累计签到 ${stats.totalCheckIns} 天',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                    if (consecutiveMissedDays > 1) // 使用传入的断签天数
                      Text(
                        '断签 $consecutiveMissedDays 天',
                        style: TextStyle(fontSize: 14, color: Colors.red[400]),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- 等级进度条 (使用 currentUser 的数据) ---
            LevelProgressBar(
              level: level,
              current: currentExp, // 传递当前总经验
              total: requiredExp, // 传递下一级所需总经验
              percentage: progressPercentage, // 传递计算好的百分比
            ),

            const SizedBox(height: 8),

            // --- 升级提示 (处理满级情况) ---
            Text(
              isMaxLevel
                  ? '已达到最高等级'
                  : '还需 $expToNextLevel 经验升级', // **使用 currentUser.expToNextLevel**
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            // --- 结束升级提示 ---

            const SizedBox(height: 16),

            // --- 签到按钮 (nextReward 来自 stats) ---
            CheckInButton(
              hasCheckedToday: hasCheckedToday,
              isLoading: isLoading, // 这是签到按钮的 loading 状态
              animationController: animationController,
              nextReward: stats.nextRewardExp, // **下次签到奖励来自 CheckInStats**
              onPressed: onCheckIn,
            ),
            // --- 结束签到按钮 ---
          ],
        ),
      ),
    );
  }
}
