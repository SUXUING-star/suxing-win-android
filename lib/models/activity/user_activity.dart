// lib/models/activity/user_activity.dart

class UserActivity {
  final String id;
  final String userId;
  final String type;
  final String sourceId;
  final String targetId;
  final String targetType;
  final String content;
  final DateTime createTime;
  final DateTime updateTime;  // 新增字段
  final bool isEdited;        // 新增字段
  int likesCount;
  int commentsCount;
  final bool isPublic;
  bool isLiked;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? target;
  List<ActivityComment> comments;

  UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.sourceId,
    required this.targetId,
    required this.targetType,
    required this.content,
    required this.createTime,
    required this.updateTime,  // 新增字段
    required this.isEdited,    // 新增字段
    required this.likesCount,
    required this.commentsCount,
    required this.isPublic,
    this.isLiked = false,
    this.metadata,
    this.user,
    this.target,
    this.comments = const [],
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    // 安全解析日期，提供默认值或处理错误
    DateTime parseDateTime(String? dateString) {
      if (dateString == null) return DateTime.now();
      try {
        // 尝试多种格式，或者确保后端总是返回 ISO 8601
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date: $dateString. Error: $e");
        return DateTime.now(); // Fallback to now if parsing fails
      }
    }
    List<ActivityComment> comments = [];
    if (json['comments'] != null) {
      comments = (json['comments'] as List)
          .map((comment) => ActivityComment.fromJson(comment))
          .toList();
    }

    return UserActivity(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      sourceId: json['sourceId'] ?? '',
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? '',
      content: json['content'] ?? '',
      createTime: parseDateTime(json['createTime']),
      updateTime: parseDateTime(json['updateTime']),
      isEdited: json['isEdited'] ?? false,  // 新增字段
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isPublic: json['isPublic'] ?? true,
      isLiked: json['isLiked'] ?? false,
      metadata: json['metadata'],
      user: json['user'],
      target: json['target'],
      comments: comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'sourceId': sourceId,
      'targetId': targetId,
      'targetType': targetType,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),  // 新增字段
      'isEdited': isEdited,  // 新增字段
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isPublic': isPublic,
      'isLiked': isLiked,
      'metadata': metadata,
      'user': user,
      'target': target,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}
class ActivityComment {
  final String id;
  final String userId;
  final String content;
  final DateTime createTime;
  int likesCount;
  bool isLiked;
  final Map<String, dynamic>? user; // 后端直接返回完整的user信息，包含userId、username和avatar

  ActivityComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createTime,
    required this.likesCount,
    this.isLiked = false,
    this.user,
  });

  factory ActivityComment.fromJson(Map<String, dynamic> json) {
    // 安全解析日期
    DateTime parseDateTime(String? dateString) {
      if (dateString == null) return DateTime.now();
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing comment date: $dateString. Error: $e");
        return DateTime.now();
      }
    }

    // 从 user map 中提取 userId
    String extractedUserId = (json['user'] as Map?)?['userId'] as String? ??
        json['userId'] as String? ?? ''; // 兼容顶层 userId
    return ActivityComment(
      id: json['id'],
      userId: extractedUserId,
      content: json['content'] ?? '',
      createTime: parseDateTime(json['createTime']),
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'likesCount': likesCount,
      'isLiked': isLiked,
      'user': user,
    };
  }

}