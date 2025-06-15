// lib/models/defence/defence_item.dart

import 'package:flutter/foundation.dart';
import 'package:suxingchahui/models/util_json.dart';

/// 表示防护列表（如黑名单、白名单）中的一个条目。
@immutable
class DefenceItem {
  /// IP 地址。
  final String ip;

  /// 条目的创建时间。
  final DateTime createdAt;

  /// 条目的过期时间。
  final DateTime expiresAt;

  /// 创建一个 [DefenceItem] 实例。
  const DefenceItem({
    required this.ip,
    required this.createdAt,
    required this.expiresAt,
  });

  /// 从 JSON 创建一个 [DefenceItem] 实例。
  factory DefenceItem.fromJson(Map<String, dynamic> json) {
    return DefenceItem(
      ip: UtilJson.parseStringSafely(json['ip']),
      createdAt: UtilJson.parseDateTime(json['created_at']),
      expiresAt: UtilJson.parseDateTime(json['expires_at']),
    );
  }

  /// 将当前的 [DefenceItem] 实例转换为 JSON (Map<String, dynamic>)。
  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// 检查条目是否已过期。
  bool get isExpired => expiresAt.isBefore(DateTime.now());
}
