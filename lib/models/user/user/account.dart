// lib/models/user/user/account.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/user/user/enrich_level.dart';

@immutable
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

  SavedAccount copyWith({
    String? email,
    String? password,
    String? username,
    String? avatarUrl,
    int? level,
    int? experience,
    String? userId,
    DateTime? lastLogin,
  }) {
    return SavedAccount(
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      userId: userId ?? this.userId,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

extension AccountExtension on SavedAccount {
  EnrichLevel get enrichLevel => EnrichLevel.fromLevel(level ?? 0);
}
