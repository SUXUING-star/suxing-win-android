// lib/models/user/account.dart

class SavedAccount {
  final String email;
  final String password;
  final String? username;
  final String? avatarUrl;
  final int? level;
  final int? experience;
  final String? userId;
  final DateTime lastLogin;

  SavedAccount({
    required this.email,
    required this.password,
    this.username,
    this.avatarUrl,
    this.level,
    this.experience,
    this.userId,
    DateTime? lastLogin,
  }) : lastLogin = lastLogin ?? DateTime.now();

  // 从JSON构造
  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: json['email'] as String,
      password: json['password'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      level: json['level'] as int?,
      experience: json['experience'] as int?,
      userId: json['userId'] as String?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : DateTime.now(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'username': username,
      'avatarUrl': avatarUrl,
      'level': level,
      'experience': experience,
      'userId': userId,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
}