// lib/widgets/components/screen/profile/level_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../../../../utils/font/font_config.dart';

class LevelProgressBar extends StatelessWidget {
  final User user;
  final double width;
  final bool isDesktop;

  const LevelProgressBar({
    super.key,
    required this.user,
    this.width = 300,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progressHeight = isDesktop ? 8.0 : 6.0;
    final double fontSize = isDesktop ? 14.0 : 12.0;
    final double infoFontSize = isDesktop ? 14.0 : 12.0;
    final double iconSize = isDesktop ? 16.0 : 14.0;

    final int level = user.level;
    final int nextLevel = level + 1;
    final int currentExp = user.experience;
    final int requiredExp = user.nextLevelExp;
    final int expToNextLevel = user.expToNextLevel;
    final bool isMaxLevel = user.isMaxLevel;

    //直接使用后端算好的 levelProgress 百分比
    final double expPercentage = (user.levelProgress / 100.0).clamp(0.0, 1.0);

    return GestureDetector(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  /* 等级显示 */
                  mainAxisSize: MainAxisSize.min,
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
                Row(
                  /* 经验值显示 */
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMaxLevel
                          ? '$currentExp XP (已满级)'
                          : '$currentExp / $requiredExp XP',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: infoFontSize,
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline,
                        size: iconSize, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              /* 进度条 */
              height: progressHeight,
              child: Stack(
                children: [
                  Container(
                    /* 背景条 */
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(progressHeight / 2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: expPercentage,
                    child: Container(
                      /* 进度条前景 */
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withSafeOpacity(0.7),
                            theme.primaryColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(progressHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withSafeOpacity(0.2),
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
            const SizedBox(height: 3),
            Center(
              /* 提示文字 */
              child: AppText(
                '升级还需 $expToNextLevel 经验',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: infoFontSize - 1,
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
