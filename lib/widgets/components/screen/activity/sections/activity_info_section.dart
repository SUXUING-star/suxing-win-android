import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart';

class ActivityInfoSection extends StatelessWidget {
  final UserActivity activity;
  final VoidCallback? onEditActivity;
  final VoidCallback? onDeleteActivity;
  final bool isDesktop;

  const ActivityInfoSection({
    super.key,
    required this.activity,
    this.onEditActivity,
    this.onDeleteActivity,
    required this.isDesktop,
  });

  // --- 内部方法：构建标题栏 ---
  Widget _buildSectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    final String title = activity.metadata?['title'] ?? '动态信息'; // 优先用元数据标题

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
            color: Colors.grey[800], // 或者 theme.textTheme.titleMedium?.color
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final NumberFormat compactFormatter = NumberFormat.compact();
    final double headerBottomMargin = isDesktop ? 16 : 12;
    final double metaInfoGap = isDesktop ? 16 : 12;
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktop ? 20 : 16); // 内边距

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
          ActivityHeader(
            user: activity.user,
            createTime: activity.createTime,
            activityType: activity.type,
            isAlternate: false, // 注意：这里的 isAlternate 可能需要调整，取决于设计
            onEdit: onEditActivity,
            onDelete: onDeleteActivity,
          ),
          SizedBox(height: headerBottomMargin),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${compactFormatter.format(activity.likesCount)} 人点赞', style: theme.textTheme.bodySmall),
              SizedBox(width: metaInfoGap),
              Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${compactFormatter.format(activity.commentsCount)} 条评论', style: theme.textTheme.bodySmall),
            ],
          ),
          if (activity.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '编辑于 ${DateTimeFormatter.formatTimeAgo(activity.updateTime)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}