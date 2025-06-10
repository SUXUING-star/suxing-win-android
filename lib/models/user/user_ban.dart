// lib/models/user/user_ban.dart

import 'package:flutter/cupertino.dart';

@immutable
class UserBan {
  final String id;
  final String userId;
  final String reason;
  final DateTime banTime;
  final DateTime? endTime;  // null表示永久封禁
  final String bannedBy;   // 执行封禁的管理员ID

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
      id: json['id'] ?? json['_id'],
      userId: json['userId'],
      reason: json['reason'],
      banTime: json['banTime'] is String
          ? DateTime.parse(json['banTime'])
          : json['banTime'],
      endTime: json['endTime'] != null
          ? (json['endTime'] is String
          ? DateTime.parse(json['endTime'])
          : json['endTime'])
          : null,
      bannedBy: json['bannedBy'],
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