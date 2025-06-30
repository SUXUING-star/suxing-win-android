// lib/models/user/user/user_with_ban_status.dart

import 'package:flutter/foundation.dart';
import 'package:suxingchahui/models/user/ban/ban_info.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';

/// 包含用户及其封禁状态的组合模型。
@immutable
class UserWithBanStatus implements ToJsonExtension {
  static const String jsonKeyBanInfo = 'banInfo';
  static const String jsonKeyUser = 'user';

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
      user: User.fromJson(json[jsonKeyUser]),
      // 如果 json 里有 banInfo，就用它来创建 BanInfo 对象
      // 使用常量
      banInfo: json[jsonKeyBanInfo] != null
          ? BanInfo.fromJson(Map<String, dynamic>.from(json[jsonKeyBanInfo]))
          : null,
    );
  }

  /// 转换为 JSON Map。
  @override
  Map<String, dynamic> toJson() {
    // 先把 user 转成 map
    final Map<String, dynamic> data = {
      jsonKeyUser: user.toSafeJson(),
    };

    // 如果有 banInfo，再把它加进去
    if (banInfo != null) {
      // 使用常量
      data[jsonKeyBanInfo] = banInfo!.toJson();
    }
    return data;
  }
}
