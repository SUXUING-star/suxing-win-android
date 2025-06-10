// lib/models/user/ban_info.dart

import 'package:flutter/foundation.dart';

/// 用户封禁信息模型。
@immutable
class BanInfo {
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
    return BanInfo(
      reason: json['reason'] as String? ?? '无原因',
      banTime: DateTime.tryParse(json['banTime'] as String? ?? '') ?? DateTime.now(),
      bannedBy: json['bannedBy'] as String? ?? '',
      isPermanent: json['isPermanent'] as bool? ?? false,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
    );
  }

  /// 转换为 JSON Map。
  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'banTime': banTime.toIso8601String(),
      'bannedBy': bannedBy,
      'isPermanent': isPermanent,
      'endTime': endTime?.toIso8601String(),
    };
  }
}