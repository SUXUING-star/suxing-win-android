// lib/models/user/daily_progress.dart

import 'package:suxingchahui/models/user/task_style.dart';

// 任务详情模型
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
      type: json['type'] as String? ?? 'unknown',
      name: json['name'] as String? ?? '未知任务',
      description: json['description'] as String? ?? '完成任务可获得经验',
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      expPerTask: (json['expPerTask'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
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

  double get progress => (limit <= 0) ? (completed ? 1.0 : 0.0) : (used / limit).clamp(0.0, 1.0);
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
      earnedToday: (json['earnedToday'] as num?)?.toInt() ?? 0,
      possibleToday: (json['possibleToday'] as num?)?.toInt() ?? 0,
      remainingToday: (json['remainingToday'] as num?)?.toInt() ?? 0,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
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
          .map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
          .toList();
    }

    return DailyProgressData(
      totalExperience: (json['totalExperience'] as num?)?.toInt() ?? 0,
      todayProgress: TodayProgressSummary.fromJson(json['todayProgress'] as Map<String, dynamic>? ?? {}),
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
      todayProgress: TodayProgressSummary(earnedToday: 0, possibleToday: 0, remainingToday: 0, completionPercentage: 0.0),
      tasks: [],
    );
  }
}