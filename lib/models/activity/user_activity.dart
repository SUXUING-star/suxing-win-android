// lib/models/activity/user_activity.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class CheckInActivityDetails {
  final int consecutiveDays;
  final int expGained;
  final List<DateTime> recentCheckIns;

  const CheckInActivityDetails({
    required this.consecutiveDays,
    required this.expGained,
    required this.recentCheckIns,
  });

  factory CheckInActivityDetails.fromMetadata(
      Map<String, dynamic> metadataMap) {
    return CheckInActivityDetails(
      consecutiveDays: UtilJson.parseIntSafely(metadataMap['consecutiveDays']),
      expGained: UtilJson.parseIntSafely(metadataMap['expGained']),
      recentCheckIns: UtilJson.parseListDateTime(metadataMap['recentCheckIns']),
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
  final Map<String, dynamic>? metadata;

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
    this.comments = const [],
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    List<ActivityComment> comments = [];
    if (json['comments'] is List) {
      comments = (json['comments'] as List)
          .map((comment) {
            if (comment is Map<String, dynamic>) {
              return ActivityComment.fromJson(comment);
            }
            return null;
          })
          .whereType<ActivityComment>()
          .toList();
    }

    final createTime = UtilJson.parseDateTime(json['createTime']);

    return UserActivity(
      id: UtilJson.parseId(json['id']),
      userId: UtilJson.parseId(json['userId']),
      type: UtilJson.parseStringSafely(json['type']),
      sourceId: UtilJson.parseId(json['sourceId']),
      targetId: UtilJson.parseId(json['targetId']),
      targetType: UtilJson.parseStringSafely(json['targetType']),
      content: UtilJson.parseStringSafely(json['content']),
      createTime: createTime,
      updateTime:
          UtilJson.parseNullableDateTime(json['updateTime']) ?? createTime,
      isEdited: UtilJson.parseBoolSafely(json['isEdited']),
      likesCount: UtilJson.parseIntSafely(json['likesCount']),
      commentsCount: UtilJson.parseIntSafely(json['commentsCount']),
      isPublic: UtilJson.parseBoolSafely(json['isPublic'], defaultValue: true),
      isLiked: UtilJson.parseBoolSafely(json['isLiked']),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
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
