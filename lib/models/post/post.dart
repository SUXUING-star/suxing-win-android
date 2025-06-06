// lib/models/post/post.dart

// PostStatus 枚举：定义帖子状态
enum PostStatus {
  active, // 活跃
  locked, // 锁定
  deleted // 删除
}

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

  Post({
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

  // 安全解析日期时间
  static DateTime _parseDateTimeSafely(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 默认值
    }
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // 兼容 Go 的零值时间 "0001-01-01T00:00:00Z"
        if (value == "0001-01-01T00:00:00Z" || value.startsWith("0001-01-01")) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 零值视为默认值
        }
        return DateTime.parse(value).toLocal(); // 解析为本地时间
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 错误回退
      }
    }
    // 假设也可能是毫秒时间戳
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 错误回退
  }

  // 安全解析可空日期时间
  static DateTime? _parseNullableDateTimeSafely(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // 兼容 Go 的零值时间 "0001-01-01T00:00:00Z"
      if (value == "0001-01-01T00:00:00Z" || value.startsWith("0001-01-01")) {
        return null; // Go的零值时间视为null
      }
    }
    try {
      return _parseDateTimeSafely(value);
    } catch (_) {
      return null;
    }
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    // 解析 _id 或 id 字段
    String postId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = List<String>.from(json['tags'].map((tag) => tag.toString()));
    }
    // 安全解析 isPinned 字段 <-- 添加这一段解析逻辑
    bool isPinnedValue = false; // 默认值
    if (json['isPinned'] != null) {
      if (json['isPinned'] is bool) {
        isPinnedValue = json['isPinned'] as bool;
      } else if (json['isPinned'] is int) {
        isPinnedValue = (json['isPinned'] as int) != 0; // 兼容 int 0/1 转 bool
      } else if (json['isPinned'] is String) {
        isPinnedValue = json['isPinned'].toLowerCase() ==
            'true'; // 兼容 string "true"/"false" 转 bool
      }
    }

    return Post(
      id: postId,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      createTime: _parseDateTimeSafely(json['createTime']),
      updateTime: _parseDateTimeSafely(json['updateTime']),
      lastViewedAt: _parseNullableDateTimeSafely(json['lastViewedAt']),
      viewCount: json['viewCount']?.toInt() ?? 0,
      replyCount: json['replyCount']?.toInt() ?? 0,
      likeCount: json['likeCount']?.toInt() ?? 0,
      agreeCount: json['agreeCount']?.toInt() ?? 0,
      favoriteCount: json['favoriteCount']?.toInt() ?? 0,
      tags: parsedTags,
      isPinned: isPinnedValue,
      status: PostStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PostStatus.active, // 默认状态
      ),
      currentUserLastViewTime: _parseNullableDateTimeSafely(
          json['currentUserLastViewTime']), // 前端特有字段
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
