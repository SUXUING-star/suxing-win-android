// lib/models/user/daily_checkin_info.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart'; // 引入 UtilJson

/// 单日签到信息模型
@immutable
class DailyCheckInInfo {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyDay = 'day';
  static const String jsonKeyCheckedIn = 'checkedIn';
  static const String jsonKeyExp = 'exp';

  final int day;
  final bool checkedIn;
  final int exp;

  const DailyCheckInInfo({
    required this.day,
    required this.checkedIn,
    required this.exp,
  });

  factory DailyCheckInInfo.fromJson(Map<String, dynamic> json) {
    return DailyCheckInInfo(
      // 直接调用 UtilJson 中新添加的方法来解析 'day' 字段
      day: UtilJson.parseDayOfMonthSafely(json[jsonKeyDay]),
      checkedIn: UtilJson.parseBoolSafely(json[jsonKeyCheckedIn]),
      exp: UtilJson.parseIntSafely(json[jsonKeyExp]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyDay: day,
      jsonKeyCheckedIn: checkedIn,
      jsonKeyExp: exp,
    };
  }
}
