import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 导入依赖

class ActivityDescriptionSection extends StatelessWidget { // 公共类
  final UserActivity activity;
  final bool isDesktop;

  const ActivityDescriptionSection({ // 构造函数
    Key? key,
    required this.activity,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SelectableText(
      activity.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
        color: Colors.black87,
        fontSize: isDesktop ? 15 : 14,
      ),
    );
  }
}