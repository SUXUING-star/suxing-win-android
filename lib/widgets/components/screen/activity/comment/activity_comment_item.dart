import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
// import 'package:suxingchahui/screens/profile/open_profile_screen.dart'; // <-- 不再直接需要
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
// import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // <-- 不再直接需要
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/image/safe_user_avatar.dart'; // <--- 1. 导入 SafeUserAvatar

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
      setState(() {
        _comment = widget.comment;
      });
    }
  }

  // ... _handleLike() 方法不变 ...
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
          // 使用 AppSnackBar 显示错误
          AppSnackBar.showError(context, '操作失败，请稍后重试');

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
        AppSnackBar.showError(context, '点赞操作出错: $e');
      }
    }
  }


  // ... _handleDelete() 方法不变 ...
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
            }
          } else {
            // 删除失败
            if (mounted) {
              AppSnackBar.showError(context, '删除评论失败，请稍后重试');
            }
          }
        } catch (e) {
          if (mounted) {

            AppSnackBar.showError(context, '删除评论时发生错误: $e');
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


  // ... _isCommentOwner() 方法不变 ...
  Future<bool> _isCommentOwner() async {
    final currentUserId = await _userService.currentUserId;
    // 从评论的 user map 中获取 userId，确保它是 String 类型
    final commentUserIdObject = _comment.user?['userId'];
    final String? commentUserId = commentUserIdObject?.toString();
    print(commentUserId);

    return currentUserId != null &&
        commentUserId != null &&
        commentUserId.isNotEmpty &&
        commentUserId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    // 从 comment.user 安全地提取信息
    final Map<String, dynamic>? userData = _comment.user;
    final String? userId = userData?['userId']?.toString(); // 确保是 String?
    print("用户id");
    print(userId);
    final String? avatarUrl = userData?['avatar'] as String?; // 安全转换
    final String username = userData?['username'] as String? ?? '未知用户'; // 安全转换并提供默认值

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // --- 2. 替换为 SafeUserAvatar ---
          SafeUserAvatar(
            userId: userId,           // <--- 3. 传递 userId
            avatarUrl: avatarUrl,     // <--- 3. 传递 avatarUrl
            username: username,       // <--- 3. 传递 username (用于fallback)
            radius: 16,               // 保持和原来 CircleAvatar 一致的大小
            enableNavigation: true,   // 保持导航功能 (SafeUserAvatar 默认就是 true)
          ),
          // --- 替换结束 ---

          const SizedBox(width: 10),

          // 评论内容区域 (这部分不变)
          Expanded(
            child: Column(
              crossAxisAlignment: widget.isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 用户名和时间行
                Row(
                  textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    // 用户名
                    const SizedBox(width: 8),
                    // 时间
                    Text(
                      DateTimeFormatter.formatTimeAgo(_comment.createTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    // 删除按钮
                    FutureBuilder<bool>(
                      future: _isCommentOwner(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(width: 18, height: 18);
                        }
                        if (snapshot.hasData && snapshot.data == true) {
                          return _isDeleting
                              ? LoadingWidget.inline(size: 12,)
                              : InkWell(
                            onTap: _handleDelete,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 评论内容
                Text(
                  _comment.content,
                  style: theme.textTheme.bodyMedium,
                  textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 6),

                // 点赞区域
                Row(
                  mainAxisAlignment: widget.isAlternate ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: _handleLike,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              _comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: _comment.isLiked ? Colors.red : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_comment.likesCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
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