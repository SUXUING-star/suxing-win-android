// lib/constants/activity_constants.dart

/// 该文件定义了活动相关的常量、类型显示信息和工具类。
/// 它包含活动类型、活动目标类型以及活动描述和显示信息的辅助方法。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/models/activity/user_activity.dart';

import '../../widgets/components/screen/activity/feed/collapsible_activity_feed.dart'; // 用户动态模型

/// `ActivityTypeDisplay` 类：活动类型相关的显示信息。
///
/// 包含文本、背景颜色、文本颜色和图标。
class ActivityTypeDisplay {
  final String text; // 显示文本
  final Color backgroundColor; // 背景颜色
  final Color textColor; // 文本颜色
  final IconData icon; // 图标

  /// 构造函数。
  const ActivityTypeDisplay({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

/// `ActivityTypeConstants` 类：定义活动类型常量。
class ActivityTypeConstants {
  static const gameComment = "game_comment"; // 游戏评论活动类型
  static const gameLike = "game_like"; // 游戏点赞活动类型
  static const postCreate = "post_create"; // 发帖活动类型
  static const postReply = "post_reply"; // 回帖活动类型
  static const checkIn = "check_in"; // 签到活动类型
  static const collection = "collection"; // 游戏收藏活动类型
  static const follow = "follow"; // 关注用户活动类型
}

/// `ActivityTargetTypeConstants` 类：定义活动目标类型常量。
class ActivityTargetTypeConstants {
  static const game = 'game'; // 游戏目标类型
  static const post = 'post'; // 帖子目标类型
  static const user = 'user'; // 用户目标类型
}

/// `ActivityType` 类：定义用户动态类型常量。
class ActivityType {
  static const String gameComment = "game_comment"; // 游戏评论动态类型
  static const String gameLike = "game_like"; // 游戏点赞动态类型
  static const String postCreate = "post_create"; // 发帖动态类型
  static const String postReply = "post_reply"; // 回帖动态类型
  static const String checkIn = "check_in"; // 签到动态类型
  static const String collection = "collection"; // 游戏收藏动态类型
  static const String follow = "follow"; // 关注用户动态类型
}

/// `ActivityTypeUtils` 类：活动类型工具类。
///
/// 该类提供获取活动描述和活动类型显示信息的方法。
class ActivityTypeUtils {
  /// 获取活动描述。
  ///
  /// [activity]：用户动态活动。
  /// 返回活动描述字符串。
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

  /// 根据活动类型获取显示信息（文本、背景色、文本色、图标）。
  ///
  /// [type]：活动类型字符串。
  /// 返回 [ActivityTypeDisplay] 实例。
  static ActivityTypeDisplay getActivityTypeDisplayInfo(String type) {
    String text; // 文本
    Color bgColor; // 背景颜色
    IconData icon; // 图标

    switch (type) {
      case ActivityTypeConstants.gameComment:
        text = '评论游戏';
        bgColor = Colors.blue.shade300;
        icon = Icons.comment_outlined;
        break;
      case ActivityTypeConstants.gameLike:
        text = '喜欢游戏';
        bgColor = Colors.pink.shade300;
        icon = Icons.favorite_border;
        break;
      case ActivityTypeConstants.collection:
        text = '收藏游戏';
        bgColor = Colors.amber.shade300;
        icon = Icons.bookmark_border;
        break;
      case ActivityTypeConstants.postReply:
        text = '回复帖子';
        bgColor = Colors.green.shade300;
        icon = Icons.reply_outlined;
        break;
      case ActivityTypeConstants.follow:
        text = '关注用户';
        bgColor = Colors.purple.shade300;
        icon = Icons.person_add_alt_1_outlined;
        break;
      case ActivityTypeConstants.checkIn:
        text = '完成签到';
        bgColor = Colors.teal.shade300;
        icon = Icons.check_circle_outline;
        break;
      case ActivityTypeConstants.postCreate:
        text = '发布帖子';
        bgColor = Colors.lightGreen.shade300;
        icon = Icons.post_add_outlined;
        break;
      default:
        text = '动态';
        bgColor = Colors.grey.shade200;
        icon = Icons.dynamic_feed_outlined;
    }

    final Color textColor = bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white; // 根据背景色亮度计算文本颜色

    return ActivityTypeDisplay(
      text: text,
      backgroundColor: bgColor,
      textColor: textColor,
      icon: icon,
    );
  }

  /// Gets the display text for the current collapse mode.
  static String getCollapseModeText(FeedCollapseMode collapseMode) {
    switch (collapseMode) {
      case FeedCollapseMode.none:
        return '标准视图';
      case FeedCollapseMode.byType:
        return '按类型折叠';
      default:
        return '标准视图'; // Fallback
    }
  }

  /// Gets the icon for the current collapse mode.
  static IconData getCollapseModeIcon(FeedCollapseMode collapseMode) {
    switch (collapseMode) {
      case FeedCollapseMode.none:
        return Icons.view_agenda_outlined; // Use outlined icons for consistency
      case FeedCollapseMode.byType:
        return Icons.category_outlined;
      default:
        return Icons.view_agenda_outlined; // Fallback
    }
  }

  /// 根据活动类型获取图标。
  ///
  /// [type]：活动类型字符串。
  /// 返回对应的图标。
  static IconData getActivityTypeIcon(String type) {
    return getActivityTypeDisplayInfo(type).icon; // 获取活动类型显示信息的图标
  }

  /// 根据活动类型获取文本。
  ///
  /// [type]：活动类型字符串。
  /// 返回对应的文本。
  static String getActivityTypeText(String type) {
    return getActivityTypeDisplayInfo(type).text; // 获取活动类型显示信息的文本
  }

  /// 根据活动类型获取背景颜色。
  ///
  /// [type]：活动类型字符串。
  /// 返回对应的背景颜色。
  static Color getActivityTypeBackgroundColor(String type) {
    return getActivityTypeDisplayInfo(type).backgroundColor; // 获取活动类型显示信息的背景颜色
  }

  /// 根据活动类型获取文本颜色。
  ///
  /// [type]：活动类型字符串。
  /// 返回对应的文本颜色。
  static Color getActivityTypeTextColor(String type) {
    return getActivityTypeDisplayInfo(type).textColor; // 获取活动类型显示信息的文本颜色
  }
}
