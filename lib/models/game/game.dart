// lib/models/game/game.dart
import 'package:flutter/cupertino.dart'; // Flutter UI 库
import 'package:mongo_dart/mongo_dart.dart'
    show ObjectId, Timestamp; // MongoDB BSON ObjectId 和 Timestamp 类型

// GameStatus 类：定义游戏审批状态常量
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
  final List<String> likedBy;
  final List<GameDownloadLink> downloadLinks;
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
    List<String>? likedBy, // 后端生成，给默认值
    List<GameDownloadLink>? downloadLinks, // 可能为空
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
        likedBy = likedBy ?? [],
        downloadLinks = downloadLinks ?? [];

  factory Game.fromJson(Map<String, dynamic> json) {
    // 解析ID字段，处理 ObjectId 和普通字符串
    String parseId(dynamic idValue) {
      if (idValue == null) return '';
      return idValue is ObjectId ? idValue.oid : idValue.toString();
    }

    // 解析下载链接列表
    List<GameDownloadLink> parseDownloadLinks(dynamic links) {
      if (links == null || links is! List) return [];
      return links
          .map((link) => link is Map<String, dynamic>
              ? GameDownloadLink.fromJson(link)
              : null)
          .whereType<GameDownloadLink>()
          .toList();
    }

    // 解析标签列表
    List<String> parseTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is List) {
        return tags.map((tag) => tag.toString()).toList();
      }
      if (tags is String) {
        return tags.split(',').map((tag) => tag.trim()).toList();
      }
      return [];
    }

    // 安全解析 DateTime
    DateTime parseDateTime(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 默认值
      }
      if (dateValue is DateTime) return dateValue;
      if (dateValue is Timestamp) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue.seconds * 1000,
            isUtc: true);
      }
      try {
        return DateTime.parse(dateValue.toString()).toLocal(); // 解析为本地时间
      } catch (e) {
        final millis = int.tryParse(dateValue.toString());
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)
              .toLocal(); // 解析毫秒为本地时间
        }
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 错误回退
      }
    }

    // 安全解析可空 DateTime
    DateTime? parseNullableDateTime(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        // Go的time.Time零值处理为null
        if (dateValue is String &&
            (dateValue == "0001-01-01T00:00:00Z" ||
                dateValue.startsWith("0001-01-01"))) {
          return null;
        }
        return parseDateTime(dateValue);
      } catch (_) {
        return null;
      }
    }

    // 安全解析 int
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    // 安全解析 double
    double parseDoubleSafely(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return Game(
      id: parseId(json['_id'] ?? json['id']),
      authorId: parseId(json['authorId']),
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      category: json['category']?.toString() ?? '',
      tags: parseTags(json['tags']),
      rating: parseDoubleSafely(json['rating']),
      totalRatingSum: parseDoubleSafely(json['totalRatingSum']),
      ratingCount: parseIntSafely(json['ratingCount']),
      ratingUpdateTime: parseNullableDateTime(json['ratingUpdateTime']),
      createTime: parseDateTime(json['createTime']),
      updateTime: parseDateTime(json['updateTime']),
      viewCount: parseIntSafely(json['viewCount']),
      likeCount: parseIntSafely(json['likeCount']),
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      downloadLinks: parseDownloadLinks(json['downloadLinks']),
      musicUrl: json['musicUrl']?.toString(),
      bvid: json['bvid']?.toString(),
      lastViewedAt: parseNullableDateTime(json['lastViewedAt']),
      currentUserLastViewTime:
          parseNullableDateTime(json['currentUserLastViewTime']), // 前端特有字段
      wantToPlayCount: parseIntSafely(json['wantToPlayCount']),
      playingCount: parseIntSafely(json['playingCount']),
      playedCount: parseIntSafely(json['playedCount']),
      totalCollections: parseIntSafely(json['totalCollections']),
      collectionUpdateTime: parseNullableDateTime(json['collectionUpdateTime']),
      approvalStatus: json['approvalStatus']?.toString(),
      reviewComment: json['reviewComment']?.toString(),
      reviewedAt: parseNullableDateTime(json['reviewedAt']),
      reviewedBy: parseId(json['reviewedBy']),
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
      'likedBy': likedBy,
      'downloadLinks': downloadLinks.map((link) => link.toJson()).toList(),
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
      likedBy: [],
      downloadLinks: [],
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
    List<String>? likedBy,
    List<GameDownloadLink>? downloadLinks,
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
      likedBy: likedBy ?? this.likedBy,
      downloadLinks: downloadLinks ?? this.downloadLinks,
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
class GameDownloadLink {
  final String id;
  final String title;
  final String description;
  final String url;

  GameDownloadLink({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  // 从 JSON 解析 GameDownloadLink
  factory GameDownloadLink.fromJson(Map<String, dynamic> json) {
    return GameDownloadLink(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
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
