// lib/widgets/components/screen/activity/activity_utils.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';

class ActivityType {
  // 用户动态类型
  static const String gameComment = "game_comment";    // 游戏评论
  static const String gameLike = "game_like";          // 游戏点赞
  static const String postCreate = "post_create";      // 发帖
  static const String postReply = "post_reply";        // 回帖
  static const String checkIn = "check_in";            // 签到
  static const String collection = "collection";       // 游戏收藏
  static const String follow = "follow";               // 关注用户
  static const String achievement = "achievement";     // 成就解锁
}

class ActivityUtils {
  // 获取活动描述
  static String getActivityDescription(UserActivity activity) {
    switch (activity.type) {
      case ActivityType.gameComment:
        return '评论了游戏 ${activity.target?['title'] ?? '未知游戏'}';
      case ActivityType.gameLike:
        return '点赞了游戏 ${activity.target?['title'] ?? '未知游戏'}';
      case ActivityType.postCreate:
        return '发布了帖子 ${activity.target?['title'] ?? '未知帖子'}';
      case ActivityType.postReply:
        return '回复了帖子 ${activity.target?['title'] ?? '未知帖子'}';
      case ActivityType.checkIn:
        return '完成了每日签到';
      case ActivityType.collection:
        return '收藏了游戏 ${activity.target?['title'] ?? '未知游戏'}';
      case ActivityType.follow:
        return '关注了用户 ${activity.target?['username'] ?? '未知用户'}';
      case ActivityType.achievement:
        return '解锁了成就 ${activity.target?['name'] ?? '未知成就'}';
      default:
        return '发布了动态';
    }
  }

  // 解析活动类型为中文名称
  static String getActivityTypeName(String type) {
    switch (type) {
      case ActivityType.gameComment:
        return '游戏评论';
      case ActivityType.gameLike:
        return '游戏点赞';
      case ActivityType.postCreate:
        return '发布帖子';
      case ActivityType.postReply:
        return '帖子回复';
      case ActivityType.checkIn:
        return '每日签到';
      case ActivityType.collection:
        return '游戏收藏';
      case ActivityType.follow:
        return '用户关注';
      case ActivityType.achievement:
        return '成就解锁';
      default:
        return '其他动态';
    }
  }

  // 获取活动类型对应的颜色
  static Color getActivityTypeColor(String type) {
    switch (type) {
      case ActivityType.gameComment:
        return Colors.blue.shade200;
      case ActivityType.gameLike:
        return Colors.pink.shade200;
      case ActivityType.postCreate:
        return Colors.green.shade200;
      case ActivityType.postReply:
        return Colors.teal.shade200;
      case ActivityType.checkIn:
        return Colors.amber.shade200;
      case ActivityType.collection:
        return Colors.purple.shade200;
      case ActivityType.follow:
        return Colors.orange.shade200;
      case ActivityType.achievement:
        return Colors.indigo.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  // 获取活动类型对应的图标
  static IconData getActivityTypeIcon(String type) {
    switch (type) {
      case ActivityType.gameComment:
        return Icons.comment_outlined;
      case ActivityType.gameLike:
        return Icons.favorite_border;
      case ActivityType.postCreate:
        return Icons.post_add;
      case ActivityType.postReply:
        return Icons.reply;
      case ActivityType.checkIn:
        return Icons.check_circle_outline;
      case ActivityType.collection:
        return Icons.collections_bookmark;
      case ActivityType.follow:
        return Icons.person_add_outlined;
      case ActivityType.achievement:
        return Icons.military_tech_outlined;
      default:
        return Icons.dynamic_feed;
    }
  }
}