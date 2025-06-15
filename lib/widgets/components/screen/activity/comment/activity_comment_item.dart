// lib/widgets/components/screen/activity/comment/activity_comment_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';

class ActivityCommentItem extends StatefulWidget {
  final ActivityComment comment;
  final UserInfoProvider userInfoProvider;
  final UserFollowService userFollowService;
  final User? currentUser;
  final String activityId;
  final bool isAlternate;
  final Future<bool> Function()? onLike;
  final Future<bool> Function()? onUnlike;
  final VoidCallback? onCommentDeleted;

  const ActivityCommentItem({
    super.key,
    required this.comment,
    required this.userInfoProvider,
    required this.userFollowService,
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

  // --- 点赞/取消点赞 ---
  Future<void> _handleLike() async {
    // 改为同步方法，异步由父级处理
    HapticFeedback.lightImpact();

    if (_comment.isLiked) {
      await widget.onLike?.call();
    } else {
      await widget.onUnlike?.call();
    }
  }

  // --- 处理删除 (调用回调) ---
  void _handleDelete() {
    widget.onCommentDeleted?.call();
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
              infoProvider: widget.userInfoProvider,
              followService: widget.userFollowService,
              currentUser: widget.currentUser,
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

          InkWell(
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
