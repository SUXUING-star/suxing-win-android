import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 导入依赖
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target.dart'; // 导入依赖
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target_navigation.dart'; // 导入依赖

class ActivityTargetSection extends StatelessWidget { // 公共类
  final UserActivity activity;
  final bool isDesktop;

  const ActivityTargetSection({ // 构造函数
    super.key,
    required this.activity,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivityTarget(
          target: activity.target,
          targetType: activity.targetType,
          isAlternate: false,
        ),
        ActivityTargetNavigation(
          activity: activity,
          isAlternate: false,
        ),
        if (activity.metadata?['download_code'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SelectableText.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: isDesktop ? 15 : 14),
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
    );
  }
}