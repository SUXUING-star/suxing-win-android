// lib/models/message.dart
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
    return Message(
      id: json['_id'].toHexString(),
      senderId: json['senderId'].toString(),
      recipientId: json['recipientId'].toString(),
      content: json['content'],
      type: json['type'],
      isRead: json['isRead'],
      createTime: json['createTime'],
      readTime: json['readTime'],
      gameId: json['gameId']?.toHexString(),
      postId: json['postId']?.toHexString(),
    );
  }

  static Map<String, dynamic> createCommentReplyMessage({
    required String senderId,
    required String recipientId,
    required String gameTitle,
    required String gameId,
    required String content,
  }) {
    return {
      'senderId': ObjectId.fromHexString(senderId),
      'recipientId': ObjectId.fromHexString(recipientId),
      'content': '你在游戏"$gameTitle"的评论收到了新回复: $content',
      'type': MessageType.commentReply.toString(),
      'isRead': false,
      'createTime': DateTime.now(),
      'readTime': null,
      'gameId': ObjectId.fromHexString(gameId),
    };
  }

  static Map<String, dynamic> createPostReplyMessage({
    required String senderId,
    required String recipientId,
    required String postTitle,
    required String postId,
    required String content,
  }) {
    return {
      'senderId': ObjectId.fromHexString(senderId),
      'recipientId': ObjectId.fromHexString(recipientId),
      'content': '你的帖子"$postTitle"收到了新回复: $content',
      'type': MessageType.postReply.toString(),
      'isRead': false,
      'createTime': DateTime.now(),
      'readTime': null,
      'postId': ObjectId.fromHexString(postId),
    };
  }
}