// lib/models/user/user_checkin.dart
import 'package:intl/intl.dart';

class UserCheckIn {
  final String id;
  final String userId;
  final DateTime checkInDate;
  final int expEarned;
  final int continuousDays;

  UserCheckIn({
    required this.id,
    required this.userId,
    required this.checkInDate,
    required this.expEarned,
    required this.continuousDays,
  });

  factory UserCheckIn.fromJson(Map<String, dynamic> json) {
    return UserCheckIn(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      checkInDate: json['checkInDate'] is String
          ? DateTime.parse(json['checkInDate'])
          : (json['checkInDate'] ?? DateTime.now()),
      expEarned: json['expEarned'] ?? json['experienceGained'] ?? 10,
      continuousDays: json['continuousDays'] ?? json['consecutiveCheckIn'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInDate': checkInDate.toIso8601String(),
      'expEarned': expEarned,
      'continuousDays': continuousDays,
    };
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(checkInDate);
  }

  // 获取连续签到天数对应的奖励
  static int getCheckInExpReward(int continuousDays) {
    // 连续签到超过7天的，按7天计算
    int days = continuousDays;
    if (days > 7) days = 7;

    // 基础经验值 + 连续签到奖励
    int baseExp = 10;
    int consecutiveBonus = days * 5;
    return baseExp + consecutiveBonus;
  }
}

class CheckInStats {
  final int totalCheckIns;
  final int continuousDays;
  final bool hasCheckedToday;
  final bool canCheckInToday;
  final int level;
  final int currentExp;
  final int requiredExp;
  final int totalExp;
  final int nextRewardExp;
  final double levelProgress;

  CheckInStats({
    required this.totalCheckIns,
    required this.continuousDays,
    required this.hasCheckedToday,
    required this.canCheckInToday,
    required this.level,
    required this.currentExp,
    required this.requiredExp,
    required this.totalExp,
    required this.nextRewardExp,
    required this.levelProgress,
  });

  factory CheckInStats.fromJson(Map<String, dynamic> json) {
    // 确保安全地处理 null 值和类型转换
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

    double safeDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // 处理布尔值
    final hasCheckedToday = safeBool(json['checkedInToday'], false);
    final canCheckInToday = json.containsKey('canCheckInToday')
        ? safeBool(json['canCheckInToday'], true)
        : !hasCheckedToday;  // 如果没有提供，则默认为未签到时可签到

    return CheckInStats(
      totalCheckIns: safeInt(json['totalCheckIn'], 0),
      continuousDays: safeInt(json['consecutiveCheckIn'], 0),
      hasCheckedToday: hasCheckedToday,
      canCheckInToday: canCheckInToday,
      level: safeInt(json['level'], 1),
      currentExp: safeInt(json['currentExp'] ?? json['experience'], 0),
      requiredExp: safeInt(json['requiredExp'] ?? json['expToNextLevel'], 500),
      totalExp: safeInt(json['totalExp'] ?? json['experience'], 0),
      nextRewardExp: safeInt(json['nextRewardExp'] ?? json['nextCheckInExp'], 10),
      levelProgress: safeDouble(json['levelProgress'] ?? json['progress'], 0.0),
    );
  }

  // 其他方法保持不变...

  Map<String, dynamic> toJson() {
    return {
      'totalCheckIn': totalCheckIns,
      'consecutiveCheckIn': continuousDays,
      'checkedInToday': hasCheckedToday,
      'canCheckInToday': canCheckInToday,
      'level': level,
      'currentExp': currentExp,
      'requiredExp': requiredExp,
      'totalExp': totalExp,
      'nextRewardExp': nextRewardExp,
      'levelProgress': levelProgress,
    };
  }

  // 创建默认统计信息
  factory CheckInStats.defaultStats() {
    return CheckInStats(
      totalCheckIns: 0,
      continuousDays: 0,
      hasCheckedToday: false,
      canCheckInToday: true,
      level: 1,
      currentExp: 0,
      requiredExp: 500,
      totalExp: 0,
      nextRewardExp: 10,
      levelProgress: 0.0,
    );
  }
}



class CheckInUser {
  final String id;
  final String userId;
  final String username;
  final String nickname;
  final String avatar;
  final int level;
  final DateTime checkInTime;
  final int experienceGained;
  final int consecutiveCheckIn;
  final int totalCheckIn;

  CheckInUser({
    required this.id,
    required this.userId,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.level,
    required this.checkInTime,
    required this.experienceGained,
    required this.consecutiveCheckIn,
    required this.totalCheckIn,
  });

  factory CheckInUser.fromJson(Map<String, dynamic> json) {
    return CheckInUser(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? json['username'] ?? '用户',
      avatar: json['avatar'] ?? '',
      level: json['level'] is int ? json['level'] : 1,
      checkInTime: json['checkInTime'] is String
          ? DateTime.parse(json['checkInTime'])
          : DateTime.now(),
      experienceGained: json['experienceGained'] is int
          ? json['experienceGained']
          : 0,
      consecutiveCheckIn: json['consecutiveCheckIn'] is int
          ? json['consecutiveCheckIn']
          : 1,
      totalCheckIn: json['totalCheckIn'] is int
          ? json['totalCheckIn']
          : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'level': level,
      'checkInTime': checkInTime.toIso8601String(),
      'experienceGained': experienceGained,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
    };
  }

  // 格式化签到时间为"HH:MM:SS"
  String get formattedTime {
    return '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}:${checkInTime.second.toString().padLeft(2, '0')}';
  }

  // 显示名称（优先使用昵称，没有则使用用户名）
  String get displayName {
    return nickname.isNotEmpty ? nickname : (username.isNotEmpty ? username : '用户');
  }
}

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
    List<CheckInUser> userList = [];

    if (json['list'] != null && json['list'] is List) {
      userList = (json['list'] as List)
          .map((item) => CheckInUser.fromJson(item))
          .toList();
    }

    return CheckInUserList(
      date: json['date'] ?? DateTime.now().toString().substring(0, 10),
      users: userList,
      count: json['count'] ?? userList.length,
    );
  }

  factory CheckInUserList.empty() {
    return CheckInUserList(
      date: DateTime.now().toString().substring(0, 10),
      users: [],
      count: 0,
    );
  }
}