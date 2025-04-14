import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import 'dart:collection'; // LinkedHashMap
import 'dart:math' as math; // math.Random 等
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_card.dart';
import 'package:suxingchahui/widgets/components/screen/activity/common/activity_empty_state.dart';
import 'package:suxingchahui/utils/activity/activity_type_utils.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

enum FeedCollapseMode { none, byUser, byType }

class CollapsibleActivityFeed extends StatefulWidget {
  final List<UserActivity> activities;
  final bool isLoading;
  final bool isLoadingMore;
  final String error;
  final FeedCollapseMode collapseMode;
  final bool useAlternatingLayout;
  final Function(UserActivity) onActivityTap;
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final ScrollController scrollController;

  final FutureOr<void> Function(String activityId)? onDeleteActivity; // 返回 FutureOr<void> 或 Future<void>
  final FutureOr<void> Function(String activityId)? onLikeActivity;
  final FutureOr<void> Function(String activityId)? onUnlikeActivity;
  final FutureOr<ActivityComment?> Function(String activityId, String content)? onAddComment;
  final FutureOr<void> Function(String activityId, String commentId)? onDeleteComment; // 修改这里！
  final FutureOr<void> Function(String activityId, String commentId)? onLikeComment;   // 修改这里！
  final FutureOr<void> Function(String activityId, String commentId)? onUnlikeComment; // 修改这里！
  final VoidCallback? Function(String activityId)? onEditActivity; // 这个返回 VoidCallback? 可能也需要调整，取决于具体逻辑，暂时保持
  const CollapsibleActivityFeed({
    Key? key,
    required this.activities,
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
  }) : super(key: key);

  @override
  _CollapsibleActivityFeedState createState() => _CollapsibleActivityFeedState();
}

class _CollapsibleActivityFeedState extends State<CollapsibleActivityFeed> with SingleTickerProviderStateMixin {
  final Map<String, bool> _expandedGroups = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
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
    if (oldWidget.collapseMode != widget.collapseMode || _listPossiblyChanged(oldWidget.activities, widget.activities)) {
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
      groups.keys.where((key) => key != firstKey).forEach((key) => _expandedGroups[key] = false);
    }
  }

  Map<String, List<UserActivity>> _getGroupedActivities() {
    if (widget.collapseMode == FeedCollapseMode.none) return {'all': widget.activities};
    final Map<String, List<UserActivity>> grouped = LinkedHashMap();
    for (final activity in widget.activities) {
      String key = (widget.collapseMode == FeedCollapseMode.byUser)
          ? (activity.user?['userId'] ?? 'unknown_user_${activity.user?['username'] ?? math.Random().nextInt(1000)}')
          : activity.type;
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    return grouped;
  }

  String _getGroupTitle(String groupKey, List<UserActivity> activities) {
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      return '${activities.first.user?['username'] ?? '未知用户'} 的动态';
    } else {
      return ActivityTypeUtils.getActivityTypeDisplayInfo(groupKey).text;
    }
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
      List<Color> userColors = [Colors.blue.shade300, Colors.red.shade300, Colors.green.shade300, Colors.purple.shade300, Colors.orange.shade300, Colors.teal.shade300, Colors.indigo.shade300, Colors.pink.shade300];
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
      return Center(child: ActivityEmptyState(message: widget.error, icon: Icons.error_outline, onRefresh: widget.onRefresh));
    }
    if (widget.activities.isEmpty) {
      return ActivityEmptyState(message: '暂无动态内容', icon: Icons.feed_outlined, onRefresh: widget.onRefresh);
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
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final activity = widget.activities[index];
        final bool isAlternate = widget.useAlternatingLayout && index % 2 == 1;
        return AnimationConfiguration.staggeredList(
          position: index, duration: const Duration(milliseconds: 375),
          child: SlideAnimation(verticalOffset: 50.0, horizontalOffset: isAlternate ? 50.0 : -50.0,
            child: FadeInAnimation(
              child: ActivityCard(
                key: ValueKey(activity.id), activity: activity, isAlternate: isAlternate,
                onActivityTap: widget.onActivityTap,
                onDelete: widget.onDeleteActivity != null ? () => widget.onDeleteActivity!(activity.id) : null,
                onEdit: widget.onEditActivity != null ? () => widget.onEditActivity!(activity.id) : null,
                onLike: widget.onLikeActivity != null ? () => widget.onLikeActivity!(activity.id) : null,
                onUnlike: widget.onUnlikeActivity != null ? () => widget.onUnlikeActivity!(activity.id) : null,
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

  Widget _buildCollapsibleFeed(Map<String, List<UserActivity>> groupedActivities) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedActivities.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedActivities.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final groupKey = groupedActivities.keys.elementAt(index);
        final activities = groupedActivities[groupKey]!;
        final isExpanded = _expandedGroups[groupKey] ?? false;
        return _buildCollapsibleGroup(groupKey, activities, isExpanded, index);
      },
    );
  }

  Widget _buildCollapsibleGroup(String groupKey, List<UserActivity> activities, bool isExpanded, int groupIndex) {
    final Color groupColor = _getGroupColor(groupKey);
    final IconData groupIcon = _getGroupIcon(groupKey);
    final String title = _getGroupTitle(groupKey, activities);
    final Animation<double> rotationAnimation = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    if (isExpanded) { _animationController.forward(); } else { _animationController.reverse(); }

    return AnimationConfiguration.staggeredList(
      position: groupIndex, duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: groupColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // --- 分组标题栏 (完整实现) ---
                  InkWell(
                    onTap: () { HapticFeedback.lightImpact(); setState(() => _expandedGroups[groupKey] = !isExpanded); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [groupColor.withOpacity(0.7), groupColor.withOpacity(0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(8)), child: Icon(groupIcon, color: Colors.white, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)), Text('共${activities.length}条动态', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)))] )),
                          RotationTransition(turns: rotationAnimation, child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24))),
                        ],
                      ),
                    ),
                  ),
                  // --- 折叠内容 ---
                  AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
                    child: isExpanded ? _buildExpandedContent(activities) : _buildCollapsedPreview(activities, groupColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(List<UserActivity> activities) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
      itemCount: activities.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final bool isAlternate = widget.useAlternatingLayout && index % 2 == 1;
        // --- 创建 ActivityCard 并传递所有回调 ---
        return ActivityCard( // <--- **传递所有回调给 ActivityCard**
          key: ValueKey(activity.id), activity: activity, isAlternate: isAlternate,
          onActivityTap: widget.onActivityTap, hasOwnBackground: false,
          // --- 操作回调传递 ---
          onDelete: widget.onDeleteActivity != null ? () => widget.onDeleteActivity!(activity.id) : null,
          onEdit: widget.onEditActivity != null ? () => widget.onEditActivity!(activity.id) : null,
          onLike: widget.onLikeActivity != null ? () => widget.onLikeActivity!(activity.id) : null,
          onUnlike: widget.onUnlikeActivity != null ? () => widget.onUnlikeActivity!(activity.id) : null,
          onAddComment: widget.onAddComment,
          onDeleteComment: widget.onDeleteComment,
          onLikeComment: widget.onLikeComment,
          onUnlikeComment: widget.onUnlikeComment,
        );
      },
    );
  }

  Widget _buildCollapsedPreview(List<UserActivity> activities, Color groupColor) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final latestActivity = activities.first;
    return InkWell(
      onTap: () { setState(() { final String groupKey = (widget.collapseMode == FeedCollapseMode.byUser) ? (latestActivity.user?['userId'] ?? 'unknown') : latestActivity.type; _expandedGroups[groupKey] = true; }); },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: groupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(_formatTimeAgo(latestActivity.createTime), style: TextStyle(fontSize: 12, color: groupColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (latestActivity.content.isNotEmpty) Text(latestActivity.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                if (latestActivity.targetType != null) Row(children: [Icon(_getTargetTypeIcon(latestActivity.targetType!), size: 14, color: Colors.grey.shade600), const SizedBox(width: 4), Expanded(child: Text(_getTargetTitle(latestActivity), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)))]),
              ])),
            ]),
            const SizedBox(height: 12),
            Center(child: Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), decoration: BoxDecoration(color: groupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: groupColor.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text('查看全部${activities.length}条动态', style: TextStyle(color: groupColor, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Icon(Icons.keyboard_arrow_down, size: 16, color: groupColor)]))),
          ],
        ),
      ),
    );
  }

  IconData _getTargetTypeIcon(String targetType) { switch (targetType) { case 'game': return Icons.videogame_asset_outlined; case 'post': return Icons.article_outlined; case 'user': return Icons.person_outline; default: return Icons.link; }}
  String _getTargetTitle(UserActivity activity) { if (activity.target == null) return '未知目标'; switch (activity.targetType) { case 'game': return activity.target!['title'] ?? '未知游戏'; case 'post': return activity.target!['title'] ?? '未知帖子'; case 'user': return activity.target!['username'] ?? '未知用户'; default: return '未知目标'; }}
  String _formatTimeAgo(DateTime dateTime) { return DateTimeFormatter.formatRelative(dateTime); }

} // _CollapsibleActivityFeedState 类结束