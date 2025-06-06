// lib/models/user/checkin_status.dart
import 'package:intl/intl.dart';

/// 签到状态和统计信息模型
class CheckInStatus {
  final bool canCheckInToday;
  final bool checkedInToday;
  final int totalCheckIn;
  final int consecutiveCheckIn;
  final int nextCheckInExp;
  final DateTime? lastCheckInDate; // Nil 会被 Gin 序列化为 null

  CheckInStatus({
    required this.canCheckInToday,
    required this.checkedInToday,
    required this.totalCheckIn,
    required this.consecutiveCheckIn,
    required this.nextCheckInExp,
    this.lastCheckInDate,
  });

  factory CheckInStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parsedLastCheckInDate;
    if (json['lastCheckInDate'] != null &&
        json['lastCheckInDate'] is String &&
        (json['lastCheckInDate'] as String).isNotEmpty) {
      try {
        // 假设日期格式为 YYYY-MM-DD
        parsedLastCheckInDate =
            DateFormat('yyyy-MM-dd').parse(json['lastCheckInDate']);
      } catch (e) {
        // print('Error parsing lastCheckInDate: ${json['lastCheckInDate']} - $e');
        // 如果解析失败，保持为 null
      }
    }

    return CheckInStatus(
      canCheckInToday: json['canCheckInToday'] as bool? ?? true,
      checkedInToday: json['checkedInToday'] as bool? ?? false,
      totalCheckIn: json['totalCheckIn'] as int? ?? 0,
      consecutiveCheckIn: json['consecutiveCheckIn'] as int? ?? 0,
      nextCheckInExp: json['nextCheckInExp'] as int? ?? 0,
      lastCheckInDate: parsedLastCheckInDate,
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
