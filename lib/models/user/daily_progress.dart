// lib/models/user/daily_progress.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/task_style.dart';
import 'package:suxingchahui/models/util_json.dart';

// 任务详情模型

@immutable
class Task {
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
      type: UtilJson.parseStringSafely(json['type']),
      name: UtilJson.parseStringSafely(json['name']),
      description: UtilJson.parseStringSafely(json['description']),
      used: UtilJson.parseIntSafely(json['used']),
      limit: UtilJson.parseIntSafely(json['limit']),
      expPerTask: UtilJson.parseIntSafely(json['expPerTask']),
      completed: UtilJson.parseBoolSafely(json['completed']),
    );
  }

  // **** 添加 toJson 方法 ****
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'description': description,
        'used': used,
        'limit': limit,
        'expPerTask': expPerTask,
        'completed': completed,
        // 'style' 不需要序列化回 JSON
      };

  double get progress =>
      (limit <= 0) ? (completed ? 1.0 : 0.0) : (used / limit).clamp(0.0, 1.0);
  String get countText => '$used/$limit';
  String get expPerTaskText => '+$expPerTask经验/次';
}

// 今日进度汇总模型
class TodayProgressSummary {
  final int earnedToday;
  final int possibleToday;
  final int remainingToday;
  final double completionPercentage;

  TodayProgressSummary({
    required this.earnedToday,
    required this.possibleToday,
    required this.remainingToday,
    required this.completionPercentage,
  });

  factory TodayProgressSummary.fromJson(Map<String, dynamic> json) {
    return TodayProgressSummary(
      earnedToday: UtilJson.parseIntSafely(json['earnedToday']),
      possibleToday: UtilJson.parseIntSafely(json['possibleToday']),
      remainingToday: UtilJson.parseIntSafely(json['remainingToday']),
      completionPercentage:
          UtilJson.parseDoubleSafely(json['completionPercentage']),
    );
  }

  // **** 添加 toJson 方法 ****
  Map<String, dynamic> toJson() => {
        'earnedToday': earnedToday,
        'possibleToday': possibleToday,
        'remainingToday': remainingToday,
        'completionPercentage': completionPercentage,
      };
}

// 完整的每日经验进度数据模型
class DailyProgressData {
  final int totalExperience;
  final TodayProgressSummary todayProgress;
  final List<Task> tasks;

  DailyProgressData({
    required this.totalExperience,
    required this.todayProgress,
    required this.tasks,
  });

  factory DailyProgressData.fromJson(Map<String, dynamic> json) {
    List<Task> parsedTasks = [];
    if (json['tasks'] is List) {
      parsedTasks = (json['tasks'] as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Task.fromJson(item);
            }
            return null;
          })
          .whereType<Task>()
          .toList();
    }

    // 确保 todayProgress 字段是 Map，如果不是或为 null 则使用空 Map
    final todayProgressData = json['todayProgress'] is Map<String, dynamic>
        ? json['todayProgress'] as Map<String, dynamic>
        : <String, dynamic>{};

    return DailyProgressData(
      totalExperience: UtilJson.parseIntSafely(json['totalExperience']),
      todayProgress: TodayProgressSummary.fromJson(todayProgressData),
      tasks: parsedTasks,
    );
  }

  // **** 添加 toJson 方法 ****
  Map<String, dynamic> toJson() => {
        'totalExperience': totalExperience,
        // 调用嵌套对象的 toJson
        'todayProgress': todayProgress.toJson(),
        // 对列表中的每个对象调用 toJson
        'tasks': tasks.map((task) => task.toJson()).toList(),
      };

  // 可以添加一个空的构造函数或静态方法，用于错误处理时返回默认值
  static DailyProgressData empty() {
    return DailyProgressData(
      totalExperience: 0,
      todayProgress: TodayProgressSummary(
          earnedToday: 0,
          possibleToday: 0,
          remainingToday: 0,
          completionPercentage: 0.0),
      tasks: [],
    );
  }
}
