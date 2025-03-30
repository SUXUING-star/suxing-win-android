// lib/widgets/components/screen/activity/activity_comment_item_updated.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 确保路径正确

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
    // 当外部传入的 comment 对象发生变化时，更新内部状态
    if (oldWidget.comment != widget.comment) {
      setState(() {
        _comment = widget.comment;
      });
    }
  }

  // 处理评论点赞
  Future<void> _handleLike() async {
    // 防止重复点击，可以在这里加一个 loading 状态，但暂时简化处理
    bool success;
    final originalLikedState = _comment.isLiked;
    final originalLikesCount = _comment.likesCount;

    // 先在 UI 上更新状态，提供即时反馈
    setState(() {
      _comment.isLiked = !_comment.isLiked;
      _comment.likesCount = _comment.isLiked
          ? originalLikesCount + 1
          : (originalLikesCount > 0 ? originalLikesCount - 1 : 0);
    });
    // 通知父组件状态变化（如果需要的话，可以在请求成功后通知）
    // widget.onLikeToggled(_comment); // 可以考虑移到请求成功后

    try {
      if (!originalLikedState) { // 原来未点赞，现在点赞
        success = await _activityService.likeComment(widget.activityId, _comment.id);
      } else { // 原来已点赞，现在取消点赞
        success = await _activityService.unlikeComment(widget.activityId, _comment.id);
      }

      if (!success) {
        // 操作失败，回滚 UI 状态
        if (mounted) {
          setState(() {
            _comment.isLiked = originalLikedState;
            _comment.likesCount = originalLikesCount;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作失败，请稍后重试')),
          );
        }
      } else {
        // 操作成功，可以再次通知父组件最终状态（如果之前没通知）
        widget.onLikeToggled(_comment);
      }
    } catch (e) {
      // 异常情况，也回滚 UI 状态
      if (mounted) {
        setState(() {
          _comment.isLiked = originalLikedState;
          _comment.likesCount = originalLikesCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('点赞操作出错: $e')),
        );
      }
    }
  }

  // 使用可复用的确认对话框处理评论删除
  Future<void> _handleDelete() async {
    // 防止重复点击
    if (_isDeleting) return;

    CustomConfirmDialog.show(
      context: context,
      title: '删除评论',
      message: '确定要删除此评论吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        // 开始删除
        setState(() {
          _isDeleting = true;
        });

        try {
          final success = await _activityService.deleteComment(widget.activityId, _comment.id);

          if (success) {
            // 删除成功，通知父组件
            if (widget.onCommentDeleted != null && mounted) {
              widget.onCommentDeleted!(_comment.id);
              // 可以在这里加一个短暂的成功提示，或者让父组件处理
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(content: Text('评论已删除')),
              // );
            }
          } else {
            // 删除失败
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('删除评论失败，请稍后重试')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除评论时发生错误: $e')),
            );
          }
        } finally {
          // 无论成功失败，结束删除状态
          if (mounted) {
            setState(() {
              _isDeleting = false;
            });
          }
        }
      },
    );
  }

  void _navigateToUserProfile() {
    // 从 user map 中获取 userId，确保它是 String 类型
    final userIdObject = _comment.user?['userId'];
    final String? userId = userIdObject?.toString();

    if (userId == null || userId.isEmpty) {
      print("无法导航：评论用户ID无效");
      return;
    }

    NavigationUtils.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }

  // 检查当前用户是否是评论作者
  Future<bool> _isCommentOwner() async {
    final currentUserId = await _userService.currentUserId;
    // 从评论的 user map 中获取 userId，确保它是 String 类型
    final commentUserIdObject = _comment.user?['userId'];
    final String? commentUserId = commentUserIdObject?.toString();

    return currentUserId != null &&
        commentUserId != null &&
        commentUserId.isNotEmpty &&
        commentUserId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final username = _comment.user?['username'] ?? '未知用户';
    final avatarUrl = _comment.user?['avatar'];
    final theme = Theme.of(context); // 获取当前主题

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // 轻微调整内边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // 头像
          GestureDetector(
            onTap: _navigateToUserProfile,
            child: CircleAvatar(
              radius: 16, // 稍微增大头像尺寸
              backgroundColor: Colors.grey.shade300, // 添加背景色以防图片加载失败
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?', // 处理用户名为空的情况
                  style: const TextStyle(fontSize: 12, color: Colors.white)
              )
                  : null,
            ),
          ),
          const SizedBox(width: 10), // 稍微增大间距

          // 评论内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: widget.isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 用户名和时间行
                Row(
                  textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    // 用户名
                    Flexible( // 防止用户名过长导致溢出
                      child: GestureDetector(
                        onTap: _navigateToUserProfile,
                        child: Text(
                          username,
                          style: theme.textTheme.bodyMedium?.copyWith( // 使用主题字体样式
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 时间 - 核心改动 2: 使用 DateTimeFormatter.formatTimeAgo
                    Text(
                      DateTimeFormatter.formatTimeAgo(_comment.createTime),
                      style: theme.textTheme.bodySmall?.copyWith( // 使用主题字体样式
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(), // 推开删除按钮
                    // 删除按钮 (仅评论作者可见)
                    FutureBuilder<bool>(
                      future: _isCommentOwner(),
                      builder: (context, snapshot) {
                        // 等待时显示占位符，避免布局跳动
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(width: 18, height: 18);
                        }
                        // 如果是作者，则显示删除按钮或加载指示器
                        if (snapshot.hasData && snapshot.data == true) {
                          return _isDeleting
                              ? Container( // 给加载指示器一个固定大小
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : InkWell( // 使用 InkWell 增加点击区域和水波纹效果
                            onTap: _handleDelete,
                            borderRadius: BorderRadius.circular(10), // 水波纹效果范围
                            child: Padding(
                              padding: const EdgeInsets.all(4.0), // 增加点击区域
                              child: Icon(
                                Icons.delete_outline,
                                size: 16, // 稍微增大图标
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        // 其他情况（非作者、加载出错等）不显示
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 评论内容
                Text(
                  _comment.content,
                  style: theme.textTheme.bodyMedium, // 使用主题字体样式
                  textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 6),

                // 点赞区域
                Row(
                  // 根据布局方向调整对齐
                  mainAxisAlignment: widget.isAlternate ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    // 使用 InkWell 增加点击反馈
                    InkWell(
                      onTap: _handleLike,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              _comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16, // 稍微增大图标
                              color: _comment.isLiked ? Colors.red : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_comment.likesCount}',
                              style: theme.textTheme.bodySmall?.copyWith( // 使用主题字体样式
                                color: _comment.isLiked ? Colors.red : Colors.grey.shade600,
                              ),
                            ),
                          ],
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
    );
  }
}