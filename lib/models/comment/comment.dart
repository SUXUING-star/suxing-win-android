// lib/models/comment.dart
import 'package:mongo_dart/mongo_dart.dart';

class Comment {
  final String id;
  final String gameId;
  final String userId;
  final String content;
  final DateTime createTime;
  final DateTime updateTime;
  final bool isEdited;
  final String username;
  final String? parentId;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.content,
    required this.createTime,
    required this.updateTime,
    required this.isEdited,
    required this.username,
    this.parentId,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  factory Comment.fromJson(Map<String, dynamic> json) {
    String commentId = json['_id'] is ObjectId
        ? json['_id'].toHexString()
        : (json['_id']?.toString() ?? json['id']?.toString() ?? '');

    String gameId = json['gameId'] is ObjectId
        ? json['gameId'].toHexString()
        : json['gameId']?.toString() ?? '';

    String userId = json['userId'] is ObjectId
        ? json['userId'].toHexString()
        : json['userId']?.toString() ?? '';

    String? parentId = json['parentId'] is ObjectId
        ? json['parentId'].toHexString()
        : json['parentId']?.toString();

    return Comment(
      id: commentId,
      gameId: gameId,
      userId: userId,
      content: json['content']?.toString() ?? '',
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime'] ?? DateTime.now().toIso8601String()),
      updateTime: json['updateTime'] is DateTime
          ? json['updateTime']
          : DateTime.parse(json['updateTime'] ?? DateTime.now().toIso8601String()),
      isEdited: json['isEdited'] ?? false,
      username: json['username']?.toString() ?? '',
      parentId: parentId,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => Comment.fromJson(reply))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'gameId': gameId,
      'userId': userId,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'isEdited': isEdited,
      'username': username,
      'parentId': parentId,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
}