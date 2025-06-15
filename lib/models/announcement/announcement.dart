// lib/models/announcement/announcement.dart

// 简化版公告模型（用于列表显示）
import 'package:suxingchahui/models/util_json.dart';

class Announcement {
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
      id: UtilJson.parseId(json['id']),
      title: UtilJson.parseStringSafely(json['title']),
      content: UtilJson.parseStringSafely(json['content']),
      // 业务逻辑: 如果后端未提供类型，默认为 'info'
      type: UtilJson.parseStringSafely(json['type'] ?? 'info'),
      imageUrl: UtilJson.parseNullableStringSafely(json['imageUrl']),
      actionUrl: UtilJson.parseNullableStringSafely(json['actionUrl']),
      actionText: UtilJson.parseNullableStringSafely(json['actionText']),
      date: UtilJson.parseDateTime(json['date']),
      // 业务逻辑: 如果后端未提供优先级，默认为 1
      priority: UtilJson.parseIntSafely(json['priority'] ?? 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'date': date.toUtc().toIso8601String(),
      'priority': priority,
    };
  }
}

// 完整公告模型（用于管理界面）
class AnnouncementFull {
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
      id: UtilJson.parseId(json['id']),
      title: UtilJson.parseStringSafely(json['title']),
      content: UtilJson.parseStringSafely(json['content']),
      // 业务逻辑: 如果后端未提供类型，默认为 'info'
      type: UtilJson.parseStringSafely(json['type'] ?? 'info'),
      imageUrl: UtilJson.parseNullableStringSafely(json['imageUrl']),
      actionUrl: UtilJson.parseNullableStringSafely(json['actionUrl']),
      actionText: UtilJson.parseNullableStringSafely(json['actionText']),
      createdAt: UtilJson.parseDateTime(json['createdAt']),
      // 业务逻辑: 如果后端未提供优先级，默认为 1
      priority: UtilJson.parseIntSafely(json['priority'] ?? 1),
      isActive: UtilJson.parseBoolSafely(json['isActive']),
      startDate: UtilJson.parseDateTime(json['startDate']),
      endDate: UtilJson.parseDateTime(json['endDate']),
      // 业务逻辑: targetUsers 是一个字符串列表，可能为 null
      targetUsers: json['targetUsers'] is List
          ? UtilJson.parseListString(json['targetUsers'])
          : null,
      createdBy: UtilJson.parseId(json['createdBy']),
    );
  }

  Map<String, dynamic> toJson() {
    // 格式化日期为UTC ISO字符串
    String formatDate(DateTime date) {
      return date.toUtc().toIso8601String();
    }

    return {
      'title': title,
      'content': content,
      'type': type,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'priority': priority,
      'isActive': isActive,
      'startDate': formatDate(startDate),
      'endDate': formatDate(endDate),
      'targetUsers': targetUsers,
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
    );
  }

// 添加 copyWith 方法
  AnnouncementFull copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    // 使用 Object? 包装 imageUrl，以便区分 null（显式设置为空）和未提供（保持不变）
    // 但简单起见，直接用 String? 也可以，需要在调用处处理 null 逻辑
    String? imageUrl,
    bool clearImageUrl = false, // 添加标志位明确清除图片
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
