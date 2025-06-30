// lib/models/user/check_in/user_checkIn_today_list.dart

// 包含用户 ID 列表

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/utils/util_json.dart'; // 引入 UtilJson

@immutable
class TodayCheckInList {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyDate = 'date';
  static const String jsonKeyUsers = 'users';
  static const String jsonKeyListFallback = 'list'; // 'users' 字段的备用名
  static const String jsonKeyCount = 'count';

  final String date;
  final List<String> users;
  final int count;

  const TodayCheckInList({
    required this.date,
    required this.users,
    required this.count,
  });

  factory TodayCheckInList.fromJson(Map<String, dynamic> json) {
    // 使用 UtilJson.parseListString 来解析用户列表，同时处理备用字段 'list'
    final userIdList = UtilJson.parseListString(
        json[jsonKeyUsers] ?? json[jsonKeyListFallback]);

    // 业务逻辑: 'count' 优先使用后端返回的值，如果不存在，则使用列表的实际长度
    // 使用 containsKey 判断键是否存在，避免 UtilJson.parseIntSafely 对 null 返回 0 导致逻辑错误
    final int count = json.containsKey(jsonKeyCount)
        ? UtilJson.parseIntSafely(json[jsonKeyCount])
        : userIdList.length;

    return TodayCheckInList(
      // 这里的默认值逻辑比较特殊，保留原样但使用常量
      date: json[jsonKeyDate]?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
      users: userIdList,
      count: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyDate: date, // 使用常量
      jsonKeyUsers: users, // 使用常量
      jsonKeyCount: count, // 使用常量
    };
  }

  factory TodayCheckInList.empty() {
    return TodayCheckInList(
      date: DateTime.now().toIso8601String().substring(0, 10),
      users: [],
      count: 0,
    );
  }
}
