// lib/models/user/checkin_status.dart

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/checkin_result.dart';
import 'package:suxingchahui/models/util_json.dart';

/// 签到状态和统计信息模型
@immutable
class CheckInStatus {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyCanCheckInToday = 'canCheckInToday';
  static const String jsonKeyCheckedInToday = 'checkedInToday';
  static const String jsonKeyTotalCheckIn = 'totalCheckIn';
  static const String jsonKeyConsecutiveCheckIn = 'consecutiveCheckIn';
  static const String jsonKeyNextCheckInExp = 'nextCheckInExp';
  static const String jsonKeyLastCheckInDate = 'lastCheckInDate';

  final bool canCheckInToday;
  final bool checkedInToday;
  final int totalCheckIn;
  final int consecutiveCheckIn;
  final int nextCheckInExp;
  final DateTime? lastCheckInDate;

  const CheckInStatus({
    required this.canCheckInToday,
    required this.checkedInToday,
    required this.totalCheckIn,
    required this.consecutiveCheckIn,
    required this.nextCheckInExp,
    this.lastCheckInDate,
  });

  factory CheckInStatus.fromJson(Map<String, dynamic> json) {
    return CheckInStatus(
      // 业务逻辑: 如果后端未明确提供，则默认为可以签到
      canCheckInToday: UtilJson.parseBoolSafely(json[jsonKeyCanCheckInToday],
          defaultValue: true), // 使用常量
      checkedInToday:
          UtilJson.parseBoolSafely(json[jsonKeyCheckedInToday]), // 使用常量
      totalCheckIn: UtilJson.parseIntSafely(json[jsonKeyTotalCheckIn]), // 使用常量
      consecutiveCheckIn:
          UtilJson.parseIntSafely(json[jsonKeyConsecutiveCheckIn]), // 使用常量
      nextCheckInExp:
          UtilJson.parseIntSafely(json[jsonKeyNextCheckInExp]), // 使用常量
      // UtilJson.parseNullableDateTime 能正确处理多种日期格式
      lastCheckInDate:
          UtilJson.parseNullableDateTime(json[jsonKeyLastCheckInDate]), // 使用常量
    );
  }

  /// 从签到成功的结果直接创建签到状态
  factory CheckInStatus.fromCheckInResult(CheckInResult result) {
    return CheckInStatus(
      // 业务逻辑: 签到成功后，当天已签到，且不能再签到
      checkedInToday: true,
      canCheckInToday: false,
      totalCheckIn: result.totalCheckIn,
      consecutiveCheckIn: result.consecutiveCheckIn,
      nextCheckInExp: result.nextCheckInExp,
      lastCheckInDate: result.checkInDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyCanCheckInToday: canCheckInToday, // 使用常量
      jsonKeyCheckedInToday: checkedInToday, // 使用常量
      jsonKeyTotalCheckIn: totalCheckIn, // 使用常量
      jsonKeyConsecutiveCheckIn: consecutiveCheckIn, // 使用常量
      jsonKeyNextCheckInExp: nextCheckInExp, // 使用常量
      jsonKeyLastCheckInDate: lastCheckInDate != null
          ? DateFormat('yyyy-MM-dd').format(lastCheckInDate!)
          : null, // 使用常量
    };
  }

  /// 提供一个默认的空状态，用于错误处理或未登录情况
  static CheckInStatus defaultStatus() {
    return CheckInStatus(
      canCheckInToday: true,
      checkedInToday: false,
      totalCheckIn: 0,
      consecutiveCheckIn: 0,
      nextCheckInExp: 0,
      lastCheckInDate: null,
    );
  }
}
