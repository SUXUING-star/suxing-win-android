// lib/widgets/components/screen/activity/feed/collapsible_activity_feed.dart

/// 该文件定义了 CollapsibleActivityFeed 组件，一个可折叠的用户活动动态列表。
/// CollapsibleActivityFeed 根据指定模式分组和显示用户活动，并支持折叠/展开。
library;

import 'dart:async'; // 导入异步操作所需
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter/services.dart'; // 导入 HapticFeedback
import 'package:suxingchahui/constants/activity/activity_constants.dart'; // 导入活动类型常量
import 'package:suxingchahui/models/activity/activity_comment.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 导入用户活动模型
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_card.dart'; // 导入活动卡片组件
import 'package:suxingchahui/widgets/components/screen/activity/common/activity_empty_state.dart'; // 导入活动空状态组件
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 导入日期时间格式化工具
import 'package:suxingchahui/widgets/ui/animation/animated_feed_item.dart'; // 导入动画列表项组件
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 导入用户信息徽章
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `FeedCollapseMode` 枚举：表示动态流的折叠模式。
enum FeedCollapseMode {
  none, // 不折叠
  byUser, // 按用户折叠
  byType // 按类型折叠
}

/// `CollapsibleActivityFeed` 类：可折叠的用户活动动态列表组件。
///
/// 该组件根据指定的折叠模式分组和显示用户活动，支持加载、刷新和交互操作。
class CollapsibleActivityFeed extends StatefulWidget {
  final List<UserActivity> activities; // 用户活动列表
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息 Provider
  final InputStateService inputStateService; // 输入状态 Provider
  final User? currentUser; // 当前登录用户
  final bool isLoading; // 是否正在加载数据
  final bool isLoadingMore; // 是否正在加载更多数据
  final String error; // 错误消息
  final FeedCollapseMode collapseMode; // 折叠模式
  final bool useAlternatingLayout; // 是否使用交替布局
  final Function(UserActivity) onActivityTap; // 活动卡片点击回调
  final Future<void> Function() onRefresh; // 刷新回调
  final VoidCallback? onLoadMore; // 加载更多回调

  final ScrollController scrollController; // 滚动控制器
  final FutureOr<void> Function(UserActivity activity)?
      onDeleteActivity; // 删除活动回调
  final Future<bool> Function(String activityId)? onLikeActivity; // 点赞活动回调
  final Future<bool> Function(String activityId)? onUnlikeActivity; // 取消点赞活动回调
  final FutureOr<ActivityComment?> Function(String activityId, String content)?
      onAddComment; // 添加评论回调
  final FutureOr<void> Function(String activityId, ActivityComment comment)?
      onDeleteComment; // 删除评论回调
  final Future<bool> Function(String activityId, String commentId)?
      onLikeComment; // 点赞评论回调
  final Future<bool> Function(String activityId, String commentId)?
      onUnlikeComment; // 取消点赞评论回调
  final VoidCallback? Function(UserActivity activity)? onEditActivity; // 编辑活动回调

  /// 构造函数。
  ///
  /// [activities]：活动列表。
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [inputStateService]：输入状态 Provider。
  /// [currentUser]：当前用户。
  /// [isLoading]：是否加载中。
  /// [isLoadingMore]：是否加载更多。
  /// [error]：错误消息。
  /// [collapseMode]：折叠模式。
  /// [useAlternatingLayout]：是否使用交替布局。
  /// [onActivityTap]：活动点击回调。
  /// [onRefresh]：刷新回调。
  /// [onLoadMore]：加载更多回调。
  /// [scrollController]：滚动控制器。
  /// [onDeleteActivity]：删除活动回调。
  /// [onLikeActivity]：点赞活动回调。
  /// [onUnlikeActivity]：取消点赞活动回调。
  /// [onAddComment]：添加评论回调。
  /// [onDeleteComment]：删除评论回调。
  /// [onLikeComment]：点赞评论回调。
  /// [onUnlikeComment]：取消点赞评论回调。
  /// [onEditActivity]：编辑活动回调。
  const CollapsibleActivityFeed({
    super.key,
    required this.activities,
    required this.followService,
    required this.infoService,
    required this.inputStateService,
    required this.currentUser,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error = '',
    this.collapseMode = FeedCollapseMode.none,
    this.useAlternatingLayout = true,
    required this.onActivityTap,
    required this.onRefresh,
    this.onLoadMore,
    required this.scrollController,
    this.onDeleteActivity,
    this.onLikeActivity,
    this.onUnlikeActivity,
    this.onAddComment,
    this.onDeleteComment,
    this.onLikeComment,
    this.onUnlikeComment,
    this.onEditActivity,
  });

  /// 创建状态。
  @override
  _CollapsibleActivityFeedState createState() =>
      _CollapsibleActivityFeedState();
}

/// `_CollapsibleActivityFeedState` 类：`CollapsibleActivityFeed` 的状态管理。
///
/// 管理分组的展开状态、动画和用户状态的更新。
class _CollapsibleActivityFeedState extends State<CollapsibleActivityFeed>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _expandedGroups = {}; // 存储分组的展开状态
  late AnimationController _animationController; // 动画控制器

  User? _currentUser; // 当前用户

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this); // 初始化动画控制器
    _initExpandedGroups(); // 初始化分组展开状态
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = widget.currentUser; // 更新当前用户
  }

  @override
  void dispose() {
    _animationController.dispose(); // 销毁动画控制器
    super.dispose();
  }

  @override
  void didUpdateWidget(CollapsibleActivityFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapseMode != widget.collapseMode ||
        _listPossiblyChanged(oldWidget.activities, widget.activities)) {
      // 折叠模式或列表变化时
      _initExpandedGroups(); // 重新初始化分组展开状态
    }
    if (_currentUser != widget.currentUser) {
      // 当前用户变化时
      setState(() {
        _currentUser = widget.currentUser; // 更新当前用户
      });
    }
  }

  /// 判断列表是否可能发生变化。
  ///
  /// [a]：旧列表。
  /// [b]：新列表。
  /// 返回 true 表示列表可能发生变化，否则返回 false。
  bool _listPossiblyChanged(List<UserActivity> a, List<UserActivity> b) {
    if (a.length != b.length) return true; // 长度不同则变化
    if (a.isEmpty) return false; // 均为空则无变化
    return a.first.id != b.first.id; // 首项ID不同则变化
  }

  /// 初始化分组展开状态。
  ///
  /// 清空现有状态，并根据折叠模式默认展开第一个分组。
  void _initExpandedGroups() {
    _expandedGroups.clear(); // 清空展开状态
    if (widget.collapseMode == FeedCollapseMode.none) return; // 不折叠模式时返回
    final groups = _getGroupedActivities(); // 获取分组活动
    if (groups.isNotEmpty) {
      final firstKey = groups.keys.first; // 第一个分组的键
      _expandedGroups[firstKey] = true; // 默认展开第一个分组
      groups.keys
          .where((key) => key != firstKey)
          .forEach((key) => _expandedGroups[key] = false); // 其他分组收起
    }
  }

  /// 获取分组后的活动列表。
  ///
  /// 根据折叠模式按用户或按类型分组活动。
  Map<String, List<UserActivity>> _getGroupedActivities() {
    if (widget.collapseMode == FeedCollapseMode.none) {
      // 不折叠模式时返回所有活动在一个组中
      return {'all': widget.activities};
    }
    final Map<String, List<UserActivity>> grouped = {}; // 分组 Map
    for (final activity in widget.activities) {
      String key = (widget.collapseMode == FeedCollapseMode.byUser)
          ? (activity.userId)
          : activity.type; // 根据模式获取分组键
      grouped.putIfAbsent(key, () => []).add(activity); // 添加活动到对应分组
    }
    return grouped;
  }

  /// 获取分组图标。
  ///
  /// [key]：分组键。
  /// 返回分组对应的图标。
  IconData _getGroupIcon(String key) {
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      // 按用户分组时返回人物图标
      return Icons.person_outline;
    }
    return ActivityTypeUtils.getActivityTypeIcon(key); // 按类型分组时返回活动类型图标
  }

  /// 获取分组颜色。
  ///
  /// [key]：分组键。
  /// 返回分组对应的颜色。
  Color _getGroupColor(String key) {
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      // 按用户分组时返回随机用户颜色
      List<Color> userColors = [
        Colors.blue.shade300,
        Colors.red.shade300,
        Colors.green.shade300,
        Colors.purple.shade300,
        Colors.orange.shade300,
        Colors.teal.shade300,
        Colors.indigo.shade300,
        Colors.pink.shade300
      ];
      return userColors[key.hashCode % userColors.length];
    }
    return ActivityTypeUtils.getActivityTypeBackgroundColor(
        key); // 按类型分组时返回活动类型背景色
  }

  /// 构建组件。
  ///
  /// 根据加载状态、错误状态和活动列表是否为空显示不同的 UI。
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.activities.isEmpty) {
      // 加载中且活动列表为空时显示加载组件
      return const LoadingWidget(message: "加载中...");
    }
    if (widget.error.isNotEmpty && widget.activities.isEmpty) {
      // 有错误且活动列表为空时显示错误状态
      return Center(
        child: ActivityEmptyState(
            message: widget.error,
            icon: Icons.error_outline,
            onRefresh: widget.onRefresh),
      );
    }
    if (widget.activities.isEmpty) {
      // 活动列表为空时显示空状态
      return ActivityEmptyState(
          message: '暂无动态内容',
          icon: Icons.feed_outlined,
          onRefresh: widget.onRefresh);
    }

    final groupedActivities = _getGroupedActivities(); // 获取分组活动
    return RefreshIndicator(
      onRefresh: widget.onRefresh, // 刷新回调
      child: widget.collapseMode == FeedCollapseMode.none // 根据折叠模式构建不同 UI
          ? _buildStandardFeed()
          : _buildCollapsibleFeed(groupedActivities),
    );
  }

  /// 构建标准动态流。
  ///
  /// 显示所有活动，不进行分组折叠。
  Widget _buildStandardFeed() {
    return ListView.builder(
      controller: widget.scrollController, // 滚动控制器
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // 内边距
      itemCount:
          widget.activities.length + (widget.isLoadingMore ? 1 : 0), // 项数量
      itemBuilder: (context, index) {
        if (index == widget.activities.length) {
          // 最后一项且正在加载更多时显示加载指示器
          return const LoadingWidget(
            size: 24,
          );
        }
        final activity = widget.activities[index]; // 当前活动
        final bool isAlternate =
            widget.useAlternatingLayout && index % 2 == 1; // 是否交替布局

        return AnimatedFeedItem(
          // 动画列表项
          position: index, // 位置
          horizontalOffset: isAlternate ? 50.0 : -50.0, // 水平偏移
          child: ActivityCard(
            // 活动卡片
            key: ValueKey(activity.id),
            activity: activity,
            currentUser: widget.currentUser,
            infoService: widget.infoService,
            followService: widget.followService,
            inputStateService: widget.inputStateService,
            isAlternate: isAlternate, // 是否交替布局
            onActivityTap: widget.onActivityTap, // 活动点击回调
            onDelete: widget.onDeleteActivity != null
                ? () => widget.onDeleteActivity!(activity)
                : null, // 删除回调
            onEdit: widget.onEditActivity != null
                ? () => widget.onEditActivity!(activity)
                : null, // 编辑回调
            onLike: widget.onLikeActivity != null
                ? () => widget.onLikeActivity!(activity.id)
                : null, // 点赞回调
            onUnlike: widget.onUnlikeActivity != null
                ? () => widget.onUnlikeActivity!(activity.id)
                : null, // 取消点赞回调
            onAddComment: widget.onAddComment, // 添加评论回调
            onDeleteComment: widget.onDeleteComment, // 删除评论回调
            onLikeComment: widget.onLikeComment, // 点赞评论回调
            onUnlikeComment: widget.onUnlikeComment, // 取消点赞评论回调
          ),
        );
      },
    );
  }

  /// 构建可折叠动态流。
  ///
  /// [groupedActivities]：分组后的活动列表。
  /// 显示分组后的活动，并支持折叠/展开。
  Widget _buildCollapsibleFeed(
      Map<String, List<UserActivity>> groupedActivities) {
    return ListView.builder(
      controller: widget.scrollController, // 滚动控制器
      padding: const EdgeInsets.symmetric(vertical: 8), // 内边距
      itemCount:
          groupedActivities.length + (widget.isLoadingMore ? 1 : 0), // 项数量
      itemBuilder: (context, index) {
        if (index == groupedActivities.length) {
          // 最后一项且正在加载更多时显示加载指示器
          return const LoadingWidget();
        }

        final groupKey = groupedActivities.keys.elementAt(index); // 分组键
        final activities = groupedActivities[groupKey]!; // 分组活动
        final isExpanded = _expandedGroups[groupKey] ?? false; // 是否展开
        return _buildCollapsibleGroup(
            groupKey, activities, isExpanded, index); // 构建可折叠分组
      },
    );
  }

  /// 构建分组的头部 UI。
  ///
  /// [groupKey]：分组键。
  /// [activities]：分组内的活动列表。
  /// [isExpanded]：分组是否展开。
  /// [groupColor]：分组颜色。
  /// [groupIcon]：分组图标。
  /// [rotationAnimation]：旋转动画。
  /// 返回分组的头部组件，包含图标、标题和展开/折叠箭头。
  Widget _buildGroupHeader({
    required String groupKey,
    required List<UserActivity> activities,
    required bool isExpanded,
    required Color groupColor,
    required IconData groupIcon,
    required Animation<double> rotationAnimation,
  }) {
    return InkWell(
      onTap: () {
        // 点击切换展开状态
        HapticFeedback.lightImpact(); // 轻微震动反馈
        setState(() => _expandedGroups[groupKey] = !isExpanded); // 切换展开状态
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 内边距
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // 渐变背景
            colors: [
              groupColor.withSafeOpacity(0.7),
              groupColor.withSafeOpacity(0.9)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // 内边距
              decoration: BoxDecoration(
                color: Colors.white.withSafeOpacity(0.3), // 背景色
                borderRadius: BorderRadius.circular(8), // 圆角
              ),
              child: Icon(groupIcon, color: Colors.white, size: 20), // 图标
            ),
            const SizedBox(width: 12), // 间距
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
                children: [
                  if (widget.collapseMode ==
                      FeedCollapseMode.byUser) // 按用户分组时显示用户信息徽章
                    UserInfoBadge(
                      key: ValueKey("badge_$groupKey"), // 唯一键
                      targetUserId: groupKey, // 目标用户ID
                      infoService: widget.infoService, // 用户信息 Provider
                      followService: widget.followService, // 关注服务
                      currentUser: widget.currentUser, // 当前用户
                      mini: true, // 迷你模式
                      showFollowButton: false, // 不显示关注按钮
                      showLevel: false, // 不显示等级
                      showCheckInStats: false, // 不显示签到统计
                      backgroundColor: Colors.transparent, // 背景色透明
                      padding: EdgeInsets.zero, // 内边距
                      textColor: Colors.white, // 文本颜色
                    )
                  else // 否则显示活动类型文本
                    Text(
                      ActivityTypeUtils.getActivityTypeDisplayInfo(groupKey)
                          .text, // 活动类型显示文本
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white), // 文本样式
                    ),
                  Text(
                    '共${activities.length}条动态', // 动态数量文本
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withSafeOpacity(0.8),
                    ), // 文本样式
                  ),
                ],
              ),
            ),
            RotationTransition(
              turns: rotationAnimation, // 旋转动画
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withSafeOpacity(0.3), // 背景色
                  shape: BoxShape.circle, // 形状为圆形
                ),
                padding: const EdgeInsets.all(4), // 内边距
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24,
                ), // 图标
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个可折叠的分组 UI。
  ///
  /// [groupKey]：分组键。
  /// [activities]：分组内的活动列表。
  /// [isExpanded]：分组是否展开。
  /// [groupIndex]：分组索引。
  /// 返回可折叠的分组组件。
  Widget _buildCollapsibleGroup(
    String groupKey,
    List<UserActivity> activities,
    bool isExpanded,
    int groupIndex,
  ) {
    final Color groupColor = _getGroupColor(groupKey); // 分组颜色
    final IconData groupIcon = _getGroupIcon(groupKey); // 分组图标

    final Animation<double> rotationAnimation = Tween(begin: 0.0, end: 0.5)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOut)); // 旋转动画

    if (isExpanded) {
      _animationController.forward(); // 展开时向前播放动画
    } else {
      _animationController.reverse(); // 收起时反向播放动画
    }

    return AnimatedFeedItem(
      // 动画列表项
      position: groupIndex, // 位置
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16), // 外边距
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // 圆角
          boxShadow: [
            // 阴影
            BoxShadow(
              color: groupColor.withSafeOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Material(
          color: Colors.white, // 背景色
          borderRadius: BorderRadius.circular(12), // 圆角
          clipBehavior: Clip.antiAlias, // 裁剪行为
          child: Column(
            children: [
              _buildGroupHeader(
                groupKey: groupKey, // 分组键
                activities: activities, // 分组活动
                isExpanded: isExpanded, // 是否展开
                groupColor: groupColor, // 分组颜色
                groupIcon: groupIcon, // 分组图标
                rotationAnimation: rotationAnimation, // 旋转动画
              ),
              AnimatedSize(
                // 动画尺寸
                duration: const Duration(milliseconds: 300), // 动画时长
                curve: Curves.easeInOut, // 动画曲线
                child: isExpanded // 根据展开状态显示内容
                    ? _buildExpandedContent(activities) // 展开内容
                    : _buildCollapsedPreview(activities, groupColor), // 折叠预览
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建展开状态的内容。
  ///
  /// [activities]：活动列表。
  /// 返回展开后的活动列表视图。
  Widget _buildExpandedContent(List<UserActivity> activities) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动
      shrinkWrap: true, // 根据内容收缩
      itemCount: activities.length, // 项数量
      separatorBuilder: (context, index) => Divider(
          // 分隔线
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final activity = activities[index]; // 当前活动
        final bool isAlternate =
            widget.useAlternatingLayout && index % 2 == 1; // 是否交替布局

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // 内边距
          child: ActivityCard(
            key: ValueKey(activity.id), activity: activity,
            currentUser: widget.currentUser,
            infoService: widget.infoService,
            inputStateService: widget.inputStateService,
            followService: widget.followService,
            isAlternate: isAlternate, // 是否交替布局
            onActivityTap: widget.onActivityTap,
            hasOwnBackground: false, // 活动点击回调
            onDelete: widget.onDeleteActivity != null
                ? () => widget.onDeleteActivity!(activity)
                : null, // 删除回调
            onEdit: widget.onEditActivity != null
                ? () => widget.onEditActivity!(activity)
                : null, // 编辑回调
            onLike: widget.onLikeActivity != null
                ? () => widget.onLikeActivity!(activity.id)
                : null, // 点赞回调
            onUnlike: widget.onUnlikeActivity != null
                ? () => widget.onUnlikeActivity!(activity.id)
                : null, // 取消点赞回调
            onAddComment: widget.onAddComment, // 添加评论回调
            onDeleteComment: widget.onDeleteComment, // 删除评论回调
            onLikeComment: widget.onLikeComment, // 点赞评论回调
            onUnlikeComment: widget.onUnlikeComment, // 取消点赞评论回调
          ),
        );
      },
    );
  }

  /// 构建折叠状态的预览内容。
  ///
  /// [activities]：活动列表。
  /// [groupColor]：分组颜色。
  /// 返回一个包含最新活动简要信息和展开按钮的预览组件。
  Widget _buildCollapsedPreview(
      List<UserActivity> activities, Color groupColor) {
    if (activities.isEmpty) return const SizedBox.shrink(); // 活动为空时返回空组件
    final latestActivity = activities.first; // 最新活动
    return InkWell(
      onTap: () {
        // 点击展开分组
        setState(
          () {
            final String groupKey =
                (widget.collapseMode == FeedCollapseMode.byUser)
                    ? (latestActivity.userId)
                    : latestActivity.type; // 分组键
            _expandedGroups[groupKey] = true; // 展开分组
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16), // 内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4), // 内边距
                  decoration: BoxDecoration(
                    color: groupColor.withSafeOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ), // 装饰
                  child: Text(
                    DateTimeFormatter.formatTimeAgo(
                        latestActivity.createTime), // 格式化时间
                    style: TextStyle(
                      fontSize: 12,
                      color: groupColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12), // 间距
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
                    children: [
                      if (latestActivity.content.isNotEmpty) // 显示活动内容
                        Text(latestActivity.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade800)),
                      Row(
                        children: [
                          Icon(
                            ActivityTypeUtils.getActivityTypeIcon(
                                latestActivity.type), // 活动类型图标
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(
                            width: 4,
                          ), // 间距
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // 间距
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16), // 内边距
                decoration: BoxDecoration(
                  color: groupColor.withSafeOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: groupColor.withSafeOpacity(0.3),
                  ),
                ), // 装饰
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('查看全部${activities.length}条动态', // 文本
                        style: TextStyle(
                            color: groupColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4), // 间距
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: groupColor,
                    ) // 图标
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
