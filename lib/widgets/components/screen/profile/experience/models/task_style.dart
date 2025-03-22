// lib/widgets/components/screen/profile/experience/models/task_style.dart

import 'package:flutter/material.dart';

class TaskStyle {
  final Color color;
  final IconData icon;

  TaskStyle({required this.color, required this.icon});

  // 获取任务样式（颜色和图标）
  static TaskStyle getTaskStyle(String type, bool completed) {
    Color taskColor;
    IconData taskIcon;

    switch (type) {
      case 'post':
        taskColor = Colors.blue.shade400;
        taskIcon = Icons.post_add;
        break;
      case 'reply':
        taskColor = Colors.green.shade400;
        taskIcon = Icons.reply;
        break;
      case 'like':
        taskColor = Colors.pink.shade300;
        taskIcon = Icons.thumb_up;
        break;
      case 'follow':
        taskColor = Colors.purple.shade300;
        taskIcon = Icons.person_add;
        break;
      case 'collection':
        taskColor = Colors.amber.shade400;
        taskIcon = Icons.bookmark;
        break;
      case 'checkin':
        taskColor = Colors.deepOrange.shade300;
        taskIcon = Icons.calendar_today;
        break;
      case 'comment':
        taskColor = Colors.teal.shade300;
        taskIcon = Icons.comment;
        break;
      default:
        taskColor = Colors.grey.shade500;
        taskIcon = Icons.task_alt;
    }

    // 调整已完成任务的不透明度
    if (completed) {
      taskColor = taskColor.withOpacity(0.6);
    }

    return TaskStyle(color: taskColor, icon: taskIcon);
  }
}