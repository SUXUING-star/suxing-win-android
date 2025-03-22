// lib/widgets/components/screen/activity/card/activity_card.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target.dart';
import 'package:suxingchahui/widgets/components/screen/activity/button/activity_action_buttons.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_item.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_input.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target_navigation.dart';
import '../dialog/activity_edit_dialog.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ActivityCard extends StatefulWidget {
  final UserActivity activity;
  final bool isAlternate; // 是否交替布局（用于左右交错）
  final VoidCallback? onUpdated; // 更新回调
  final bool isInDetailView; // 是否在详情页面中显示
  final Function(UserActivity)? onActivityTap; // 点击活动的回调
  final bool hasOwnBackground; // 是否有自己的背景色（用于详情页避免重叠）

  const ActivityCard({
    Key? key,
    required this.activity,
    this.isAlternate = false,
    this.onUpdated,
    this.isInDetailView = false,
    this.onActivityTap,
    this.hasOwnBackground = true,
  }) : super(key: key);

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late UserActivity _activity;
  bool _isAlternate =false;
  final UserActivityService _activityService = UserActivityService();
  bool _showComments = false;
  late double _cardHeight; // 控制卡片高度
  late double _cardWidth; // 控制卡片宽度

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _isAlternate = widget.isAlternate;
    _initializeCardProperties();
  }

  // 初始化卡片属性（保留原有的卡片高度和宽度计算逻辑）
  void _initializeCardProperties() {
    final random = math.Random(widget.activity.id.hashCode);

    final bool hasContent = _activity.content.isNotEmpty;
    final bool hasTarget = _activity.targetType != null;
    final bool hasComments = _activity.comments.isNotEmpty;

    // 高度计算
    double minHeight = 1.0;
    double maxHeight = 1.5;

    if (hasContent && hasTarget) {
      minHeight = 1.0;
      maxHeight = 1.8;
    } else if (hasContent) {
      minHeight = 0.9;
      maxHeight = 1.5;
    } else if (hasTarget) {
      minHeight = 1.0;
      maxHeight = 1.4;
    } else {
      minHeight = 0.8;
      maxHeight = 1.2;
    }

    // 根据内容长度增加高度变化
    double contentLengthFactor = 0;
    if (hasContent) {
      contentLengthFactor = math.min(
          _activity.content.length / 200, // 假设200字符为满分
          0.3 // 最多增加0.3的高度系数
      );
    }

    _cardHeight = minHeight + random.nextDouble() * (maxHeight - minHeight) + contentLengthFactor;

    // 添加宽度计算，让卡片宽度也有变化，更像聊天气泡
    // 宽度会根据内容长度和类型有所变化
    double widthBase = 0.75; // 基础宽度，屏幕的75%
    double widthVariation = 0.2; // 最大变化量，屏幕的20%

    // 根据内容长度调整宽度
    double contentWidthFactor = 0;
    if (hasContent) {
      contentWidthFactor = math.min(
          _activity.content.length / 300, // 假设300字符为满分
          0.15 // 最多增加0.15的宽度系数
      );
    }

    _cardWidth = widthBase + random.nextDouble() * widthVariation + contentWidthFactor;

    // 如果在详情页中，则宽度设为更大的值
    if (widget.isInDetailView) {
      _cardWidth = 0.95;
    }
  }


  @override
  void didUpdateWidget(ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity != widget.activity) {
      _activity = widget.activity;
      _initializeCardProperties();
    }
  }

  void _handleEdit() async {
    HapticFeedback.mediumImpact();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ActivityEditDialog(
        initialContent: _activity.content,
        metadata: _activity.metadata,
      ),
    );

    if (result != null) {
      final success = await _activityService.updateActivity(
          _activity.id,
          result['content'],
          result['metadata']
      );

      if (success) {
        // 加载更新后的活动
        final updatedActivity = await _activityService.getActivityDetail(_activity.id);
        if (updatedActivity != null && mounted) {
          setState(() {
            _activity = updatedActivity;
          });

          if (widget.onUpdated != null) {
            widget.onUpdated!();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('动态已更新')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败，请稍后重试')),
        );
      }
    }
  }

// 处理活动删除
  void _handleDelete() async {
    HapticFeedback.heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除动态'),
        content: const Text('确定要删除这条动态吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _activityService.deleteActivity(_activity.id);

      if (success && mounted) {
        if (widget.onUpdated != null) {
          widget.onUpdated!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('动态已删除')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，请稍后重试')),
        );
      }
    }
  }

  // 处理点赞
  Future<void> _handleLike() async {
    HapticFeedback.lightImpact();

    bool success;

    if (_activity.isLiked) {
      success = await _activityService.unlikeActivity(_activity.id);
      if (success) {
        setState(() {
          _activity.isLiked = false;
          _activity.likesCount -= 1;
        });
      }
    } else {
      success = await _activityService.likeActivity(_activity.id);
      if (success) {
        setState(() {
          _activity.isLiked = true;
          _activity.likesCount += 1;
        });
      }
    }

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请稍后重试')),
        );
      }
    }

    if (widget.onUpdated != null) {
      widget.onUpdated!();
    }
  }

  // 处理评论切换
  void _handleComment() {
    HapticFeedback.mediumImpact();

    setState(() {
      _showComments = !_showComments;
    });
  }

  // 添加评论
  Future<void> _addComment(String content) async {
    if (content.trim().isEmpty) return;

    final comment = await _activityService.commentOnActivity(_activity.id, content);
    if (comment != null) {
      setState(() {
        _activity.comments.add(comment);
        _activity.commentsCount += 1;
      });

      if (widget.onUpdated != null) {
        widget.onUpdated!();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论失败，请稍后重试')),
        );
      }
    }
  }

  // 删除评论
  void _handleCommentDeleted(String commentId) {
    setState(() {
      _activity.comments.removeWhere((comment) => comment.id == commentId);
      _activity.commentsCount = _activity.commentsCount > 0 ? _activity.commentsCount - 1 : 0;
    });

    if (widget.onUpdated != null) {
      widget.onUpdated!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('评论已删除')),
    );
  }

  // 导航到用户个人资料页
  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }

  // 处理活动卡片点击
  void _handleActivityTap() {
    // 如果在详情页内，或者没有提供点击回调，则不执行任何操作
    if (widget.isInDetailView || widget.onActivityTap == null) return;

    // 触发轻度触觉反馈
    HapticFeedback.selectionClick();

    // 调用回调，传递活动数据
    widget.onActivityTap!(_activity);
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度用于计算卡片宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = screenWidth * _cardWidth;

    // 内容部分的Widget
    Widget contentWidget = Column(
      crossAxisAlignment: widget.isAlternate
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // 使用ActivityHeader组件
        ActivityHeader(
          user: _activity.user,
          createTime: _activity.createTime,
          activityType: _activity.type,
          isAlternate: widget.isAlternate,
          cardHeight: _cardHeight * 0.8, // 缩小字体比例
        ),

        SizedBox(height: 12 * _cardHeight),


        // 内容文本
        if (_activity.content.isNotEmpty)
          Container(
            width: double.infinity,
            alignment: widget.isAlternate
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              _activity.content,
              style: TextStyle(fontSize: 14 * math.sqrt(_cardHeight * 0.7)), // 调小字体大小
              textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left,
            ),
          ),

        // 使用ActivityTarget组件
        if (_activity.targetType != null) ...[
          SizedBox(height: 12 * _cardHeight),
          ActivityTarget(
            target: _activity.target,
            targetType: _activity.targetType,
            isAlternate: widget.isAlternate,
            cardHeight: _cardHeight * 0.8, // 缩小比例
          ),
        ],
        // 添加导航至目标组件
        ActivityTargetNavigation(
          activity: _activity,
          isAlternate: _isAlternate,
        ),



        SizedBox(height: 16 * _cardHeight),

        // 使用ActivityActionButtons组件
        ActivityActionButtons(
          isLiked: _activity.isLiked,
          likesCount: _activity.likesCount,
          commentsCount: _activity.commentsCount,
          isAlternate: widget.isAlternate,
          cardHeight: _cardHeight * 0.8, // 缩小比例
          onLike: _handleLike,
          onComment: _handleComment,
        ),

        // 评论区域
        if (_showComments || _activity.comments.isNotEmpty) ...[
          const Divider(height: 24),
          _buildComments(),
        ]
      ],
    );

    // 如果不需要自己的背景（在详情页里的卡片），则直接返回内容
    if (!widget.hasOwnBackground) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleActivityTap,
          child: contentWidget,
        ),
      );
    }

    // 否则用卡片包装内容，保持原有的左右交错排列
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      // 根据是否为交替布局（左右交错）调整对齐方式
      alignment: widget.isAlternate ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4 * _cardHeight,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleActivityTap,
          child: Container(
            width: calculatedWidth,
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.95, // 最大不超过屏幕宽度的95%
              minWidth: screenWidth * 0.6,  // 最小不小于屏幕宽度的60%
            ),
            child: Card(
              elevation: 1, // 减小阴影
              margin: EdgeInsets.zero,
              // 使用更圆润的边角，增加气泡效果
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.isAlternate ? 20 : 4),
                  topRight: Radius.circular(widget.isAlternate ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(16 * math.sqrt(_cardHeight)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.isAlternate ? 20 : 4),
                    topRight: Radius.circular(widget.isAlternate ? 4 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  // 去掉渐变，使用单色背景
                  color: Colors.white,
                ),
                child: contentWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建评论区
  Widget _buildComments() {
    return Column(
      crossAxisAlignment: widget.isAlternate
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (_activity.comments.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(bottom: 8 * _cardHeight),
            child: Text(
              '评论 (${_activity.comments.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14 * math.sqrt(_cardHeight * 0.7), // 调小字体大小
              ),
            ),
          ),
          ...List.generate(
            _activity.comments.length > 3 && !_showComments
                ? 3
                : _activity.comments.length,
                (index) => ActivityCommentItem(
              comment: _activity.comments[index],
              activityId: _activity.id,
              isAlternate: widget.isAlternate,
              onLikeToggled: (comment) {
                setState(() {
                  // 评论已在ActivityCommentItem中更新
                });
                if (widget.onUpdated != null) {
                  widget.onUpdated!();
                }
              },
              onCommentDeleted: _handleCommentDeleted,
            ),
          ),

          // 显示查看更多按钮
          if (_activity.comments.length > 3 && !_showComments)
            TextButton(
              onPressed: () => setState(() => _showComments = true),
              child: Text(
                '查看更多评论...',
                style: TextStyle(fontSize: 14 * math.sqrt(_cardHeight * 0.7)),
              ),
            ),

          // 只有当显示评论区时才显示评论输入框
          if (_showComments)
            ActivityCommentInput(
              onSubmit: _addComment,
              isAlternate: widget.isAlternate,
            ),
        ] else if (_showComments) ...[
          // 没有评论但显示评论区
          Padding(
            padding: EdgeInsets.only(bottom: 8 * _cardHeight),
            child: Text(
              '暂无评论，发表第一条评论吧',
              style: TextStyle(
                fontSize: 14 * math.sqrt(_cardHeight * 0.7),
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          ActivityCommentInput(
            onSubmit: _addComment,
            isAlternate: widget.isAlternate,
          ),
        ],
      ],
    );
  }
}