import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target.dart';
import 'package:suxingchahui/widgets/components/screen/activity/button/activity_action_buttons.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_item.dart';
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_input.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target_navigation.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ActivityCard extends StatefulWidget {
  final UserActivity activity;
  final User? currentUser;
  final bool isAlternate;
  final VoidCallback? onUpdated;
  final bool isInDetailView;
  final Function(UserActivity)? onActivityTap;
  final bool hasOwnBackground;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onUnlike;
  final FutureOr<ActivityComment?> Function(String activityId, String content)?
      onAddComment;
  final FutureOr<void> Function(String activityId, String commentId)?
      onDeleteComment; // 修改这里！
  final FutureOr<void> Function(String activityId, String commentId)?
      onLikeComment; // 修改这里！
  final FutureOr<void> Function(String activityId, String commentId)?
      onUnlikeComment; // 修改这里！

  const ActivityCard({
    super.key,
    required this.activity,
    required this.currentUser,
    this.isAlternate = false,
    this.onUpdated,
    this.isInDetailView = false,
    this.onActivityTap,
    this.hasOwnBackground = true,
    this.onEdit,
    this.onDelete,
    this.onLike,
    this.onUnlike,
    this.onAddComment,
    this.onDeleteComment,
    this.onLikeComment,
    this.onUnlikeComment,
  });

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late UserActivity _activity;
  bool _isAlternate = false;
  bool _showComments = false;
  late double _cardHeight;
  late double _cardWidth;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _isAlternate = widget.isAlternate;
    _initializeCardProperties();
  }

  @override
  void didUpdateWidget(ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activity.id != oldWidget.activity.id ||
        widget.activity.updateTime != oldWidget.activity.updateTime) {
      setState(() => _activity = widget.activity);
    }
    if (widget.isAlternate != oldWidget.isAlternate) {
      setState(() => _isAlternate = widget.isAlternate);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _initializeCardProperties() {
    final random = math.Random(widget.activity.id.hashCode);
    final bool hasContent = _activity.content.isNotEmpty;
    double minHeight = 1.0, maxHeight = 1.5;
    if (hasContent) {
      minHeight = 1.0;
      maxHeight = 1.8;
    } else if (hasContent) {
      minHeight = 0.9;
      maxHeight = 1.5;
    } else {
      minHeight = 1.0;
      maxHeight = 1.4;
    }
    double contentLengthFactor =
        hasContent ? math.min(_activity.content.length / 200, 0.3) : 0;
    _cardHeight = minHeight +
        random.nextDouble() * (maxHeight - minHeight) +
        contentLengthFactor;
    double widthBase = 0.75, widthVariation = 0.2;
    double contentWidthFactor =
        hasContent ? math.min(_activity.content.length / 300, 0.15) : 0;
    _cardWidth =
        widthBase + random.nextDouble() * widthVariation + contentWidthFactor;
    if (widget.isInDetailView) _cardWidth = 0.95;
  }

  void _handleLike() {
    if (widget.onLike == null && widget.onUnlike == null) return;
    HapticFeedback.lightImpact();
    final originalLikedState = _activity.isLiked;
    final originalLikesCount = _activity.likesCount;
    setState(() {
      _activity.isLiked = !originalLikedState;
      _activity.likesCount += _activity.isLiked ? 1 : -1;
      if (_activity.likesCount < 0) _activity.likesCount = 0;
    });
    try {
      if (_activity.isLiked) {
        widget.onLike?.call();
      } else {
        widget.onUnlike?.call();
      }
      widget.onUpdated?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _activity.isLiked = originalLikedState;
          _activity.likesCount = originalLikesCount;
        });
      }
    }
  }

  void _handleComment() {
    HapticFeedback.mediumImpact();
    setState(() => _showComments = !_showComments);
  }

  // --- 这个方法现在由 ActivityCommentInput 的 onSubmit 调用 ---
  Future<void> _addComment(String content) async {
    // <--- 接收 String content
    // content 由 ActivityCommentInput 传递进来，已经 trim 过了
    if (content.isEmpty || _isSubmittingComment) return;
    if (widget.onAddComment == null) {
      if (mounted) AppSnackBar.showError(context, '无法添加评论');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmittingComment = true); // 开始提交状态

    try {
      // --- 调用父级传递的 onAddComment 回调，传入 activityId 和 content ---
      final newComment = await widget.onAddComment!(_activity.id, content);
      if (newComment != null && mounted) {
        setState(() {
          // 评论成功，更新计数，展开评论区
          _activity.commentsCount += 1;
          _showComments = true;
          // 不再需要清空 controller，由 ActivityCommentInput 内部处理
        });
        widget.onUpdated?.call(); // 通知父级（可选）
        // 可以在这里或父级显示成功提示
        // AppSnackBar.showSuccess(context, '评论成功');
      } else if (mounted) {
        // 父级返回 null 可能表示失败
        throw Exception("添加评论失败"); // 抛出异常以便 catch 处理
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '评论失败: $e');
    } finally {
      // --- 无论成功失败，结束提交状态 ---
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  void _handleActivityTap() {
    if (widget.isInDetailView || widget.onActivityTap == null) return;
    HapticFeedback.selectionClick();
    widget.onActivityTap!(widget.activity);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = screenWidth * _cardWidth;
    final UserInfoProvider userInfoProvider = context.watch<UserInfoProvider>();
    userInfoProvider.ensureUserInfoLoaded(_activity.userId);
    final UserDataStatus userDataStatus =
        userInfoProvider.getUserStatus(_activity.userId);

    // --- 内容 Widget (传递 edit/delete 给 Header) ---
    Widget contentWidget = Column(
      crossAxisAlignment:
          _isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ActivityHeader(
          userId: _activity.userId,
          currentUser: widget.currentUser,
          userDataStatus: userDataStatus,
          createTime: _activity.createTime,
          updateTime: _activity.updateTime,
          isEdited: _activity.isEdited,
          activityType: _activity.type,
          isAlternate: _isAlternate,
          cardHeight: _cardHeight,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        ),
        SizedBox(height: 12 * _cardHeight),
        if (_activity.content.isNotEmpty)
          Container(
            width: double.infinity,
            alignment:
                _isAlternate ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(_activity.content,
                style: TextStyle(fontSize: 14 * math.sqrt(_cardHeight * 0.7)),
                textAlign: _isAlternate ? TextAlign.right : TextAlign.left),
          ),
        ...[
          SizedBox(height: 12 * _cardHeight),
          ActivityTarget(
              currentUser: widget.currentUser,
              activity: _activity,
              userDataStatus: userDataStatus,
              isAlternate: _isAlternate,
              cardHeight: _cardHeight),
        ],
        ActivityTargetNavigation(
            activity: _activity, isAlternate: _isAlternate),
        SizedBox(height: 16 * _cardHeight),
        ActivityActionButtons(
          isLiked: _activity.isLiked,
          likesCount: _activity.likesCount,
          commentsCount: _activity.commentsCount,
          isAlternate: _isAlternate,
          cardHeight: _cardHeight,
          onLike: _handleLike,
          onComment: _handleComment,
        ),
        if (_showComments || _activity.comments.isNotEmpty) ...[
          const Divider(height: 24, indent: 16, endIndent: 16, thickness: 0.5),
          _buildComments(userInfoProvider),
        ]
      ],
    );

    // --- 卡片包装 ---
    if (!widget.hasOwnBackground) {
      // 详情页中的卡片可能不需要额外的点击区域和背景
      return Padding(
        // 添加一些内边距，模拟卡片效果
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: contentWidget,
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: _isAlternate ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4 * _cardHeight),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleActivityTap,
          child: Container(
            width: calculatedWidth,
            constraints: BoxConstraints(
                maxWidth: screenWidth * 0.95, minWidth: screenWidth * 0.6),
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(_isAlternate ? 20 : 4),
                      topRight: Radius.circular(_isAlternate ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20))),
              child: Container(
                padding: EdgeInsets.all(16 * math.sqrt(_cardHeight)),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_isAlternate ? 20 : 4),
                        topRight: Radius.circular(_isAlternate ? 4 : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20)),
                    color: Colors.white),
                child: contentWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 构建评论区 (完整实现) ---
  Widget _buildComments(UserInfoProvider userInfoProvider) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment:
            _isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // --- 显示评论列表 ---
          if (_activity.comments.isNotEmpty)
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _activity.comments.length > 3 && !_showComments
                  ? 3
                  : _activity.comments.length,
              itemBuilder: (context, index) {
                final comment = _activity.comments[index];
                final userId = comment.userId;
                userInfoProvider.ensureUserInfoLoaded(userId);
                final UserDataStatus userDataStatus =
                    userInfoProvider.getUserStatus(userId);

                return ActivityCommentItem(
                  key: ValueKey(comment.id),
                  comment: comment,
                  currentUser: widget.currentUser,
                  userDataStatus: userDataStatus,
                  activityId: _activity.id,
                  isAlternate: _isAlternate,
                  // --- 传递评论的操作回调 ---
                  onLike: widget.onLikeComment != null
                      ? () => widget.onLikeComment!(_activity.id, comment.id)
                      : null,
                  onUnlike: widget.onUnlikeComment != null
                      ? () => widget.onUnlikeComment!(_activity.id, comment.id)
                      : null,
                  // --- 注意：这里是 ActivityCommentItem 自己的删除回调，它会调用父级 (ActivityCard) 的 onDeleteComment ---
                  // --- 而 ActivityCard 的 onDeleteComment 回调最终会调用 ActivityFeedScreen 的 _handleDeleteComment ---
                  onCommentDeleted: widget.onDeleteComment != null
                      ? () => widget.onDeleteComment!(_activity.id, comment.id)
                      : null,
                );
              },
            ),

          // --- 查看更多按钮 ---
          if (_activity.comments.length > 3 && !_showComments)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () => setState(() => _showComments = true),
                child: Text('查看全部 ${_activity.commentsCount} 条评论...',
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).primaryColor)),
              ),
            ),

          // --- 评论输入框 ---
          if (_showComments)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ActivityCommentInput(
                onSubmit: _addComment, // 调用 _addComment 方法
                isSubmitting: _isSubmittingComment,
                isAlternate: _isAlternate,
              ),
            ),

          // --- 如果没有评论但展开了评论区 ---
          if (_activity.comments.isEmpty && _showComments)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Text('暂无评论，快来抢沙发吧~',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }
} // _ActivityCardState 类结束
