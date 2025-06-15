// lib/models/user/checkin_result.dart
import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/util_json.dart'; // 引用

@immutable
class CheckInResult {
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
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      experienceGained: UtilJson.parseIntSafely(json['experienceGained']),
      coinsGained: UtilJson.parseIntSafely(json['coinsGained']),
      nextCheckInExp: UtilJson.parseIntSafely(json['nextCheckInExp']),
      consecutiveCheckIn: UtilJson.parseIntSafely(json['consecutiveCheckIn']),
      totalCheckIn: UtilJson.parseIntSafely(json['totalCheckIn']),
      checkInDate: UtilJson.parseDateTime(json['checkInDate']),
      canGetExp: UtilJson.parseBoolSafely(json['canGetExp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toSafeJson(),
      'coinsGained': coinsGained,
      'experienceGained': experienceGained,
      'nextCheckInExp': nextCheckInExp,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
      'checkInDate': checkInDate.toIso8601String(),
      'canGetExp': canGetExp,
    };
  }
}
