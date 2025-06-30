// lib/models/post/user_post_actions.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

@immutable
class UserPostActions {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyLiked = 'liked';
  static const String jsonKeyAgreed = 'agreed';
  static const String jsonKeyFavorited = 'favorited';
  static const String jsonKeyPostId = 'postId';
  static const String jsonKeyUserId = 'userId';

  // 这些是业务逻辑常量，已经定义为 static const String，无需额外处理
  static const String agreeAction = 'agree';
  static const String favoriteAction = 'favorite';
  static const String likeAction = 'like';

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

  // 提供一个默认的 "无交互" 状态
  factory UserPostActions.defaultActions(String postId, String userId) {
    return UserPostActions(postId: postId, userId: userId);
  }

  factory UserPostActions.fromJson(Map<String, dynamic> json) {
    return UserPostActions(
      // 业务逻辑: postId 和 userId 可能不在 action 的直接响应中，但为保持模型完整性而解析
      postId: UtilJson.parseId(json[jsonKeyPostId]), // 使用常量
      userId: UtilJson.parseId(json[jsonKeyUserId]), // 使用常量
      liked: UtilJson.parseBoolSafely(json[jsonKeyLiked]), // 使用常量
      agreed: UtilJson.parseBoolSafely(json[jsonKeyAgreed]), // 使用常量
      favorited: UtilJson.parseBoolSafely(json[jsonKeyFavorited]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'postId': postId, // 通常不需要序列化 postId/userId
      // 'userId': userId,
      jsonKeyLiked: liked, // 使用常量
      jsonKeyAgreed: agreed, // 使用常量
      jsonKeyFavorited: favorited, // 使用常量
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
