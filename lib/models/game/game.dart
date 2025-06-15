// lib/models/game/game.dart
import 'package:flutter/cupertino.dart'; // Flutter UI 库
import 'package:suxingchahui/models/util_json.dart'; // MongoDB BSON ObjectId 和 Timestamp 类型

// GameStatus 类：定义游戏审批状态常量
@immutable
class GameStatus {
  static const String approved = "approved";
  static const String rejected = "rejected";
  static const String pending = "pending";
}

class Game {
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
      id: UtilJson.parseId(json['_id'] ?? json['id']),
      authorId: UtilJson.parseId(json['authorId']),
      title: UtilJson.parseStringSafely(json['title']),
      summary: UtilJson.parseStringSafely(json['summary']),
      description: UtilJson.parseStringSafely(json['description']),
      coverImage: UtilJson.parseStringSafely(json['coverImage']),
      images: UtilJson.parseListString(json['images']),
      category: UtilJson.parseStringSafely(json['category']),
      tags: UtilJson.parseListString(json['tags']),
      rating: UtilJson.parseDoubleSafely(json['rating']),
      totalRatingSum: UtilJson.parseDoubleSafely(json['totalRatingSum']),
      ratingCount: UtilJson.parseIntSafely(json['ratingCount']),
      ratingUpdateTime:
          UtilJson.parseNullableDateTime(json['ratingUpdateTime']),
      createTime: UtilJson.parseDateTime(json['createTime']),
      updateTime: UtilJson.parseDateTime(json['updateTime']),
      viewCount: UtilJson.parseIntSafely(json['viewCount']),
      likeCount: UtilJson.parseIntSafely(json['likeCount']),
      coinsCount: UtilJson.parseIntSafely(json['coinsCount']),
      downloadLinks: UtilJson.parseGameDownloadLinks(json['downloadLinks']),
      externalLinks: UtilJson.parseGameExternalLinks(json['externalLinks']),
      musicUrl: UtilJson.parseNullableStringSafely(json['musicUrl']),
      bvid: UtilJson.parseNullableStringSafely(json['bvid']),
      lastViewedAt: UtilJson.parseNullableDateTime(json['lastViewedAt']),
      currentUserLastViewTime:
          UtilJson.parseNullableDateTime(json['currentUserLastViewTime']),
      wantToPlayCount: UtilJson.parseIntSafely(json['wantToPlayCount']),
      playingCount: UtilJson.parseIntSafely(json['playingCount']),
      playedCount: UtilJson.parseIntSafely(json['playedCount']),
      totalCollections: UtilJson.parseIntSafely(json['totalCollections']),
      collectionUpdateTime:
          UtilJson.parseNullableDateTime(json['collectionUpdateTime']),
      approvalStatus:
          UtilJson.parseNullableStringSafely(json['approvalStatus']),
      reviewComment: UtilJson.parseNullableStringSafely(json['reviewComment']),
      reviewedAt: UtilJson.parseNullableDateTime(json['reviewedAt']),
      reviewedBy: UtilJson.parseId(json['reviewedBy']),
    );
  }

  // 将 Game 对象转换为完整 JSON 格式 (通常用于接收后端响应或保存完整数据)
  Map<String, dynamic> toJson() {
    return {
      '_id': id, // 匹配后端 _id 字段
      'authorId': authorId,
      'title': title,
      'summary': summary,
      'description': description,
      'coverImage': coverImage,
      'images': images,
      'category': category,
      'tags': tags,
      'rating': rating,
      'totalRatingSum': totalRatingSum,
      'ratingCount': ratingCount,
      'ratingUpdateTime': ratingUpdateTime?.toIso8601String(),
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      "coinsCount": coinsCount,
      'downloadLinks': downloadLinks.map((link) => link.toJson()).toList(),
      'externalLinks': externalLinks.map((link) => link.toJson()).toList(),
      'musicUrl': musicUrl,
      'bvid': bvid,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      'currentUserLastViewTime':
          currentUserLastViewTime?.toIso8601String(), // 前端特有字段
      'wantToPlayCount': wantToPlayCount,
      'playingCount': playingCount,
      'playedCount': playedCount,
      'totalCollections': totalCollections,
      'collectionUpdateTime': collectionUpdateTime?.toIso8601String(),
      'approvalStatus': approvalStatus,
      'reviewComment': reviewComment,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
    };
  }

  // 将 Game 对象转换为请求体 JSON 格式 (用于 addGame 或 updateGame 接口提交)
  // 只包含前端需要提交给后端的可编辑字段
  Map<String, dynamic> toRequestJson() {
    return {
      // id和authorId在创建时由后端生成，更新时可能通过URL参数传递，所以请求体中通常不需要
      // 'id': id, // 更新时可能需要，但通常放URL或单独字段
      // 'authorId': authorId, // 创建时前端可能已知，更新时不变
      'title': title,
      'summary': summary,
      'description': description,
      'coverImage': coverImage,
      'images': images,
      'category': category,
      'tags': tags,
      'downloadLinks': downloadLinks.map((link) => link.toJson()).toList(),
      'externalLinks': externalLinks.map((link) => link.toJson()).toList(),
      'musicUrl': musicUrl ?? "", // String?
      'bvid': bvid ?? "", // String?
      // 'rating' 等统计字段由后端计算，'createTime', 'updateTime' 由后端管理
      // 'approvalStatus', 'reviewComment', 'reviewedAt', 'reviewedBy' 由管理员操作，前端普通用户提交不需要
    };
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
  final String id;
  final String title;
  final String description;
  final String url;

  const GameDownloadLink({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameDownloadLink.fromJson(Map<String, dynamic> json) {
    return GameDownloadLink(
      id: UtilJson.parseStringSafely(json['id']),
      title: UtilJson.parseStringSafely(json['title']),
      description: UtilJson.parseStringSafely(json['description']),
      url: UtilJson.parseStringSafely(json['url']),
    );
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
    };
  }

  // 创建一个空的 GameDownloadLink 对象
  static GameDownloadLink empty() {
    return GameDownloadLink(
      id: '',
      title: '',
      description: '',
      url: '',
    );
  }
}

// 游戏关联链接模型
@immutable
class GameExternalLink {
  final String title;
  final String url;

  const GameExternalLink({
    required this.title,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameExternalLink.fromJson(Map<String, dynamic> json) {
    return GameExternalLink(
      title: UtilJson.parseStringSafely(json['title']),
      url: UtilJson.parseStringSafely(json['url']),
    );
  }

  // 将 GameDownloadLink 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
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
