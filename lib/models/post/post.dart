// lib/models/post/post.dart

// PostStatus 枚举：定义帖子状态
import 'package:suxingchahui/models/util_json.dart';

enum PostStatus {
  active, // 活跃
  locked, // 锁定
  deleted // 删除
}

class Post {
  // 1. 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id'; // MongoDB 默认的 _id 字段
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyAuthorId = 'authorId';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeyLastViewedAt = 'lastViewedAt';
  static const String jsonKeyViewCount = 'viewCount';
  static const String jsonKeyReplyCount = 'replyCount';
  static const String jsonKeyLikeCount = 'likeCount';
  static const String jsonKeyAgreeCount = 'agreeCount';
  static const String jsonKeyFavoriteCount = 'favoriteCount';
  static const String jsonKeyTags = 'tags';
  static const String jsonKeyIsPinned = 'isPinned';
  static const String jsonKeyStatus = 'status';
  static const String jsonKeyCurrentUserLastViewTime =
      'currentUserLastViewTime';

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
  final bool isPinned; // 帖子是否被置顶
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

  // 2. 添加一个静态的查验接口函数
  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// Post 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'id' (或 '_id') 键，且其值为 [String] 类型。
  /// 3. 必须包含 'title' 键，且其值为 [String] 类型。
  /// 4. 必须包含 'content' 键，且其值为 [String] 类型。
  /// 5. 必须包含 'authorId' 键，且其值为 [String] 类型。
  /// 6. 必须包含 'createTime' 键，且其值为 [String] 类型。
  /// 7. 必须包含 'updateTime' 键，且其值为 [String] 类型。
  /// 8. 必须包含 'isPinned' 键，且其值为 [bool] 类型。
  /// 9. 必须包含 'status' 键，且其值为 [String] 类型。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 [Map<String, dynamic>]
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查核心字段的存在和类型
    // id (或 _id)
    final dynamic idData = json[jsonKeyId] ?? json[jsonKeyMongoId];
    if (idData is! String) {
      // id 必须是字符串
      return false;
    }
    // 标题
    if (json[jsonKeyTitle] is! String) {
      return false;
    }
    // 内容
    if (json[jsonKeyContent] is! String) {
      return false;
    }
    // 作者ID
    if (json[jsonKeyAuthorId] is! String) {
      return false;
    }
    // 创建时间
    if (json[jsonKeyCreateTime] is! String) {
      return false;
    }
    // 更新时间
    if (json[jsonKeyUpdateTime] is! String) {
      return false;
    }
    // 是否置顶
    if (json[jsonKeyIsPinned] is! bool) {
      return false;
    }
    // 状态
    if (json[jsonKeyStatus] is! String) {
      return false;
    }

    // 所有必要条件都满足
    return true;
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    // 在这里不再进行 isValidJson 检查和抛出异常，
    // 假定调用方已在外部进行了前置判断。
    return Post(
      id: UtilJson.parseId(json[jsonKeyMongoId] ?? json[jsonKeyId]), // 使用常量
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]), // 使用常量
      content: UtilJson.parseStringSafely(json[jsonKeyContent]), // 使用常量
      authorId: UtilJson.parseId(json[jsonKeyAuthorId]), // 使用常量
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
      updateTime: UtilJson.parseDateTime(json[jsonKeyUpdateTime]), // 使用常量
      lastViewedAt:
          UtilJson.parseNullableDateTime(json[jsonKeyLastViewedAt]), // 使用常量
      viewCount: UtilJson.parseIntSafely(json[jsonKeyViewCount]), // 使用常量
      replyCount: UtilJson.parseIntSafely(json[jsonKeyReplyCount]), // 使用常量
      likeCount: UtilJson.parseIntSafely(json[jsonKeyLikeCount]), // 使用常量
      agreeCount: UtilJson.parseIntSafely(json[jsonKeyAgreeCount]), // 使用常量
      favoriteCount:
          UtilJson.parseIntSafely(json[jsonKeyFavoriteCount]), // 使用常量
      tags: UtilJson.parseListString(json[jsonKeyTags]), // 使用常量
      isPinned: UtilJson.parseBoolSafely(json[jsonKeyIsPinned]), // 使用常量
      // 业务逻辑: 从字符串安全解析枚举类型，如果匹配失败则使用默认值 PostStatus.active
      status: PostStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json[jsonKeyStatus], // 使用常量
        orElse: () => PostStatus.active,
      ),
      currentUserLastViewTime: UtilJson.parseNullableDateTime(
          json[jsonKeyCurrentUserLastViewTime]), // 使用常量
    );
  }

  static List<Post> fromListJson(dynamic json) {
    if (json is! List) {
      return [];
    }

    return UtilJson.parseObjectList<Post>(
        json, (listJson) => Post.fromJson(listJson));
  }

  // 将 Post 对象转换为完整 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用常量
      jsonKeyTitle: title, // 使用常量
      jsonKeyContent: content, // 使用常量
      jsonKeyAuthorId: authorId, // 使用常量
      jsonKeyCreateTime: createTime.toIso8601String(), // 使用常量
      jsonKeyUpdateTime: updateTime.toIso8601String(), // 使用常量
      jsonKeyLastViewedAt: lastViewedAt?.toIso8601String(), // 使用常量
      jsonKeyViewCount: viewCount, // 使用常量
      jsonKeyReplyCount: replyCount, // 使用常量
      jsonKeyLikeCount: likeCount, // 使用常量
      jsonKeyAgreeCount: agreeCount, // 使用常量
      jsonKeyFavoriteCount: favoriteCount, // 使用常量
      jsonKeyTags: tags, // 使用常量
      jsonKeyIsPinned: isPinned, // 使用常量
      jsonKeyStatus: status.toString().split('.').last, // 使用常量
      jsonKeyCurrentUserLastViewTime:
          currentUserLastViewTime?.toIso8601String(), // 使用常量
    };
  }

  // 将 Post 对象转换为请求体 JSON 格式 (用于 addPost 或 updatePost 接口提交)
  // 只包含前端需要提交给后端的可编辑字段
  Map<String, dynamic> toRequestJson() {
    return {
      // id, authorId, createTime, updateTime, 各类计数和状态通常由后端管理
      // jsonKeyId: id, // 更新时可能需要，但通常在URL路径中
      // jsonKeyAuthorId: authorId, // 创建时可提交，更新时通常不变或由后端验证
      jsonKeyTitle: title, // 使用常量
      jsonKeyContent: content, // 使用常量
      jsonKeyTags: tags, // 使用常量
      // jsonKeyStatus: status.toString().split('.').last, // 状态一般由管理员更改，普通用户提交不包含
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
