// lib/widgets/components/screen/activity/activity_detail_content.dart

/// 该文件定义了 ActivityDetailContent 组件，用于展示用户活动详情。
/// ActivityDetailContent 将活动信息、描述、目标和评论区域组织成可滚动的布局。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:intl/intl.dart'; // 导入国际化数字格式化
import 'package:suxingchahui/models/activity/user_activity.dart'; // 导入用户活动模型
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类

// --- 动画组件 Imports ---
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件

// --- Section 组件 Imports ---
import 'sections/activity_info_section.dart'; // 导入活动信息区域组件
import 'sections/activity_description_section.dart'; // 导入活动描述区域组件
import 'sections/activity_target_section.dart'; // 导入活动目标区域组件
import 'sections/activity_comments_section.dart'; // 导入活动评论区域组件

/// `ActivityDetailContent` 类：用户活动详情内容组件。
///
/// 该组件负责将活动信息、描述、目标和评论区域组织成可滚动的布局，并支持动画效果。
class ActivityDetailContent extends StatelessWidget {
  final UserActivity activity; // 用户活动数据
  final UserFollowService userFollowService; // 用户关注服务
  final UserInfoProvider userInfoProvider; // 用户信息 Provider
  final InputStateService inputStateService; // 输入状态 Provider
  final User? currentUser; // 当前登录用户
  final List<ActivityComment> comments; // 评论列表
  final bool isLoadingComments; // 评论是否正在加载
  final ScrollController scrollController; // 滚动控制器
  final Function(String) onAddComment; // 添加评论回调
  final Function(ActivityComment) onCommentDeleted; // 评论删除回调
  final Function(ActivityComment) onCommentLikeToggled; // 评论点赞切换回调
  final VoidCallback onActivityUpdated; // 活动更新回调
  final VoidCallback? onEditActivity; // 编辑活动回调
  final VoidCallback? onDeleteActivity; // 删除活动回调

  /// 构造函数。
  ///
  /// [activity]：活动数据。
  /// [userFollowService]：用户关注服务。
  /// [userInfoProvider]：用户信息 Provider。
  /// [inputStateService]：输入状态 Provider。
  /// [currentUser]：当前用户。
  /// [comments]：评论列表。
  /// [isLoadingComments]：是否加载评论。
  /// [scrollController]：滚动控制器。
  /// [onAddComment]：添加评论回调。
  /// [onCommentDeleted]：评论删除回调。
  /// [onCommentLikeToggled]：评论点赞切换回调。
  /// [onActivityUpdated]：活动更新回调。
  /// [onEditActivity]：编辑活动回调。
  /// [onDeleteActivity]：删除活动回调。
  const ActivityDetailContent({
    super.key,
    required this.activity,
    required this.userFollowService,
    required this.userInfoProvider,
    required this.inputStateService,
    required this.currentUser,
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

  /// 构建活动信息区域。
  ///
  /// [isDesktop]：是否为桌面布局。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildInfoSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required double slideOffset,
    required Key key,
  }) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑入偏移量
      child: ActivityInfoSection(
        infoProvider: userInfoProvider, // 用户信息 Provider
        followService: userFollowService, // 关注服务
        currentUser: currentUser, // 当前用户
        activity: activity, // 活动数据
        onEditActivity: onEditActivity, // 编辑活动回调
        onDeleteActivity: onDeleteActivity, // 删除活动回调
        isDesktop: isDesktop, // 是否为桌面布局
      ),
    );
  }

  /// 构建活动描述区域。
  ///
  /// [isDesktop]：是否为桌面布局。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildDescriptionSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required Key key,
  }) {
    return FadeInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: ActivityDescriptionSection(
        activity: activity, // 活动数据
        isDesktop: isDesktop, // 是否为桌面布局
      ),
    );
  }

  /// 构建活动目标区域。
  ///
  /// [isDesktop]：是否为桌面布局。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildTargetSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required Key key,
  }) {
    return FadeInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: ActivityTargetSection(
        followService: userFollowService, // 关注服务
        infoProvider: userInfoProvider, // 用户信息 Provider
        currentUser: currentUser, // 当前用户
        activity: activity, // 活动数据
        isDesktop: isDesktop, // 是否为桌面布局
      ),
    );
  }

  /// 构建活动评论区域。
  ///
  /// [isDesktop]：是否为桌面布局。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildCommentsSection({
    required bool isDesktop,
    required Duration duration,
    required Duration delay,
    required double slideOffset,
    required Key key,
  }) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑入偏移量
      child: ActivityCommentsSection(
        inputStateService: inputStateService, // 输入状态 Provider
        userInfoProvider: userInfoProvider, // 用户信息 Provider
        userFollowService: userFollowService, // 用户关注服务
        currentUser: currentUser, // 当前用户
        activityId: activity.id, // 活动 ID
        comments: comments, // 评论列表
        isLoadingComments: isLoadingComments, // 评论是否加载中
        onAddComment: onAddComment, // 添加评论回调
        onCommentDeleted: onCommentDeleted, // 评论删除回调
        onCommentLikeToggled: onCommentLikeToggled, // 评论点赞切换回调
        isDesktop: isDesktop, // 是否为桌面布局
      ),
    );
  }

  /// 构建移动端布局。
  ///
  /// [context]：Build 上下文。
  /// [baseDelay]：基础延迟。
  /// [delayIncrement]：延迟增量。
  /// [slideOffset]：滑入偏移量。
  /// [slideDuration]：滑入动画时长。
  /// [fadeDuration]：淡入动画时长。
  Widget _buildMobileLayout(
    BuildContext context,
    Duration baseDelay,
    Duration delayIncrement,
    double slideOffset,
    Duration slideDuration,
    Duration fadeDuration,
  ) {
    int delayIndex = 0; // 延迟索引
    final bool isDesktop = false; // 非桌面布局
    final NumberFormat compactFormatter = NumberFormat.compact(); // 数字格式化器

    final infoKey = ValueKey('info_mob_${activity.id}'); // 信息区域键
    final descriptionKey = ValueKey('desc_mob_${activity.id}'); // 描述区域键
    final targetKey = ValueKey('target_mob_${activity.id}'); // 目标区域键
    final commentsKey = ValueKey('comments_mob_${activity.id}'); // 评论区域键

    return ListView(
      controller: scrollController, // 滚动控制器
      padding: const EdgeInsets.all(16), // 内边距
      children: [
        _buildInfoSection(
          isDesktop: isDesktop,
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
          key: infoKey,
        ),
        const SizedBox(height: 16), // 间距

        if (activity.content.isNotEmpty) ...[
          // 活动内容非空时显示描述区域
          _buildDescriptionSection(
            isDesktop: isDesktop,
            duration: fadeDuration,
            delay: baseDelay + (delayIncrement * delayIndex++),
            key: descriptionKey,
          ),
          const SizedBox(height: 16), // 间距
        ],

        ...[
          _buildTargetSection(
            isDesktop: isDesktop,
            duration: fadeDuration,
            delay: baseDelay + (delayIncrement * delayIndex++),
            key: targetKey,
          ),
        ],

        FadeInSlideUpItem(
          key: ValueKey('comments_title_mob_${activity.id}'), // 独立键
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex),
          slideOffset: slideOffset,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 底部内边距
            child: Text(
              '评论 (${compactFormatter.format(activity.commentsCount)})', // 评论数量
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold), // 文本样式
            ),
          ),
        ),

        _buildCommentsSection(
          isDesktop: isDesktop,
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
          key: commentsKey,
        ),

        const SizedBox(height: 80), // 底部留白
      ],
    );
  }

  /// 构建桌面端布局。
  ///
  /// [context]：Build 上下文。
  /// [baseDelay]：基础延迟。
  /// [delayIncrement]：延迟增量。
  /// [slideOffset]：滑入偏移量。
  /// [slideDuration]：滑入动画时长。
  /// [fadeDuration]：淡入动画时长。
  Widget _buildDesktopLayout(
    BuildContext context,
    Duration baseDelay,
    Duration delayIncrement,
    double slideOffset,
    Duration slideDuration,
    Duration fadeDuration,
  ) {
    int leftDelayIndex = 0; // 左侧延迟索引
    int rightDelayIndex = 0; // 右侧延迟索引
    final bool isDesktop = true; // 桌面布局
    final NumberFormat compactFormatter = NumberFormat.compact(); // 数字格式化器

    final infoKey = ValueKey('info_desk_${activity.id}'); // 信息区域键
    final descriptionKey = ValueKey('desc_desk_${activity.id}'); // 描述区域键
    final targetKey = ValueKey('target_desk_${activity.id}'); // 目标区域键
    final commentsKey = ValueKey('comments_desk_${activity.id}'); // 评论区域键
    final commentsTitleKey =
        ValueKey('comments_title_desk_${activity.id}'); // 评论标题键

    List<Widget> leftColumnItems = [
      // 左侧列项
      _buildInfoSection(
        isDesktop: isDesktop,
        duration: slideDuration,
        delay: baseDelay + (delayIncrement * leftDelayIndex++),
        slideOffset: slideOffset,
        key: infoKey,
      ),
      const SizedBox(height: 24), // 间距

      if (activity.content.isNotEmpty) ...[
        // 活动内容非空时显示描述区域
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
      ],
    ];

    List<Widget> rightColumnItems = [
      // 右侧列项
      FadeInSlideUpItem(
        key: commentsTitleKey, // 评论标题键
        duration: slideDuration,
        delay: baseDelay +
            (delayIncrement * rightDelayIndex) +
            const Duration(milliseconds: 100), // 延迟
        slideOffset: slideOffset,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // 底部内边距
          child: Text(
            '评论 (${compactFormatter.format(activity.commentsCount)})', // 评论数量
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold), // 文本样式
          ),
        ),
      ),

      _buildCommentsSection(
        isDesktop: isDesktop,
        duration: slideDuration,
        delay: baseDelay +
            (delayIncrement * rightDelayIndex++) +
            const Duration(milliseconds: 100), // 延迟
        slideOffset: slideOffset,
        key: commentsKey,
      ),
    ];

    return SingleChildScrollView(
      controller: scrollController, // 滚动控制器
      padding: const EdgeInsets.all(24.0), // 内边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
        children: [
          Expanded(
            flex: 5, // 左侧内容区域占比
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 水平拉伸
              children: leftColumnItems, // 左侧列项
            ),
          ),
          const SizedBox(width: 24), // 间距
          Expanded(
            flex: 4, // 右侧评论区占比
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 水平拉伸
              children: rightColumnItems, // 右侧列项
            ),
          ),
        ],
      ),
    );
  }

  /// 构建活动详情内容组件。
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktopScreen(context); // 判断是否为桌面屏幕

    const Duration slideDuration = Duration(milliseconds: 400); // 滑入动画时长
    const Duration fadeDuration = Duration(milliseconds: 350); // 淡入动画时长
    const Duration baseDelay = Duration(milliseconds: 50); // 基础延迟
    const Duration delayIncrement = Duration(milliseconds: 40); // 延迟增量
    double slideOffset = 20.0; // 滑入偏移量

    return Padding(
      key: ValueKey('activity_detail_content_${activity.id}'), // 唯一键
      padding: EdgeInsets.zero, // 内边距
      child: isDesktop // 根据是否为桌面布局选择构建方法
          ? _buildDesktopLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration)
          : _buildMobileLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration),
    );
  }
}
