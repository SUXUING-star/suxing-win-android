// lib/models/user/monthly_checkin_report.dart

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/daily_checkin_info.dart';
import 'package:suxingchahui/models/util_json.dart'; // 导入UtilJson

/// 月度签到报告模型
@immutable
class MonthlyCheckInReport {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyYear = 'year';
  static const String jsonKeyMonth = 'month';
  static const String jsonKeyMonthName = 'monthName';
  static const String jsonKeyDays = 'days';
  static const String jsonKeyTotal = 'total';
  static const String jsonKeyDaysInMonth = 'daysInMonth';
  static const String jsonKeyMaxConsecutive = 'maxConsecutive';
  static const String jsonKeyTotalExp = 'totalExp';

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
    // 使用 UtilJson.parseObjectList 来安全地解析 'days' 列表
    final parsedDays = UtilJson.parseObjectList<DailyCheckInInfo>(
      json[jsonKeyDays],
      (itemJson) => DailyCheckInInfo.fromJson(itemJson),
    );

    // 业务逻辑: 如果后端未提供 year 或 month，则使用当前年份和月份作为默认值
    final now = DateTime.now();
    final year = UtilJson.parseIntSafely(json[jsonKeyYear] ?? now.year);
    final month = UtilJson.parseIntSafely(json[jsonKeyMonth] ?? now.month);

    return MonthlyCheckInReport(
      year: year,
      month: month,
      // 业务逻辑: monthName 和 daysInMonth 都可以根据 year 和 month 在前端计算得出，减少对后端的依赖
      monthName: UtilJson.parseStringSafely(json[jsonKeyMonthName]), // 使用常量
      days: parsedDays,
      total: UtilJson.parseIntSafely(json[jsonKeyTotal]), // 使用常量
      daysInMonth: UtilJson.parseIntSafely(
          json[jsonKeyDaysInMonth] ?? DateTime(year, month + 1, 0).day), // 使用常量
      maxConsecutive:
          UtilJson.parseIntSafely(json[jsonKeyMaxConsecutive]), // 使用常量
      totalExp: UtilJson.parseIntSafely(json[jsonKeyTotalExp]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyYear: year, // 使用常量
      jsonKeyMonth: month, // 使用常量
      jsonKeyMonthName: monthName, // 使用常量
      jsonKeyDays: days.map((e) => e.toJson()).toList(), // 使用常量
      jsonKeyTotal: total, // 使用常量
      jsonKeyDaysInMonth: daysInMonth, // 使用常量
      jsonKeyMaxConsecutive: maxConsecutive, // 使用常量
      jsonKeyTotalExp: totalExp, // 使用常量
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
