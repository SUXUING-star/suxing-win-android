// lib/models/announcement/announcement.dart
import 'package:json_annotation/json_annotation.dart';

// 简化版公告模型（用于列表显示）
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
    // 处理日期字段
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('日期解析错误: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'info',
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      actionText: json['actionText'],
      date: parseDate(json['date']),
      priority: json['priority'] ?? 1,
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
    // 处理日期字段
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('日期解析错误: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // 处理目标用户
    List<String>? targetUsers;
    if (json['targetUsers'] != null) {
      targetUsers = List<String>.from(json['targetUsers']);
    }

    return AnnouncementFull(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'info',
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      actionText: json['actionText'],
      createdAt: parseDate(json['createdAt']),
      priority: json['priority'] ?? 1,
      isActive: json['isActive'] ?? false,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      targetUsers: targetUsers,
      createdBy: json['createdBy'] ?? '',
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
}