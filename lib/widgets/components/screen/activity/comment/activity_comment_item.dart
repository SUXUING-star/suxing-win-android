// lib/widgets/components/screen/activity/activity_comment_item.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart'; // 确保引入UserService

class ActivityCommentItem extends StatefulWidget {
  final ActivityComment comment;
  final String activityId;
  final bool isAlternate; // 是否交替布局
  final Function(ActivityComment) onLikeToggled;
  final Function(String commentId)? onCommentDeleted; // 删除评论回调

  const ActivityCommentItem({
    Key? key,
    required this.comment,
    required this.activityId,
    this.isAlternate = false,
    required this.onLikeToggled,
    this.onCommentDeleted,
  }) : super(key: key);

  @override
  _ActivityCommentItemState createState() => _ActivityCommentItemState();
}

class _ActivityCommentItemState extends State<ActivityCommentItem> {
  late ActivityComment _comment;
  final UserActivityService _activityService = UserActivityService();
  final UserService _userService = UserService();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _comment = widget.comment;
  }

  @override
  void didUpdateWidget(ActivityCommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment) {
      _comment = widget.comment;
    }
  }

  // 处理评论点赞
  Future<void> _handleLike() async {
    bool success;

    if (_comment.isLiked) {
      success = await _activityService.unlikeComment(widget.activityId, _comment.id);
      if (success) {
        setState(() {
          _comment.isLiked = false;
          _comment.likesCount = _comment.likesCount > 0 ? _comment.likesCount - 1 : 0;
        });
      }
    } else {
      success = await _activityService.likeComment(widget.activityId, _comment.id);
      if (success) {
        setState(() {
          _comment.isLiked = true;
          _comment.likesCount += 1;
        });
      }
    }

    if (!success) {
      // 显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请稍后重试')),
        );
      }
    }

    // 通知父组件
    widget.onLikeToggled(_comment);
  }

  // 处理评论删除
  Future<void> _handleDelete() async {
    // 显示确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除此评论吗？此操作无法撤销。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    // 如果用户取消，则不执行删除
    if (confirm != true) return;

    // 开始删除
    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _activityService.deleteComment(widget.activityId, _comment.id);

      if (success) {
        if (widget.onCommentDeleted != null && mounted) {
          widget.onCommentDeleted!(_comment.id);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除评论失败，请稍后重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发生错误: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _navigateToUserProfile() {
    // 从user map中获取userId
    final userId = _comment.user?['userId'];
    print(_comment);


    if (userId == null || userId.toString().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId.toString()),
      ),
    );
  }

  // 检查当前用户是否是评论作者
  Future<bool> _isCommentOwner() async {
    final currentUserId = await _userService.currentUserId;

    // 从评论的user map中获取userId
    final commentUserId = _comment.user?['userId'];

    return currentUserId != null &&
        commentUserId != null &&
        commentUserId.toString().isNotEmpty &&
        commentUserId.toString() == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final username = _comment.user?['username'] ?? '未知用户';
    final avatarUrl = _comment.user?['avatar'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          GestureDetector(
            onTap: _navigateToUserProfile,
            child: CircleAvatar(
              radius: 14,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? Text(username[0].toUpperCase(), style: const TextStyle(fontSize: 10)) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: widget.isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _navigateToUserProfile,
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(_comment.createTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    // 评论作者才能看到删除按钮
                    FutureBuilder<bool>(
                      future: _isCommentOwner(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return _isDeleting
                              ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2)
                          )
                              : GestureDetector(
                            onTap: _handleDelete,
                            child: Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _comment.content,
                  style: const TextStyle(fontSize: 14),
                  textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: widget.isAlternate ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _handleLike,
                      child: Row(
                        children: [
                          Icon(
                            _comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: _comment.isLiked ? Colors.red : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_comment.likesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _comment.isLiked ? Colors.red : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
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
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}