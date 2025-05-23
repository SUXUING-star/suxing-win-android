// lib/models/game/game.dart
import 'package:flutter/cupertino.dart';
import 'package:mongo_dart/mongo_dart.dart';

class GameStatus {
  static const String approved = "approved";
  static const String rejected = "rejected";
  static const String pending  = "pending";
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
  final DateTime createTime;
  final DateTime updateTime;
  final int viewCount;
  final int likeCount;
  final List<String> likedBy;
  final List<DownloadLink> downloadLinks;
  final String? musicUrl;
  final String? bvid;
  final DateTime? lastViewedAt;
  final String? approvalStatus; // "pending", "approved", "rejected"
  final String? reviewComment; // Admin feedback if rejected
  final DateTime? reviewedAt; // When the game was reviewed
  final String? reviewedBy; // Admin who reviewed the game
  final double totalRatingSum;
  final int ratingCount;
  final DateTime? ratingUpdateTime; // 评分最后更新时间

  // 新增收藏统计字段
  final int wantToPlayCount;
  final int playingCount;
  final int playedCount;
  final int totalCollections;

  Game({
    required this.id,
    required this.authorId,
    required this.title,
    required this.summary,
    required this.description,
    required this.coverImage,
    required this.images,
    required this.category,
    List<String>? tags,
    required this.rating,
    required this.createTime,
    required this.updateTime,
    required this.viewCount,
    required this.likeCount,
    required this.likedBy,
    required this.downloadLinks,
    this.musicUrl,
    this.bvid,
    this.lastViewedAt,
    // 初始化新增的收藏统计字段
    this.wantToPlayCount = 0,
    this.playingCount = 0,
    this.playedCount = 0,
    this.totalCollections = 0,
    this.totalRatingSum = 0.0,
    this.ratingCount = 0,
    this.ratingUpdateTime,
    this.approvalStatus,
    this.reviewComment,
    this.reviewedAt,
    this.reviewedBy,
  }) : tags = tags ?? [];

  factory Game.fromJson(Map<String, dynamic> json) {
    // Helper functions (保持你原来的，确认它们能处理 null 和类型转换)
    String parseId(dynamic idValue) {
      if (idValue == null) return '';
      return idValue is ObjectId ? idValue.oid: idValue.toString();
    }

    List<DownloadLink> parseDownloadLinks(dynamic links) {
      if (links == null || links is! List) return [];
      try {
        return links
            .map((link) => link is Map<String, dynamic>
                ? DownloadLink.fromJson(link)
                : null) // Handle non-map items
            .whereType<DownloadLink>() // Filter out nulls
            .toList();
      } catch (e) {
        // print('Error parsing download links: $e');
        return [];
      }
    }

    List<String> parseTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is List) {
        try {
          return tags.map((tag) => tag.toString()).toList();
        } catch (e) {
          // print('Error parsing tags: $e');
          return [];
        }
      }
      if (tags is String) {
        return tags.split(',').map((tag) => tag.trim()).toList();
      }
      return [];
    }

    DateTime parseDateTime(dynamic dateValue) {
      if (dateValue == null) return DateTime.now(); // Or throw error?
      if (dateValue is DateTime) return dateValue;
      if (dateValue is Timestamp) {
        // 处理 MongoDB Timestamp 类型
        // Timestamp 包含 seconds 和 incrementing counter
        // 从 seconds 创建 DateTime
        return DateTime.fromMillisecondsSinceEpoch(dateValue.seconds * 1000);
      }
      try {
        // 尝试解析 ISO 8601 字符串
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        // print('Error parsing date $dateValue: $e');
        // 尝试解析数字（毫秒时间戳）
        final millis = int.tryParse(dateValue.toString());
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
        return DateTime.now(); // Fallback
      }
    }

    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt(); // Handle double
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDoubleSafely(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    DateTime? parseNullableDateTime(dynamic dateValue) {
      if (dateValue == null) return null;
      // Use the robust parseDateTime logic
      try {
        return parseDateTime(dateValue);
      } catch (_) {
        return null;
      }
    }

    return Game(
      id: parseId(json['_id'] ?? json['id']), // Handle both _id and id
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
      // rating: 已经是计算好的平均分
      rating: parseDoubleSafely(json['rating']),
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
      wantToPlayCount: parseIntSafely(json['wantToPlayCount']),
      playingCount: parseIntSafely(json['playingCount']),
      playedCount: parseIntSafely(json['playedCount']),
      totalCollections: parseIntSafely(json['totalCollections']),
      // *** 解析新增字段 ***
      totalRatingSum: parseDoubleSafely(json['totalRatingSum']),
      ratingCount: parseIntSafely(json['ratingCount']),
      ratingUpdateTime: parseNullableDateTime(json['ratingUpdateTime']),
      // --- 审核字段 ---
      approvalStatus: json['approvalStatus']?.toString(),
      reviewComment: json['reviewComment']?.toString(),
      reviewedAt: parseNullableDateTime(json['reviewedAt']),
      reviewedBy: parseId(json['reviewedBy']), // 解析 reviewedBy ID
    );
  }
  Map<String, dynamic> toJson() {
    return {
      // '_id': id, // 通常API交互用 'id'
      'id': id,
      'authorId': authorId,
      'title': title,
      'summary': summary,
      'description': description,
      'coverImage': coverImage,
      'images': images,
      'category': category,
      'tags': tags,
      'rating': rating, // 平均分
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'downloadLinks': downloadLinks.map((link) => link.toJson()).toList(),
      'musicUrl': musicUrl,
      'bvid': bvid,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      'wantToPlayCount': wantToPlayCount,
      'playingCount': playingCount,
      'playedCount': playedCount,
      'totalCollections': totalCollections,
      // *** 添加新增字段到 JSON ***
      'totalRatingSum': totalRatingSum,
      'ratingCount': ratingCount,
      'ratingUpdateTime': ratingUpdateTime?.toIso8601String(),
      // --- 审核字段 ---
      'approvalStatus': approvalStatus,
      'reviewComment': reviewComment,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy, // 发送 reviewedBy ID
    };
  }

  // copyWith 方法也要加上新字段
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
    DateTime? createTime,
    DateTime? updateTime,
    int? viewCount,
    int? likeCount,
    List<String>? likedBy,
    List<DownloadLink>? downloadLinks,
    String? musicUrl,
    ValueGetter<String?>? bvid,
    DateTime? lastViewedAt,
    int? wantToPlayCount,
    int? playingCount,
    int? playedCount,
    int? totalCollections,
    double? totalRatingSum,
    int? ratingCount,
    DateTime? ratingUpdateTime,
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
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      downloadLinks: downloadLinks ?? this.downloadLinks,
      musicUrl: musicUrl ?? this.musicUrl,
      bvid: bvid != null ? bvid() : this.bvid,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      wantToPlayCount: wantToPlayCount ?? this.wantToPlayCount,
      playingCount: playingCount ?? this.playingCount,
      playedCount: playedCount ?? this.playedCount,
      totalCollections: totalCollections ?? this.totalCollections,
      // *** 使用 copyWith 参数 ***
      totalRatingSum: totalRatingSum ?? this.totalRatingSum,
      ratingCount: ratingCount ?? this.ratingCount,
      ratingUpdateTime: ratingUpdateTime ?? this.ratingUpdateTime,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}

class DownloadLink {
  final String id;
  final String title;
  final String description;
  final String url; // Using lowercase 'url' to match backend

  DownloadLink({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    // Safely handle different possible key names and null values
    return DownloadLink(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '', // Backend uses lowercase 'url'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url, // Ensure we're using lowercase 'url' to match backend
    };
  }
}
