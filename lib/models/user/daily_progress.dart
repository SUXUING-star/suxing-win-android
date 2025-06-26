// lib/models/user/daily_progress.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/task_style.dart';
import 'package:suxingchahui/models/util_json.dart';

// 任务详情模型

@immutable
class Task {
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
  late final TaskStyle style;

  Task({
    required this.type,
    required this.name,
    required this.description,
    required this.used,
    required this.limit,
    required this.expPerTask,
    required this.completed,
  }) {
    style = TaskStyle.getTaskStyle(type, completed);
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
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

  double get progress =>
      (limit <= 0) ? (completed ? 1.0 : 0.0) : (used / limit).clamp(0.0, 1.0);
  String get countText => '$used/$limit';
  String get expPerTaskText => '+$expPerTask经验/次';
}

// 今日进度汇总模型
@immutable
class TodayProgressSummary {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyEarnedToday = 'earnedToday';
  static const String jsonKeyPossibleToday = 'possibleToday';
  static const String jsonKeyRemainingToday = 'remainingToday';
  static const String jsonKeyCompletionPercentage = 'completionPercentage';

  final int earnedToday;
  final int possibleToday;
  final int remainingToday;
  final double completionPercentage;

  const TodayProgressSummary({
    required this.earnedToday,
    required this.possibleToday,
    required this.remainingToday,
    required this.completionPercentage,
  });

  factory TodayProgressSummary.fromJson(Map<String, dynamic> json) {
    return TodayProgressSummary(
      earnedToday: UtilJson.parseIntSafely(json[jsonKeyEarnedToday]),
      possibleToday: UtilJson.parseIntSafely(json[jsonKeyPossibleToday]),
      remainingToday: UtilJson.parseIntSafely(json[jsonKeyRemainingToday]),
      completionPercentage:
          UtilJson.parseDoubleSafely(json[jsonKeyCompletionPercentage]),
    );
  }

  Map<String, dynamic> toJson() => {
        jsonKeyEarnedToday: earnedToday,
        jsonKeyPossibleToday: possibleToday,
        jsonKeyRemainingToday: remainingToday,
        jsonKeyCompletionPercentage: completionPercentage,
      };
}

// 完整的每日经验进度数据模型
@immutable
class DailyProgressData {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyTotalExperience = 'totalExperience';
  static const String jsonKeyTodayProgress = 'todayProgress';
  static const String jsonKeyTasks = 'tasks';

  final int totalExperience;
  final TodayProgressSummary todayProgress;
  final List<Task> tasks;

  const DailyProgressData({
    required this.totalExperience,
    required this.todayProgress,
    required this.tasks,
  });

  factory DailyProgressData.fromJson(Map<String, dynamic> json) {
    // 使用 UtilJson.parseObjectList 来安全地解析 'tasks' 列表
    final parsedTasks = UtilJson.parseObjectList<Task>(
      json[jsonKeyTasks],
      (itemJson) => Task.fromJson(itemJson),
    );

    // 确保 todayProgress 字段是 Map，如果不是或为 null 则使用空 Map
    final todayProgressData = json[jsonKeyTodayProgress] is Map<String, dynamic>
        ? json[jsonKeyTodayProgress] as Map<String, dynamic>
        : <String, dynamic>{};

    return DailyProgressData(
      totalExperience: UtilJson.parseIntSafely(json[jsonKeyTotalExperience]),
      todayProgress: TodayProgressSummary.fromJson(todayProgressData),
      tasks: parsedTasks,
    );
  }

  Map<String, dynamic> toJson() => {
        jsonKeyTotalExperience: totalExperience,
        jsonKeyTodayProgress: todayProgress.toJson(),
        jsonKeyTasks: tasks.map((task) => task.toJson()).toList(),
      };

  static DailyProgressData empty() {
    return DailyProgressData(
      totalExperience: 0,
      todayProgress: const TodayProgressSummary(
          earnedToday: 0,
          possibleToday: 0,
          remainingToday: 0,
          completionPercentage: 0.0),
      tasks: [],
    );
  }
}
