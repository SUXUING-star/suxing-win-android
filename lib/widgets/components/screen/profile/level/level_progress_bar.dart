// lib/widgets/components/screen/profile/level_progress_bar.dart

import 'package:flutter/material.dart';
import '../../../../../models/user/user.dart';
import '../../../../../models/user/user_level.dart';
import '../../../../../services/main/user/user_level_service.dart';
import '../../../../../utils/font/font_config.dart';
import 'level_rules_dialog.dart';

class LevelProgressBar extends StatefulWidget {
  final User user;
  final double width;
  final bool isDesktop;

  const LevelProgressBar({
    Key? key,
    required this.user,
    this.width = 300,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  _LevelProgressBarState createState() => _LevelProgressBarState();
}

class _LevelProgressBarState extends State<LevelProgressBar> {
  final UserLevelService _levelService = UserLevelService();
  UserLevel? _userLevel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLevelInfo();
  }

  Future<void> _loadUserLevelInfo() async {
    try {
      final level = await _levelService.getUserLevel();
      if (mounted) {
        setState(() {
          _userLevel = level;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLevelRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => LevelRulesDialog(
        currentLevel: _userLevel?.level ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 为桌面端和移动端使用不同的尺寸设置
    final double progressHeight = widget.isDesktop ? 8.0 : 6.0;
    final double fontSize = widget.isDesktop ? 14.0 : 12.0;
    final double infoFontSize = widget.isDesktop ? 12.0 : 10.0;
    final double iconSize = widget.isDesktop ? 16.0 : 14.0;

    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final level = _userLevel?.level ?? 1;
    final nextLevel = level + 1;
    final expPercentage = _userLevel?.expPercentage ?? 0.0;
    final currentExp = _userLevel?.currentExp ?? 0;
    final requiredExp = _userLevel?.requiredExp ?? 1000;

    return GestureDetector(
      onTap: _showLevelRulesDialog,
      child: Container(
        width: widget.width,
        padding: EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 等级信息和经验值
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                  children: [
                    Text(
                      '$currentExp/$requiredExp',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: infoFontSize,
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.info_outline, size: iconSize, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),

            SizedBox(height: 6),

            // 进度条
            Stack(
              children: [
                // 背景
                Container(
                  height: progressHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(progressHeight / 2),
                  ),
                ),

                // 进度
                Container(
                  height: progressHeight,
                  width: widget.width * expPercentage,
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
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 3),

            // 点击提示
            Center(
              child: Text(
                '点击查看等级规则',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: infoFontSize - 2,
                  fontStyle: FontStyle.italic,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}