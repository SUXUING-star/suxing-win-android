// lib/models/user/user_ban.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class UserBan {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id';
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyReason = 'reason';
  static const String jsonKeyBanTime = 'banTime';
  static const String jsonKeyEndTime = 'endTime';
  static const String jsonKeyBannedBy = 'bannedBy';

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
      id: UtilJson.parseId(json[jsonKeyId] ?? json[jsonKeyMongoId]), // 使用常量
      userId: UtilJson.parseId(json[jsonKeyUserId]), // 使用常量
      reason: UtilJson.parseStringSafely(json[jsonKeyReason]), // 使用常量
      banTime: UtilJson.parseDateTime(json[jsonKeyBanTime]), // 使用常量
      // 业务逻辑: endTime 为 null 表示永久封禁
      endTime: UtilJson.parseNullableDateTime(json[jsonKeyEndTime]), // 使用常量
      bannedBy: UtilJson.parseId(json[jsonKeyBannedBy]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id 通常由后端生成，在提交更新/创建时不需要
      jsonKeyUserId: userId, // 使用常量
      jsonKeyReason: reason, // 使用常量
      jsonKeyBanTime: banTime.toIso8601String(), // 使用常量
      jsonKeyEndTime: endTime?.toIso8601String(), // 使用常量
      jsonKeyBannedBy: bannedBy, // 使用常量
    };
  }

  bool get isPermanent => endTime == null;

  bool get isActive {
    if (isPermanent) return true;
    return endTime!.isAfter(DateTime.now());
  }
}
