import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 确保导入模型
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 需要时间格式化
// --- 依赖更新后的 ActivityHeader ---
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart';

/// 活动详情页的头部信息区域
///
/// 显示活动的基本信息，如作者、类型、时间、点赞/评论数等。
class ActivityInfoSection extends StatelessWidget {
  /// 要显示的活动对象。
  final UserActivity activity;
  /// 编辑活动的回调，会传递给 ActivityHeader。
  final VoidCallback? onEditActivity;
  /// 删除活动的回调，会传递给 ActivityHeader。
  final VoidCallback? onDeleteActivity;
  /// 是否为桌面布局 (影响内边距等)。
  final bool isDesktop;

  const ActivityInfoSection({
    super.key,
    required this.activity,
    this.onEditActivity,
    this.onDeleteActivity,
    required this.isDesktop,
  });

  // --- 内部方法：构建标题栏 (保持不变) ---
  Widget _buildSectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    // 优先使用元数据中的标题，否则提供默认标题
    final String title = activity.metadata?['section_title'] ?? // 可以自定义元数据 key
        activity.metadata?['title'] ??
        '动态信息';

    return Row(
      children: [
        Container(
          width: 4,
          height: 18, // 稍微减小一点高度
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith( // 使用 titleMedium 更合适
            fontWeight: FontWeight.bold,
            color: Colors.grey[850], // 深灰色
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 使用紧凑数字格式化工具
    final NumberFormat compactFormatter = NumberFormat.compact(locale: 'zh_CN'); // 指定中文区域设置
    // 根据布局调整间距
    final double headerBottomMargin = isDesktop ? 16 : 12;
    final double metaInfoGap = isDesktop ? 16 : 12;
    // 根据布局调整内边距
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktop ? 20 : 16);

    return Container(
      padding: sectionPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // 阴影更柔和
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 构建并添加标题栏 ---
          _buildSectionTitle(context),
          const SizedBox(height: 16), // 标题和内容间距

          // --- 使用更新后的 ActivityHeader ---
          ActivityHeader(
            // *** 传递 userId 而不是 user Map ***
            userId: activity.userId,
            createTime: activity.createTime,
            updateTime: activity.updateTime,
            isEdited: activity.isEdited,
            activityType: activity.type,
            // 在 InfoSection 中，通常不使用交替布局，cardHeight 设为 1.0
            isAlternate: false,
            cardHeight: 1.0,
            // *** 将回调传递下去 ***
            onEdit: onEditActivity,
            onDelete: onDeleteActivity,
          ),
          SizedBox(height: headerBottomMargin), // Header 和统计信息间距

          // --- 点赞和评论统计 (保持不变) ---
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              // 使用 compactFormatter
              Text('${compactFormatter.format(activity.likesCount)} 人点赞', style: theme.textTheme.bodySmall),
              SizedBox(width: metaInfoGap),
              Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              // 使用 compactFormatter
              Text('${compactFormatter.format(activity.commentsCount)} 条评论', style: theme.textTheme.bodySmall),
            ],
          ),

          // --- 编辑时间 (保持不变) ---
          if (activity.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                // 安全地使用 updateTime，虽然理论上 isEdited=true 时它应该存在
                '编辑于 ${DateTimeFormatter.formatTimeAgo(activity.updateTime)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}