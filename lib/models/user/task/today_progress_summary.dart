// lib/models/user/task/today_progress_summary.dart

// 今日进度汇总模型
import 'package:suxingchahui/models/utils/util_json.dart';

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
