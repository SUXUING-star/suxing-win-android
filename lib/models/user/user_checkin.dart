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
      id: json['id'],
      userId: json['userId'],
      checkInDate: json['checkInDate'] is String
          ? DateTime.parse(json['checkInDate'])
          : json['checkInDate'],
      expEarned: json['expEarned'],
      continuousDays: json['continuousDays'],
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
}

class UserLevel {
  final String id;
  final String userId;
  final int level;
  final int currentExp;
  final int requiredExp;
  final int totalExp;
  final DateTime? lastCheckIn;
  final DateTime updatedAt;
  final DateTime createdAt;

  UserLevel({
    required this.id,
    required this.userId,
    required this.level,
    required this.currentExp,
    required this.requiredExp,
    required this.totalExp,
    this.lastCheckIn,
    required this.updatedAt,
    required this.createdAt,
  });

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      id: json['id'],
      userId: json['userId'],
      level: json['level'],
      currentExp: json['currentExp'],
      requiredExp: json['requiredExp'],
      totalExp: json['totalExp'],
      lastCheckIn: json['lastCheckIn'] != null
          ? (json['lastCheckIn'] is String
          ? DateTime.parse(json['lastCheckIn'])
          : json['lastCheckIn'])
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : json['updatedAt'],
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'level': level,
      'currentExp': currentExp,
      'requiredExp': requiredExp,
      'totalExp': totalExp,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 获取经验值百分比，用于进度条
  double get expPercentage {
    if (requiredExp <= 0) return 1.0;
    return currentExp / requiredExp;
  }
}

class CheckInStats {
  final int totalCheckIns;
  final int continuousDays;
  final bool hasCheckedToday;
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
    required this.level,
    required this.currentExp,
    required this.requiredExp,
    required this.totalExp,
    required this.nextRewardExp,
    required this.levelProgress,
  });

  factory CheckInStats.fromJson(Map<String, dynamic> json) {
    return CheckInStats(
      totalCheckIns: json['totalCheckIns'] ?? 0,
      continuousDays: json['continuousDays'] ?? 0,
      hasCheckedToday: json['hasCheckedToday'] ?? false,
      level: json['level'] ?? 1,
      currentExp: json['currentExp'] ?? 0,
      requiredExp: json['requiredExp'] ?? 500,
      totalExp: json['totalExp'] ?? 0,
      nextRewardExp: json['nextRewardExp'] ?? 10,
      levelProgress: (json['levelProgress'] ?? 0.0) * 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCheckIns': totalCheckIns,
      'continuousDays': continuousDays,
      'hasCheckedToday': hasCheckedToday,
      'level': level,
      'currentExp': currentExp,
      'requiredExp': requiredExp,
      'totalExp': totalExp,
      'nextRewardExp': nextRewardExp,
      'levelProgress': levelProgress,
    };
  }
}