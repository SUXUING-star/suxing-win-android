// lib/models/user/user_checkin.dart
import 'package:intl/intl.dart';

// --- UserCheckIn 模型 ---
// 代表单次签到记录，包含本次获得的经验
class UserCheckIn {
  final String id;
  final String userId;
  final DateTime checkInDate;
  final int expEarned; // 本次签到获得的经验
  final int continuousDays; // 签到时的连续天数

  UserCheckIn({
    required this.id,
    required this.userId,
    required this.checkInDate,
    required this.expEarned,
    required this.continuousDays,
  });

  factory UserCheckIn.fromJson(Map<String, dynamic> json) {
    // Helper function for safe integer parsing
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

    // Helper function for safe DateTime parsing
    DateTime safeDateTime(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          print('Error parsing DateTime from String: $value');
          return defaultValue;
        }
      }
      if (value is DateTime) return value;
      if (value is Map && value['\$date'] is String) {
        // Handle MongoDB BSON Date format
        try {
          return DateTime.parse(value['\$date']);
        } catch (e) {
          print('Error parsing DateTime from BSON: $e, value: $value');
          return defaultValue;
        }
      }
      print('Unexpected DateTime format: ${value.runtimeType}');
      return defaultValue;
    }

    return UserCheckIn(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '', // 兼容 _id
      userId: json['userId']?.toString() ?? '',
      checkInDate: safeDateTime(json['checkInDate'], DateTime.now()),
      // 优先使用 experienceGained，其次 expEarned，最后默认 10
      expEarned: safeInt(json['experienceGained'] ?? json['expEarned'], 10),
      // 优先使用 consecutiveCheckIn，其次 continuousDays，最后默认 1
      continuousDays:
          safeInt(json['consecutiveCheckIn'] ?? json['continuousDays'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInDate': checkInDate.toIso8601String(),
      'expEarned': expEarned,
      'continuousDays': continuousDays, // 或者用 'consecutiveCheckIn'，与后端保持一致
    };
  }

  // 格式化日期 (保持不变)
  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(checkInDate);
  }

  // 静态方法计算预期奖励 (保持不变)
  static int getCheckInExpReward(int continuousDays) {
    int days = continuousDays > 0 ? continuousDays : 1;
    if (days > 7) days = 7;
    int baseExp = 10;
    // 连续奖励通常从第二天开始累加，或者按你的规则来
    int consecutiveBonus = (days > 1) ? (days * 5) : 0; // 示例规则
    // 或者 int consecutiveBonus = days * 5; // 如果第一天也有奖励
    return baseExp + consecutiveBonus;
  }
}

// --- CheckInStats 模型 ---
// 只包含签到状态相关信息，移除全局等级/经验
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
          print('Error parsing DateTime from String: $value');
          return defaultValue;
        }
      }
      if (value is DateTime) return value;
      if (value is Map && value['\$date'] is String) {
        // Handle MongoDB BSON Date format
        try {
          return DateTime.parse(value['\$date']);
        } catch (e) {
          print('Error parsing DateTime from BSON: $e, value: $value');
          return defaultValue;
        }
      }
      print('Unexpected DateTime format: ${value.runtimeType}');
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

// --- CheckInUserList 模型 ---
// 包含精简后的 CheckInUser 列表
class CheckInUserList {
  final String date;
  final List<CheckInUser> users;
  final int count;

  CheckInUserList({
    required this.date,
    required this.users,
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

    List<CheckInUser> userList = [];
    if (json['list'] != null && json['list'] is List) {
      userList = (json['list'] as List)
          .map((item) {
            if (item is Map) {
              try {
                // 使用修改后的 CheckInUser.fromJson
                return CheckInUser.fromJson(Map<String, dynamic>.from(item));
              } catch (e) {
                print("Error parsing CheckInUser item: $e, item: $item");
                return null;
              }
            }
            return null;
          })
          .where((user) => user != null)
          .cast<CheckInUser>()
          .toList();
    }

    return CheckInUserList(
      date: json['date']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
      users: userList,
      count: safeInt(json['count'], userList.length),
    );
  }

  factory CheckInUserList.empty() {
    return CheckInUserList(
      date: DateTime.now().toIso8601String().substring(0, 10),
      users: [],
      count: 0,
    );
  }
}
