import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 确保 ActivityComment 也在此或单独导入

// --- 动画组件 Imports ---
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';

// --- Section 组件 Imports ---
import 'sections/activity_info_section.dart';
import 'sections/activity_description_section.dart';
import 'sections/activity_target_section.dart';
import 'sections/activity_comments_section.dart';

class ActivityDetailContent extends StatelessWidget {
  // 保持 StatelessWidget，因为动画依赖 Key 触发
  final UserActivity activity;
  final List<ActivityComment> comments;
  final bool isLoadingComments;
  final ScrollController scrollController;
  final Function(String) onAddComment;
  final Function(String) onCommentDeleted;
  final Function(ActivityComment) onCommentLikeToggled;
  final VoidCallback onActivityUpdated; // 这个回调看起来没有在当前布局中使用，但保留
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

  // --- Section 构建器 (带动画) ---

  Widget _buildInfoSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required double slideOffset,
    required Key key,
  }) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: ActivityInfoSection(
        activity: activity,
        onEditActivity: onEditActivity,
        onDeleteActivity: onDeleteActivity,
        isDesktop: isDesktop,
      ),
    );
  }

  Widget _buildDescriptionSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required Key key,
  }) {
    // 描述通常用 FadeIn 效果比较自然
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: ActivityDescriptionSection(
        activity: activity,
        isDesktop: isDesktop,
        // 同样，内部处理样式或在这里加 Wrapper
      ),
    );
  }

  Widget _buildTargetSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required Key key,
  }) {
    // Target 内容也用 FadeIn
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: ActivityTargetSection(
        activity: activity,
        isDesktop: isDesktop,
        // 内部处理样式或在这里加 Wrapper
      ),
    );
  }

  Widget _buildCommentsSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required double slideOffset,
    required Key key,
  }) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: ActivityCommentsSection(
        activityId: activity.id,
        comments: comments,
        isLoadingComments: isLoadingComments,
        onAddComment: onAddComment,
        onCommentDeleted: onCommentDeleted,
        onCommentLikeToggled: onCommentLikeToggled,
        isDesktop: isDesktop,
        // 内部处理样式或在这里加 Wrapper
      ),
    );
  }

  // --- Mobile Layout (应用动画和解耦后的构建器) ---
  Widget _buildMobileLayout(
    BuildContext context,
    Duration baseDelay,
    Duration delayIncrement,
    double slideOffset,
    Duration slideDuration,
    Duration fadeDuration,
  ) {
    int delayIndex = 0;
    final bool isDesktop = false;
    final NumberFormat compactFormatter =
        NumberFormat.compact(); // 需要时传递给 Comments Section

    // --- 为每个 Section 定义唯一的 Key ---
    final infoKey = ValueKey('info_mob_${activity.id}');
    final descriptionKey = ValueKey('desc_mob_${activity.id}');
    final targetKey = ValueKey('target_mob_${activity.id}');
    final commentsKey = ValueKey('comments_mob_${activity.id}');

    return ListView(
      controller: scrollController,
      // 使用 Padding 代替之前的 Container/Card 效果，模仿 GameDetailContent
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoSection(
          isDesktop: isDesktop,
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
          key: infoKey,
        ),
        const SizedBox(height: 16), // Section 间距

        if (activity.content.isNotEmpty) ...[
          _buildDescriptionSection(
            isDesktop: isDesktop,
            duration: fadeDuration, // 使用 FadeIn 动画时长
            delay: baseDelay + (delayIncrement * delayIndex++),
            key: descriptionKey,
          ),
          const SizedBox(height: 16), // Section 间距
        ],

        ...[
          _buildTargetSection(
            isDesktop: isDesktop,
            duration: fadeDuration, // 使用 FadeIn 动画时长
            delay: baseDelay + (delayIncrement * delayIndex++),
            key: targetKey,
          ),
          const SizedBox(height: 16), // Section 间距
        ],

        // 评论区标题，模仿 GameDetailContent 在外部添加文本
        // (或者也可以考虑将标题逻辑移入 ActivityCommentsSection 内部)
        // 为了与 GameDetailContent 更一致，我们可以在这里加个简单的标题动画
        FadeInSlideUpItem(
          key: ValueKey('comments_title_mob_${activity.id}'), // 独立 key
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex), // 和评论内容一起出现或稍早
          slideOffset: slideOffset,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 标题和内容间距
            child: Text(
              '评论 (${compactFormatter.format(activity.commentsCount)})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        _buildCommentsSection(
          isDesktop: isDesktop,
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++), // 和标题一起的延迟
          slideOffset: slideOffset,
          key: commentsKey,
        ),

        const SizedBox(height: 80), // 底部留白，防止被 FAB 遮挡
      ],
    );
  }

  // --- Desktop Layout (应用动画和解耦后的构建器) ---
  Widget _buildDesktopLayout(
    BuildContext context,
    Duration baseDelay,
    Duration delayIncrement,
    double slideOffset,
    Duration slideDuration,
    Duration fadeDuration,
  ) {
    int leftDelayIndex = 0;
    int rightDelayIndex = 0;
    final bool isDesktop = true;
    final NumberFormat compactFormatter = NumberFormat.compact(); // 需要时传递

    // --- 定义 Keys ---
    final infoKey = ValueKey('info_desk_${activity.id}');
    final descriptionKey = ValueKey('desc_desk_${activity.id}');
    final targetKey = ValueKey('target_desk_${activity.id}');
    final commentsKey = ValueKey('comments_desk_${activity.id}');
    final commentsTitleKey = ValueKey('comments_title_desk_${activity.id}');

    // --- 构建左右列 ---
    List<Widget> leftColumnItems = [
      _buildInfoSection(
        isDesktop: isDesktop,
        duration: slideDuration,
        delay: baseDelay + (delayIncrement * leftDelayIndex++),
        slideOffset: slideOffset,
        key: infoKey,
      ),
      const SizedBox(height: 24), // Section 间距 (桌面端大一些)

      if (activity.content.isNotEmpty) ...[
        _buildDescriptionSection(
          isDesktop: isDesktop,
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * leftDelayIndex++),
          key: descriptionKey,
        ),
        const SizedBox(height: 24),
      ],

      ...[
        _buildTargetSection(
          isDesktop: isDesktop,
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * leftDelayIndex++),
          key: targetKey,
        ),
        // 左侧最后一个元素下方不需要 SizedBox 了
      ],
    ];

    List<Widget> rightColumnItems = [
      // 评论区标题 (动画)
      FadeInSlideUpItem(
        key: commentsTitleKey,
        duration: slideDuration,
        // 稍微延迟于左侧第一个元素，制造层次感
        delay: baseDelay +
            (delayIncrement * rightDelayIndex) +
            Duration(milliseconds: 100),
        slideOffset: slideOffset,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // 标题和内容间距
          child: Text(
            '评论 (${compactFormatter.format(activity.commentsCount)})',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),

      _buildCommentsSection(
        isDesktop: isDesktop,
        duration: slideDuration,
        // 和标题一起出现
        delay: baseDelay +
            (delayIncrement * rightDelayIndex++) +
            Duration(milliseconds: 100),
        slideOffset: slideOffset,
        key: commentsKey,
      ),
      // 右侧最后一个元素下方不需要 SizedBox 了
    ];

    // --- 组合布局 ---
    // 使用 SingleChildScrollView + Row 来实现桌面滚动（如果内容超长）
    return SingleChildScrollView(
      controller: scrollController, // 传递 ScrollController
      padding: const EdgeInsets.all(24.0), // 桌面端更大的 Padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
        children: [
          // 左侧
          Expanded(
            flex: 5, // 左侧内容区域占比
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 让内容撑满宽度
              children: leftColumnItems,
            ),
          ),
          const SizedBox(width: 24), // 左右列间距
          // 右侧
          Expanded(
            flex: 4, // 右侧评论区占比
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rightColumnItems,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // --- 动画参数 (与 GameDetailContent 保持一致或微调) ---
    const Duration slideDuration = Duration(milliseconds: 400);
    const Duration fadeDuration = Duration(milliseconds: 350);
    // const Duration scaleDuration = Duration(milliseconds: 450); // 如果需要
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration delayIncrement = Duration(milliseconds: 40);
    double slideOffset = 20.0;

    // 使用 unique key 保证 Activity ID 变化时重建，触发动画
    return Padding(
      key: ValueKey('activity_detail_content_${activity.id}'),
      // 移除这里的内边距，因为布局方法内部已经处理了
      padding: EdgeInsets
          .zero, // 或者 EdgeInsets.all(isDesktop ? 0 : 16.0) 如果需要外层padding
      child: isDesktop
          ? _buildDesktopLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration)
          : _buildMobileLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration),
    );
  }
}
