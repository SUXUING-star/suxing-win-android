// lib/models/user/user/user.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/user/user/user_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

@immutable
class User {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id';
  static const String jsonKeyUsername = 'username';
  static const String jsonKeyEmail = 'email';
  static const String jsonKeyAvatar = 'avatar';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeySignature = 'signature';
  static const String jsonKeyIsAdmin = 'isAdmin';
  static const String jsonKeyIsSuperAdmin = 'isSuperAdmin';
  static const String jsonKeyExperience = 'experience';
  static const String jsonKeyLevel = 'level';
  static const String jsonKeyConsecutiveCheckIn = 'consecutiveCheckIn';
  static const String jsonKeyTotalCheckIn = 'totalCheckIn';
  static const String jsonKeyCoins = 'coins';
  static const String jsonKeyLastCheckInDate = 'lastCheckInDate';
  static const String jsonKeyFollowing = 'following';
  static const String jsonKeyFollowers = 'followers';
  static const String jsonKeyCurrentLevelExp = 'currentLevelExp';
  static const String jsonKeyNextLevelExp = 'nextLevelExp';
  static const String jsonKeyExpToNextLevel = 'expToNextLevel';
  static const String jsonKeyLevelProgress = 'levelProgress';
  static const String jsonKeyIsMaxLevel = 'isMaxLevel';

  // 为 toSafeJson 中额外添加的字段也定义常量
  static const String jsonKeyFollowingCount = 'followingCount';
  static const String jsonKeyFollowersCount = 'followersCount';
  static const String jsonKeyCheckedInToday = 'checkedInToday';

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
  final int coins;
  final DateTime? lastCheckInDate;
  final List<String> following; // 关注列表 (ID 字符串)
  final List<String> followers; // 粉丝列表 (ID 字符串)
  final int currentLevelExp; // 当前等级起始经验
  final int nextLevelExp; // 下一级所需总经验
  final int expToNextLevel; // 距离下一级还差多少经验
  final double levelProgress; // 当前等级进度百分比 (0-100)
  final bool isMaxLevel; // 是否满级

  const User({
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
    this.coins = 0,
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
    return User(
      // 业务逻辑: ID 字段兼容 '_id' 和 'id'
      id: UtilJson.parseId(json[jsonKeyMongoId] ?? json[jsonKeyId]),
      username: UtilJson.parseStringSafely(json[jsonKeyUsername]),
      email: UtilJson.parseStringSafely(json[jsonKeyEmail]),
      avatar: UtilJson.parseNullableStringSafely(json[jsonKeyAvatar]),
      signature: UtilJson.parseNullableStringSafely(json[jsonKeySignature]),
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]),
      updateTime: UtilJson.parseNullableDateTime(json[jsonKeyUpdateTime]),
      isAdmin: UtilJson.parseBoolSafely(json[jsonKeyIsAdmin]),
      isSuperAdmin: UtilJson.parseBoolSafely(json[jsonKeyIsSuperAdmin]),
      experience: UtilJson.parseIntSafely(json[jsonKeyExperience]),
      level: UtilJson.parseIntSafely(json[jsonKeyLevel]),
      coins: UtilJson.parseIntSafely(json[jsonKeyCoins]),
      consecutiveCheckIn:
          UtilJson.parseNullableIntSafely(json[jsonKeyConsecutiveCheckIn]),
      totalCheckIn: UtilJson.parseNullableIntSafely(json[jsonKeyTotalCheckIn]),
      lastCheckInDate:
          UtilJson.parseNullableDateTime(json[jsonKeyLastCheckInDate]),
      following: UtilJson.parseListString(json[jsonKeyFollowing]),
      followers: UtilJson.parseListString(json[jsonKeyFollowers]),
      currentLevelExp: UtilJson.parseIntSafely(json[jsonKeyCurrentLevelExp]),
      nextLevelExp: UtilJson.parseIntSafely(json[jsonKeyNextLevelExp]),
      expToNextLevel: UtilJson.parseIntSafely(json[jsonKeyExpToNextLevel]),
      levelProgress: UtilJson.parseDoubleSafely(json[jsonKeyLevelProgress]),
      isMaxLevel: UtilJson.parseBoolSafely(json[jsonKeyIsMaxLevel]),
    );
  }

  // --- 完整的 toSafeJson 方法 ---
  // 用于 UI 显示，可以包含一些计算字段，不含敏感信息
  Map<String, dynamic> toSafeJson() {
    return {
      jsonKeyId: id,
      jsonKeyUsername: username,
      jsonKeyAvatar: avatar,
      jsonKeyCoins: coins,
      jsonKeySignature: signature,
      jsonKeyCreateTime: createTime.toIso8601String(),
      jsonKeyUpdateTime: updateTime?.toIso8601String(),
      jsonKeyIsAdmin: isAdmin,
      jsonKeyIsSuperAdmin: isSuperAdmin,
      jsonKeyExperience: experience,
      jsonKeyLevel: level,
      jsonKeyConsecutiveCheckIn: consecutiveCheckIn,
      jsonKeyTotalCheckIn: totalCheckIn,
      jsonKeyLastCheckInDate: lastCheckInDate?.toIso8601String(),
      jsonKeyFollowing: following,
      jsonKeyFollowers: followers,
      jsonKeyFollowingCount: following.length, // 添加计数
      jsonKeyFollowersCount: followers.length, // 添加计数
      jsonKeyCheckedInToday: hasCheckedInToday, // 添加今日签到状态
      jsonKeyCurrentLevelExp: currentLevelExp,
      jsonKeyNextLevelExp: nextLevelExp,
      jsonKeyExpToNextLevel: expToNextLevel,
      jsonKeyLevelProgress: levelProgress,
      jsonKeyIsMaxLevel: isMaxLevel,
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
    int? coins,
    int? consecutiveCheckIn,
    int? totalCheckIn,
    DateTime? lastCheckInDate,
    List<String>? following,
    List<String>? followers,
    int? currentLevelExp,
    int? nextLevelExp,
    int? expToNextLevel,
    double? levelProgress,
    bool? isMaxLevel,
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
      coins: coins ?? this.coins,
      consecutiveCheckIn: consecutiveCheckIn ?? this.consecutiveCheckIn,
      totalCheckIn: totalCheckIn ?? this.totalCheckIn,
      lastCheckInDate: clearLastCheckInDate
          ? null
          : (lastCheckInDate ?? this.lastCheckInDate),
      following: following ?? this.following,
      followers: followers ?? this.followers,
      currentLevelExp: currentLevelExp ?? this.currentLevelExp,
      nextLevelExp: nextLevelExp ?? this.nextLevelExp,
      expToNextLevel: expToNextLevel ?? this.expToNextLevel,
      levelProgress: levelProgress ?? this.levelProgress,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
    );
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
      coins: 0,
      level: 0, // 等级通常从 1 开始，但占位符用 0 或 1 都可以
      consecutiveCheckIn: 0,
      totalCheckIn: 0,
      lastCheckInDate: null,
      following: [], // 空列表
      followers: [], // 空列表
      currentLevelExp: 0,
      nextLevelExp: 0, // 或者一个基础值如 1000
      expToNextLevel: 0, // 或者基础值
      levelProgress: 0.0,
      isMaxLevel: false,
    );
  }
}
