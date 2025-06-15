// lib/models/user/user_checkIn_today_list.dart

// 包含用户 ID 列表

import 'package:meta/meta.dart';

@immutable
class TodayCheckInList {
  final String date;
  final List<String> users;
  final int count;

  TodayCheckInList({
    required this.date,
    required this.users, // <-- 修改这里
    required this.count,
  });

  factory TodayCheckInList.fromJson(Map<String, dynamic> json) {
    // Helper function (can be defined outside or copied here)
    int safeInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (_) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    List<String> userIdList = []; // <-- 修改这里：初始化为空的 String 列表
    if (json['users'] != null && json['users'] is List) {
      // <-- 修改这里：检查 'users' 字段
      userIdList = (json['users'] as List)
          .map((item) => item?.toString() ?? '') // 将每个元素转为 String
          .where((id) => id.isNotEmpty) // 过滤掉空的 ID
          .toList();
    } else if (json['list'] != null && json['list'] is List) {
      // 兼容旧的 'list' 字段，如果后端可能返回两种格式
      userIdList = (json['list'] as List)
          .map((item) => item?.toString() ?? '') // 将每个元素转为 String
          .where((id) => id.isNotEmpty) // 过滤掉空的 ID
          .toList();
      // print("Warning: Received 'list' field instead of 'users' for check-in list. Assuming it contains user IDs.");
    }

    return TodayCheckInList(
      date: json['date']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
      users: userIdList, // <-- 修改这里：使用解析出的 userIdList
      // count 优先使用后端返回的，其次使用列表长度
      count: safeInt(json['count'], userIdList.length),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'users': users,
      'count': count,
    };
  }

  factory TodayCheckInList.empty() {
    return TodayCheckInList(
      date: DateTime.now().toIso8601String().substring(0, 10),
      users: [], // <-- 修改这里：空列表
      count: 0,
    );
  }
}
