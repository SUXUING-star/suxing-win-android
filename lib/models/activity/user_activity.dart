// lib/models/activity/user_activity.dart

import 'package:suxingchahui/constants/activity/activity_constants.dart';

class CheckInActivityDetails {
  final int consecutiveDays;
  final int expGained;
  final List<DateTime> recentCheckIns;

  CheckInActivityDetails({
    required this.consecutiveDays,
    required this.expGained,
    required this.recentCheckIns,
  });

  factory CheckInActivityDetails.fromMetadata(
      Map<String, dynamic> metadataMap) {
    List<DateTime> parsedRecentCheckIns = [];
    if (metadataMap['recentCheckIns'] != null &&
        metadataMap['recentCheckIns'] is List) {
      for (var item in (metadataMap['recentCheckIns'] as List)) {
        if (item is String) {
          try {
            parsedRecentCheckIns.add(DateTime.parse(item).toLocal());
          } catch (e) {
            // print(
            //     "Error parsing recentCheckIn date string from metadata: '$item'. Error: $e");
          }
        }
      }
    }
    return CheckInActivityDetails(
      consecutiveDays: metadataMap['consecutiveDays'] as int? ?? 0,
      expGained: metadataMap['expGained'] as int? ?? 0,
      recentCheckIns: parsedRecentCheckIns,
    );
  }
}

class UserActivity {
  final String id;
  final String userId;
  final String type;
  final String sourceId;
  final String targetId;
  final String targetType;
  final String content;
  final DateTime createTime;
  final DateTime updateTime;
  final bool isEdited;
  int likesCount;
  int commentsCount;
  final bool isPublic;
  bool isLiked;
  final Map<String, dynamic>? metadata; // <--- 这个保留，信息从这里取

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
    required this.updateTime,
    required this.isEdited,
    required this.likesCount,
    required this.commentsCount,
    required this.isPublic,
    this.isLiked = false,
    this.metadata,
    // this.target, // <--- *** 从构造函数删除 ***
    this.comments = const [],
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    // 日期解析逻辑保持不变
    DateTime parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return DateTime(1970); // 返回一个明确的默认值，而不是 now()
      }
      try {
        return DateTime.parse(dateString).toLocal(); // 确保转为本地时间
      } catch (e) {
        // print("Error parsing date: $dateString. Error: $e");
        return DateTime(1970); // 解析失败也返回默认值
      }
    }

    List<ActivityComment> comments = [];
    if (json['comments'] != null && json['comments'] is List) {
      // 增加类型检查
      try {
        // 添加 try-catch 处理评论解析错误
        comments = (json['comments'] as List)
            .map((comment) => ActivityComment.fromJson(
                comment as Map<String, dynamic>)) // 确保类型转换
            .toList();
      } catch (e) {
        // print("Error parsing comments: ${json['comments']}. Error: $e");
        // 解析评论列表失败，返回空列表，避免整个活动解析失败
      }
    }

    return UserActivity(
      id: json['id'] ?? '', // 提供默认空字符串防止 null
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      sourceId: json['sourceId'] ?? '',
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? '',
      content: json['content'] ?? '',
      createTime: parseDateTime(json['createTime']),
      // updateTime 可能不存在，需要更安全的处理
      updateTime: json['updateTime'] == null || json['updateTime'] == ""
          ? parseDateTime(
              json['createTime']) // 如果 updateTime 为空或不存在，用 createTime
          : parseDateTime(json['updateTime']),
      isEdited: json['isEdited'] ?? false,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isPublic: json['isPublic'] ?? true, // 默认公开
      isLiked: json['isLiked'] ?? false,
      metadata:
          json['metadata'] != null && json['metadata'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(json['metadata']) // 确保是 Map
              : null,
      // target: json['target'], // <--- *** 从 fromJson 删除 ***
      comments: comments,
    );
  }

  // toJson 方法保持不变，只是没有 target 了
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
      'updateTime': updateTime.toIso8601String(),
      'isEdited': isEdited,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isPublic': isPublic,
      'isLiked': isLiked,
      'metadata': metadata,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }

  // --- 添加 Helper 方法从 metadata 获取信息 ---
  String? get gameTitle => metadata?['gameTitle'] as String?;
  String? get gameCoverImage => metadata?['gameCoverImage'] as String?;
  String? get postTitle => metadata?['postTitle'] as String?;
  String? get targetUsername =>
      metadata?['targetUsername'] as String?; // 如果关注用户时存了

  CheckInActivityDetails? get checkInDetails {
    if (type == ActivityTypeConstants.checkIn && metadata != null) {
      try {
        return CheckInActivityDetails.fromMetadata(metadata!);
      } catch (e) {
        // print(
        //     "Error creating CheckInActivityDetails from UserActivity.metadata: $e. Metadata: $metadata");
        return null;
      }
    }
    return null;
  }
}

class ActivityComment {
  final String id;
  final String userId; // <--- 直接用这个
  final String content;
  final DateTime createTime;
  int likesCount;
  bool isLiked;

  ActivityComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createTime,
    required this.likesCount,
    this.isLiked = false,
  });

  factory ActivityComment.fromJson(Map<String, dynamic> json) {
    // 日期解析逻辑保持不变
    DateTime parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return DateTime(1970);
      try {
        return DateTime.parse(dateString).toLocal();
      } catch (e) {
        // print("Error parsing comment date: $dateString. Error: $e");
        return DateTime(1970);
      }
    }

    // --- *** 直接从顶层获取 userId *** ---
    String extractedUserId =
        json['userId'] as String? ?? ''; // 如果后端保证有，可以去掉 ?? ''

    return ActivityComment(
      id: json['id'] ?? '',
      userId: extractedUserId, // <--- 使用顶层 userId
      content: json['content'] ?? '',
      createTime: parseDateTime(json['createTime']),
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
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
    };
  }
}
