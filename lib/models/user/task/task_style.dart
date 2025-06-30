// lib/models/user/task/task_style.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class EnrichTaskType implements CommonColorThemeExtension {
  static const String postType = 'post';
  static const String replyType = 'reply';
  static const String likeType = 'like';
  static const String followType = 'follow';
  static const String collectionType = 'collection';
  static const String commentType = 'comment';
  static const String gameType = 'game';

  final String type;

  final bool completed;

  const EnrichTaskType({
    required this.type,
    required this.completed,
  });

  factory EnrichTaskType.fromType(String type, bool completed) =>
      EnrichTaskType(type: type, completed: completed);

  @override
  Color getTextColor() => getTaskStyle(type, completed).textColor;

  @override
  String getTextLabel() => getTaskStyle(type, completed).textLabel;

  @override
  IconData getIconData() => getTaskStyle(type, completed).iconData;

  @override
  Color getBackgroundColor() => getTaskStyle(type, completed).backgroundColor;

  // 获取任务样式（颜色和图标）
  static CommonColorTheme getTaskStyle(String type, bool completed) {
    Color taskBackgroundColor;
    IconData taskIcon;
    const taskTextColor = Colors.white;

    String taskLabel;

    switch (type) {
      case postType:
        taskBackgroundColor = Colors.blue.shade400;
        taskIcon = Icons.post_add;
        taskLabel = '发布帖子';
        break;
      case replyType:
        taskBackgroundColor = Colors.green.shade400;
        taskIcon = Icons.reply;
        taskLabel = '发布帖子评论';
        break;
      case likeType:
        taskBackgroundColor = Colors.pink.shade300;
        taskIcon = Icons.thumb_up;
        taskLabel = '点赞游戏';
        break;
      case followType:
        taskBackgroundColor = Colors.purple.shade300;
        taskIcon = Icons.person_add;
        taskLabel = '关注用户';
        break;
      case collectionType:
        taskBackgroundColor = Colors.amber.shade400;
        taskIcon = Icons.bookmark;
        taskLabel = '收藏游戏';
        break;
      case commentType:
        taskBackgroundColor = Colors.teal.shade300;
        taskIcon = Icons.comment;
        taskLabel = '评论游戏';
        break;
      case gameType: // 新增游戏创建任务类型
        taskBackgroundColor = Colors.indigo.shade400;
        taskIcon = Icons.games;
        taskLabel = '创建游戏';
        break;
      default:
        taskBackgroundColor = Colors.grey.shade500;
        taskIcon = Icons.task_alt;
        taskLabel = '其他';
    }

    // 调整已完成任务的不透明度
    if (completed) {
      taskBackgroundColor = taskBackgroundColor.withSafeOpacity(0.6);
    }

    return CommonColorTheme(
      backgroundColor: taskBackgroundColor,
      iconData: taskIcon,
      textColor: taskTextColor,
      textLabel: taskLabel,
    );
  }
}
