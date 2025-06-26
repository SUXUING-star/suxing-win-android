// lib/models/game/game_comment.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameComment {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id'; // MongoDB 默认的 _id 字段
  static const String jsonKeyGameId = 'gameId';
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeyUsername = 'username';
  static const String jsonKeyParentId = 'parentId';
  static const String jsonKeyReplies = 'replies'; // 注意：嵌套回复的键

  final String id;
  final String gameId;
  final String userId;
  final String content;
  final DateTime createTime;
  final DateTime updateTime; // 用这个和 createTime 比较
  final String username;
  final String? parentId;
  final List<GameComment> replies; // 注意：嵌套回复的处理

  const GameComment({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.content,
    required this.createTime,
    required this.updateTime,
    required this.username,
    this.parentId,
    this.replies = const [],
  });

  factory GameComment.fromJson(Map<String, dynamic> json) {
    List<GameComment> parsedReplies = [];
    // 使用常量
    if (json[jsonKeyReplies] is List) {
      parsedReplies = (json[jsonKeyReplies] as List)
          .map((replyJson) {
            if (replyJson is Map<String, dynamic>) {
              return GameComment.fromJson(replyJson);
            }
            return null;
          })
          .whereType<GameComment>()
          .toList();
    }

    return GameComment(
      id: UtilJson.parseId(json[jsonKeyMongoId] ?? json[jsonKeyId]), // 使用常量
      gameId: UtilJson.parseId(json[jsonKeyGameId]), // 使用常量
      userId: UtilJson.parseId(json[jsonKeyUserId]), // 使用常量
      content: UtilJson.parseStringSafely(json[jsonKeyContent]), // 使用常量
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
      updateTime: UtilJson.parseDateTime(json[jsonKeyUpdateTime]), // 使用常量
      username: UtilJson.parseStringSafely(json[jsonKeyUsername]), // 使用常量
      parentId:
          UtilJson.parseNullableStringSafely(json[jsonKeyParentId]), // 使用常量
      replies: parsedReplies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用常量
      jsonKeyGameId: gameId, // 使用常量
      jsonKeyUserId: userId, // 使用常量
      jsonKeyContent: content, // 使用常量
      jsonKeyCreateTime: createTime.toIso8601String(), // 使用常量
      jsonKeyUpdateTime: updateTime.toIso8601String(), // 使用常量
      jsonKeyUsername: username, // 使用常量
      jsonKeyParentId: parentId, // 使用常量
      jsonKeyReplies: replies.map((r) => r.toJson()).toList(), // 使用常量，递归转换
    };
  }

  static List<GameComment> fromListJson(dynamic json) {
    if (json is! List) {
      return [];
    }
    return UtilJson.parseObjectList<GameComment>(
        json, (listJson) => GameComment.fromJson(listJson));
  }

  static GameComment empty() {
    return GameComment(
      id: '',
      gameId: '',
      userId: '',
      content: '',
      createTime: DateTime.fromMillisecondsSinceEpoch(0), // 或者 DateTime.now()
      updateTime: DateTime.fromMillisecondsSinceEpoch(0), // 或者 DateTime.now()
      username: '', // 或者 '未知用户'
      parentId: null,
      replies: [],
    );
  }

  // UI 判断是否编辑过
  bool get hasBeenEdited {
    const Duration tolerance = Duration(seconds: 1);
    return updateTime.difference(createTime).abs() > tolerance;
  }
}
