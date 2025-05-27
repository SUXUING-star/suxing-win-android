// lib/models/game/game_comment.dart

class GameComment {
  final String id;
  final String gameId;
  final String userId;
  final String content;
  final DateTime createTime;
  final DateTime updateTime; // 用这个和 createTime 比较
  final String username;
  final String? parentId;
  final List<GameComment> replies; // 注意：嵌套回复的处理

  GameComment({
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
    // 处理嵌套的 replies
    List<GameComment> parsedReplies = [];
    if (json['replies'] is List) {
      parsedReplies = (json['replies'] as List)
          .map((replyJson) {
        try {
          return GameComment.fromJson(Map<String, dynamic>.from(replyJson));
        } catch (e) { return null; } // 防错
      })
          .whereType<GameComment>()
          .toList();
    }

    return GameComment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      gameId: json['gameId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      content: json['content'] ?? '',
      createTime: DateTime.parse(json['createTime']),
      updateTime: DateTime.parse(json['updateTime']),
      username: json['username'] ?? '未知用户',
      parentId: json['parentId']?.toString(),
      replies: parsedReplies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'userId': userId,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'username': username,
      'parentId': parentId,
      'replies': replies.map((r) => r.toJson()).toList(), // 递归转换
    };
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