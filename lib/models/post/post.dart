// lib/models/post/post.dart

// PostStatus 枚举：定义帖子状态
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

enum PostStatus {
  active, // 活跃
  locked, // 锁定
  deleted // 删除
}

@immutable
class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime createTime;
  final DateTime updateTime; // 更新时间
  final DateTime? lastViewedAt; // 最后浏览时间
  final int viewCount; // 浏览量
  final int replyCount; // 评论量
  final int likeCount; // 点赞数
  final int agreeCount; // 赞成数
  final int favoriteCount; // 收藏数
  final List<String> tags; // 标签
  final bool isPinned; // 帖子是否被置顶  <-- 添加这一行
  final PostStatus status; // 状态

  // 前端特定字段：当前用户最后浏览时间，用于历史记录展示
  final DateTime? currentUserLastViewTime;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createTime,
    required this.updateTime,
    this.lastViewedAt,
    this.viewCount = 0,
    this.replyCount = 0,
    this.likeCount = 0,
    this.agreeCount = 0,
    this.favoriteCount = 0,
    this.tags = const [],
    required this.isPinned,
    this.status = PostStatus.active,
    this.currentUserLastViewTime, // 前端特有字段
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: UtilJson.parseId(json['_id'] ?? json['id']),
      title: UtilJson.parseStringSafely(json['title']),
      content: UtilJson.parseStringSafely(json['content']),
      authorId: UtilJson.parseId(json['authorId']),
      createTime: UtilJson.parseDateTime(json['createTime']),
      updateTime: UtilJson.parseDateTime(json['updateTime']),
      lastViewedAt: UtilJson.parseNullableDateTime(json['lastViewedAt']),
      viewCount: UtilJson.parseIntSafely(json['viewCount']),
      replyCount: UtilJson.parseIntSafely(json['replyCount']),
      likeCount: UtilJson.parseIntSafely(json['likeCount']),
      agreeCount: UtilJson.parseIntSafely(json['agreeCount']),
      favoriteCount: UtilJson.parseIntSafely(json['favoriteCount']),
      tags: UtilJson.parseListString(json['tags']),
      isPinned: UtilJson.parseBoolSafely(json['isPinned']),
      // 业务逻辑: 从字符串安全解析枚举类型，如果匹配失败则使用默认值 PostStatus.active
      status: PostStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PostStatus.active,
      ),
      currentUserLastViewTime:
          UtilJson.parseNullableDateTime(json['currentUserLastViewTime']),
    );
  }

  // 将 Post 对象转换为完整 JSON 格式 (通常用于接收后端响应或保存完整数据)
  Map<String, dynamic> toJson() {
    return {
      '_id': id, // 匹配后端 _id 字段
      'title': title,
      'content': content,
      'authorId': authorId,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      'viewCount': viewCount,
      'replyCount': replyCount,
      'likeCount': likeCount,
      'agreeCount': agreeCount,
      'favoriteCount': favoriteCount,
      'tags': tags,
      'isPinned': isPinned,
      'status': status.toString().split('.').last,
      'currentUserLastViewTime':
          currentUserLastViewTime?.toIso8601String(), // 前端特有字段
    };
  }

  // 将 Post 对象转换为请求体 JSON 格式 (用于 addPost 或 updatePost 接口提交)
  // 只包含前端需要提交给后端的可编辑字段
  Map<String, dynamic> toRequestJson() {
    return {
      // id, authorId, createTime, updateTime, 各类计数和状态通常由后端管理
      // 'id': id, // 更新时可能需要，但通常在URL路径中
      // 'authorId': authorId, // 创建时可提交，更新时通常不变或由后端验证
      'title': title,
      'content': content,
      'tags': tags,
      // 'status': status.toString().split('.').last, // 状态一般由管理员更改，普通用户提交不包含
    };
  }

  // 创建一个空的 Post 对象
  static Post empty() {
    return Post(
      id: '',
      title: '',
      content: '',
      authorId: '',
      createTime: DateTime.fromMillisecondsSinceEpoch(0),
      updateTime: DateTime.fromMillisecondsSinceEpoch(0),
      lastViewedAt: null,
      viewCount: 0,
      replyCount: 0,
      likeCount: 0,
      agreeCount: 0,
      favoriteCount: 0,
      tags: [],
      isPinned: false,
      status: PostStatus.active,
      currentUserLastViewTime: null, // 前端特有字段空值
    );
  }

  // 复制并更新 Post 对象部分字段
  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    DateTime? createTime,
    DateTime? updateTime,
    DateTime? lastViewedAt,
    int? viewCount,
    int? replyCount,
    int? likeCount,
    int? agreeCount,
    int? favoriteCount,
    List<String>? tags,
    bool? isPinned,
    PostStatus? status,
    DateTime? currentUserLastViewTime,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      viewCount: viewCount ?? this.viewCount,
      replyCount: replyCount ?? this.replyCount,
      likeCount: likeCount ?? this.likeCount,
      agreeCount: agreeCount ?? this.agreeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
      currentUserLastViewTime:
          currentUserLastViewTime ?? this.currentUserLastViewTime, // 前端特有字段
    );
  }
}
