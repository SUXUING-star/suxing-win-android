import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_card.dart';
import 'package:suxingchahui/widgets/components/screen/activity/common/activity_empty_state.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

enum FeedCollapseMode { none, byUser, byType }

class CollapsibleActivityFeed extends StatefulWidget {
  final List<UserActivity> activities;
  final User? currentUser;
  final bool isLoading;
  final bool isLoadingMore;
  final String error;
  final FeedCollapseMode collapseMode;
  final bool useAlternatingLayout;
  final Function(UserActivity) onActivityTap;
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final ScrollController scrollController;

  final FutureOr<void> Function(String activityId)?
      onDeleteActivity; // 返回 FutureOr<void> 或 Future<void>
  final FutureOr<void> Function(String activityId)? onLikeActivity;
  final FutureOr<void> Function(String activityId)? onUnlikeActivity;
  final FutureOr<ActivityComment?> Function(String activityId, String content)?
      onAddComment;
  final FutureOr<void> Function(String activityId, String commentId)?
      onDeleteComment; // 修改这里！
  final FutureOr<void> Function(String activityId, String commentId)?
      onLikeComment; // 修改这里！
  final FutureOr<void> Function(String activityId, String commentId)?
      onUnlikeComment; // 修改这里！
  final VoidCallback? Function(String activityId)?
      onEditActivity; // 这个返回 VoidCallback? 可能也需要调整，取决于具体逻辑，暂时保持
  const CollapsibleActivityFeed({
    super.key,
    required this.activities,
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

  @override
  _CollapsibleActivityFeedState createState() =>
      _CollapsibleActivityFeedState();
}

class _CollapsibleActivityFeedState extends State<CollapsibleActivityFeed>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _expandedGroups = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _initExpandedGroups();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CollapsibleActivityFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapseMode != widget.collapseMode ||
        _listPossiblyChanged(oldWidget.activities, widget.activities)) {
      _initExpandedGroups();
    }
  }

  bool _listPossiblyChanged(List<UserActivity> a, List<UserActivity> b) {
    if (a.length != b.length) return true;
    if (a.isEmpty) return false;
    return a.first.id != b.first.id;
  }

  void _initExpandedGroups() {
    _expandedGroups.clear();
    if (widget.collapseMode == FeedCollapseMode.none) return;
    final groups = _getGroupedActivities();
    if (groups.isNotEmpty) {
      final firstKey = groups.keys.first;
      _expandedGroups[firstKey] = true;
      groups.keys
          .where((key) => key != firstKey)
          .forEach((key) => _expandedGroups[key] = false);
    }
  }

  Map<String, List<UserActivity>> _getGroupedActivities() {
    if (widget.collapseMode == FeedCollapseMode.none) {
      return {'all': widget.activities};
    }
    final Map<String, List<UserActivity>> grouped = {};
    for (final activity in widget.activities) {
      String key = (widget.collapseMode == FeedCollapseMode.byUser)
          ? (activity.userId)
          : activity.type;
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    return grouped;
  }

  IconData _getGroupIcon(String key) {
    // 如果是按用户分组，还是返回用户图标
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      return Icons.person_outline;
    }
    // --- !!! 直接调用工具类获取图标 !!! ---
    return ActivityTypeUtils.getActivityTypeIcon(key);
  }

  // --- 获取分组颜色 (修正后) ---
  Color _getGroupColor(String key) {
    // 如果是按用户分组，保持原来的颜色逻辑
    if (widget.collapseMode == FeedCollapseMode.byUser) {
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
    // --- !!! 直接调用工具类获取背景色 !!! ---
    // 注意：工具类返回的是背景色，如果需要不同的颜色逻辑，可以在这里调整
    return ActivityTypeUtils.getActivityTypeBackgroundColor(key);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.activities.isEmpty) {
      return LoadingWidget.inline(message: "加载中...");
    }
    if (widget.error.isNotEmpty && widget.activities.isEmpty) {
      return Center(
          child: ActivityEmptyState(
              message: widget.error,
              icon: Icons.error_outline,
              onRefresh: widget.onRefresh));
    }
    if (widget.activities.isEmpty) {
      return ActivityEmptyState(
          message: '暂无动态内容',
          icon: Icons.feed_outlined,
          onRefresh: widget.onRefresh);
    }

    final groupedActivities = _getGroupedActivities();
    return RefreshIndicator(
      onRefresh: widget.onRefresh, // 使用父级传递的 onRefresh
      child: widget.collapseMode == FeedCollapseMode.none
          ? _buildStandardFeed()
          : _buildCollapsibleFeed(groupedActivities),
    );
  }

  Widget _buildStandardFeed() {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: widget.activities.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.activities.length) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final activity = widget.activities[index];
        final bool isAlternate = widget.useAlternatingLayout && index % 2 == 1;
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            horizontalOffset: isAlternate ? 50.0 : -50.0,
            child: FadeInAnimation(
              child: ActivityCard(
                key: ValueKey(activity.id),
                currentUser: widget.currentUser,
                activity: activity,
                isAlternate: isAlternate,
                onActivityTap: widget.onActivityTap,
                onDelete: widget.onDeleteActivity != null
                    ? () => widget.onDeleteActivity!(activity.id)
                    : null,
                onEdit: widget.onEditActivity != null
                    ? () => widget.onEditActivity!(activity.id)
                    : null,
                onLike: widget.onLikeActivity != null
                    ? () => widget.onLikeActivity!(activity.id)
                    : null,
                onUnlike: widget.onUnlikeActivity != null
                    ? () => widget.onUnlikeActivity!(activity.id)
                    : null,
                onAddComment: widget.onAddComment,
                onDeleteComment: widget.onDeleteComment,
                onLikeComment: widget.onLikeComment,
                onUnlikeComment: widget.onUnlikeComment,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleFeed(
      Map<String, List<UserActivity>> groupedActivities) {
    final userInfoProvider = context.watch<UserInfoProvider>();
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedActivities.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedActivities.length) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final groupKey = groupedActivities.keys.elementAt(index);
        UserDataStatus? userDataStatus;
        if (widget.collapseMode == FeedCollapseMode.byUser) {
          final String userId = groupKey;
          userInfoProvider.ensureUserInfoLoaded(userId);
          userDataStatus = userInfoProvider.getUserStatus(userId);
        }

        final activities = groupedActivities[groupKey]!;
        final isExpanded = _expandedGroups[groupKey] ?? false;
        return _buildCollapsibleGroup(
            groupKey, activities, isExpanded, index, userDataStatus);
      },
    );
  }

  // 构建单个可折叠的分组 UI
  Widget _buildCollapsibleGroup(
    String groupKey, // 分组的键 (可能是 userId 或 activityType)
    List<UserActivity> activities, // 这个分组下的所有活动
    bool isExpanded, // 当前分组是否展开
    int groupIndex, // 分组在列表中的索引 (用于动画)
    UserDataStatus? userDataStatus,
  ) {
    // --- 1. 获取分组的视觉属性 ---
    final Color groupColor = _getGroupColor(groupKey); // 根据 groupKey 获取颜色
    final IconData groupIcon = _getGroupIcon(groupKey); // 根据 groupKey 获取图标

    // --- 2. 设置折叠/展开图标的旋转动画 ---
    final Animation<double> rotationAnimation =
        Tween(begin: 0.0, end: 0.5) // 从 0 度转到 180 度
            .animate(CurvedAnimation(
                parent: _animationController, // 使用 state 里的动画控制器
                curve: Curves.easeInOut // 使用缓动曲线
                ));
    // 根据当前展开状态，控制动画向前或向后播放
    if (isExpanded) {
      _animationController.forward(); // 展开时，箭头向下 (180度)
    } else {
      _animationController.reverse(); // 折叠时，箭头向上 (0度)
    }

    // --- 3. 构建分组的整体 UI (带动画效果) ---
    return AnimationConfiguration.staggeredList(
      position: groupIndex, // 列表项的位置，用于交错动画
      duration: const Duration(milliseconds: 375), // 动画持续时间
      child: SlideAnimation(
        // 滑入动画
        verticalOffset: 50.0, // 从下方 50px 处滑入
        child: FadeInAnimation(
          // 淡入动画
          child: Container(
            // --- 4. 分组容器样式 ---
            margin:
                const EdgeInsets.only(bottom: 16, left: 16, right: 16), // 外边距
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // 圆角
                boxShadow: [
                  // 阴影效果
                  BoxShadow(
                      color: groupColor.withSafeOpacity(0.2), // 阴影颜色使用分组颜色
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            // --- 5. 使用 Material 实现水波纹效果和裁剪 ---
            child: Material(
              color: Colors.white, // 背景色
              borderRadius: BorderRadius.circular(12), // 圆角（与外层 Container 一致）
              clipBehavior: Clip.antiAlias, // 裁剪超出圆角的内容
              child: Column(
                // 垂直布局：标题栏 + 折叠内容
                children: [
                  // --- 6. 分组标题栏 (点击可折叠/展开) ---
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact(); // 轻微震动反馈
                      // 点击时，切换当前分组的展开状态
                      setState(() => _expandedGroups[groupKey] = !isExpanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12), // 内边距
                      // 标题栏背景渐变
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                        groupColor.withSafeOpacity(0.7),
                        groupColor.withSafeOpacity(0.9)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                      // --- 7. 标题栏内部 Row 布局 ---
                      child: Row(
                        children: [
                          // --- 左侧图标 ---
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withSafeOpacity(0.3), // 半透明白色背景
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(groupIcon,
                                  color: Colors.white, size: 20) // 分组图标
                              ),
                          const SizedBox(width: 12), // 图标和标题间距

                          // --- 中间标题区域 (*** 核心修改点 ***) ---
                          Expanded(
                              // 占据剩余空间
                              child: Column(
                                  // 垂直排列：主标题 + 副标题（动态数量）
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start, // 左对齐
                                  children: [
                                // **** 条件渲染：根据分组模式显示不同内容 ****
                                if (widget.collapseMode ==
                                    FeedCollapseMode.byUser)
                                  UserInfoBadge(
                                    key: ValueKey(
                                        "badge_$groupKey"), // 提供 Key 确保重建
                                    userId:
                                        groupKey, // 将 groupKey (即 userId) 传递给 Badge
                                    userDataStatus: userDataStatus!,
                                    // 这个地方当这个if条件成立上层传递这个userDataStatus不可能为空值
                                    currentUser: widget.currentUser,
                                    mini: true, // 使用紧凑模式
                                    showFollowButton: false, // 不显示关注按钮
                                    showLevel: false, // 不显示等级
                                    showCheckInStats: false, // 不显示签到
                                    backgroundColor: Colors.transparent, // 透明背景
                                    padding: EdgeInsets.zero, // 无内边距
                                    textColor: Colors.white, // 设置文字颜色以适应背景
                                  )
                                else
                                  // **** 按类型分组: 显示类型名称 Text ****
                                  Text(
                                      // 使用工具类获取类型显示名称
                                      ActivityTypeUtils
                                              .getActivityTypeDisplayInfo(
                                                  groupKey)
                                          .text,
                                      style: const TextStyle(
                                          // 标题文字样式
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white)),

                                // **** 显示动态数量 (通用) ****
                                Text('共${activities.length}条动态', // 显示分组内动态数量
                                    style: TextStyle(
                                        // 数量文字样式
                                        fontSize: 12,
                                        color: Colors.white
                                            .withSafeOpacity(0.8) // 半透明白色
                                        ))
                              ])),
                          // --- 结束中间标题区域 ---

                          // --- 右侧折叠/展开箭头 ---
                          RotationTransition(
                              turns: rotationAnimation, // 应用旋转动画
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white
                                          .withSafeOpacity(0.3), // 半透明背景
                                      shape: BoxShape.circle // 圆形
                                      ),
                                  padding: const EdgeInsets.all(4), // 内边距
                                  child: const Icon(Icons.keyboard_arrow_down,
                                      color: Colors.white, size: 24) // 向下箭头图标
                                  )),
                        ],
                      ),
                    ),
                  ), // --- 结束分组标题栏 ---

                  // --- 8. 折叠内容区域 ---
                  AnimatedSize(
                    // 高度变化动画
                    duration: const Duration(milliseconds: 300), // 动画时长
                    curve: Curves.easeInOut, // 动画曲线
                    // 根据 isExpanded 状态决定显示完整内容还是预览
                    child: isExpanded
                        ? _buildExpandedContent(activities) // 展开时显示完整列表
                        : _buildCollapsedPreview(
                            activities, groupColor), // 折叠时显示预览
                  ), // --- 结束折叠内容区域 ---
                ],
              ),
            ), // --- 结束 Material ---
          ), // --- 结束 Container ---
        ), // --- 结束 FadeInAnimation ---
      ), // --- 结束 SlideAnimation ---
    ); // --- 结束 AnimationConfiguration ---
  } // --- _buildCollapsibleGroup 方法结束 ---

  Widget _buildExpandedContent(List<UserActivity> activities) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: activities.length,
      separatorBuilder: (context, index) => Divider(
          height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final bool isAlternate = widget.useAlternatingLayout && index % 2 == 1;
        // --- 创建 ActivityCard 并传递所有回调 ---
        return Padding(
          // 添加水平方向的边距，模拟标准视图中卡片的间距
          // 你可以根据需要调整这个值，8.0 或 12.0 应该比较合适
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0, vertical: 4.0), // 增加了垂直方向的微小间距
          child: ActivityCard(
            key: ValueKey(activity.id), activity: activity,
            currentUser: widget.currentUser,
            isAlternate: isAlternate,
            onActivityTap: widget.onActivityTap, hasOwnBackground: false,
            // --- 操作回调传递 ---
            onDelete: widget.onDeleteActivity != null
                ? () => widget.onDeleteActivity!(activity.id)
                : null,
            onEdit: widget.onEditActivity != null
                ? () => widget.onEditActivity!(activity.id)
                : null,
            onLike: widget.onLikeActivity != null
                ? () => widget.onLikeActivity!(activity.id)
                : null,
            onUnlike: widget.onUnlikeActivity != null
                ? () => widget.onUnlikeActivity!(activity.id)
                : null,
            onAddComment: widget.onAddComment,
            onDeleteComment: widget.onDeleteComment,
            onLikeComment: widget.onLikeComment,
            onUnlikeComment: widget.onUnlikeComment,
          ),
        );
      },
    );
  }

  Widget _buildCollapsedPreview(
      List<UserActivity> activities, Color groupColor) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final latestActivity = activities.first;
    return InkWell(
      onTap: () {
        setState(() {
          final String groupKey =
              (widget.collapseMode == FeedCollapseMode.byUser)
                  ? (latestActivity.userId)
                  : latestActivity.type;
          _expandedGroups[groupKey] = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: groupColor.withSafeOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(_formatTimeAgo(latestActivity.createTime),
                      style: TextStyle(
                          fontSize: 12,
                          color: groupColor,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (latestActivity.content.isNotEmpty)
                      Text(latestActivity.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade800)),
                    Row(children: [
                      Icon(
                          ActivityTypeUtils.getActivityTypeIcon(
                              latestActivity.type),
                          size: 14,
                          color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                    ]),
                  ])),
            ]),
            const SizedBox(height: 12),
            Center(
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                        color: groupColor.withSafeOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: groupColor.withSafeOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('查看全部${activities.length}条动态',
                          style: TextStyle(
                              color: groupColor, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          size: 16, color: groupColor)
                    ]))),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    return DateTimeFormatter.formatRelative(dateTime);
  }
} // _CollapsibleActivityFeedState 类结束
