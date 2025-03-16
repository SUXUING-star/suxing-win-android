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
    bool _safeBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
      return defaultValue;
    }

    int _safeInt(dynamic value, int defaultValue) {
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

    double _safeDouble(dynamic value, double defaultValue) {
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
    final hasCheckedToday = _safeBool(json['checkedInToday'], false);
    final canCheckInToday = json.containsKey('canCheckInToday')
        ? _safeBool(json['canCheckInToday'], true)
        : !hasCheckedToday;  // 如果没有提供，则默认为未签到时可签到

    return CheckInStats(
      totalCheckIns: _safeInt(json['totalCheckIn'], 0),
      continuousDays: _safeInt(json['consecutiveCheckIn'], 0),
      hasCheckedToday: hasCheckedToday,
      canCheckInToday: canCheckInToday,
      level: _safeInt(json['level'], 1),
      currentExp: _safeInt(json['currentExp'] ?? json['experience'], 0),
      requiredExp: _safeInt(json['requiredExp'] ?? json['expToNextLevel'], 500),
      totalExp: _safeInt(json['totalExp'] ?? json['experience'], 0),
      nextRewardExp: _safeInt(json['nextRewardExp'] ?? json['nextCheckInExp'], 10),
      levelProgress: _safeDouble(json['levelProgress'] ?? json['progress'], 0.0),
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