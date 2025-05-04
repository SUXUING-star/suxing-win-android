// lib/constants/activity_constants.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';

/// 活动类型相关的显示信息
class ActivityTypeDisplay {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const ActivityTypeDisplay({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

class ActivityTypeConstants {
  static const gameComment = "game_comment"; // 游戏评论
  static const gameLike = "game_like"; // 游戏点赞
  static const postCreate = "post_create"; // 发帖
  static const postReply = "post_reply"; // 回帖
  static const checkIn = "check_in"; // 签到
  static const collection = "collection"; // 游戏收藏
  static const follow = "follow"; // 关注用户
}

class ActivityTargetTypeConstants {
  static const game = 'game';
  static const post = 'post';
  static const user = 'user';
}

class ActivityType {
  // 用户动态类型
  static const String gameComment = "game_comment"; // 游戏评论
  static const String gameLike = "game_like"; // 游戏点赞
  static const String postCreate = "post_create"; // 发帖
  static const String postReply = "post_reply"; // 回帖
  static const String checkIn = "check_in"; // 签到
  static const String collection = "collection"; // 游戏收藏
  static const String follow = "follow"; // 关注用户
}

/// 活动类型工具类
class ActivityTypeUtils {
  // 获取活动描述
  static String getActivityDescription(UserActivity activity) {
    switch (activity.type) {
      case ActivityType.gameComment:
        return '评论了游戏 ${activity.gameTitle ?? '未知游戏'}';
      case ActivityType.gameLike:
        return '点赞了游戏 ${activity.gameTitle ?? '未知游戏'}';
      case ActivityType.postCreate:
        return '发布了帖子 ${activity.postTitle ?? '未知帖子'}';
      case ActivityType.postReply:
        return '回复了帖子 ${activity.postTitle ?? '未知帖子'}';
      case ActivityType.checkIn:
        return '完成了每日签到';
      case ActivityType.collection:
        return '收藏了游戏 ${activity.gameTitle ?? '未知游戏'}';
      case ActivityType.follow:
        return '关注了用户 ${activity.targetUsername ?? '未知用户'}';
      default:
        return '发布了动态';
    }
  }


  /// 根据活动类型获取显示信息（文本、背景色、文本色、图标）
  static ActivityTypeDisplay getActivityTypeDisplayInfo(String type) {
    String text;
    Color bgColor;
    IconData icon; // <-- 定义图标变量

    switch (type) {
      case ActivityTypeConstants.gameComment:
        text = '评论游戏';
        bgColor = Colors.blue.shade300;
        icon = Icons.comment_outlined; // <-- 指定图标
        break;
      case ActivityTypeConstants.gameLike:
        text = '喜欢游戏';
        bgColor = Colors.pink.shade300;
        icon = Icons.favorite_border; // <-- 指定图标
        break;
      case ActivityTypeConstants.collection:
        text = '收藏游戏';
        bgColor = Colors.amber.shade300;
        icon = Icons.bookmark_border; // <-- 指定图标
        break;
      case ActivityTypeConstants.postReply:
        text = '回复帖子';
        bgColor = Colors.green.shade300;
        icon = Icons.reply_outlined; // <-- 指定图标
        break;
      case ActivityTypeConstants.follow:
        text = '关注用户';
        bgColor = Colors.purple.shade300;
        icon = Icons.person_add_alt_1_outlined; // <-- 指定图标
        break;
      case ActivityTypeConstants.checkIn:
        text = '完成签到';
        bgColor = Colors.teal.shade300;
        icon = Icons.check_circle_outline; // <-- 指定图标
        break;
    // --- 示例：添加你可能有的其他类型 ---
      case ActivityTypeConstants.postCreate:
        text = '发布帖子';
        bgColor = Colors.lightGreen.shade300;
        icon = Icons.post_add_outlined;
        break;
    // --- 结束示例 ---
      default:
        text = '动态'; // 其他未知类型
        bgColor = Colors.grey.shade200;
        icon = Icons.dynamic_feed_outlined; // <-- 默认图标
    }

    // 根据背景色亮度计算文本颜色
    final Color textColor =
    bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

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
