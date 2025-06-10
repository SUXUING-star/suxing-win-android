// lib/models/user/user_with_ban_status.dart

import 'package:flutter/foundation.dart';
import 'package:suxingchahui/models/user/ban_info.dart';
import 'package:suxingchahui/models/user/user.dart';

/// 包含用户及其封禁状态的组合模型。
@immutable
class UserWithBanStatus {
  final User user;
  final BanInfo? banInfo;

  const UserWithBanStatus({
    required this.user,
    this.banInfo,
  });

  /// 从 JSON Map 创建实例。
  ///
  /// 后端返回的是一个扁平化的结构，user 字段和 banInfo 字段都在同一层。
  factory UserWithBanStatus.fromJson(Map<String, dynamic> json) {
    return UserWithBanStatus(
      // 直接用整个 json 去创建 User 对象
      user: User.fromJson(json),
      // 如果 json 里有 banInfo，就用它来创建 BanInfo 对象
      banInfo: json['banInfo'] != null
          ? BanInfo.fromJson(Map<String, dynamic>.from(json['banInfo']))
          : null,
    );
  }

  /// 转换为 JSON Map。
  Map<String, dynamic> toJson() {
    // 先把 user 转成 map
    final data = user.toJson();
    // 如果有 banInfo，再把它加进去
    if (banInfo != null) {
      data['banInfo'] = banInfo!.toJson();
    }
    return data;
  }
}