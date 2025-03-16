// lib/models/user/user.dart
class User {
  final String id;
  final String username;
  final String email;
  final String? hash;      // 仅在认证过程中使用
  final String? salt;      // 仅在认证过程中使用
  final String? avatar;
  final DateTime createTime;
  final bool isAdmin;
  final bool isSuperAdmin;
  final int experience;
  final int level;
  final int? consecutiveCheckIn;
  final int? totalCheckIn;
  final DateTime? lastCheckInDate;
  final List<String> following;    // 添加关注列表
  final List<String> followers;    // 添加粉丝列表

  User({
    required this.id,
    required this.username,
    required this.email,
    this.hash,
    this.salt,
    this.avatar,
    required this.createTime,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.experience = 0,
    this.level = 1,
    this.consecutiveCheckIn,
    this.totalCheckIn,
    this.lastCheckInDate,
    this.following = const [],     // 初始化为空列表
    this.followers = const [],     // 初始化为空列表
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // 处理关注和粉丝列表
    List<String> followingList = [];
    if (json['following'] != null) {
      if (json['following'] is List) {
        followingList = List<String>.from(json['following']);
      }
    }

    List<String> followersList = [];
    if (json['followers'] != null) {
      if (json['followers'] is List) {
        followersList = List<String>.from(json['followers']);
      }
    }

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      hash: json['hash'],
      salt: json['salt'],
      avatar: json['avatar'],
      createTime: json['createTime'] != null
          ? (json['createTime'] is String
          ? DateTime.parse(json['createTime'])
          : json['createTime'])
          : DateTime.now(),
      isAdmin: json['isAdmin'] ?? false,
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      experience: json['experience'] ?? 0,
      level: json['level'] ?? 1,
      consecutiveCheckIn: json['consecutiveCheckIn'],
      totalCheckIn: json['totalCheckIn'],
      lastCheckInDate: json['lastCheckInDate'] != null
          ? (json['lastCheckInDate'] is String
          ? DateTime.parse(json['lastCheckInDate'])
          : json['lastCheckInDate'])
          : null,
      following: followingList,
      followers: followersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'hash': hash,
      'salt': salt,
      'avatar': avatar,
      'createTime': createTime.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'experience': experience,
      'level': level,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
      'lastCheckInDate': lastCheckInDate?.toIso8601String(),
      'following': following,
      'followers': followers,
    };
  }

  // 安全对象，用于UI显示，不包含敏感信息
  Map<String, dynamic> toSafeJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'createTime': createTime.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'experience': experience,
      'level': level,
      'consecutiveCheckIn': consecutiveCheckIn,
      'totalCheckIn': totalCheckIn,
      'lastCheckInDate': lastCheckInDate?.toIso8601String(),
      'following': following,
      'followers': followers,
      'followingCount': following.length,
      'followersCount': followers.length,
    };
  }

  // 复制带有更新的用户对象
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? hash,
    String? salt,
    String? avatar,
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
    bool clearLastCheckInDate = false,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      hash: hash ?? this.hash,
      salt: salt ?? this.salt,
      avatar: avatar ?? this.avatar,
      createTime: createTime ?? this.createTime,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      consecutiveCheckIn: consecutiveCheckIn ?? this.consecutiveCheckIn,
      totalCheckIn: totalCheckIn ?? this.totalCheckIn,
      lastCheckInDate: clearLastCheckInDate ? null : (lastCheckInDate ?? this.lastCheckInDate),
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }

  // 判断用户是否今日已签到
  bool get hasCheckedInToday {
    if (lastCheckInDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkInDate = DateTime(
      lastCheckInDate!.year,
      lastCheckInDate!.month,
      lastCheckInDate!.day,
    );

    return checkInDate.isAtSameMomentAs(today);
  }
}