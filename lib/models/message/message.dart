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
    };
  }
  // 添加到 Message 类中
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
    );
  }
}