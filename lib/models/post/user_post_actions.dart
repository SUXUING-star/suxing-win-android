// lib/models/post/user_post_actions.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/util_json.dart';



@immutable
class UserPostActions {
  final bool liked;
  final bool agreed;
  final bool favorited;
  final String postId;
  final String userId;

  const UserPostActions({
    required this.postId,
    required this.userId,
    this.liked = false,
    this.agreed = false,
    this.favorited = false,
  });

  static const String agreeAction = 'agree';
  static const String favoriteAction = 'favorite';
  static const String likeAction = 'like';


  // 提供一个默认的 "无交互" 状态
  factory UserPostActions.defaultActions(String postId, String userId) {
    return UserPostActions(postId: postId, userId: userId);
  }

  factory UserPostActions.fromJson(Map<String, dynamic> json) {
    return UserPostActions(
      // 业务逻辑: postId 和 userId 可能不在 action 的直接响应中，但为保持模型完整性而解析
      postId: UtilJson.parseId(json['postId']),
      userId: UtilJson.parseId(json['userId']),
      liked: UtilJson.parseBoolSafely(json['liked']),
      agreed: UtilJson.parseBoolSafely(json['agreed']),
      favorited: UtilJson.parseBoolSafely(json['favorited']),
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