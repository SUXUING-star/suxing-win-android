// lib/models/user/ban/ban_info.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/utils/util_json.dart'; // 引入 UtilJson

// 用户封禁信息模型。
@immutable
class BanInfo {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyReason = 'reason';
  static const String jsonKeyBanTime = 'banTime';
  static const String jsonKeyBannedBy = 'bannedBy';
  static const String jsonKeyIsPermanent = 'isPermanent';
  static const String jsonKeyEndTime = 'endTime';

  final String reason;
  final DateTime banTime;
  final String bannedBy;
  final bool isPermanent;
  final DateTime? endTime;

  const BanInfo({
    required this.reason,
    required this.banTime,
    required this.bannedBy,
    required this.isPermanent,
    this.endTime,
  });

  /// 从 JSON Map 创建实例。
  factory BanInfo.fromJson(Map<String, dynamic> json) {
    // 使用 UtilJson 进行安全解析
    final String parsedReason = UtilJson.parseStringSafely(json[jsonKeyReason]);

    return BanInfo(
      // 业务逻辑: 如果解析出的 reason 为空，则使用 '无原因' 作为默认值
      reason: parsedReason.isEmpty ? '无原因' : parsedReason,
      // 业务逻辑: 如果 banTime 解析失败，则使用当前时间作为默认值
      banTime: UtilJson.parseNullableDateTime(json[jsonKeyBanTime]) ??
          DateTime.now(),
      bannedBy: UtilJson.parseStringSafely(json[jsonKeyBannedBy]),
      isPermanent: UtilJson.parseBoolSafely(json[jsonKeyIsPermanent]),
      endTime: UtilJson.parseNullableDateTime(json[jsonKeyEndTime]),
    );
  }

  /// 转换为 JSON Map。
  Map<String, dynamic> toJson() {
    return {
      jsonKeyReason: reason, // 使用常量
      jsonKeyBanTime: banTime.toIso8601String(), // 使用常量
      jsonKeyBannedBy: bannedBy, // 使用常量
      jsonKeyIsPermanent: isPermanent, // 使用常量
      jsonKeyEndTime: endTime?.toIso8601String(), // 使用常量
    };
  }
}
