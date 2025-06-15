// lib/models/user/user_ban.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class UserBan {
  final String id;
  final String userId;
  final String reason;
  final DateTime banTime;
  final DateTime? endTime; // null表示永久封禁
  final String bannedBy; // 执行封禁的管理员ID

  const UserBan({
    required this.id,
    required this.userId,
    required this.reason,
    required this.banTime,
    this.endTime,
    required this.bannedBy,
  });

  factory UserBan.fromJson(Map<String, dynamic> json) {
    return UserBan(
      id: UtilJson.parseId(json['id'] ?? json['_id']),
      userId: UtilJson.parseId(json['userId']),
      reason: UtilJson.parseStringSafely(json['reason']),
      banTime: UtilJson.parseDateTime(json['banTime']),
      // 业务逻辑: endTime 为 null 表示永久封禁
      endTime: UtilJson.parseNullableDateTime(json['endTime']),
      bannedBy: UtilJson.parseId(json['bannedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'reason': reason,
      'banTime': banTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'bannedBy': bannedBy,
    };
  }

  bool get isPermanent => endTime == null;

  bool get isActive {
    if (isPermanent) return true;
    return endTime!.isAfter(DateTime.now());
  }
}
