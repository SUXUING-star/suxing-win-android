// lib/models/user/user.dart

class User {
  final String id;
  final String username;
  final String email;
  final String? avatar;
  final DateTime createTime;
  final DateTime? updateTime;
  final String? signature;
  final bool isAdmin;
  final bool isSuperAdmin;
  final int experience; // 总经验值
  final int level; // 等级
  final int? consecutiveCheckIn;
  final int? totalCheckIn;
  final DateTime? lastCheckInDate;
  final List<String> following; // 关注列表 (ID 字符串)
  final List<String> followers; // 粉丝列表 (ID 字符串)
  final int currentLevelExp; // 当前等级起始经验
  final int nextLevelExp; // 下一级所需总经验
  final int expToNextLevel; // 距离下一级还差多少经验
  final double levelProgress; // 当前等级进度百分比 (0-100)
  final bool isMaxLevel; // 是否满级

  User({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    required this.createTime,
    this.signature,
    this.updateTime,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.experience = 0,
    this.level = 1,
    this.consecutiveCheckIn,
    this.totalCheckIn,
    this.lastCheckInDate,
    this.following = const [],
    this.followers = const [],
    // 新增字段的默认值
    this.currentLevelExp = 0,
    this.nextLevelExp = 1000,
    this.expToNextLevel = 1000,
    this.levelProgress = 0.0,
    this.isMaxLevel = false,
  });

  // --- 完整的 fromJson 工厂方法 ---
  factory User.fromJson(Map<String, dynamic> json) {
    // 安全地解析 ID
    String idFromJson = '';
    if (json['id'] is String) {
      idFromJson = json['id'];
    } else if (json['_id'] is String) {
      // 兼容 _id
      idFromJson = json['_id'];
    }

    // 安全地解析 email
    String emailFromJson = json['email'] ?? '';

    // 安全地解析 createTime
    DateTime createTimeFromJson = DateTime.now(); // 默认当前时间
    if (json['createTime'] is String) {
      try {
        createTimeFromJson = DateTime.parse(json['createTime']);
      } catch (_) {} // 解析失败则使用默认值
    } else if (json['createTime'] is DateTime) {
      // 如果直接是 DateTime 类型
      createTimeFromJson = json['createTime'];
    } else if (json['createTime'] is Map &&
        json['createTime']['\$date'] is String) {
      // 处理 MongoDB BSON Date 格式
      try {
        createTimeFromJson = DateTime.parse(json['createTime']['\$date']);
      } catch (_) {}
    }

    // 解析关注/粉丝列表
    List<String> followingList = [];
    if (json['following'] is List) {
      // 确保列表内元素是 String
      followingList = List<String>.from(
          (json['following'] as List).map((item) => item.toString()));
    }
    List<String> followersList = [];
    if (json['followers'] is List) {
      followersList = List<String>.from(
          (json['followers'] as List).map((item) => item.toString()));
    }

    // 安全地解析 experience
    int experienceFromJson = 0;
    if (json['experience'] is int) {
      experienceFromJson = json['experience'];
    } else if (json['experience'] != null) {
      experienceFromJson = int.tryParse(json['experience'].toString()) ?? 0;
    }

    // 安全地解析 level
    int levelFromJson = 0;
    if (json['level'] is int) {
      levelFromJson = json['level'];
    } else if (json['level'] != null) {
      levelFromJson = int.tryParse(json['level'].toString()) ?? 0;
    }

    // 安全地解析 currentLevelExp
    int currentLevelExpFromJson = 0;
    if (json['currentLevelExp'] is int) {
      currentLevelExpFromJson = json['currentLevelExp'];
    } else if (json['currentLevelExp'] != null) {
      currentLevelExpFromJson =
          int.tryParse(json['currentLevelExp'].toString()) ?? 0;
    }

    // 安全地解析 nextLevelExp
    int nextLevelExpFromJson =
        levelFromJson > 0 ? currentLevelExpFromJson + 1 : 1000; // 提供一个更合理的默认值
    if (json['nextLevelExp'] is int) {
      nextLevelExpFromJson = json['nextLevelExp'];
    } else if (json['nextLevelExp'] != null) {
      nextLevelExpFromJson =
          int.tryParse(json['nextLevelExp'].toString()) ?? nextLevelExpFromJson;
    }

    // 安全地解析 expToNextLevel
    int expToNextLevelFromJson =
        nextLevelExpFromJson - experienceFromJson; // 默认计算
    if (json['expToNextLevel'] is int) {
      expToNextLevelFromJson = json['expToNextLevel'];
    } else if (json['expToNextLevel'] != null) {
      expToNextLevelFromJson =
          int.tryParse(json['expToNextLevel'].toString()) ??
              expToNextLevelFromJson;
    }
    // 确保非负
    if (expToNextLevelFromJson < 0) expToNextLevelFromJson = 0;

    // 安全地解析 levelProgress (处理 int, double, String)
    double levelProgressFromJson = 0.0;
    if (json['levelProgress'] is double) {
      levelProgressFromJson = json['levelProgress'];
    } else if (json['levelProgress'] is int) {
      levelProgressFromJson = (json['levelProgress'] as int).toDouble();
    } else if (json['levelProgress'] is String) {
      levelProgressFromJson = double.tryParse(json['levelProgress']) ?? 0.0;
    }
    levelProgressFromJson =
        levelProgressFromJson.clamp(0.0, 100.0); // 确保在 0-100 范围

    // 安全地解析 isMaxLevel
    bool isMaxLevelFromJson = json['isMaxLevel'] ?? false;

    // 安全地解析签到日期
    DateTime? lastCheckInDateFromJson;
    if (json['lastCheckInDate'] is String) {
      try {
        lastCheckInDateFromJson = DateTime.parse(json['lastCheckInDate']);
      } catch (_) {}
    } else if (json['lastCheckInDate'] is DateTime) {
      lastCheckInDateFromJson = json['lastCheckInDate'];
    } else if (json['lastCheckInDate'] is Map &&
        json['lastCheckInDate']['\$date'] is String) {
      try {
        lastCheckInDateFromJson =
            DateTime.parse(json['lastCheckInDate']['\$date']);
      } catch (_) {}
    }

    DateTime? parseDateTime(dynamic dateValue) {
      if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      } else if (dateValue is Map && dateValue['\$date'] is String) {
        // MongoDB BSON Date
        return DateTime.tryParse(dateValue['\$date']);
      }
      return null;
    }

    return User(
      id: idFromJson,
      username: json['username'] ?? '',
      email: emailFromJson,
      avatar: json['avatar'],
      createTime: createTimeFromJson,
      updateTime: parseDateTime(json['updateTime']),
      signature: json['signature'] as String?,
      isAdmin: json['isAdmin'] ?? false,
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      experience: experienceFromJson,
      level: levelFromJson,
      consecutiveCheckIn: json['consecutiveCheckIn'] is int
          ? json['consecutiveCheckIn']
          : (json['consecutiveCheckIn'] != null
              ? int.tryParse(json['consecutiveCheckIn'].toString())
              : null),
      totalCheckIn: json['totalCheckIn'] is int
          ? json['totalCheckIn']
          : (json['totalCheckIn'] != null
              ? int.tryParse(json['totalCheckIn'].toString())
              : null),
      lastCheckInDate: lastCheckInDateFromJson,
      following: followingList,
      followers: followersList,
      // 赋值新增字段
      currentLevelExp: currentLevelExpFromJson,
      nextLevelExp: nextLevelExpFromJson,
      expToNextLevel: expToNextLevelFromJson,
      levelProgress: levelProgressFromJson,
      isMaxLevel: isMaxLevelFromJson,
    );
  }

  // --- 完整的 toJson 方法 ---
  Map<String, dynamic> toJson() {
    return {
      'id': id, // 或者用 '_id': id, 看你的后端和缓存习惯
      'username': username,
      'email': email,
      // 通常不序列化 hash 和 salt
      // 'hash': hash,
      // 'salt': salt,
      'avatar': avatar,
      'createTime': createTime.toIso8601String(), // 序列化为 ISO 字符串
      'signature': signature,
      'updateTime': updateTime?.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'experience': experience,
      'level': level,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
      'lastCheckInDate': lastCheckInDate?.toIso8601String(), // 序列化为 ISO 字符串
      'following': following, // 直接序列化列表
      'followers': followers, // 直接序列化列表
      'currentLevelExp': currentLevelExp,
      'nextLevelExp': nextLevelExp,
      'expToNextLevel': expToNextLevel,
      'levelProgress': levelProgress,
      'isMaxLevel': isMaxLevel,
    };
  }

  // --- 完整的 toSafeJson 方法 ---
  // 用于 UI 显示，可以包含一些计算字段，不含敏感信息
  Map<String, dynamic> toSafeJson() {
    return {
      'id': id,
      'username': username,
      // 'email': email, // SafeJson 通常也不包含 email，除非特定场景需要
      'avatar': avatar,
      'signature': signature,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'experience': experience,
      'level': level,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
      'lastCheckInDate': lastCheckInDate?.toIso8601String(),
      'following': following,
      'followers': followers,
      'followingCount': following.length, // 添加计数
      'followersCount': followers.length, // 添加计数
      'checkedInToday': hasCheckedInToday, // 添加今日签到状态
      'currentLevelExp': currentLevelExp,
      'nextLevelExp': nextLevelExp,
      'expToNextLevel': expToNextLevel,
      'levelProgress': levelProgress,
      'isMaxLevel': isMaxLevel,
      // --- 结束添加 ---
    };
  }

  // --- 完整的 copyWith 方法 ---
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? hash,
    String? salt,
    String? avatar,
    String? signature,
    DateTime? updateTime,
    DateTime? createTime,
    bool? isAdmin,
    bool? isSuperAdmin,
    int? experience,
    int? level,
    int? consecutiveCheckIn,
    int? totalCheckIn,
    DateTime? lastCheckInDate,
    List<String>? following,
    List<String>? followers,
    // --- 新字段 ---
    int? currentLevelExp,
    int? nextLevelExp,
    int? expToNextLevel,
    double? levelProgress,
    bool? isMaxLevel,
    // --- 结束 ---
    bool clearLastCheckInDate = false, // 用于特殊情况清空日期
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      signature: signature ?? this.signature,
      updateTime: updateTime ?? this.updateTime,
      createTime: createTime ?? this.createTime,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      consecutiveCheckIn: consecutiveCheckIn ?? this.consecutiveCheckIn,
      totalCheckIn: totalCheckIn ?? this.totalCheckIn,
      lastCheckInDate: clearLastCheckInDate
          ? null
          : (lastCheckInDate ?? this.lastCheckInDate),
      following: following ?? this.following,
      followers: followers ?? this.followers,
      // --- 新字段赋值 ---
      currentLevelExp: currentLevelExp ?? this.currentLevelExp,
      nextLevelExp: nextLevelExp ?? this.nextLevelExp,
      expToNextLevel: expToNextLevel ?? this.expToNextLevel,
      levelProgress: levelProgress ?? this.levelProgress,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
      // --- 结束 ---
    );
  }

  // --- 完整的 hasCheckedInToday getter ---
  bool get hasCheckedInToday {
    if (lastCheckInDate == null) return false;

    final now = DateTime.now();
    // 使用 toUtc() 来比较日期，避免时区问题
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final checkInDateUtc = DateTime.utc(
      lastCheckInDate!.year,
      lastCheckInDate!.month,
      lastCheckInDate!.day,
    );

    return checkInDateUtc.isAtSameMomentAs(todayUtc);
  }

  // --- 可选：添加 hashCode 和 == 操作符重载，用于比较对象和在 Set/Map 中使用 ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          email == other.email &&
          avatar == other.avatar &&
          other.signature == signature &&
          createTime == other.createTime &&
          other.updateTime == updateTime &&
          isAdmin == other.isAdmin &&
          isSuperAdmin == other.isSuperAdmin &&
          experience == other.experience &&
          level == other.level &&
          consecutiveCheckIn == other.consecutiveCheckIn &&
          totalCheckIn == other.totalCheckIn &&
          lastCheckInDate == other.lastCheckInDate &&
          _listEquals(following, other.following) && // 需要辅助函数比较列表
          _listEquals(followers, other.followers) &&
          currentLevelExp == other.currentLevelExp &&
          nextLevelExp == other.nextLevelExp &&
          expToNextLevel == other.expToNextLevel &&
          levelProgress == other.levelProgress &&
          isMaxLevel == other.isMaxLevel;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      email.hashCode ^
      avatar.hashCode ^
      createTime.hashCode ^
      signature.hashCode ^
      updateTime.hashCode ^
      isAdmin.hashCode ^
      isSuperAdmin.hashCode ^
      experience.hashCode ^
      level.hashCode ^
      consecutiveCheckIn.hashCode ^
      totalCheckIn.hashCode ^
      lastCheckInDate.hashCode ^
      following.hashCode ^ // 列表直接用 hashCode 可能不够精确，但通常够用
      followers.hashCode ^
      currentLevelExp.hashCode ^
      nextLevelExp.hashCode ^
      expToNextLevel.hashCode ^
      levelProgress.hashCode ^
      isMaxLevel.hashCode;

  // 辅助函数比较列表内容是否相等
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  static User placeholder(String userId, {String message = '加载失败'}) {
    return User(
      id: userId,
      username: message, // 使用传入的消息，默认为'加载失败'
      email: '', // 邮箱通常为空
      avatar: null, // 通常没有头像
      signature: null,
      createTime: DateTime(1970), // 或者一个明确表示无效的默认时间
      updateTime: null,
      isAdmin: false,
      isSuperAdmin: false,
      experience: 0,
      level: 0, // 等级通常从 1 开始，但占位符用 0 或 1 都可以
      consecutiveCheckIn: 0,
      totalCheckIn: 0,
      lastCheckInDate: null,
      following: [], // 空列表
      followers: [], // 空列表
      // --- 所有新增等级相关字段的默认值 ---
      currentLevelExp: 0,
      nextLevelExp: 0, // 或者一个基础值如 1000
      expToNextLevel: 0, // 或者基础值
      levelProgress: 0.0,
      isMaxLevel: false,
    );
  }
}
