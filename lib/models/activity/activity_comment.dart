// lib/models/activity/activity_comment.dart

import 'package:suxingchahui/models/utils/util_json.dart'; // 确保导入了 util_json

class ActivityComment {
  // --- JSON 字段键常量 ---
  static const String jsonKeyId = 'id';
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyLikesCount = 'likesCount';
  static const String jsonKeyIsLiked = 'isLiked';

  final String id;
  final String userId;
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
    return ActivityComment(
      // 修正：全部使用 UtilJson 的工具函数进行解析
      id: UtilJson.parseId(
          json[jsonKeyId]), // 假设 parseId 会处理 null/空字符串并返回空字符串或抛错
      userId: UtilJson.parseId(json[jsonKeyUserId]),
      content: UtilJson.parseStringSafely(
          json[jsonKeyContent]), // parseStringSafely 处理 null 返回空字符串
      createTime: UtilJson.parseDateTime(
          json[jsonKeyCreateTime]), // parseDateTime 处理 null 返回 DateTime(1970)
      likesCount: UtilJson.parseIntSafely(
          json[jsonKeyLikesCount]), // parseIntSafely 处理 null 返回 0
      isLiked: UtilJson.parseBoolSafely(
          json[jsonKeyIsLiked]), // parseBoolSafely 处理 null 返回 false
    );
  }

  static List<ActivityComment> fromListJson(dynamic json) {
    return UtilJson.parseObjectList<ActivityComment>(
        json, (listJson) => ActivityComment.fromJson(listJson));
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id,
      jsonKeyUserId: userId,
      jsonKeyContent: content,
      jsonKeyCreateTime: createTime.toIso8601String(),
      jsonKeyLikesCount: likesCount,
      jsonKeyIsLiked: isLiked,
    };
  }

  /// 创建一个空的 ActivityComment 对象。
  static ActivityComment empty() {
    return ActivityComment(
      id: '',
      userId: '',
      content: '',
      createTime: DateTime.fromMillisecondsSinceEpoch(0),
      likesCount: 0,
      isLiked: false,
    );
  }

  /// 复制并更新 ActivityComment 对象部分字段。
  ActivityComment copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? createTime,
    int? likesCount,
    bool? isLiked,
  }) {
    return ActivityComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createTime: createTime ?? this.createTime,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
