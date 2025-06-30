// lib/widgets/components/screen/activity/sections/activity_target_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/models/activity/activity_extension.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target_navigation.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class ActivityTargetSection extends StatelessWidget {
  final Activity activity;
  final UserFollowService followService;
  final UserInfoService infoService;
  final User? currentUser;
  final bool isDesktopLayout;

  const ActivityTargetSection({
    super.key,
    required this.currentUser,
    required this.followService,
    required this.infoService,
    required this.activity,
    required this.isDesktopLayout,
  });

  // --- 内部方法：构建标题栏 ---
  Widget _buildSectionTitle(BuildContext context) {
    final theme = Theme.of(context);




    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          activity.targetText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktopLayout ? 20 : 16);

    // --- 使用 Container 实现卡片样式 ---
    return Container(
      padding: sectionPadding, // 应用内边距
      decoration: BoxDecoration(
        color: Colors.white, // 背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [ // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 内部调用标题栏 ---
          _buildSectionTitle(context),
          const SizedBox(height: 16), // 标题和内容间距

          // --- 原有的内容 ---
          ActivityTarget(
            currentUser: currentUser,
            infoService: infoService,
            followService: followService,
            activity: activity,
            isAlternate: false, // 注意：isAlternate
          ),
          // Target 和 Navigation 之间通常需要一点间距
          const SizedBox(height: 12),
          ActivityTargetNavigation(
            activity: activity,
            isAlternate: false, // 注意：isAlternate
          ),
          if (activity.metadata?['download_code'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: SelectableText.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: isDesktopLayout ? 15 : 14),
                  children: [
                    const TextSpan(text: "提取码: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: "${activity.metadata!['download_code']}",
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}