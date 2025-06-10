// lib/models/post/user_post_actions.dart

import 'package:flutter/cupertino.dart';

@immutable
class UserPostActions {
  final bool liked;
  final bool agreed;
  final bool favorited;
  final String postId;
  final String userId;

  UserPostActions({
    required this.postId,
    required this.userId,
    this.liked = false,
    this.agreed = false,
    this.favorited = false,
  });

  // 提供一个默认的 "无交互" 状态
  factory UserPostActions.defaultActions(String postId, String userId) {
    return UserPostActions(postId: postId, userId: userId);
  }

  factory UserPostActions.fromJson(Map<String, dynamic> json) {
    return UserPostActions(
      // 通常 postId 和 userId 不会直接在 action 数据里，调用者需要提供
      // 这里假设 API 返回的结构可能包含，或者调用者组装
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      liked: json['liked'] ?? false,
      agreed: json['agreed'] ?? false,
      favorited: json['favorited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'postId': postId, // 通常不需要序列化 postId/userId
      // 'userId': userId,
      'liked': liked,
      'agreed': agreed,
      'favorited': favorited,
    };
  }

  UserPostActions copyWith({
    bool? liked,
    bool? agreed,
    bool? favorited,
  }) {
    return UserPostActions(
      postId: postId, // 保持 postId 和 userId
      userId: userId,
      liked: liked ?? this.liked,
      agreed: agreed ?? this.agreed,
      favorited: favorited ?? this.favorited,
    );
  }
}