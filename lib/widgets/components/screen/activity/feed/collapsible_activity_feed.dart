// lib/widgets/components/screen/activity/feed/collapsible_activity_feed.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:suxingchahui/widgets/components/screen/activity/common/activity_empty_state.dart';
import 'package:flutter/services.dart';
import 'dart:collection';

enum FeedCollapseMode {
  none,
  byUser,
  byType
}

class CollapsibleActivityFeed extends StatefulWidget {
  final List<UserActivity> activities;
  final bool isLoading;
  final bool isLoadingMore;
  final String error;
  final FeedCollapseMode collapseMode;
  final bool useAlternatingLayout;
  final Function(UserActivity) onActivityTap;
  final VoidCallback onRefresh;
  final VoidCallback? onLoadMore;
  final ScrollController scrollController;

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
  }) : super(key: key);

  @override
  _CollapsibleActivityFeedState createState() => _CollapsibleActivityFeedState();
}

class _CollapsibleActivityFeedState extends State<CollapsibleActivityFeed> with SingleTickerProviderStateMixin {
  // 存储展开/折叠状态的Map
  final Map<String, bool> _expandedGroups = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // 默认情况下只展开第一个组
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
        oldWidget.activities.length != widget.activities.length) {
      _initExpandedGroups();
    }
  }

  // 初始化折叠状态，默认只展开第一个组
  void _initExpandedGroups() {
    _expandedGroups.clear();

    if (widget.collapseMode == FeedCollapseMode.none) {
      return;
    }

    final groups = _getGroupedActivities();
    if (groups.isNotEmpty) {
      String firstKey = groups.keys.first;
      _expandedGroups[firstKey] = true;

      // 其余的组默认折叠
      for (final key in groups.keys) {
        if (key != firstKey) {
          _expandedGroups[key] = false;
        }
      }
    }
  }

  // 根据折叠模式对活动进行分组
  Map<String, List<UserActivity>> _getGroupedActivities() {
    if (widget.collapseMode == FeedCollapseMode.none) {
      return {'all': widget.activities};
    }

    final Map<String, List<UserActivity>> grouped = LinkedHashMap();

    for (final activity in widget.activities) {
      String key;

      if (widget.collapseMode == FeedCollapseMode.byUser) {
        // 按用户分组
        key = activity.user?['userId'] ?? 'unknown';
      } else {
        // 按活动类型分组
        key = activity.type;
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(activity);
    }

    return grouped;
  }

  // 获取分组标题
  String _getGroupTitle(String groupKey, List<UserActivity> activities) {
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      final username = activities.first.user?['username'] ?? '未知用户';
      return '$username的动态';
    } else {
      // 按活动类型显示标题
      String typeText;
      switch (groupKey) {
        case 'game_comment':
          typeText = '游戏评论';
          break;
        case 'game_like':
          typeText = '游戏点赞';
          break;
        case 'post_create':
          typeText = '发布帖子';
          break;
        case 'post_reply':
          typeText = '帖子回复';
          break;
        case 'check_in':
          typeText = '签到';
          break;
        case 'collection':
          typeText = '游戏收藏';
          break;
        case 'follow':
          typeText = '关注用户';
          break;
        case 'achievement':
          typeText = '成就解锁';
          break;
        default:
          typeText = '其他动态';
      }
      return typeText;
    }
  }

  // 获取分组图标
  IconData _getGroupIcon(String key) {
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      return Icons.person;
    }

    // 按活动类型返回适当的图标
    switch (key) {
      case 'game_comment':
        return Icons.comment;
      case 'game_like':
        return Icons.favorite;
      case 'post_create':
        return Icons.post_add;
      case 'post_reply':
        return Icons.reply;
      case 'check_in':
        return Icons.check_circle;
      case 'collection':
        return Icons.collections_bookmark;
      case 'follow':
        return Icons.people;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.feed;
    }
  }

  // 获取分组颜色
  Color _getGroupColor(String key) {
    if (widget.collapseMode == FeedCollapseMode.byUser) {
      // 为每个用户分配一个不同的颜色
      List<Color> userColors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.purple,
        Colors.orange,
        Colors.teal,
        Colors.indigo,
        Colors.pink
      ];
      return userColors[key.hashCode % userColors.length];
    }

    // 按活动类型返回适当的颜色
    switch (key) {
      case 'game_comment':
        return Colors.blue;
      case 'game_like':
        return Colors.pink;
      case 'post_create':
        return Colors.green;
      case 'post_reply':
        return Colors.teal;
      case 'check_in':
        return Colors.amber;
      case 'collection':
        return Colors.deepPurple;
      case 'follow':
        return Colors.indigo;
      case 'achievement':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.error.isNotEmpty && widget.activities.isEmpty) {
      return ActivityEmptyState(
        message: widget.error,
        icon: Icons.error_outline,
        onRefresh: widget.onRefresh,
      );
    }

    if (widget.activities.isEmpty) {
      return const ActivityEmptyState(
        message: '暂无动态内容',
        icon: Icons.feed_outlined,
      );
    }

    final groupedActivities = _getGroupedActivities();

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
      },
      child: widget.collapseMode == FeedCollapseMode.none
          ? _buildStandardFeed()
          : _buildCollapsibleFeed(groupedActivities),
    );
  }

  // 构建标准活动流（无折叠）
  Widget _buildStandardFeed() {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.activities.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.activities.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
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
                activity: activity,
                isAlternate: isAlternate,
                onActivityTap: widget.onActivityTap,
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建可折叠的活动流
  Widget _buildCollapsibleFeed(Map<String, List<UserActivity>> groupedActivities) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedActivities.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedActivities.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final groupKey = groupedActivities.keys.elementAt(index);
        final activities = groupedActivities[groupKey]!;
        final isExpanded = _expandedGroups[groupKey] ?? false;

        return _buildCollapsibleGroup(
          groupKey,
          activities,
          isExpanded,
          index,
        );
      },
    );
  }

  // 构建可折叠的活动组
  Widget _buildCollapsibleGroup(String groupKey, List<UserActivity> activities, bool isExpanded, int index) {
    final Color groupColor = _getGroupColor(groupKey);
    final IconData groupIcon = _getGroupIcon(groupKey);
    final String title = _getGroupTitle(groupKey, activities);

    // 创建展开/折叠的动画
    final Animation<double> rotationAnimation = Tween(begin: 0.0, end: 0.5)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: groupColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // 分组标题栏
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _expandedGroups[groupKey] = !isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            groupColor.withOpacity(0.7),
                            groupColor.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              groupIcon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '共${activities.length}条动态',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RotationTransition(
                            turns: rotationAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 折叠/展开的内容区域
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      color: Colors.white,
                      child: isExpanded
                          ? _buildExpandedContent(activities)
                          : _buildCollapsedPreview(activities, groupColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建展开状态的内容
  Widget _buildExpandedContent(List<UserActivity> activities) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final bool isAlternate = widget.useAlternatingLayout && index % 2 == 1;

        return InkWell(
          onTap: () => widget.onActivityTap(activity),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ActivityCard(
              activity: activity,
              isAlternate: isAlternate,
              hasOwnBackground: false,
            ),
          ),
        );
      },
    );
  }

  // 构建折叠状态的预览
  Widget _buildCollapsedPreview(List<UserActivity> activities, Color groupColor) {
    if (activities.isEmpty) return const SizedBox.shrink();

    // 只显示最新的一条动态作为预览
    final latestActivity = activities.first;

    return InkWell(
      onTap: () {
        setState(() {
          final String groupKey;
          if (widget.collapseMode == FeedCollapseMode.byUser) {
            groupKey = latestActivity.user?['userId'] ?? 'unknown';
          } else {
            groupKey = latestActivity.type;
          }
          _expandedGroups[groupKey] = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览最新的一条动态
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 动态创建时间
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatTimeAgo(latestActivity.createTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: groupColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 动态内容预览
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 内容文本
                      if (latestActivity.content.isNotEmpty)
                        Text(
                          latestActivity.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),

                      // 目标信息（仅显示类型和简短信息）
                      if (latestActivity.targetType != null)
                        Row(
                          children: [
                            Icon(
                              _getTargetTypeIcon(latestActivity.targetType!),
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getTargetTitle(latestActivity),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // "查看全部"按钮
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: groupColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: groupColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '查看全部${activities.length}条动态',
                      style: TextStyle(
                        color: groupColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: groupColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取目标类型的图标
  IconData _getTargetTypeIcon(String targetType) {
    switch (targetType) {
      case 'game':
        return Icons.videogame_asset;
      case 'post':
        return Icons.article;
      case 'user':
        return Icons.person;
      default:
        return Icons.circle;
    }
  }

  // 获取目标标题
  String _getTargetTitle(UserActivity activity) {
    if (activity.target == null) {
      return '未知目标';
    }

    switch (activity.targetType) {
      case 'game':
        return activity.target!['title'] ?? '未知游戏';
      case 'post':
        return activity.target!['title'] ?? '未知帖子';
      case 'user':
        return activity.target!['username'] ?? '未知用户';
      default:
        return '未知目标';
    }
  }

  // 格式化时间
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  // 获取所有分组的键值对
  Map<String, List<UserActivity>> get groupedActivities => _getGroupedActivities();
}