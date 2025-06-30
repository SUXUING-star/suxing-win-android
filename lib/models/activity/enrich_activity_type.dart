// lib/models/activity/enrich_activity_type.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';

class EnrichActivityType implements CommonColorThemeExtension {
  final String type;

  const EnrichActivityType({
    required this.type,
  });

  factory EnrichActivityType.fromType(String type) =>
      EnrichActivityType(type: type);

  static const String gameComment = "game_comment"; // 游戏评论动态类型
  static const String gameLike = "game_like"; // 游戏点赞动态类型
  static const String postCreate = "post_create"; // 发帖动态类型
  static const String postReply = "post_reply"; // 回帖动态类型
  static const String checkIn = "check_in"; // 签到动态类型
  static const String collection = "collection"; // 游戏收藏动态类型
  static const String follow = "follow"; // 关注用户动态类型

  @override
  Color getTextColor() => getTypeTheme(type).textColor;

  @override
  String getTextLabel() => getTypeTheme(type).textLabel;

  @override
  IconData getIconData() => getTypeTheme(type).iconData;

  @override
  Color getBackgroundColor() => getTypeTheme(type).backgroundColor;

  /// 根据活动类型获取显示信息（文本、背景色、文本色、图标）。
  ///
  /// [type]：活动类型字符串。
  /// 返回 [ActivityTypeDisplay] 实例。
  static CommonColorTheme getTypeTheme(String type) {
    String text; // 文本
    Color bgColor; // 背景颜色
    IconData icon; // 图标

    switch (type) {
      case gameComment:
        text = '评论游戏';
        bgColor = Colors.blue.shade300;
        icon = Icons.comment_outlined;
        break;
      case gameLike:
        text = '喜欢游戏';
        bgColor = Colors.pink.shade300;
        icon = Icons.favorite_border;
        break;
      case collection:
        text = '收藏游戏';
        bgColor = Colors.amber.shade300;
        icon = Icons.bookmark_border;
        break;
      case postReply:
        text = '回复帖子';
        bgColor = Colors.green.shade300;
        icon = Icons.reply_outlined;
        break;
      case follow:
        text = '关注用户';
        bgColor = Colors.purple.shade300;
        icon = Icons.person_add_alt_1_outlined;
        break;
      case checkIn:
        text = '完成签到';
        bgColor = Colors.teal.shade300;
        icon = Icons.check_circle_outline;
        break;
      case postCreate:
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

    return CommonColorTheme(
      textLabel: text,
      backgroundColor: bgColor,
      textColor: textColor,
      iconData: icon,
    );
  }

  bool get isCheckIn => type == checkIn;
}
