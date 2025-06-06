// lib/models/user/user_checkin.dart
import 'package:intl/intl.dart';


// --- CheckInStats 模型 ---
class CheckInStats {
  final int totalCheckIns; // 累计签到天数
  final int continuousDays; // 当前连续签到天数
  final bool hasCheckedToday; // 今天是否已签到
  final bool canCheckInToday; // 今天是否还能签到
  final int nextRewardExp; // 下次签到预计可获得的经验

  CheckInStats({
    required this.totalCheckIns,
    required this.continuousDays,
    required this.hasCheckedToday,
    required this.canCheckInToday,
    required this.nextRewardExp,
  });

  factory CheckInStats.fromJson(Map<String, dynamic> json) {
    // Helper functions (can be defined outside or copied here)
    bool safeBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
      return defaultValue;
    }

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

    final hasCheckedTodayFromJson = safeBool(json['checkedInToday'], false);
    final canCheckInTodayFromJson = json.containsKey('canCheckInToday')
        ? safeBool(json['canCheckInToday'], true)
        : !hasCheckedTodayFromJson;

    return CheckInStats(
      totalCheckIns: safeInt(json['totalCheckIns'] ?? json['totalCheckIn'], 0),
      continuousDays:
          safeInt(json['continuousDays'] ?? json['consecutiveCheckIn'], 0),
      hasCheckedToday: hasCheckedTodayFromJson,
      canCheckInToday: canCheckInTodayFromJson,
      nextRewardExp:
          safeInt(json['nextRewardExp'] ?? json['nextCheckInExp'], 10),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCheckIn': totalCheckIns,
      'consecutiveCheckIn': continuousDays,
      'checkedInToday': hasCheckedToday,
      'canCheckInToday': canCheckInToday,
      'nextCheckInExp': nextRewardExp,
    };
  }

  factory CheckInStats.defaultStats() {
    return CheckInStats(
      totalCheckIns: 0,
      continuousDays: 0,
      hasCheckedToday: false,
      canCheckInToday: true,
      nextRewardExp: 10,
    );
  }
}

// --- CheckInUser 模型 ---
// 只包含签到列表项必需的信息：用户ID和签到相关数据
class CheckInUser {
  final String id; // 签到记录 ID
  final String userId; // 用户 ID (核心)
  final DateTime checkInTime; // 签到时间
  final int experienceGained; // 本次签到获得的经验
  final int consecutiveCheckIn; // 签到时的连续天数
  final int totalCheckIn; // 签到时的总天数

  CheckInUser({
    required this.id,
    required this.userId,
    required this.checkInTime,
    required this.experienceGained,
    required this.consecutiveCheckIn,
    required this.totalCheckIn,
  });

  factory CheckInUser.fromJson(Map<String, dynamic> json) {
    // Helper functions (can be defined outside or copied here)
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

    DateTime safeDateTime(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          // print('Error parsing DateTime from String: $value');
          return defaultValue;
        }
      }
      if (value is DateTime) return value;
      if (value is Map && value['\$date'] is String) {
        // Handle MongoDB BSON Date format
        try {
          return DateTime.parse(value['\$date']);
        } catch (e) {
          // print('Error parsing DateTime from BSON: $e, value: $value');
          return defaultValue;
        }
      }
      // print('Unexpected DateTime format: ${value.runtimeType}');
      return defaultValue;
    }

    return CheckInUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      checkInTime: safeDateTime(json['checkInTime'], DateTime.now()),
      experienceGained: safeInt(json['experienceGained'], 0),
      consecutiveCheckIn: safeInt(json['consecutiveCheckIn'], 1),
      totalCheckIn: safeInt(json['totalCheckIn'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInTime': checkInTime.toIso8601String(),
      'experienceGained': experienceGained,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
    };
  }

  // 格式化签到时间 (保持不变)
  String get formattedTime {
    return DateFormat('HH:mm:ss').format(checkInTime);
  }
}

// --- CheckInUserList 模型 (修改后) ---
// 包含用户 ID 列表
class CheckInUserList {
  final String date;
  final List<String> users; // <-- 修改这里：从 List<CheckInUser> 改为 List<String>
  final int count;

  CheckInUserList({
    required this.date,
    required this.users,    // <-- 修改这里
    required this.count,
  });

  factory CheckInUserList.fromJson(Map<String, dynamic> json) {
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
    if (json['users'] != null && json['users'] is List) { // <-- 修改这里：检查 'users' 字段
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


    return CheckInUserList(
      date: json['date']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
      users: userIdList, // <-- 修改这里：使用解析出的 userIdList
      // count 优先使用后端返回的，其次使用列表长度
      count: safeInt(json['count'], userIdList.length),
    );
  }

  factory CheckInUserList.empty() {
    return CheckInUserList(
      date: DateTime.now().toIso8601String().substring(0, 10),
      users: [], // <-- 修改这里：空列表
      count: 0,
    );
  }
}
