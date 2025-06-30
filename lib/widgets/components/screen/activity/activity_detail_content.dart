// lib/widgets/components/screen/activity/activity_detail_content.dart

/// 该文件定义了 [ActivityDetailContent] 组件，用于展示用户活动详情。
/// [ActivityDetailContent] 将活动信息、描述、目标和评论区域组织成可滚动的布局。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/activity_comment.dart';
import 'package:suxingchahui/models/activity/activity_navigation_info.dart';
import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'navigation/activity_detail_navigation.dart';
import 'sections/activity_info_section.dart';
import 'sections/activity_description_section.dart';
import 'sections/activity_target_section.dart';
import 'sections/activity_comments_section.dart';

/// `ActivityDetailContent` 类：用户活动详情内容组件。
class ActivityDetailContent extends StatelessWidget {
  final Activity activity;
  final ActivityNavigationInfo? navigationInfo;
  final UserFollowService userFollowService;
  final UserInfoService userInfoService;
  final InputStateService inputStateService;
  final User? currentUser;
  final bool isDesktopLayout;
  final List<ActivityComment> comments;
  final bool isLoadingComments;
  final ScrollController scrollController;
  final Function(String) onAddComment;
  final Function(ActivityComment) onCommentDeleted;
  final Future<bool> Function(ActivityComment) onCommentLike;
  final Future<bool> Function(ActivityComment) onCommentUnLike;
  final VoidCallback onActivityUpdated;
  final VoidCallback? onEditActivity;
  final VoidCallback? onDeleteActivity;

  final String deviceCtx;

  const ActivityDetailContent({
    super.key,
    required this.navigationInfo,
    required this.activity,
    required this.userFollowService,
    required this.userInfoService,
    required this.inputStateService,
    required this.currentUser,
    required this.isDesktopLayout,
    required this.comments,
    required this.isLoadingComments,
    required this.scrollController,
    required this.onAddComment,
    required this.onCommentDeleted,
    required this.onCommentLike,
    required this.onCommentUnLike,
    required this.onActivityUpdated,
    this.onEditActivity,
    this.onDeleteActivity,
  }) : deviceCtx = isDesktopLayout ? 'desk' : 'mob';

  /// 构建一个唯一的 [ValueKey]。
  ValueKey _makeValueKey(String mainCtx) =>
      ValueKey('${mainCtx}_${deviceCtx}_${activity.id}');

  // --- Section Builders (核心重构区) ---

  Widget _buildInfoSection({
    required Duration duration,
    required Duration delay,
    required double slideOffset,
  }) {
    return FadeInSlideUpItem(
      key: _makeValueKey('info'),
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: ActivityInfoSection(
        infoService: userInfoService,
        followService: userFollowService,
        currentUser: currentUser,
        activity: activity,
        onEditActivity: onEditActivity,
        onDeleteActivity: onDeleteActivity,
        isDesktopLayout: isDesktopLayout,
      ),
    );
  }

  Widget _buildDescriptionSection({
    required Duration duration,
    required Duration delay,
  }) {
    return FadeInItem(
      key: _makeValueKey('description'),
      duration: duration,
      delay: delay,
      child: ActivityDescriptionSection(
        activity: activity,
        isDesktopLayout: isDesktopLayout,
      ),
    );
  }

  Widget _buildTargetSection({
    required Duration duration,
    required Duration delay,
  }) {
    return FadeInItem(
      key: _makeValueKey('target'),
      duration: duration,
      delay: delay,
      child: ActivityTargetSection(
        followService: userFollowService,
        infoService: userInfoService,
        currentUser: currentUser,
        activity: activity,
        isDesktopLayout: isDesktopLayout,
      ),
    );
  }

  Widget _buildCommentsSection({
    required Duration duration,
    required Duration delay,
    required double slideOffset,
  }) {
    return FadeInSlideUpItem(
      key: _makeValueKey('comments'),
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: ActivityCommentsSection(
        inputStateService: inputStateService,
        userInfoService: userInfoService,
        userFollowService: userFollowService,
        currentUser: currentUser,
        activityId: activity.id,
        comments: comments,
        isLoadingComments: isLoadingComments,
        onAddComment: onAddComment,
        onCommentDeleted: onCommentDeleted,
        onCommentLike: onCommentLike,
        onCommentUnLike: onCommentUnLike,
        isDesktopLayout: isDesktopLayout,
      ),
    );
  }

  Widget _buildNavigationSection({
    required Duration duration,
    required Duration delay,
  }) {
    return FadeInItem(
      key: _makeValueKey('navigation'),
      duration: duration,
      delay: delay,
      child: ActivityDetailNavigation(
        navigationInfo: navigationInfo!,
        isDesktopLayout: isDesktopLayout,
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Duration baseDelay,
    Duration delayIncrement,
    double slideOffset,
    Duration slideDuration,
    Duration fadeDuration,
  ) {
    int delayIndex = 0;
    final NumberFormat compactFormatter = NumberFormat.compact();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoSection(
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
        ),
        const SizedBox(height: 16),
        if (activity.content.isNotEmpty) ...[
          _buildDescriptionSection(
            duration: fadeDuration,
            delay: baseDelay + (delayIncrement * delayIndex++),
          ),
          const SizedBox(height: 16),
        ],
        _buildTargetSection(
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
        ),
        FadeInSlideUpItem(
          key: _makeValueKey('comments_title'),
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex),
          slideOffset: slideOffset,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
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
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
        ),
        if (navigationInfo != null &&
            (navigationInfo!.prevActivity != null ||
                navigationInfo!.nextActivity != null)) ...[
          const SizedBox(height: 32),
          _buildNavigationSection(
            duration: fadeDuration,
            delay: baseDelay + (delayIncrement * delayIndex++),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

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
    final NumberFormat compactFormatter = NumberFormat.compact();

    List<Widget> leftColumnItems = [
      _buildInfoSection(
        duration: slideDuration,
        delay: baseDelay + (delayIncrement * leftDelayIndex++),
        slideOffset: slideOffset,
      ),
      const SizedBox(height: 24),
      if (activity.content.isNotEmpty) ...[
        _buildDescriptionSection(
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * leftDelayIndex++),
        ),
        const SizedBox(height: 24),
      ],
      _buildTargetSection(
        duration: fadeDuration,
        delay: baseDelay + (delayIncrement * leftDelayIndex++),
      ),
      if (navigationInfo != null &&
          (navigationInfo!.prevActivity != null ||
              navigationInfo!.nextActivity != null)) ...[
        const SizedBox(height: 48),
        _buildNavigationSection(
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * leftDelayIndex++),
        ),
      ],
    ];

    List<Widget> rightColumnItems = [
      FadeInSlideUpItem(
        key: _makeValueKey('comments_title'),
        duration: slideDuration,
        delay: baseDelay +
            (delayIncrement * rightDelayIndex) +
            const Duration(milliseconds: 100),
        slideOffset: slideOffset,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
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
        duration: slideDuration,
        delay: baseDelay +
            (delayIncrement * rightDelayIndex++) +
            const Duration(milliseconds: 100),
        slideOffset: slideOffset,
      ),
    ];

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: leftColumnItems,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
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
    const Duration slideDuration = Duration(milliseconds: 400);
    const Duration fadeDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration delayIncrement = Duration(milliseconds: 40);
    const double slideOffset = 20.0;

    return Padding(
      key: ValueKey('activity_detail_content_${activity.id}'),
      padding: EdgeInsets.zero,
      child: isDesktopLayout
          ? _buildDesktopLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration)
          : _buildMobileLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration),
    );
  }
}
