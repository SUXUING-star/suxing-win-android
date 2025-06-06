// lib/models/user/checkin_result.dart
import 'package:suxingchahui/models/user/user.dart';

class CheckInResult {
  final String message;
  final User? user; // User 对象现在由 performCheckIn 方法内部解析并设置
  final int experienceGained;
  final int nextCheckInExp; // <<< --- 新增字段 ---
  final int consecutiveCheckIn;
  final int totalCheckIn;
  final DateTime checkInDate;
  final bool canGetExp;

  CheckInResult({
    required this.message,
    this.user,
    required this.experienceGained,
    required this.nextCheckInExp, // <<< --- 新增字段 ---
    required this.consecutiveCheckIn,
    required this.totalCheckIn,
    required this.checkInDate,
    required this.canGetExp,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['checkInDate'] as String? ?? '');
    } catch (e) {
      parsedDate = DateTime.now();
    }

    User? parsedUser;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      try {
        parsedUser = User.fromJson(json['user'] as Map<String, dynamic>);
      } catch (e) {
        // print('Error parsing user from CheckInResult: $e');
      }
    }

    return CheckInResult(
      message: json['message'] as String? ?? '签到成功',
      user: parsedUser, // 直接从 json['user'] 解析
      experienceGained: json['experienceGained'] as int? ?? 0,
      nextCheckInExp: json['nextCheckInExp'] as int? ?? 0, // <<< --- 新增字段解析 ---
      consecutiveCheckIn: json['consecutiveCheckIn'] as int? ?? 0,
      totalCheckIn: json['totalCheckIn'] as int? ?? 0,
      checkInDate: parsedDate,
      canGetExp: json['canGetExp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user?.toJson(),
      'experienceGained': experienceGained,
      'nextCheckInExp': nextCheckInExp, // <<< --- 新增字段 ---
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
      'checkInDate': checkInDate.toIso8601String(),
      'canGetExp': canGetExp,
    };
  }
}
