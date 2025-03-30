import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart'; // 导入依赖

class ActivityInfoSection extends StatelessWidget { // 公共类
  final UserActivity activity;
  final VoidCallback? onEditActivity;
  final VoidCallback? onDeleteActivity;
  final bool isDesktop;

  const ActivityInfoSection({ // 构造函数
    Key? key,
    required this.activity,
    this.onEditActivity,
    this.onDeleteActivity,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final NumberFormat compactFormatter = NumberFormat.compact();
    final double headerBottomMargin = isDesktop ? 16 : 12;
    final double metaInfoGap = isDesktop ? 16 : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivityHeader(
          user: activity.user,
          createTime: activity.createTime,
          activityType: activity.type,
          isAlternate: false,
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
    );
  }
}