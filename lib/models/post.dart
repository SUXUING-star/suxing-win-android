// lib/models/post.dart
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
  final String authorName;
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
    required this.authorName,
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
      authorName: json['authorName'] ?? '',
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
      'authorName': authorName,
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

class Reply {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final String? parentId;
  final DateTime createTime;
  final DateTime updateTime;
  final ReplyStatus status;

  Reply({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.parentId,
    required this.createTime,
    required this.updateTime,
    this.status = ReplyStatus.active,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    // 处理 MongoDB 的 _id 字段
    String replyId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return Reply(
      id: replyId,
      postId: json['postId'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      parentId: json['parentId'],
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
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'parentId': parentId,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}