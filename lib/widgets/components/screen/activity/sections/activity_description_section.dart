import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';

class ActivityDescriptionSection extends StatelessWidget {
  final UserActivity activity;
  final bool isDesktop;

  const ActivityDescriptionSection({
    super.key,
    required this.activity,
    required this.isDesktop,
  });

  // --- 内部方法：构建标题栏 ---
  Widget _buildSectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    const String title = '详细描述';

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
          title,
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
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktop ? 20 : 16);

    // --- 使用 Container 实现卡片样式 ---
    return Container(
      padding: sectionPadding, // 应用内边距
      decoration: BoxDecoration(
        color: Colors.white, // 背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [ // 阴影
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          SelectableText(
            activity.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.black87,
              fontSize: isDesktop ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}