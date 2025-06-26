// lib/widgets/components/screen/activity/comment/activity_comment_item.dart

/// 该文件定义了 ActivityCommentItem 组件，用于显示单个动态评论。
/// ActivityCommentItem 封装了评论的显示、点赞、取消点赞和删除功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:flutter/services.dart'; // 触觉反馈所需
import 'package:suxingchahui/models/activity/activity_comment.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 用户动态模型所需
import 'package:suxingchahui/models/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务所需
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务所需
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 日期时间格式化工具所需
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件所需

/// `ActivityCommentItem` 类：显示单个动态评论的 StatefulWidget。
///
/// 该组件展示评论内容、作者信息、时间，并提供点赞和删除操作。
class ActivityCommentItem extends StatefulWidget {
  final ActivityComment comment; // 评论数据
  final UserInfoService userInfoService; // 用户信息服务
  final UserFollowService userFollowService; // 用户关注服务
  final User? currentUser; // 当前登录用户
  final String activityId; // 动态 ID
  final bool isAlternate; // 是否为交替显示模式
  final Future<bool> Function()? onLike; // 点赞回调
  final Future<bool> Function()? onUnlike; // 取消点赞回调
  final VoidCallback? onCommentDeleted; // 评论删除回调

  /// 构造函数。
  ///
  /// [comment]：评论数据。
  /// [userInfoService]：用户信息服务。
  /// [userFollowService]：用户关注服务。
  /// [currentUser]：当前登录用户。
  /// [activityId]：动态 ID。
  /// [isAlternate]：是否为交替显示模式。
  /// [onLike]：点赞回调。
  /// [onUnlike]：取消点赞回调。
  /// [onCommentDeleted]：评论删除回调。
  const ActivityCommentItem({
    super.key,
    required this.comment,
    required this.userInfoService,
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
  late ActivityComment _comment; // 内部评论数据
  User? _currentUser; // 内部当前用户数据

  @override
  void initState() {
    super.initState(); // 调用父类 initState
    _comment = widget.comment; // 初始化评论数据
    _currentUser = widget.currentUser; // 初始化当前用户
  }

  @override
  void didUpdateWidget(ActivityCommentItem oldWidget) {
    super.didUpdateWidget(oldWidget); // 调用父类 didUpdateWidget
    if (oldWidget.comment.id != widget.comment.id ||
        oldWidget.comment.likesCount != widget.comment.likesCount ||
        oldWidget.comment.isLiked != widget.comment.isLiked) {
      setState(() {
        _comment = widget.comment; // 更新评论数据
      });
    }
    if (widget.currentUser != oldWidget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser; // 更新当前用户
      });
    }
  }

  /// 处理点赞或取消点赞操作。
  ///
  /// 根据评论的当前点赞状态调用相应的回调函数。
  Future<void> _handleLike() async {
    HapticFeedback.lightImpact(); // 触发轻微触觉反馈

    if (_comment.isLiked) {
      await widget.onLike?.call(); // 调用点赞回调
    } else {
      await widget.onUnlike?.call(); // 调用取消点赞回调
    }
  }

  /// 处理删除操作。
  ///
  /// 调用评论删除回调函数。
  void _handleDelete() {
    widget.onCommentDeleted?.call(); // 调用评论删除回调
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 获取当前主题
    final timeAgo =
        DateTimeFormatter.formatTimeAgo(_comment.createTime); // 格式化评论创建时间

    /// 构建用户信息和操作按钮区域。
    Widget buildUserInfoAndActions() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
        textDirection: widget.isAlternate
            ? TextDirection.rtl
            : TextDirection.ltr, // 根据交替模式设置文本方向
        children: [
          Expanded(
            child: UserInfoBadge(
              // 用户信息徽章
              infoService: widget.userInfoService,
              followService: widget.userFollowService,
              currentUser: widget.currentUser,
              targetUserId: _comment.userId,
              showFollowButton: false,
              showLevel: true, // 显示等级
              mini: true, // 紧凑模式
              backgroundColor: Colors.transparent, // 透明背景
            ),
          ),
          const SizedBox(width: 8), // 用户信息与时间间距

          Text(
            timeAgo,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey[600], fontSize: 11), // 文本样式
          ),
          const SizedBox(width: 4), // 时间与删除按钮间距

          InkWell(
            onTap: _handleDelete, // 点击时触发删除操作
            borderRadius: BorderRadius.circular(10), // 圆角
            child: Padding(
              padding: const EdgeInsets.all(4.0), // 内边距
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.grey.shade600,
                semanticLabel: '删除评论', // 语义标签
              ),
            ),
          ),
        ],
      );
    }

    /// 构建评论内容和点赞区域。
    Widget buildContentAndLikes() {
      return Column(
        crossAxisAlignment: widget.isAlternate
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start, // 根据交替模式设置交叉轴对齐方式
        children: [
          Text(
            _comment.content, // 评论内容
            style: theme.textTheme.bodyMedium,
            textAlign: widget.isAlternate
                ? TextAlign.right
                : TextAlign.left, // 根据交替模式设置文本对齐
          ),
          const SizedBox(height: 8), // 内容与点赞按钮间距

          InkWell(
            onTap: _handleLike, // 点击时触发点赞操作
            borderRadius: BorderRadius.circular(12), // 圆角
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 内边距
              child: Row(
                mainAxisSize: MainAxisSize.min, // 最小化主轴尺寸
                children: [
                  Icon(
                    _comment.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border, // 根据点赞状态显示不同图标
                    size: 16,
                    color: _comment.isLiked
                        ? theme.colorScheme.error
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6), // 图标与数字间距
                  Text(
                    '${_comment.likesCount}', // 点赞数量
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12, // 字体大小
                      fontWeight: _comment.isLiked
                          ? FontWeight.bold
                          : FontWeight.normal, // 根据点赞状态设置字体粗细
                      color: _comment.isLiked
                          ? theme.colorScheme.error
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 底部外边距
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // 内边距
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // 背景色
        borderRadius: BorderRadius.circular(8), // 圆角
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 默认左对齐
        children: [
          buildUserInfoAndActions(), // 构建用户信息和操作按钮区域
          const SizedBox(height: 6), // 用户信息与评论内容间距
          Padding(
            padding: EdgeInsets.only(
              left: widget.isAlternate ? 0 : 40.0,
              right: widget.isAlternate ? 40.0 : 0,
            ),
            child: buildContentAndLikes(), // 构建评论内容和点赞区域
          ),
        ],
      ),
    );
  }
}
