// lib/models/user.dart
class User {
  final String id;
  final String username;
  final String email;
  final String? hash;      // 仅在认证过程中使用
  final String? salt;      // 仅在认证过程中使用
  final String? avatar;
  final DateTime createTime;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.hash,
    this.salt,
    this.avatar,
    required this.createTime,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'], // 添加 '_id' 兼容
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'hash': hash,
      'salt': salt,
      'avatar': avatar,
      'createTime': createTime.toIso8601String(),
      'isAdmin': isAdmin,
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
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? hash,
    String? salt,
    String? avatar,
    DateTime? createTime,
    bool? isAdmin,
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
    );
  }
}