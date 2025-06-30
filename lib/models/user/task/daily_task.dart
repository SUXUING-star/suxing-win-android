// lib/models/user/task/daily_task.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/user/task/task_style.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

// 任务详情模型

class DailyTask implements CommonColorThemeExtension {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyType = 'type';
  static const String jsonKeyName = 'name';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyUsed = 'used';
  static const String jsonKeyLimit = 'limit';
  static const String jsonKeyExpPerTask = 'expPerTask';
  static const String jsonKeyCompleted = 'completed';

  final String type;
  final String name;
  final String description;
  final int used;
  final int limit;
  final int expPerTask;
  final bool completed;

  DailyTask({
    required this.type,
    required this.name,
    required this.description,
    required this.used,
    required this.limit,
    required this.expPerTask,
    required this.completed,
  });

  @override
  String getTextLabel() => enrichType.textLabel;

  @override
  Color getTextColor() => enrichType.textColor;

  @override
  IconData getIconData() => enrichType.iconData;

  @override
  Color getBackgroundColor() => enrichType.backgroundColor;

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      type: UtilJson.parseStringSafely(json[jsonKeyType]),
      name: UtilJson.parseStringSafely(json[jsonKeyName]),
      description: UtilJson.parseStringSafely(json[jsonKeyDescription]),
      used: UtilJson.parseIntSafely(json[jsonKeyUsed]),
      limit: UtilJson.parseIntSafely(json[jsonKeyLimit]),
      expPerTask: UtilJson.parseIntSafely(json[jsonKeyExpPerTask]),
      completed: UtilJson.parseBoolSafely(json[jsonKeyCompleted]),
    );
  }

  Map<String, dynamic> toJson() => {
        jsonKeyType: type,
        jsonKeyName: name,
        jsonKeyDescription: description,
        jsonKeyUsed: used,
        jsonKeyLimit: limit,
        jsonKeyExpPerTask: expPerTask,
        jsonKeyCompleted: completed,
      };
}

extension DailyTaskExtension on DailyTask {
  double get progress =>
      (limit <= 0) ? (completed ? 1.0 : 0.0) : (used / limit).clamp(0.0, 1.0);
  String get countText => '$used/$limit';
  String get expPerTaskText => '+$expPerTask经验/次';

  EnrichTaskType get enrichType => EnrichTaskType.fromType(type, completed);
}
