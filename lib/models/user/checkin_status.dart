// lib/models/user/checkin_status.dart

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/checkin_result.dart';
import 'package:suxingchahui/models/util_json.dart';

/// 签到状态和统计信息模型
@immutable
class CheckInStatus {
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
      canCheckInToday: UtilJson.parseBoolSafely(json['canCheckInToday'], defaultValue: true),
      checkedInToday: UtilJson.parseBoolSafely(json['checkedInToday']),
      totalCheckIn: UtilJson.parseIntSafely(json['totalCheckIn']),
      consecutiveCheckIn: UtilJson.parseIntSafely(json['consecutiveCheckIn']),
      nextCheckInExp: UtilJson.parseIntSafely(json['nextCheckInExp']),
      // UtilJson.parseNullableDateTime 能正确处理多种日期格式
      lastCheckInDate: UtilJson.parseNullableDateTime(json['lastCheckInDate']),
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
      'canCheckInToday': canCheckInToday,
      'checkedInToday': checkedInToday,
      'totalCheckIn': totalCheckIn,
      'consecutiveCheckIn': consecutiveCheckIn,
      'nextCheckInExp': nextCheckInExp,
      'lastCheckInDate': lastCheckInDate != null
          ? DateFormat('yyyy-MM-dd').format(lastCheckInDate!)
          : null,
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
