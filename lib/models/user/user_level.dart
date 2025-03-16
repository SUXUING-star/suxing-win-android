
// lib/models/user/user_level.dart
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
    // 确保我们有合适的Map<String, dynamic>类型
    Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

    // 安全处理字符串值
    String id = '';
    if (safeJson.containsKey('id')) {
      id = safeJson['id']?.toString() ?? '';
    }

    String userId = '';
    if (safeJson.containsKey('userId')) {
      userId = safeJson['userId']?.toString() ?? '';
    }

    // 安全处理整数值
    int level = 1;
    if (safeJson.containsKey('level')) {
      if (safeJson['level'] is int) {
        level = safeJson['level'];
      } else if (safeJson['level'] != null) {
        level = int.tryParse(safeJson['level'].toString()) ?? 1;
      }
    }

    int currentExp = 0;
    if (safeJson.containsKey('currentExp')) {
      if (safeJson['currentExp'] is int) {
        currentExp = safeJson['currentExp'];
      } else if (safeJson['currentExp'] != null) {
        currentExp = int.tryParse(safeJson['currentExp'].toString()) ?? 0;
      }
    } else if (safeJson.containsKey('experience')) {
      if (safeJson['experience'] is int) {
        currentExp = safeJson['experience'];
      } else if (safeJson['experience'] != null) {
        currentExp = int.tryParse(safeJson['experience'].toString()) ?? 0;
      }
    }

    int requiredExp = 1000;
    if (safeJson.containsKey('requiredExp')) {
      if (safeJson['requiredExp'] is int) {
        requiredExp = safeJson['requiredExp'];
      } else if (safeJson['requiredExp'] != null) {
        requiredExp = int.tryParse(safeJson['requiredExp'].toString()) ?? 1000;
      }
    } else if (safeJson.containsKey('nextLevelExp')) {
      if (safeJson['nextLevelExp'] is int) {
        requiredExp = safeJson['nextLevelExp'];
      } else if (safeJson['nextLevelExp'] != null) {
        requiredExp = int.tryParse(safeJson['nextLevelExp'].toString()) ?? 1000;
      }
    }

    int totalExp = 0;
    if (safeJson.containsKey('totalExp')) {
      if (safeJson['totalExp'] is int) {
        totalExp = safeJson['totalExp'];
      } else if (safeJson['totalExp'] != null) {
        totalExp = int.tryParse(safeJson['totalExp'].toString()) ?? 0;
      }
    } else if (safeJson.containsKey('experience')) {
      if (safeJson['experience'] is int) {
        totalExp = safeJson['experience'];
      } else if (safeJson['experience'] != null) {
        totalExp = int.tryParse(safeJson['experience'].toString()) ?? 0;
      }
    }

    // 安全处理日期
    DateTime? lastCheckIn;
    if (safeJson.containsKey('lastCheckIn') && safeJson['lastCheckIn'] != null) {
      if (safeJson['lastCheckIn'] is String) {
        try {
          lastCheckIn = DateTime.parse(safeJson['lastCheckIn']);
        } catch (e) {
          print('日期格式解析错误: ${safeJson['lastCheckIn']}');
        }
      } else if (safeJson['lastCheckIn'] is DateTime) {
        lastCheckIn = safeJson['lastCheckIn'];
      }
    }

    DateTime updatedAt = DateTime.now();
    if (safeJson.containsKey('updatedAt') && safeJson['updatedAt'] != null) {
      if (safeJson['updatedAt'] is String) {
        try {
          updatedAt = DateTime.parse(safeJson['updatedAt']);
        } catch (e) {
          print('日期格式解析错误: ${safeJson['updatedAt']}');
        }
      } else if (safeJson['updatedAt'] is DateTime) {
        updatedAt = safeJson['updatedAt'];
      }
    }

    DateTime createdAt = DateTime.now();
    if (safeJson.containsKey('createdAt') && safeJson['createdAt'] != null) {
      if (safeJson['createdAt'] is String) {
        try {
          createdAt = DateTime.parse(safeJson['createdAt']);
        } catch (e) {
          print('日期格式解析错误: ${safeJson['createdAt']}');
        }
      } else if (safeJson['createdAt'] is DateTime) {
        createdAt = safeJson['createdAt'];
      }
    }

    return UserLevel(
      id: id,
      userId: userId,
      level: level,
      currentExp: currentExp,
      requiredExp: requiredExp,
      totalExp: totalExp,
      lastCheckIn: lastCheckIn,
      updatedAt: updatedAt,
      createdAt: createdAt,
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

  // 判断是否达到最高等级
  bool get isMaxLevel => level >= 30;

  // 获取下一级所需经验
  int get expToNextLevel => requiredExp - currentExp;

  // 获取等级对应的称号
  String get levelTitle {
    if (level <= 5) return "茶会初学者";
    if (level <= 10) return "茶会学徒";
    if (level <= 15) return "茶会探索者";
    if (level <= 20) return "茶会专家";
    if (level <= 25) return "茶会大师";
    return "茶会传奇";
  }

  // 创建一个副本并更新属性
  UserLevel copyWith({
    String? id,
    String? userId,
    int? level,
    int? currentExp,
    int? requiredExp,
    int? totalExp,
    DateTime? lastCheckIn,
    bool clearLastCheckIn = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return UserLevel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      requiredExp: requiredExp ?? this.requiredExp,
      totalExp: totalExp ?? this.totalExp,
      lastCheckIn: clearLastCheckIn ? null : (lastCheckIn ?? this.lastCheckIn),
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

