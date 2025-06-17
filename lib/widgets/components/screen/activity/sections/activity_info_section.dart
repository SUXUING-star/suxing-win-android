// lib/widgets/components/screen/activity/sections/activity_info_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 确保导入模型
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 需要时间格式化
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart';
import 'package:suxingchahui/widgets/components/screen/activity/sections/check_in_history_expansion.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// 活动详情页的头部信息区域
///
/// 显示活动的基本信息，如作者、类型、时间、点赞/评论数等。
class ActivityInfoSection extends StatelessWidget {
  /// 要显示的活动对象。
  final UserActivity activity;

  final UserFollowService followService;

  final UserInfoService infoService;

  final User? currentUser;

  /// 编辑活动的回调，会传递给 ActivityHeader。
  final VoidCallback? onEditActivity;

  /// 删除活动的回调，会传递给 ActivityHeader。
  final VoidCallback? onDeleteActivity;

  /// 是否为桌面布局 (影响内边距等)。
  final bool isDesktopLayout;

  const ActivityInfoSection({
    super.key,
    required this.currentUser,
    required this.infoService,
    required this.followService,
    required this.activity,
    this.onEditActivity,
    this.onDeleteActivity,
    required this.isDesktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 使用紧凑数字格式化工具
    final NumberFormat compactFormatter =
        NumberFormat.compact(locale: 'zh_CN'); // 指定中文区域设置
    // 根据布局调整间距
    final double headerBottomMargin = isDesktopLayout ? 16 : 12;
    final double metaInfoGap = isDesktopLayout ? 16 : 12;
    // 根据布局调整内边距
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktopLayout ? 20 : 16);

    return Container(
      padding: sectionPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05), // 阴影更柔和
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActivityHeader(
            userId: activity.userId,
            currentUser: currentUser,
            followService: followService,
            infoService: infoService,
            createTime: activity.createTime,
            updateTime: activity.updateTime,
            isEdited: activity.isEdited,
            activityType: activity.type,
            isAlternate: false,
            cardHeight: 1.0,
            onEdit: onEditActivity,
            onDelete: onDeleteActivity,
          ),
          SizedBox(height: headerBottomMargin), // Header 和统计信息间距

          // --- 点赞和评论统计 (保持不变) ---
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined,
                  size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              // 使用 compactFormatter
              Text('${compactFormatter.format(activity.likesCount)} 人点赞',
                  style: theme.textTheme.bodySmall),
              SizedBox(width: metaInfoGap),
              Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              // 使用 compactFormatter
              Text('${compactFormatter.format(activity.commentsCount)} 条评论',
                  style: theme.textTheme.bodySmall),
            ],
          ),

          // --- 编辑时间 (保持不变) ---
          if (activity.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                // 安全地使用 updateTime，虽然理论上 isEdited=true 时它应该存在
                '编辑于 ${DateTimeFormatter.formatTimeAgo(activity.updateTime)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ),
          if (activity.type == ActivityTypeConstants.checkIn) // 判断是否为签到活动
            CheckInHistoryExpansion(activity: activity),
        ],
      ),
    );
  }
}
