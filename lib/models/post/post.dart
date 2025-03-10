// lib/models/post.dart
import 'package:mongo_dart/mongo_dart.dart';
enum PostStatus {
  active,
  locked,
  deleted
}

class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime createTime;
  final DateTime updateTime;
  final int viewCount;
  final int replyCount;
  final List<String> tags;
  final PostStatus status;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createTime,
    required this.updateTime,
    this.viewCount = 0,
    this.replyCount = 0,
    this.tags = const [],
    this.status = PostStatus.active,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // 处理 MongoDB 的 _id 字段
    String postId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return Post(
      id: postId,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime']),
      updateTime: json['updateTime'] is DateTime
          ? json['updateTime']
          : DateTime.parse(json['updateTime']),
      viewCount: json['viewCount']?.toInt() ?? 0,
      replyCount: json['replyCount']?.toInt() ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      status: PostStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => PostStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'viewCount': viewCount,
      'replyCount': replyCount,
      'tags': tags,
      'status': status.toString().split('.').last,
    };
  }
}

enum ReplyStatus {
  active,
  deleted
}

// In post.dart

class Reply {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String? parentId;
  final DateTime createTime;
  final DateTime updateTime;
  final ReplyStatus status;

  Reply({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    this.parentId,
    required this.createTime,
    required this.updateTime,
    this.status = ReplyStatus.active,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    String replyId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return Reply(
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
      status: ReplyStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => ReplyStatus.active,
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
      print('Error in Reply.toMongoDocument(): $e');
      rethrow;
    }
  }
}