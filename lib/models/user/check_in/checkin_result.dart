// lib/models/user/checkin_result.dart
import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/models/utils/util_json.dart'; // 引用

@immutable
class CheckInResult {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyUser = 'user';
  static const String jsonKeyExperienceGained = 'experienceGained';
  static const String jsonKeyCoinsGained = 'coinsGained';
  static const String jsonKeyNextCheckInExp = 'nextCheckInExp';
  static const String jsonKeyConsecutiveCheckIn = 'consecutiveCheckIn';
  static const String jsonKeyTotalCheckIn = 'totalCheckIn';
  static const String jsonKeyCheckInDate = 'checkInDate';
  static const String jsonKeyCanGetExp = 'canGetExp';

  final User? user;
  final int experienceGained;
  final int coinsGained;
  final int nextCheckInExp;
  final int consecutiveCheckIn;
  final int totalCheckIn;
  final DateTime checkInDate;
  final bool canGetExp;

  const CheckInResult({
    this.user,
    required this.experienceGained,
    required this.coinsGained,
    required this.nextCheckInExp,
    required this.consecutiveCheckIn,
    required this.totalCheckIn,
    required this.checkInDate,
    required this.canGetExp,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      // 使用 UtilJson.parseObjectList 的思想，但这里是单个对象
      user: json[jsonKeyUser] is Map<String, dynamic>
          ? User.fromJson(json[jsonKeyUser] as Map<String, dynamic>)
          : null,
      experienceGained:
          UtilJson.parseIntSafely(json[jsonKeyExperienceGained]), // 使用常量
      coinsGained: UtilJson.parseIntSafely(json[jsonKeyCoinsGained]), // 使用常量
      nextCheckInExp:
          UtilJson.parseIntSafely(json[jsonKeyNextCheckInExp]), // 使用常量
      consecutiveCheckIn:
          UtilJson.parseIntSafely(json[jsonKeyConsecutiveCheckIn]), // 使用常量
      totalCheckIn: UtilJson.parseIntSafely(json[jsonKeyTotalCheckIn]), // 使用常量
      checkInDate: UtilJson.parseDateTime(json[jsonKeyCheckInDate]), // 使用常量
      canGetExp: UtilJson.parseBoolSafely(json[jsonKeyCanGetExp]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyUser: user?.toSafeJson(), // 使用常量
      jsonKeyCoinsGained: coinsGained, // 使用常量
      jsonKeyExperienceGained: experienceGained, // 使用常量
      jsonKeyNextCheckInExp: nextCheckInExp, // 使用常量
      jsonKeyConsecutiveCheckIn: consecutiveCheckIn, // 使用常量
      jsonKeyTotalCheckIn: totalCheckIn, // 使用常量
      jsonKeyCheckInDate: checkInDate.toIso8601String(), // 使用常量
      jsonKeyCanGetExp: canGetExp, // 使用常量
    };
  }
}
