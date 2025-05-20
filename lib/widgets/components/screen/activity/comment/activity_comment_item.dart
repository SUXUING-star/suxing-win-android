import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class ActivityCommentItem extends StatefulWidget {
  final ActivityComment comment;
  final UserDataStatus userDataStatus;
  final User? currentUser;
  final String activityId;
  final bool isAlternate;
  final VoidCallback? onLike;
  final VoidCallback? onUnlike;
  final VoidCallback? onCommentDeleted;

  const ActivityCommentItem({
    super.key,
    required this.comment,
    required this.userDataStatus,
    required this.currentUser,
    required this.activityId,
    this.isAlternate = false,
    this.onLike,
    this.onUnlike,
    this.onCommentDeleted,
  });

  @override
  _ActivityCommentItemState createState() => _ActivityCommentItemState();
}

class _ActivityCommentItemState extends State<ActivityCommentItem> {
  late ActivityComment _comment;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _comment = widget.comment;
    _currentUser = widget.currentUser;
  }

  @override
  void didUpdateWidget(ActivityCommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.id != widget.comment.id ||
        oldWidget.comment.likesCount != widget.comment.likesCount ||
        oldWidget.comment.isLiked != widget.comment.isLiked) {
      setState(() {
        _comment = widget.comment;
      });
    }
    if (widget.currentUser != oldWidget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  // --- 点赞/取消点赞 (前端补偿 + 调用回调) ---
  void _handleLike() {
    // 改为同步方法，异步由父级处理
    HapticFeedback.lightImpact();
    final originalLikedState = _comment.isLiked;
    final originalLikesCount = _comment.likesCount;

    // 前端补偿
    setState(() {
      _comment.isLiked = !originalLikedState;
      _comment.likesCount = _comment.isLiked
          ? originalLikesCount + 1
          : (originalLikesCount > 0 ? originalLikesCount - 1 : 0);
    });

    // 调用父级回调
    try {
      if (_comment.isLiked) {
        widget.onLike?.call();
      } else {
        widget.onUnlike?.call();
      }
    } catch (e) {
      debugPrint("Error calling like/unlike callback: $e");
      // 回滚补偿
      if (mounted) {
        setState(() {
          _comment.isLiked = originalLikedState;
          _comment.likesCount = originalLikesCount;
        });
        AppSnackBar.showError(context, '操作失败');
      }
    }
  }

  // --- 处理删除 (调用回调) ---
  void _handleDelete() {
    // 改为同步方法
    // 直接调用父级回调，父级处理确认和 Service 调用
    widget.onCommentDeleted?.call();
    // if (widget.onCommentDeleted == null && mounted) {
    //   AppSnackBar.showError(context, '无法执行删除操作');
    // }
  }

  // --- 判断是否是评论所有者或管理员 (更完整) ---
  Future<bool> _canDeleteComment() async {
    if (widget.currentUser == null) return false; // 未登录不能删
    final String? currentUserId = widget.currentUser?.id;
    final bool isAdmin = widget.currentUser?.isAdmin ?? false;
    final String commentUserId = _comment.userId; // 直接用 comment 的 userId

    // 管理员或评论所有者可以删除
    return isAdmin || (currentUserId != null && commentUserId == currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = DateTimeFormatter.formatTimeAgo(_comment.createTime);

    // --- 构建用户信息和操作按钮区域 ---
    Widget buildUserInfoAndActions() {
      return Row(
        // Row 包含 UserInfoBadge 和 Actions
        crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
        textDirection:
            widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // --- UserInfoBadge ---
          // 将 UserInfoBadge 放在 Expanded 里，允许名字过长时换行或省略
          Expanded(
            child: UserInfoBadge(
              currentUser: widget.currentUser,
              userDataStatus: widget.userDataStatus,
              targetUserId: _comment.userId,
              showFollowButton: false,
              showLevel: true, // 评论区简化，不显示等级
              mini: true, // 使用紧凑模式
              backgroundColor: Colors.transparent, // 透明背景
              // nameStyle: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold), // 可以自定义名字样式
              // avatarSize: 28, // 可以微调头像大小
            ),
          ),
          const SizedBox(width: 8), // 用户信息和操作按钮之间的间距

          // --- 时间文本 ---
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey[600], fontSize: 11), // 调整样式
          ),
          const SizedBox(width: 4), // 时间和删除按钮间距

          // --- 删除按钮 (FutureBuilder 判断权限) ---
          FutureBuilder<bool>(
            future: _canDeleteComment(), // 使用更新后的权限检查
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data == true) {
                return InkWell(
                  onTap: _handleDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                      semanticLabel: '删除评论', // 增加语义标签
                    ),
                  ),
                );
              }
              // 加载中或无权限时返回空 SizedBox
              return const SizedBox(width: 16); // 保持占位，避免布局跳动
            },
          ),
        ],
      );
    }

    // --- 构建评论内容和点赞区域 ---
    Widget buildContentAndLikes() {
      return Column(
        crossAxisAlignment: widget.isAlternate
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // 评论内容
          Text(
            _comment.content,
            style: theme.textTheme.bodyMedium,
            textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 8), // 内容和点赞按钮间距增大

          // --- 点赞按钮 ---
          InkWell(
            onTap: _handleLike,
            borderRadius: BorderRadius.circular(12), // 增大点击区域和圆角
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4), // 增加 Padding
              child: Row(
                mainAxisSize: MainAxisSize.min, // 让 Row 包裹内容
                children: [
                  Icon(
                    _comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: _comment.isLiked
                        ? theme.colorScheme.error
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6), // 图标和数字间距增大
                  Text(
                    '${_comment.likesCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12, // 稍微增大字体
                      fontWeight: _comment.isLiked
                          ? FontWeight.bold
                          : FontWeight.normal, // 点赞时加粗
                      color: _comment.isLiked
                          ? theme.colorScheme.error
                          : Colors.grey.shade700, // 调整未点赞颜色
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // --- 整体布局 (不再使用 Row 包裹 UserInfoBadge 和 Expanded Column) ---
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 增大评论间距
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // 调整内边距
      //可以加个背景色或边框，让评论更清晰
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 默认左对齐
        children: [
          buildUserInfoAndActions(),
          const SizedBox(height: 6), // 用户信息和评论内容间距
          Padding(
            padding: EdgeInsets.only(
              left: widget.isAlternate ? 0 : 40.0,
              right: widget.isAlternate ? 40.0 : 0,
            ),
            child: buildContentAndLikes(),
          ),
        ],
      ),
    );
  }
}
