// lib/widgets/components/screen/profile/level_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart'; // **只需要导入 User 模型**
import '../../../../../utils/font/font_config.dart';
import 'level_rules_dialog.dart'; // 保留规则弹窗的导入

// --- 改为 StatelessWidget ---
class LevelProgressBar extends StatelessWidget {
  final User user; // **直接接收 User 对象**
  final double width;
  final bool isDesktop; // 保留桌面端标识，用于调整样式

  const LevelProgressBar({
    super.key,
    required this.user, // **参数类型改为 User**
    this.width = 300,
    this.isDesktop = false,
  });

  // --- 显示等级规则弹窗的方法 ---
  void _showLevelRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LevelRulesDialog(
        currentLevel: user.level, // **直接从 user 对象获取当前等级**
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- 样式变量 (保持不变) ---
    final double progressHeight = isDesktop ? 8.0 : 6.0;
    final double fontSize = isDesktop ? 14.0 : 12.0;
    final double infoFontSize = isDesktop ? 12.0 : 10.0;
    final double iconSize = isDesktop ? 16.0 : 14.0;

    // --- 直接从传入的 user 对象获取数据 ---
    final int level = user.level;
    final int nextLevel = level + 1; // 下一级（用于显示）
    // 使用后端计算好的百分比，并确保范围
    final double expPercentage = (user.levelProgress / 100.0).clamp(0.0, 1.0);
    final int currentExp = user.experience; // 显示用户的总经验
    final int requiredExp = user.nextLevelExp; // 显示下一级需要的总经验
    final int expToNextLevel = user.expToNextLevel; // 显示还差多少经验
    final bool isMaxLevel = user.isMaxLevel; // 获取是否满级状态

    // --- 不再需要 _isLoading 判断 ---

    return GestureDetector( // 点击区域触发规则弹窗
      onTap: () => _showLevelRulesDialog(context), // 传递 context
      child: Container(
        width: width, // 使用传入的宽度
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. 等级信息和经验值显示 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧：等级 Lv.X -> Lv.Y
                Row(
                  mainAxisSize: MainAxisSize.min, // 防止过度伸展
                  children: [
                    Text(
                      'Lv.$level',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                      ),
                    ),
                    // 如果不是最高级，显示箭头和下一级
                    if (!isMaxLevel)
                      Text(
                        ' → Lv.$nextLevel',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: fontSize,
                          fontFamily: FontConfig.defaultFontFamily,
                          fontFamilyFallback: FontConfig.fontFallback,
                        ),
                      ),
                  ],
                ),
                // 右侧：经验值 当前总经验 / 下一级所需总经验
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMaxLevel ? '$currentExp XP (已满级)' : '$currentExp / $requiredExp XP', // 显示总经验和目标，满级时提示
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: infoFontSize,
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                      ),
                      overflow: TextOverflow.ellipsis, // 防止数字过长溢出
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: iconSize, color: Colors.grey[600]), // 信息图标
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6), // 间距

            // --- 2. 进度条 ---
            SizedBox( // 限制进度条高度
              height: progressHeight,
              child: Stack(
                children: [
                  // 背景条
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(progressHeight / 2),
                    ),
                  ),
                  // 进度条 (使用 FractionallySizedBox 控制宽度)
                  FractionallySizedBox(
                    widthFactor: expPercentage, // 使用计算好的百分比
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.7),
                            theme.primaryColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(progressHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.2), // 浅阴影
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3), // 进度条和提示文字间距

            // --- 3. 点击提示 / 升级提示 ---
            Center(
              child: Text(
                isMaxLevel ? '' : '升级还需 $expToNextLevel 经验 | 点击查看等级规则', // 满级时不显示升级提示
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: infoFontSize - 1, // 字体稍小
                  // fontStyle: FontStyle.italic,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}