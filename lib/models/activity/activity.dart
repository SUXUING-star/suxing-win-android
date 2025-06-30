// lib/models/activity/activity.dart

import 'package:suxingchahui/models/activity/activity_comment.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class Activity implements ToJsonExtension{

  static const targetGame = 'game'; // 游戏目标类型
  static const targetPost = 'post'; // 帖子目标类型
  static const targetUser = 'user'; // 用户目标类型
  // --- JSON 字段键常量 ---
  static const String jsonKeyId = 'id';
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyType = 'type';
  static const String jsonKeySourceId = 'sourceId';
  static const String jsonKeyTargetId = 'targetId';
  static const String jsonKeyTargetType = 'targetType';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeyIsEdited = 'isEdited';
  static const String jsonKeyLikesCount = 'likesCount';
  static const String jsonKeyCommentsCount = 'commentsCount';
  static const String jsonKeyIsPublic = 'isPublic';
  static const String jsonKeyIsLiked = 'isLiked';
  static const String jsonKeyMetadata = 'metadata';
  static const String jsonKeyComments = 'comments';

  // --- Metadata 内部字段键常量 ---
  static const String metadataKeyGameTitle = 'gameTitle';
  static const String metadataKeyGameCoverImage = 'gameCoverImage';
  static const String metadataKeyPostTitle = 'postTitle';
  static const String metadataKeyTargetUsername = 'targetUsername';
  static const String metadataKeyUserRelationshipAction = 'action';

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

  Activity({
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


  static List<Activity> fromListJson(dynamic json) {
    return UtilJson.parseObjectList<Activity>(
        json, (listJson) => Activity.fromJson(listJson));
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    List<ActivityComment> comments =
        ActivityComment.fromListJson(json[jsonKeyComments]);

    final createTime = UtilJson.parseDateTime(json[jsonKeyCreateTime]);

    return Activity(
      id: UtilJson.parseId(json[jsonKeyId]),
      userId: UtilJson.parseId(json[jsonKeyUserId]),
      type: UtilJson.parseStringSafely(json[jsonKeyType]),
      sourceId: UtilJson.parseId(json[jsonKeySourceId]),
      targetId: UtilJson.parseId(json[jsonKeyTargetId]),
      targetType: UtilJson.parseStringSafely(json[jsonKeyTargetType]),
      content: UtilJson.parseStringSafely(json[jsonKeyContent]),
      createTime: createTime,
      updateTime:
          UtilJson.parseNullableDateTime(json[jsonKeyUpdateTime]) ?? createTime,
      isEdited: UtilJson.parseBoolSafely(json[jsonKeyIsEdited]),
      likesCount: UtilJson.parseIntSafely(json[jsonKeyLikesCount]),
      commentsCount: UtilJson.parseIntSafely(json[jsonKeyCommentsCount]),
      isPublic:
          UtilJson.parseBoolSafely(json[jsonKeyIsPublic], defaultValue: true),
      isLiked: UtilJson.parseBoolSafely(json[jsonKeyIsLiked]),
      metadata: json[jsonKeyMetadata] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json[jsonKeyMetadata])
          : null,
      comments: comments,
    );
  }

  // toJson 方法保持不变，只是没有 target 了
  @override
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id,
      jsonKeyUserId: userId,
      jsonKeyType: type,
      jsonKeySourceId: sourceId,
      jsonKeyTargetId: targetId,
      jsonKeyTargetType: targetType,
      jsonKeyContent: content,
      jsonKeyCreateTime: createTime.toIso8601String(),
      jsonKeyUpdateTime: updateTime.toIso8601String(),
      jsonKeyIsEdited: isEdited,
      jsonKeyLikesCount: likesCount,
      jsonKeyCommentsCount: commentsCount,
      jsonKeyIsPublic: isPublic,
      jsonKeyIsLiked: isLiked,
      jsonKeyMetadata: metadata,
      jsonKeyComments: comments.map((comment) => comment.toJson()).toList(),
    };
  }

  /// 创建一个空的 UserActivity 对象。
  static Activity empty() {
    return Activity(
      id: '',
      userId: '',
      type: '',
      sourceId: '',
      targetId: '',
      targetType: '',
      content: '',
      createTime: DateTime.fromMillisecondsSinceEpoch(0),
      updateTime: DateTime.fromMillisecondsSinceEpoch(0),
      isEdited: false,
      likesCount: 0,
      commentsCount: 0,
      isPublic: true,
      isLiked: false,
      metadata: null,
      comments: [],
    );
  }

  /// 复制并更新 UserActivity 对象部分字段。
  Activity copyWith({
    String? id,
    String? userId,
    String? type,
    String? sourceId,
    String? targetId,
    String? targetType,
    String? content,
    DateTime? createTime,
    DateTime? updateTime,
    bool? isEdited,
    int? likesCount,
    int? commentsCount,
    bool? isPublic,
    bool? isLiked,
    Map<String, dynamic>? metadata,
    List<ActivityComment>? comments,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      content: content ?? this.content,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      isEdited: isEdited ?? this.isEdited,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isPublic: isPublic ?? this.isPublic,
      isLiked: isLiked ?? this.isLiked,
      metadata: metadata ?? this.metadata,
      comments: comments ?? this.comments,
    );
  }
}
