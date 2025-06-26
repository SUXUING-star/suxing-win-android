// lib/models/game/game.dart
import 'package:flutter/cupertino.dart'; // Flutter UI 库
import 'package:suxingchahui/models/util_json.dart'; // MongoDB BSON ObjectId 和 Timestamp 类型

enum WatchGameListScope {
  all,
  tag,
  category,
  author,
  myGames,
}

class Game {
  /// 汉化分类常量。
  static const String categoryTranslated = '汉化';

  /// 生肉分类常量。
  static const String categoryOriginal = '生肉';

  /// 默认游戏分类列表。
  static const List<String> defaultGameCategory = [
    categoryOriginal,
    categoryTranslated
  ];

  /// 默认筛选选项 Map。
  static const Map<String, String> defaultFilter = {
    Game.sortByCreateTime: '最新发布',
    Game.sortByUpdateTime: '最近更新',
    Game.sortByViewCount: '最多浏览',
    Game.sortByRating: '最高评分'
  };

  // 审核状态枚举
  static const String gameStatusApproved = "approved";
  static const String gameStatusRejected = "rejected";
  static const String gameStatusPending = "pending";

  static const String sortByCreateTime = Game.jsonKeyCreateTime;
  static const String sortByUpdateTime = Game.jsonKeyUpdateTime;
  static const String sortByRating = Game.jsonKeyRating;
  static const String sortByViewCount = Game.jsonKeyViewCount;
  static const String sortByLastViewedAt = Game.jsonKeyLastViewedAt;

  // gameListScope
  static const String gameListScopeAuthor = "author";
  static const String gameListScopeAll = "all";

  // 提取 JSON 字段名为 static const String 常量，使用驼峰命名（camelCase）
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id'; // MongoDB 默认的 _id 字段
  static const String jsonKeyAuthorId = 'authorId';
  static const String jsonKeyTitle = 'title';
  static const String jsonKeySummary = 'summary';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyCoverImage = 'coverImage';
  static const String jsonKeyImages = 'images';
  static const String jsonKeyCategory = 'category';
  static const String jsonKeyTags = 'tags';
  static const String jsonKeyRating = 'rating';
  static const String jsonKeyTotalRatingSum = 'totalRatingSum';
  static const String jsonKeyRatingCount = 'ratingCount';
  static const String jsonKeyRatingUpdateTime = 'ratingUpdateTime';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeyViewCount = 'viewCount';
  static const String jsonKeyLikeCount = 'likeCount';
  static const String jsonKeyCoinsCount = 'coinsCount';
  static const String jsonKeyDownloadLinks = 'downloadLinks';
  static const String jsonKeyExternalLinks = 'externalLinks';
  static const String jsonKeyMusicUrl = 'musicUrl';
  static const String jsonKeyBvid = 'bvid';
  static const String jsonKeyLastViewedAt = 'lastViewedAt';
  static const String jsonKeyCurrentUserLastViewTime =
      'currentUserLastViewTime';
  static const String jsonKeyWantToPlayCount = 'wantToPlayCount';
  static const String jsonKeyPlayingCount = 'playingCount';
  static const String jsonKeyPlayedCount = 'playedCount';
  static const String jsonKeyTotalCollections = 'totalCollections';
  static const String jsonKeyCollectionUpdateTime = 'collectionUpdateTime';
  static const String jsonKeyApprovalStatus = 'approvalStatus';
  static const String jsonKeyReviewComment = 'reviewComment';
  static const String jsonKeyReviewedAt = 'reviewedAt';
  static const String jsonKeyReviewedBy = 'reviewedBy';

  final String id;
  final String authorId;
  final String title;
  final String summary;
  final String description;
  final String coverImage;
  final List<String> images;
  final String category;
  final List<String> tags;
  final double rating;
  final double totalRatingSum; // 所有评分的总和
  final int ratingCount; // 提供评分的人数
  final DateTime? ratingUpdateTime; // 评分统计最后更新时间

  final DateTime createTime;
  final DateTime updateTime;
  final int viewCount;
  final int likeCount;
  final int coinsCount;
  final List<GameDownloadLink> downloadLinks;
  final List<GameExternalLink> externalLinks;
  final String? musicUrl; // 游戏音乐URL
  final String? bvid; // 关联B站视频ID
  final DateTime? lastViewedAt; // 游戏本身最后查看时间

  // 前端特定字段：当前用户最后浏览时间，用于历史记录展示
  final DateTime? currentUserLastViewTime;

  final int wantToPlayCount; // 想玩人数
  final int playingCount; // 正在玩人数
  final int playedCount; // 已玩人数
  final int totalCollections; // 总收藏人数
  final DateTime? collectionUpdateTime; // 收藏统计最后更新时间

  final String? approvalStatus; // 审批状态: "pending", "approved", "rejected"
  final String? reviewComment; // 生产反馈
  final DateTime? reviewedAt; // 审核时间
  final String? reviewedBy; // 审核管理员ID

  Game({
    required this.id, // ID通常是必须的
    required this.authorId, // 作者ID通常是必须的
    required this.title,
    required this.summary,
    required this.description,
    required this.coverImage,
    required this.images,
    required this.category,
    List<String>? tags,
    this.rating = 0.0, // 评分可以有默认值
    this.totalRatingSum = 0.0, // 后端生成，给默认值
    this.ratingCount = 0, // 后端生成，给默认值
    this.ratingUpdateTime, // 后端生成，可空
    required this.createTime, // 创建时间通常必须有
    required this.updateTime, // 更新时间通常必须有
    this.viewCount = 0, // 后端生成，给默认值
    this.likeCount = 0, // 后端生成，给默认值
    this.coinsCount = 0,
    List<GameDownloadLink>? downloadLinks, // 可能为空
    List<GameExternalLink>? externalLinks,
    this.musicUrl,
    this.bvid,
    this.lastViewedAt,
    this.currentUserLastViewTime, // 前端特有字段，可空
    this.wantToPlayCount = 0, // 后端生成，给默认值
    this.playingCount = 0, // 后端生成，给默认值
    this.playedCount = 0, // 后端生成，给默认值
    this.totalCollections = 0, // 后端生成，给默认值
    this.collectionUpdateTime, // 后端生成，可空
    this.approvalStatus, // 后端生成，可空
    this.reviewComment, // 后端生成，可空
    this.reviewedAt, // 后端生成，可空
    this.reviewedBy, // 后端生成，可空
  })  : tags = tags ?? [],
        downloadLinks = downloadLinks ?? [],
        externalLinks = externalLinks ?? [];

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: UtilJson.parseId(json[jsonKeyMongoId] ?? json[jsonKeyId]),
      authorId: UtilJson.parseId(json[jsonKeyAuthorId]),
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      summary: UtilJson.parseStringSafely(json[jsonKeySummary]),
      description: UtilJson.parseStringSafely(json[jsonKeyDescription]),
      coverImage: UtilJson.parseStringSafely(json[jsonKeyCoverImage]),
      images: UtilJson.parseListString(json[jsonKeyImages]),
      category: UtilJson.parseStringSafely(json[jsonKeyCategory]),
      tags: UtilJson.parseListString(json[jsonKeyTags]),
      rating: UtilJson.parseDoubleSafely(json[jsonKeyRating]),
      totalRatingSum: UtilJson.parseDoubleSafely(json[jsonKeyTotalRatingSum]),
      ratingCount: UtilJson.parseIntSafely(json[jsonKeyRatingCount]),
      ratingUpdateTime:
          UtilJson.parseNullableDateTime(json[jsonKeyRatingUpdateTime]),
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]),
      updateTime: UtilJson.parseDateTime(json[jsonKeyUpdateTime]),
      viewCount: UtilJson.parseIntSafely(json[jsonKeyViewCount]),
      likeCount: UtilJson.parseIntSafely(json[jsonKeyLikeCount]),
      coinsCount: UtilJson.parseIntSafely(json[jsonKeyCoinsCount]),
      downloadLinks:
          UtilJson.parseGameDownloadLinks(json[jsonKeyDownloadLinks]),
      externalLinks:
          UtilJson.parseGameExternalLinks(json[jsonKeyExternalLinks]),
      musicUrl: UtilJson.parseNullableStringSafely(json[jsonKeyMusicUrl]),
      bvid: UtilJson.parseNullableStringSafely(json[jsonKeyBvid]),
      lastViewedAt: UtilJson.parseNullableDateTime(json[jsonKeyLastViewedAt]),
      currentUserLastViewTime:
          UtilJson.parseNullableDateTime(json[jsonKeyCurrentUserLastViewTime]),
      wantToPlayCount: UtilJson.parseIntSafely(json[jsonKeyWantToPlayCount]),
      playingCount: UtilJson.parseIntSafely(json[jsonKeyPlayingCount]),
      playedCount: UtilJson.parseIntSafely(json[jsonKeyPlayedCount]),
      totalCollections: UtilJson.parseIntSafely(json[jsonKeyTotalCollections]),
      collectionUpdateTime:
          UtilJson.parseNullableDateTime(json[jsonKeyCollectionUpdateTime]),
      approvalStatus:
          UtilJson.parseNullableStringSafely(json[jsonKeyApprovalStatus]),
      reviewComment:
          UtilJson.parseNullableStringSafely(json[jsonKeyReviewComment]),
      reviewedAt: UtilJson.parseNullableDateTime(json[jsonKeyReviewedAt]),
      reviewedBy: UtilJson.parseId(json[jsonKeyReviewedBy]),
    );
  }

  // 将 Game 对象转换为完整 JSON 格式 (通常用于接收后端响应或保存完整数据)
  Map<String, dynamic> toJson() {
    return {
      jsonKeyMongoId: id, // 匹配后端 _id 字段
      jsonKeyAuthorId: authorId,
      jsonKeyTitle: title,
      jsonKeySummary: summary,
      jsonKeyDescription: description,
      jsonKeyCoverImage: coverImage,
      jsonKeyImages: images,
      jsonKeyCategory: category,
      jsonKeyTags: tags,
      jsonKeyRating: rating,
      jsonKeyTotalRatingSum: totalRatingSum,
      jsonKeyRatingCount: ratingCount,
      jsonKeyRatingUpdateTime: ratingUpdateTime?.toIso8601String(),
      jsonKeyCreateTime: createTime.toIso8601String(),
      jsonKeyUpdateTime: updateTime.toIso8601String(),
      jsonKeyViewCount: viewCount,
      jsonKeyLikeCount: likeCount,
      jsonKeyCoinsCount: coinsCount,
      jsonKeyDownloadLinks: downloadLinks.map((link) => link.toJson()).toList(),
      jsonKeyExternalLinks: externalLinks.map((link) => link.toJson()).toList(),
      jsonKeyMusicUrl: musicUrl,
      jsonKeyBvid: bvid,
      jsonKeyLastViewedAt: lastViewedAt?.toIso8601String(),
      jsonKeyCurrentUserLastViewTime:
          currentUserLastViewTime?.toIso8601String(), // 前端特有字段
      jsonKeyWantToPlayCount: wantToPlayCount,
      jsonKeyPlayingCount: playingCount,
      jsonKeyPlayedCount: playedCount,
      jsonKeyTotalCollections: totalCollections,
      jsonKeyCollectionUpdateTime: collectionUpdateTime?.toIso8601String(),
      jsonKeyApprovalStatus: approvalStatus,
      jsonKeyReviewComment: reviewComment,
      jsonKeyReviewedAt: reviewedAt?.toIso8601String(),
      jsonKeyReviewedBy: reviewedBy,
    };
  }

  // 将 Game 对象转换为请求体 JSON 格式 (用于 addGame 或 updateGame 接口提交)
  // 只包含前端需要提交给后端的可编辑字段
  Map<String, dynamic> toRequestJson() {
    return {
      // id和authorId在创建时由后端生成，更新时可能通过URL参数传递，所以请求体中通常不需要
      // 'id': id, // 更新时可能需要，但通常放URL或单独字段
      // 'authorId': authorId, // 创建时前端可能已知，更新时不变
      jsonKeyTitle: title,
      jsonKeySummary: summary,
      jsonKeyDescription: description,
      jsonKeyCoverImage: coverImage,
      jsonKeyImages: images,
      jsonKeyCategory: category,
      jsonKeyTags: tags,
      jsonKeyDownloadLinks: downloadLinks.map((link) => link.toJson()).toList(),
      jsonKeyExternalLinks: externalLinks.map((link) => link.toJson()).toList(),
      jsonKeyMusicUrl: musicUrl ?? "", // String?
      jsonKeyBvid: bvid ?? "", // String?
      // 'rating' 等统计字段由后端计算，'createTime', 'updateTime' 由后端管理
      // 'approvalStatus', 'reviewComment', 'reviewedAt', 'reviewedBy' 由管理员操作，前端普通用户提交不需要
    };
  }

  static List<Game> fromListJson(dynamic json) {
    if (json is! List) {
      return [];
    }

    return UtilJson.parseObjectList<Game>(
        json, (listJson) => Game.fromJson(listJson));
  }

  // 创建一个空的 Game 对象
  static Game empty() {
    return Game(
      id: '',
      authorId: '',
      title: '',
      summary: '',
      description: '',
      coverImage: '',
      images: [],
      category: '',
      tags: [],
      rating: 0.0,
      totalRatingSum: 0.0,
      ratingCount: 0,
      ratingUpdateTime: null,
      createTime: DateTime.fromMillisecondsSinceEpoch(0),
      updateTime: DateTime.fromMillisecondsSinceEpoch(0),
      viewCount: 0,
      likeCount: 0,
      coinsCount: 0,
      downloadLinks: [],
      externalLinks: [],
      musicUrl: null,
      bvid: null,
      lastViewedAt: null,
      currentUserLastViewTime: null, // 前端特有字段空值
      wantToPlayCount: 0,
      playingCount: 0,
      playedCount: 0,
      totalCollections: 0,
      collectionUpdateTime: null,
      approvalStatus: null,
      reviewComment: null,
      reviewedAt: null,
      reviewedBy: null,
    );
  }

  Game afterResubmit() {
    return copyWith(
      approvalStatus: gameStatusPending,
      reviewComment: '',
      reviewedAt: null,
      reviewedBy: null,
      updateTime: DateTime.now(),
    );
  }

  // 复制并更新 Game 对象部分字段
  Game copyWith({
    String? id,
    String? authorId,
    String? title,
    String? summary,
    String? description,
    String? coverImage,
    List<String>? images,
    String? category,
    List<String>? tags,
    double? rating,
    double? totalRatingSum,
    int? ratingCount,
    DateTime? ratingUpdateTime,
    DateTime? createTime,
    DateTime? updateTime,
    int? viewCount,
    int? likeCount,
    int? coinsCount,
    List<GameDownloadLink>? downloadLinks,
    List<GameExternalLink>? externalLinks,
    String? musicUrl,
    ValueGetter<String?>? bvid,
    DateTime? lastViewedAt,
    DateTime? currentUserLastViewTime, // 前端特有字段
    int? wantToPlayCount,
    int? playingCount,
    int? playedCount,
    int? totalCollections,
    DateTime? collectionUpdateTime,
    String? approvalStatus,
    String? reviewComment,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return Game(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      totalRatingSum: totalRatingSum ?? this.totalRatingSum,
      ratingCount: ratingCount ?? this.ratingCount,
      ratingUpdateTime: ratingUpdateTime ?? this.ratingUpdateTime,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      coinsCount: coinsCount ?? this.coinsCount,
      downloadLinks: downloadLinks ?? this.downloadLinks,
      externalLinks: externalLinks ?? this.externalLinks,
      musicUrl: musicUrl ?? this.musicUrl,
      bvid: bvid != null ? bvid() : this.bvid,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      currentUserLastViewTime:
          currentUserLastViewTime ?? this.currentUserLastViewTime, // 前端特有字段
      wantToPlayCount: wantToPlayCount ?? this.wantToPlayCount,
      playingCount: playingCount ?? this.playingCount,
      playedCount: playedCount ?? this.playedCount,
      totalCollections: totalCollections ?? this.totalCollections,
      collectionUpdateTime: collectionUpdateTime ?? this.collectionUpdateTime,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}

// 游戏下载链接模型
@immutable
class GameDownloadLink {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyUrl = 'url';
  static const String jsonKeyUserId = 'userId';

  final String id;
  final String title;
  final String description;
  final String url;
  final String userId;

  const GameDownloadLink({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameDownloadLink.fromJson(Map<String, dynamic> json) {
    return GameDownloadLink(
      id: UtilJson.parseId(json[jsonKeyId]),
      userId: UtilJson.parseId(json[jsonKeyUserId]),
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      description: UtilJson.parseStringSafely(json[jsonKeyDescription]),
      url: UtilJson.parseStringSafely(json[jsonKeyUrl]),
    );
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id,
      jsonKeyUserId: userId,
      jsonKeyTitle: title,
      jsonKeyDescription: description,
      jsonKeyUrl: url,
    };
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toRequestJson() {
    return {
      jsonKeyTitle: title,
      jsonKeyDescription: description,
      jsonKeyUrl: url,
    };
  }

  // 创建一个空的 GameDownloadLink 对象
  static GameDownloadLink empty() {
    return GameDownloadLink(
      id: '',
      userId: '',
      title: '',
      description: '',
      url: '',
    );
  }
}

// 游戏关联链接模型
@immutable
class GameExternalLink {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyUrl = 'url';

  final String title;
  final String url;

  const GameExternalLink({
    required this.title,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameExternalLink.fromJson(Map<String, dynamic> json) {
    return GameExternalLink(
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      url: UtilJson.parseStringSafely(json[jsonKeyUrl]),
    );
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      jsonKeyTitle: title,
      jsonKeyUrl: url,
    };
  }

  // 创建一个空的 GameDownloadLink 对象
  static GameExternalLink empty() {
    return GameExternalLink(
      title: '',
      url: '',
    );
  }
}
