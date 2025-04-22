import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
// 需要 Provider 获取 AuthProvider
import 'package:suxingchahui/models/activity/user_activity.dart'; // 需要评论模型
// 需要 AuthProvider
import 'package:suxingchahui/services/main/user/user_service.dart'; // 仍然需要 UserService 判断所有者
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
// 需要确认对话框
import 'package:suxingchahui/widgets/ui/image/safe_user_avatar.dart'; // 使用安全头像组件
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 需要 Snackbar

class ActivityCommentItem extends StatefulWidget {
  final ActivityComment comment;
  final String activityId; // 仍然需要活动 ID，传递给回调
  final bool isAlternate;

  // --- !!! 修改回调函数 !!! ---
  // onLikeToggled 拆分为 onLike 和 onUnlike
  final VoidCallback? onLike;        // 点赞回调
  final VoidCallback? onUnlike;      // 取消点赞回调
  final VoidCallback? onCommentDeleted; // 删除评论回调 (保持 VoidCallback?)
  // 或者可以改为 Future<bool> Function()? onDelete，让父级处理确认和加载？
  // 暂时保持 VoidCallback，父级在收到回调后处理

  const ActivityCommentItem({
    super.key,
    required this.comment,
    required this.activityId, // 父级需要知道是哪个活动的评论
    this.isAlternate = false,
    // --- !!! 修改构造函数参数 !!! ---
    this.onLike,
    this.onUnlike,
    this.onCommentDeleted,
  });

  @override
  _ActivityCommentItemState createState() => _ActivityCommentItemState();
}

class _ActivityCommentItemState extends State<ActivityCommentItem> {
  late ActivityComment _comment; // 内部状态，用于前端补偿
  final UserService _userService = UserService(); // 仍需要判断所有者
  final bool _isDeleting = false; // 内部删除加载状态

  @override
  void initState() {
    super.initState();
    _comment = widget.comment; // 初始化内部状态
  }

  // 当外部传入的 comment 更新时，同步内部状态
  @override
  void didUpdateWidget(ActivityCommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 简单比较 ID 和更新时间，如果不同则更新内部状态
    if (oldWidget.comment.id != widget.comment.id) {
      setState(() {
        _comment = widget.comment;
      });
    }
  }

  // --- 处理点赞/取消点赞 ---
  Future<void> _handleLike() async {
    HapticFeedback.lightImpact();
    final originalLikedState = _comment.isLiked;
    final originalLikesCount = _comment.likesCount;

    // --- 前端补偿 (UI 立即响应) ---
    setState(() {
      _comment.isLiked = !originalLikedState;
      _comment.likesCount = _comment.isLiked
          ? originalLikesCount + 1
          : (originalLikesCount > 0 ? originalLikesCount - 1 : 0);
    });

    // --- 调用父级传递的回调 ---
    try {
      if (_comment.isLiked) { // 如果补偿后是点赞状态，调用 onLike
        widget.onLike?.call();
      } else { // 否则调用 onUnlike
        widget.onUnlike?.call();
      }
      // 假设父级的回调会处理 API 调用和最终状态同步
      // 如果父级回调失败，这里无法直接知道，父级需要通过某种方式通知子组件回滚
      // (或者更简单的方式是：父级在 Service 失败时不更新数据，下次 UI 监听缓存变化时会自动修正)
    } catch (e) {
      // 如果调用回调本身出错 (理论上不应该)，或者需要处理父级抛出的异常
      //debugPrint("Error calling like/unlike callback: $e");
      // --- 回滚前端补偿 ---
      if (mounted) {
        setState(() {
          _comment.isLiked = originalLikedState;
          _comment.likesCount = originalLikesCount;
        });
        AppSnackBar.showError(context, '操作失败'); // 通用错误提示
      }
    }
  }


  // --- 处理删除评论 ---
  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    // --- 调用父级传递的删除回调 ---
    // 父级 (`ActivityFeedScreen`) 会负责显示确认对话框和调用 Service
    if (widget.onCommentDeleted != null) {
      widget.onCommentDeleted!(); // 直接调用父级方法
      // 父级方法内部会处理确认、调用 Service、缓存失效等
      // 这个组件不再需要管理 _isDeleting 状态或调用 Service
    } else {
      //print("WARN: onDeleteComment callback is null in ActivityCommentItem.");
      // 可以选择显示一个错误，表明无法删除
      if (mounted) AppSnackBar.showError(context, '无法执行删除操作');
    }
    
  }


  // --- 判断是否是评论所有者 (不变) ---
  Future<bool> _isCommentOwner() async {
    final currentUserId = await _userService.currentUserId;
    final commentUserIdObject = _comment.user?['userId'];
    final String? commentUserId = commentUserIdObject?.toString();
    return currentUserId != null && commentUserId != null && commentUserId.isNotEmpty && commentUserId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    // --- 从内部状态 _comment 获取数据 ---
    final Map<String, dynamic>? userData = _comment.user;
    final String? userId = userData?['userId']?.toString();
    final String? avatarUrl = userData?['avatar'] as String?;
    final String username = userData?['username'] as String? ?? '未知用户';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // --- 头像 ---
          SafeUserAvatar(
            userId: userId, avatarUrl: avatarUrl, username: username,
            radius: 16, enableNavigation: true,
          ),
          const SizedBox(width: 10),
          // --- 评论内容区域 ---
          Expanded(
            child: Column(
              crossAxisAlignment: widget.isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 用户名和时间行
                Row(
                  textDirection: widget.isAlternate ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Flexible( // 让用户名可省略
                      child: Text(username, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(DateTimeFormatter.formatTimeAgo(_comment.createTime), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                    const Spacer(), // 推向右边
                    // --- 删除按钮 ---
                    FutureBuilder<bool>(
                      future: _isCommentOwner(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data == true) {
                          // --- 直接调用 _handleDelete ---
                          return InkWell(
                            onTap: _handleDelete, // 调用修改后的删除处理
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade600),
                            ),
                          );
                        }
                        return const SizedBox.shrink(); // 不显示或占位
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 评论内容
                Text(_comment.content, style: theme.textTheme.bodyMedium, textAlign: widget.isAlternate ? TextAlign.right : TextAlign.left),
                const SizedBox(height: 6),
                // --- 点赞区域 ---
                Row(
                  mainAxisAlignment: widget.isAlternate ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: _handleLike, // 调用修改后的点赞处理
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              _comment.isLiked ? Icons.favorite : Icons.favorite_border, // 使用内部状态
                              size: 16,
                              color: _comment.isLiked ? Colors.red : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_comment.likesCount}', // 使用内部状态
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