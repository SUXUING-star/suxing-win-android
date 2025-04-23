import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 确保 ActivityComment 也在此或单独导入

// 导入独立的 Section 组件
import 'sections/activity_info_section.dart';
import 'sections/activity_description_section.dart';
import 'sections/activity_target_section.dart';
import 'sections/activity_comments_section.dart';

class ActivityDetailContent extends StatelessWidget {
  final UserActivity activity;
  final List<ActivityComment> comments;
  final bool isLoadingComments;
  final ScrollController scrollController;
  final Function(String) onAddComment;
  final Function(String) onCommentDeleted;
  final Function(ActivityComment) onCommentLikeToggled;
  final VoidCallback onActivityUpdated;
  final VoidCallback? onEditActivity;
  final VoidCallback? onDeleteActivity;

  const ActivityDetailContent({
    super.key,
    required this.activity,
    required this.comments,
    required this.isLoadingComments,
    required this.scrollController,
    required this.onAddComment,
    required this.onCommentDeleted,
    required this.onCommentLikeToggled,
    required this.onActivityUpdated,
    this.onEditActivity,
    this.onDeleteActivity,
  });

  // --- Section 构建器 (保持不变，用于包裹各个 Section Widget) ---
  Widget _buildSectionWrapper({
    required BuildContext context,
    required String title,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    EdgeInsets margin = const EdgeInsets.only(bottom: 16),
    double opacity = 0.9,
    Color backgroundColor = Colors.white,
  }) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
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
            Row(
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
            ),
            const SizedBox(height: 16),
            child, // 将传入的 Section Widget 放在这里
          ],
        ),
      ),
    );
  }

  // --- Mobile Layout (排列 Section Widgets) ---
  Widget _buildMobileLayout(BuildContext context) {
    final NumberFormat compactFormatter = NumberFormat.compact();
    final bool isDesktop = false;
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktop ? 20 : 16);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionWrapper(
          context: context,
          title: activity.metadata?['title'] ?? '动态信息',
          padding: sectionPadding,
          child: ActivityInfoSection( // 使用导入的公共类
            activity: activity,
            onEditActivity: onEditActivity,
            onDeleteActivity: onDeleteActivity,
            isDesktop: isDesktop,
          ),
        ),
        if (activity.content.isNotEmpty)
          _buildSectionWrapper(
            context: context,
            title: '详细描述',
            padding: sectionPadding,
            child: ActivityDescriptionSection( // 使用导入的公共类
              activity: activity,
              isDesktop: isDesktop,
            ),
          ),
        if (activity.target != null)
          _buildSectionWrapper(
            context: context,
            title: activity.targetType == 'game' ? '游戏信息' :
            activity.targetType == 'download' ? '下载链接' :
            '相关内容',
            padding: sectionPadding,
            child: ActivityTargetSection( // 使用导入的公共类
              activity: activity,
              isDesktop: isDesktop,
            ),
          ),
        _buildSectionWrapper(
          context: context,
          title: '评论 (${compactFormatter.format(activity.commentsCount)})',
          padding: sectionPadding,
          child: ActivityCommentsSection( // 使用导入的公共类
            activityId: activity.id,
            comments: comments,
            isLoadingComments: isLoadingComments,
            onAddComment: onAddComment,
            onCommentDeleted: onCommentDeleted,
            onCommentLikeToggled: onCommentLikeToggled,
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // --- Desktop Layout (排列 Section Widgets) ---
  Widget _buildDesktopLayout(BuildContext context) {
    final NumberFormat compactFormatter = NumberFormat.compact();
    final bool isDesktop = true;
    final EdgeInsets sectionPadding = EdgeInsets.all(isDesktop ? 20 : 16);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _buildSectionWrapper(
                  context: context,
                  title: activity.metadata?['title'] ?? '动态信息',
                  padding: sectionPadding,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ActivityInfoSection( // 使用导入的公共类
                    activity: activity,
                    onEditActivity: onEditActivity,
                    onDeleteActivity: onDeleteActivity,
                    isDesktop: isDesktop,
                  ),
                ),
                if (activity.content.isNotEmpty)
                  _buildSectionWrapper(
                    context: context,
                    title: '详细描述',
                    padding: sectionPadding,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ActivityDescriptionSection( // 使用导入的公共类
                      activity: activity,
                      isDesktop: isDesktop,
                    ),
                  ),
                if (activity.target != null)
                  _buildSectionWrapper(
                    context: context,
                    title: activity.targetType == 'game' ? '游戏信息' :
                    activity.targetType == 'download' ? '下载链接' :
                    '相关内容',
                    padding: sectionPadding,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ActivityTargetSection( // 使用导入的公共类
                      activity: activity,
                      isDesktop: isDesktop,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // 右侧
          Expanded(
            flex: 4,
            child: _buildSectionWrapper(
              context: context,
              title: '评论 (${compactFormatter.format(activity.commentsCount)})',
              margin: EdgeInsets.zero,
              padding: sectionPadding,
              child: ActivityCommentsSection( // 使用导入的公共类
                activityId: activity.id,
                comments: comments,
                isLoadingComments: isLoadingComments,
                onAddComment: onAddComment,
                onCommentDeleted: onCommentDeleted,
                onCommentLikeToggled: onCommentLikeToggled,
                isDesktop: isDesktop,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context);
  }
}