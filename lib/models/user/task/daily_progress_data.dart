// lib/models/user/task/daily_progress_data.dart

// 完整的每日经验进度数据模型
import 'package:suxingchahui/models/user/task/daily_task.dart';
import 'package:suxingchahui/models/user/task/today_progress_summary.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class DailyProgressData {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyTotalExperience = 'totalExperience';
  static const String jsonKeyTodayProgress = 'todayProgress';
  static const String jsonKeyTasks = 'tasks';

  final int totalExperience;
  final TodayProgressSummary todayProgress;
  final List<DailyTask> tasks;

  const DailyProgressData({
    required this.totalExperience,
    required this.todayProgress,
    required this.tasks,
  });

  factory DailyProgressData.fromJson(Map<String, dynamic> json) {
    // 使用 UtilJson.parseObjectList 来安全地解析 'tasks' 列表
    final parsedTasks = UtilJson.parseObjectList<DailyTask>(
      json[jsonKeyTasks],
      (itemJson) => DailyTask.fromJson(itemJson),
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
