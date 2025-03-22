// lib/widgets/components/screen/activity/card/activity_header.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/components/badge/info/user_info_badge.dart';
import 'dart:math' as math;

class ActivityHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final DateTime createTime;
  final DateTime? updateTime;  // 新增字段
  final bool isEdited;         // 新增字段
  final String activityType;
  final bool isAlternate;
  final double cardHeight;
  final VoidCallback? onEdit;  // 新增回调
  final VoidCallback? onDelete; // 新增回调


  const ActivityHeader({
    Key? key,
    required this.user,
    required this.createTime,
    this.updateTime,
    this.isEdited = false,
    required this.activityType,
    this.isAlternate = false,
    this.cardHeight = 1.0,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final userId = user?['userId'] ?? '';
    final String timeAgo = _formatDateTime(createTime);
    final String? updateTimeAgo = updateTime != null && isEdited
        ? _formatDateTime(updateTime!)
        : null;

    return Column(
      crossAxisAlignment: isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // UserInfoBadge 部分保持不变
            Expanded(
              child: userId.isNotEmpty
                  ? UserInfoBadge(
                userId: userId,
                showFollowButton: true,
                mini: true,
                showLevel: true,
                backgroundColor: Colors.transparent,
              )
                  : _buildLegacyUserInfo(),
            ),

            // 显示时间
            if (!isAlternate)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11 * math.sqrt(cardHeight * 0.8),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // 活动类型标签
            _buildActivityTypeChip(),

            // 如果是交替布局，显示时间在右侧
            if (isAlternate)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11 * math.sqrt(cardHeight * 0.8),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // 如果有编辑或删除回调，显示操作菜单
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16 * math.sqrt(cardHeight * 0.8),
                  color: Colors.grey.shade600,
                ),
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit!();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),

        // 如果是编辑过的，显示编辑时间
        if (isEdited && updateTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Icon(
                  Icons.edit,
                  size: 10 * math.sqrt(cardHeight * 0.7),
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '编辑于 $updateTimeAgo',
                  style: TextStyle(
                    fontSize: 10 * math.sqrt(cardHeight * 0.7),
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 原来的用户信息显示方式，作为备用
  Widget _buildLegacyUserInfo() {
    final username = user?['username'] ?? '未知用户';
    final avatarUrl = user?['avatar'];

    return Row(
      textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? Text(username[0].toUpperCase(),
              style: TextStyle(fontSize: 14 * math.sqrt(cardHeight * 0.7))) : null,
          radius: 16 * math.sqrt(cardHeight * 0.7),
        ),
        SizedBox(width: 8 * cardHeight),
        Text(
          username,
          style: TextStyle(
            fontSize: 14 * math.sqrt(cardHeight * 0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTypeChip() {
    String typeText;
    Color? bgColor;

    // 根据activityType设置类型文本和颜色
    switch (activityType) {
      case 'game_comment':
        typeText = '评论游戏';
        bgColor = Colors.blue.shade100;
        break;
      case 'game_like':
        typeText = '喜欢游戏';
        bgColor = Colors.pink.shade100;
        break;
      case 'game_collection':
        typeText = '收藏游戏';
        bgColor = Colors.amber.shade100;
        break;
      case 'post_reply':
        typeText = '回复帖子';
        bgColor = Colors.green.shade100;
        break;
      case 'user_follow':
        typeText = '关注用户';
        bgColor = Colors.purple.shade100;
        break;
      case 'check_in':
        typeText = '完成签到';
        bgColor = Colors.teal.shade100;
        break;
      default:
        typeText = '动态';
        bgColor = Colors.grey.shade100;
    }

    // 调整字体大小和padding，避免过大
    double fontSize = math.min(math.max(11, 11 * math.sqrt(cardHeight * 0.7)), 12);
    double horizontalPadding = math.min(math.max(6, 6 * cardHeight * 0.8), 8);
    double verticalPadding = math.min(math.max(3, 3 * cardHeight * 0.8), 4);
    double borderRadius = math.min(math.max(10, 10 * cardHeight * 0.8), 12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        typeText,
        style: TextStyle(
          fontSize: fontSize,
          color: bgColor.withOpacity(1.0).computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white,
        ),
      ),
    );
  }

  // 日期格式化方法
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