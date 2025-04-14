// lib/utils/activity/activity_type_utils.dart
import 'package:flutter/material.dart';

/// 活动类型相关的显示信息
class ActivityTypeDisplay {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon; // <--- !!! 新增 icon 字段 !!!

  const ActivityTypeDisplay({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon, // <--- !!! 设为 required !!!
  });
}

/// 活动类型工具类
class ActivityTypeUtils {
  /// 根据活动类型获取显示信息（文本、背景色、文本色、图标）
  static ActivityTypeDisplay getActivityTypeDisplayInfo(String type) {
    String text;
    Color bgColor;
    IconData icon; // <-- 定义图标变量

    switch (type) {
      case 'game_comment':
        text = '评论游戏';
        bgColor = Colors.blue.shade100;
        icon = Icons.comment_outlined; // <-- 指定图标
        break;
      case 'game_like':
        text = '喜欢游戏';
        bgColor = Colors.pink.shade100;
        icon = Icons.favorite_border; // <-- 指定图标
        break;
      case 'game_collection':
        text = '收藏游戏';
        bgColor = Colors.amber.shade100;
        icon = Icons.bookmark_border; // <-- 指定图标
        break;
      case 'post_reply':
        text = '回复帖子';
        bgColor = Colors.green.shade100;
        icon = Icons.reply_outlined; // <-- 指定图标
        break;
      case 'user_follow':
        text = '关注用户';
        bgColor = Colors.purple.shade100;
        icon = Icons.person_add_alt_1_outlined; // <-- 指定图标
        break;
      case 'check_in':
        text = '完成签到';
        bgColor = Colors.teal.shade100;
        icon = Icons.check_circle_outline; // <-- 指定图标
        break;
    // --- 示例：添加你可能有的其他类型 ---
      case 'post_create':
        text = '发布帖子';
        bgColor = Colors.lightGreen.shade100;
        icon = Icons.post_add_outlined;
        break;
      case 'achievement':
        text = '成就解锁';
        bgColor = Colors.orange.shade100;
        icon = Icons.emoji_events_outlined;
        break;
    // --- 结束示例 ---
      default:
        text = '动态'; // 其他未知类型
        bgColor = Colors.grey.shade200;
        icon = Icons.dynamic_feed_outlined; // <-- 默认图标
    }

    // 根据背景色亮度计算文本颜色
    final Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    // --- 返回包含 icon 的 ActivityTypeDisplay 实例 ---
    return ActivityTypeDisplay(
      text: text,
      backgroundColor: bgColor,
      textColor: textColor,
      icon: icon, // <--- 传递图标
    );
  }

  // --- 其他辅助方法现在也可以获取图标 ---
  static IconData getActivityTypeIcon(String type) {
    return getActivityTypeDisplayInfo(type).icon;
  }

  static String getActivityTypeText(String type) {
    return getActivityTypeDisplayInfo(type).text;
  }
  static Color getActivityTypeBackgroundColor(String type) {
    return getActivityTypeDisplayInfo(type).backgroundColor;
  }
  static Color getActivityTypeTextColor(String type) {
    return getActivityTypeDisplayInfo(type).textColor;
  }
}