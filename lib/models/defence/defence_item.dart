// lib/models/defence/defence_item.dart

import 'package:flutter/foundation.dart'; // 保留原始代码中的 import
import 'package:suxingchahui/models/utils/util_json.dart';

/// 表示防护列表（如黑名单、白名单）中的一个条目。
@immutable // 保留原始代码中的 @immutable
class DefenceItem {
  // --- JSON 字段键常量 ---
  static const String jsonKeyIp = 'ip';
  static const String jsonKeyCreatedAt = 'created_at';
  static const String jsonKeyExpiresAt = 'expires_at';

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
      ip: UtilJson.parseStringSafely(json[jsonKeyIp]),
      createdAt: UtilJson.parseDateTime(json[jsonKeyCreatedAt]),
      expiresAt: UtilJson.parseDateTime(json[jsonKeyExpiresAt]),
    );
  }

  /// 将当前的 [DefenceItem] 实例转换为 JSON。
  Map<String, dynamic> toJson() {
    return {
      jsonKeyIp: ip,
      jsonKeyCreatedAt: createdAt.toIso8601String(),
      jsonKeyExpiresAt: expiresAt.toIso8601String(),
    };
  }

  /// 检查条目是否已过期。
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  /// 创建一个空的 [DefenceItem] 实例。
  static DefenceItem empty() {
    return DefenceItem(
      ip: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// 复制当前 [DefenceItem] 实例并选择性地更新字段。
  DefenceItem copyWith({
    String? ip,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return DefenceItem(
      ip: ip ?? this.ip,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
