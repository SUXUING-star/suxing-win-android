// lib/models/user/monthly_checkin_report.dart
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/user/daily_checkin_info.dart'; // 导入DailyCheckInInfo

/// 月度签到报告模型
class MonthlyCheckInReport {
  final int year;
  final int month;
  final String monthName;
  final List<DailyCheckInInfo> days;
  final int total; // 当月总签到天数
  final int daysInMonth; // 当月总天数
  final int maxConsecutive; // 当月最大连续签到天数
  final int totalExp; // 当月总经验值

  MonthlyCheckInReport({
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
    if (json['days'] != null && json['days'] is List) {
      parsedDays = (json['days'] as List)
          .map((e) => DailyCheckInInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 默认值处理，防止API返回 null 或缺失字段
    final currentYear = json['year'] as int? ?? DateTime.now().year;
    final currentMonth = json['month'] as int? ?? DateTime.now().month;
    final defaultMonthName =
        DateFormat('MMMM').format(DateTime(currentYear, currentMonth));
    final defaultDaysInMonth =
        DateTime(currentYear, currentMonth + 1, 0).day; // 获取当月天数

    return MonthlyCheckInReport(
      year: currentYear,
      month: currentMonth,
      monthName: json['monthName'] as String? ?? defaultMonthName,
      days: parsedDays,
      total: json['total'] as int? ?? 0,
      daysInMonth: json['daysInMonth'] as int? ?? defaultDaysInMonth,
      maxConsecutive: json['maxConsecutive'] as int? ?? 0,
      totalExp: json['totalExp'] as int? ?? 0,
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
