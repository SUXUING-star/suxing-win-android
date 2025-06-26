// lib/models/announcement/announcement.dart

// 简化版公告模型（用于列表显示）
import 'package:flutter/cupertino.dart'; // 保留，因为 AnnouncementFull 的 copyWith 里有 bool flag，虽然现在不是 ValueGetter，但通常 copyWith 引入此 import
import 'package:suxingchahui/models/util_json.dart';

class Announcement {
  // --- JSON 字段键常量 ---
  static const String jsonKeyId = 'id';
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyType = 'type';
  static const String jsonKeyImageUrl = 'imageUrl';
  static const String jsonKeyActionUrl = 'actionUrl';
  static const String jsonKeyActionText = 'actionText';
  static const String jsonKeyDate = 'date';
  static const String jsonKeyPriority = 'priority';

  final String id;
  final String title;
  final String content;
  final String type;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;
  final DateTime date;
  final int priority;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
    required this.date,
    required this.priority,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: UtilJson.parseId(json[jsonKeyId]),
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      content: UtilJson.parseStringSafely(json[jsonKeyContent]),
      // 业务逻辑: 如果后端未提供类型，默认为 'info'
      type: UtilJson.parseStringSafely(json[jsonKeyType] ?? 'info'),
      imageUrl: UtilJson.parseNullableStringSafely(json[jsonKeyImageUrl]),
      actionUrl: UtilJson.parseNullableStringSafely(json[jsonKeyActionUrl]),
      actionText: UtilJson.parseNullableStringSafely(json[jsonKeyActionText]),
      date: UtilJson.parseDateTime(json[jsonKeyDate]),
      // 业务逻辑: 如果后端未提供优先级，默认为 1
      priority: UtilJson.parseIntSafely(json[jsonKeyPriority] ?? 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id,
      jsonKeyTitle: title,
      jsonKeyContent: content,
      jsonKeyType: type,
      jsonKeyImageUrl: imageUrl,
      jsonKeyActionUrl: actionUrl,
      jsonKeyActionText: actionText,
      jsonKeyDate: date.toUtc().toIso8601String(),
      jsonKeyPriority: priority,
    };
  }

  /// 创建一个空的 Announcement 对象。
  static Announcement empty() {
    return Announcement(
      id: '',
      title: '',
      content: '',
      type: 'info',
      imageUrl: null,
      actionUrl: null,
      actionText: null,
      date: DateTime.fromMillisecondsSinceEpoch(0),
      priority: 0,
    );
  }

  /// 复制并更新 Announcement 对象部分字段。
  // 注意：此处没有明确的 clearImage/actionUrl/actionText 逻辑，按标准 nullable 参数处理
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
    DateTime? date,
    int? priority,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      date: date ?? this.date,
      priority: priority ?? this.priority,
    );
  }
}

// 完整公告模型（用于管理界面）
class AnnouncementFull {
  // --- JSON 字段键常量 ---
  static const String jsonKeyId = 'id';
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyType = 'type';
  static const String jsonKeyImageUrl = 'imageUrl';
  static const String jsonKeyActionUrl = 'actionUrl';
  static const String jsonKeyActionText = 'actionText';
  static const String jsonKeyCreatedAt = 'createdAt';
  static const String jsonKeyPriority = 'priority';
  static const String jsonKeyIsActive = 'isActive';
  static const String jsonKeyStartDate = 'startDate';
  static const String jsonKeyEndDate = 'endDate';
  static const String jsonKeyTargetUsers = 'targetUsers';
  static const String jsonKeyCreatedBy = 'createdBy';

  String id;
  String title;
  String content;
  String type;
  String? imageUrl;
  String? actionUrl;
  String? actionText;
  DateTime createdAt;
  int priority;
  bool isActive;
  DateTime startDate;
  DateTime endDate;
  List<String>? targetUsers;
  String createdBy;

  AnnouncementFull({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
    required this.createdAt,
    required this.priority,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    this.targetUsers,
    required this.createdBy,
  });

  factory AnnouncementFull.fromJson(Map<String, dynamic> json) {
    return AnnouncementFull(
      id: UtilJson.parseId(json[jsonKeyId]),
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      content: UtilJson.parseStringSafely(json[jsonKeyContent]),
      // 业务逻辑: 如果后端未提供类型，默认为 'info'
      type: UtilJson.parseStringSafely(json[jsonKeyType] ?? 'info'),
      imageUrl: UtilJson.parseNullableStringSafely(json[jsonKeyImageUrl]),
      actionUrl: UtilJson.parseNullableStringSafely(json[jsonKeyActionUrl]),
      actionText: UtilJson.parseNullableStringSafely(json[jsonKeyActionText]),
      createdAt: UtilJson.parseDateTime(json[jsonKeyCreatedAt]),
      // 业务逻辑: 如果后端未提供优先级，默认为 1
      priority: UtilJson.parseIntSafely(json[jsonKeyPriority] ?? 1),
      isActive: UtilJson.parseBoolSafely(json[jsonKeyIsActive]),
      startDate: UtilJson.parseDateTime(json[jsonKeyStartDate]),
      endDate: UtilJson.parseDateTime(json[jsonKeyEndDate]),
      // 业务逻辑: targetUsers 是一个字符串列表，可能为 null
      targetUsers: json[jsonKeyTargetUsers] is List
          ? UtilJson.parseListString(json[jsonKeyTargetUsers])
          : null,
      createdBy: UtilJson.parseId(json[jsonKeyCreatedBy]),
    );
  }

  Map<String, dynamic> toJson() {
    // 格式化日期为UTC ISO字符串
    String formatDate(DateTime date) {
      return date.toUtc().toIso8601String();
    }

    // 严格保持与你原始代码的 toJson 方法返回的字段一致
    return {
      jsonKeyTitle: title,
      jsonKeyContent: content,
      jsonKeyType: type,
      jsonKeyImageUrl: imageUrl,
      jsonKeyActionUrl: actionUrl,
      jsonKeyActionText: actionText,
      jsonKeyPriority: priority,
      jsonKeyIsActive: isActive,
      jsonKeyStartDate: formatDate(startDate),
      jsonKeyEndDate: formatDate(endDate),
      jsonKeyTargetUsers: targetUsers,
    };
  }

  // 创建新公告
  static AnnouncementFull createNew() {
    final now = DateTime.now();
    return AnnouncementFull(
      id: '',
      title: '',
      content: '',
      type: 'info',
      createdAt: now,
      priority: 5,
      isActive: true,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      createdBy: '',
      targetUsers: null, // 默认不指定目标用户
    );
  }

  // 保持原始 copyWith 方法的签名和内部逻辑，只替换字段访问时的硬编码字符串
  // 这包括 imageUrl 等字段使用 bool clear... 标志位的原始逻辑
  AnnouncementFull copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? imageUrl,
    bool clearImageUrl = false, // 添加标志位明确清除图片 (原始代码就有)
    String? actionUrl,
    bool clearActionUrl = false,
    String? actionText,
    bool clearActionText = false,
    DateTime? createdAt,
    int? priority,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetUsers,
    String? createdBy,
  }) {
    return AnnouncementFull(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      // 严格保持原始逻辑处理 imageUrl、actionUrl、actionText 的 null/清空
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      actionUrl: clearActionUrl ? null : (actionUrl ?? this.actionUrl),
      actionText: clearActionText ? null : (actionText ?? this.actionText),
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetUsers: targetUsers ?? this.targetUsers,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
