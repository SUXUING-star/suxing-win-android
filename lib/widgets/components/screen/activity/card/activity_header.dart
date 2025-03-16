// lib/widgets/components/screen/activity/activity_header.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/components/badge/user_info_badge.dart';
import 'dart:math' as math;

class ActivityHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final DateTime createTime;
  final String activityType;
  final bool isAlternate;
  final double cardHeight;

  const ActivityHeader({
    Key? key,
    required this.user,
    required this.createTime,
    required this.activityType,
    this.isAlternate = false,
    this.cardHeight = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = user?['userId'] ?? '';
    final timeAgo = _formatDateTime(createTime);

    return Row(
      textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
      children: [
        // 使用UserInfoBadge替代原来的用户信息显示
        Expanded(
          child: userId.isNotEmpty
              ? UserInfoBadge(
            userId: userId,
            showFollowButton: true, // 不显示关注按钮
            mini: true, // 使用小尺寸
            showLevel: true, // 不显示等级
            backgroundColor: Colors.transparent, // 透明背景
          )
              : _buildLegacyUserInfo(), // 如果没有userId，使用原来的方式显示
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