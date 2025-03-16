// lib/models/message/message.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'message_type.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createTime;
  final DateTime? readTime;
  final String? gameId;    // 关联的游戏ID
  final String? postId;    // 关联的帖子ID
  // 新增分组字段
  final int? groupCount;   // 此组中消息的数量
  final List<String>? references; // 相关引用，可以是用户ID或内容摘要
  final String? lastContent; // 最新内容的摘要
  final DateTime? updateTime; // 消息更新时间

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createTime,
    this.readTime,
    this.gameId,
    this.postId,
    this.groupCount,
    this.references,
    this.lastContent,
    this.updateTime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // 安全解析ID字段，处理ObjectId和String类型
    String safeParseId(dynamic value) {
      if (value == null) return '';

      // 如果是字符串，直接返回
      if (value is String) return value;

      // 如果是ObjectId类型
      try {
        if (value.toString().contains('ObjectId')) {
          // 处理ObjectId("xxxx")格式
          final idStr = value.toString();
          final matches = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(idStr);
          if (matches != null && matches.groupCount >= 1) {
            return matches.group(1) ?? '';
          }
        }

        // 尝试直接调用toHexString
        return value.toHexString();
      } catch (e) {
        print('Error parsing ID: $e');
        // 尝试转字符串
        return value.toString();
      }
    }

    // 安全解析日期时间
    DateTime safeParseDateTime(dynamic value) {
      if (value == null) return DateTime.now();

      if (value is DateTime) return value;

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing datetime string: $e');
          return DateTime.now();
        }
      }

      // 尝试其他格式转换
      try {
        final timestamp = int.tryParse(value.toString());
        if (timestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      } catch (e) {
        print('Error parsing timestamp: $e');
      }

      return DateTime.now();
    }

    // 安全解析引用列表
    List<String>? safeParseReferences(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return null;
    }

    return Message(
      id: safeParseId(json['_id'] ?? json['id']),
      senderId: safeParseId(json['senderId']),
      recipientId: safeParseId(json['recipientId']),
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      createTime: safeParseDateTime(json['createTime']),
      readTime: json['readTime'] != null ? safeParseDateTime(json['readTime']) : null,
      gameId: json['gameId'] != null ? safeParseId(json['gameId']) : null,
      postId: json['postId'] != null ? safeParseId(json['postId']) : null,
      // 解析新增的分组字段
      groupCount: json['groupCount'] is int ? json['groupCount'] : null,
      references: safeParseReferences(json['references']),
      lastContent: json['lastContent'],
      updateTime: json['updateTime'] != null ? safeParseDateTime(json['updateTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'type': type,
      'isRead': isRead,
      'createTime': createTime.toIso8601String(),
      'readTime': readTime?.toIso8601String(),
      'gameId': gameId,
      'postId': postId,
      // 包含新增的分组字段
      'groupCount': groupCount,
      'references': references,
      'lastContent': lastContent,
      'updateTime': updateTime?.toIso8601String(),
    };
  }

  // 获取消息预览内容
  String getPreviewContent() {
    if (lastContent != null && lastContent!.isNotEmpty) {
      if (lastContent!.length > 50) {
        return lastContent!.substring(0, 47) + '...';
      }
      return lastContent!;
    }

    // 尝试从内容中提取预览
    if (type == MessageType.commentReply.toString() || type == MessageType.postReply.toString()) {
      final parts = content.split('收到了新回复: ');
      if (parts.length > 1) {
        final extractedContent = parts[1];
        if (extractedContent.length > 50) {
          return extractedContent.substring(0, 47) + '...';
        }
        return extractedContent;
      }
    }

    // 如果无法提取特定内容，使用原始内容的截断
    if (content.length > 50) {
      return content.substring(0, 47) + '...';
    }
    return content;
  }

  // 判断是否为分组消息
  bool get isGrouped => (groupCount != null && groupCount! > 1);

  // 获取消息显示的时间（优先使用更新时间）
  DateTime get displayTime => updateTime ?? createTime;

  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    String? type,
    bool? isRead,
    DateTime? createTime,
    DateTime? readTime,
    String? gameId,
    String? postId,
    int? groupCount,
    List<String>? references,
    String? lastContent,
    DateTime? updateTime,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createTime: createTime ?? this.createTime,
      readTime: readTime ?? this.readTime,
      gameId: gameId ?? this.gameId,
      postId: postId ?? this.postId,
      groupCount: groupCount ?? this.groupCount,
      references: references ?? this.references,
      lastContent: lastContent ?? this.lastContent,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}