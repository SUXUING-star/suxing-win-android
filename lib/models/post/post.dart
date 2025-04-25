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
  final int likeCount;       // 点赞总数
  final int agreeCount;      // 赞成总数
  final int favoriteCount;   // 收藏总数
  final List<String> tags;
  final PostStatus status;

  // 移除了 isLiked, isAgreed, isFavorited

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createTime,
    required this.updateTime,
    this.viewCount = 0,
    this.replyCount = 0,
    this.likeCount = 0,
    this.agreeCount = 0,
    this.favoriteCount = 0,
    this.tags = const [],
    this.status = PostStatus.active,
    // 移除了构造函数中的 isLiked 等
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    String postId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    // 不再尝试解析 userActions
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
      likeCount: json['likeCount']?.toInt() ?? 0,
      agreeCount: json['agreeCount']?.toInt() ?? 0,
      favoriteCount: json['favoriteCount']?.toInt() ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      status: PostStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => PostStatus.active,
      ),
      // 不再设置 isLiked 等
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'viewCount': viewCount,
      'replyCount': replyCount,
      'likeCount': likeCount,
      'agreeCount': agreeCount,
      'favoriteCount': favoriteCount,
      'tags': tags,
      'status': status.toString().split('.').last,
      // 不再包含 isLiked 等
    };
  }

  Post copyWith({ // 移除 isLiked 等参数
    String? id,
    String? title,
    String? content,
    String? authorId,
    DateTime? createTime,
    DateTime? updateTime,
    int? viewCount,
    int? replyCount,
    int? likeCount,
    int? agreeCount,
    int? favoriteCount,
    List<String>? tags,
    PostStatus? status,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      viewCount: viewCount ?? this.viewCount,
      replyCount: replyCount ?? this.replyCount,
      likeCount: likeCount ?? this.likeCount,
      agreeCount: agreeCount ?? this.agreeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }
}

// Reply 模型保持不变...
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