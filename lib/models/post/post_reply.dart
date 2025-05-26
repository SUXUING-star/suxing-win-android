// lib/models/post/post_reply.dart
import 'package:mongo_dart/mongo_dart.dart';

enum PostReplyStatus {
  active,
  deleted,
}

class PostReply {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String? parentId;
  final DateTime createTime;
  final DateTime updateTime;
  final PostReplyStatus status;

  PostReply({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    this.parentId,
    required this.createTime,
    required this.updateTime,
    this.status = PostReplyStatus.active,
  });

  factory PostReply.fromJson(Map<String, dynamic> json) {
    String replyId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return PostReply(
      id: replyId,
      postId: json['postId']?.toString() ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime']),
      updateTime: json['updateTime'] is DateTime
          ? json['updateTime']
          : DateTime.parse(json['updateTime']),
      status: PostReplyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PostReplyStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'parentId': parentId,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  // 添加一个新方法用于转换为 MongoDB 文档
  Map<String, dynamic> toMongoDocument() {
    try {
      return {
        '_id': id.isEmpty ? ObjectId() : ObjectId.fromHexString(id),
        'postId': ObjectId.fromHexString(postId),
        'content': content,
        'authorId': ObjectId.fromHexString(authorId),
        'parentId': parentId != null ? ObjectId.fromHexString(parentId!) : null,
        'createTime': createTime,
        'updateTime': updateTime,
        'status': status.toString().split('.').last,
      };
    } catch (e) {
      // print('Error in Reply.toMongoDocument(): $e');
      rethrow;
    }
  }

  // UI 判断是否编辑过
  bool get hasBeenEdited {
    const Duration tolerance = Duration(seconds: 1);
    return updateTime.difference(createTime).abs() > tolerance;
  }
}
