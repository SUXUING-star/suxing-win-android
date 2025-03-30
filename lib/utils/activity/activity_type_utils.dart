// lib/utils/activity/activity_type_utils.dart
import 'package:flutter/material.dart';

/// 活动类型相关的显示信息
class ActivityTypeDisplay {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const ActivityTypeDisplay({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });
}

/// 活动类型工具类
class ActivityTypeUtils {
  /// 根据活动类型获取显示信息（文本、背景色、文本色）
  static ActivityTypeDisplay getActivityTypeDisplayInfo(String type) {
    String text;
    Color bgColor;

    switch (type) {
      case 'game_comment':
        text = '评论游戏';
        bgColor = Colors.blue.shade100;
        break;
      case 'game_like':
        text = '喜欢游戏';
        bgColor = Colors.pink.shade100;
        break;
      case 'game_collection':
        text = '收藏游戏';
        bgColor = Colors.amber.shade100;
        break;
      case 'post_reply':
        text = '回复帖子';
        bgColor = Colors.green.shade100;
        break;
      case 'user_follow':
        text = '关注用户';
        bgColor = Colors.purple.shade100;
        break;
      case 'check_in':
        text = '完成签到';
        bgColor = Colors.teal.shade100;
        break;
      default:
        text = '动态';
        bgColor = Colors.grey.shade200; // 默认给个更浅的灰色
    }

    // 根据背景色亮度计算文本颜色，确保对比度
    final Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return ActivityTypeDisplay(
      text: text,
      backgroundColor: bgColor,
      textColor: textColor,
    );
  }

  /// 获取活动类型显示文本
  static String getActivityTypeText(String type) {
    return getActivityTypeDisplayInfo(type).text;
  }

  /// 获取活动类型背景色
  static Color getActivityTypeBackgroundColor(String type) {
    return getActivityTypeDisplayInfo(type).backgroundColor;
  }

  /// 获取活动类型文本颜色
  static Color getActivityTypeTextColor(String type) {
    return getActivityTypeDisplayInfo(type).textColor;
  }
}