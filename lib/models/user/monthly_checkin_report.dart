// lib/models/user/monthly_checkin_report.dart

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/daily_checkin_info.dart';
import 'package:suxingchahui/models/util_json.dart'; // 导入DailyCheckInInfo

/// 月度签到报告模型
@immutable
class MonthlyCheckInReport {
  final int year;
  final int month;
  final String monthName;
  final List<DailyCheckInInfo> days;
  final int total; // 当月总签到天数
  final int daysInMonth; // 当月总天数
  final int maxConsecutive; // 当月最大连续签到天数
  final int totalExp; // 当月总经验值

  const MonthlyCheckInReport({
    required this.year,
    required this.month,
    required this.monthName,
    required this.days,
    required this.total,
    required this.daysInMonth,
    required this.maxConsecutive,
    required this.totalExp,
  });

  factory MonthlyCheckInReport.fromJson(Map<String, dynamic> json) {
    List<DailyCheckInInfo> parsedDays = [];
    if (json['days'] is List) {
      parsedDays = (json['days'] as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return DailyCheckInInfo.fromJson(item);
            }
            return null;
          })
          .whereType<DailyCheckInInfo>()
          .toList();
    }

    // 业务逻辑: 如果后端未提供 year 或 month，则使用当前年份和月份作为默认值
    final now = DateTime.now();
    final year = UtilJson.parseIntSafely(json['year'] ?? now.year);
    final month = UtilJson.parseIntSafely(json['month'] ?? now.month);

    return MonthlyCheckInReport(
      year: year,
      month: month,
      // 业务逻辑: monthName 和 daysInMonth 都可以根据 year 和 month 在前端计算得出，减少对后端的依赖
      monthName:
          UtilJson.parseStringSafely(json['monthName']), // 假设后端会提供，如果没有，会是空字符串
      days: parsedDays,
      total: UtilJson.parseIntSafely(json['total']),
      daysInMonth: UtilJson.parseIntSafely(
          json['daysInMonth'] ?? DateTime(year, month + 1, 0).day),
      maxConsecutive: UtilJson.parseIntSafely(json['maxConsecutive']),
      totalExp: UtilJson.parseIntSafely(json['totalExp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'monthName': monthName,
      'days': days.map((e) => e.toJson()).toList(),
      'total': total,
      'daysInMonth': daysInMonth,
      'maxConsecutive': maxConsecutive,
      'totalExp': totalExp,
    };
  }

  /// 提供一个默认的空报告，用于错误处理或未登录情况
  static MonthlyCheckInReport defaultReport({int? year, int? month}) {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    return MonthlyCheckInReport(
      year: targetYear,
      month: targetMonth,
      monthName: DateFormat('MMMM').format(DateTime(targetYear, targetMonth)),
      days: [],
      total: 0,
      daysInMonth: DateTime(targetYear, targetMonth + 1, 0).day,
      maxConsecutive: 0,
      totalExp: 0,
    );
  }
}
