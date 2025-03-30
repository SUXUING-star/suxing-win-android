// lib/models/game/game.dart
import 'package:mongo_dart/mongo_dart.dart';

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
  final DateTime? lastViewedAt;
  final String? approvalStatus; // "pending", "approved", "rejected"
  final String? reviewComment;  // Admin feedback if rejected
  final DateTime? reviewedAt;   // When the game was reviewed
  final String? reviewedBy;     // Admin who reviewed the game

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
    this.lastViewedAt,
    // 初始化新增的收藏统计字段
    this.wantToPlayCount = 0,
    this.playingCount = 0,
    this.playedCount = 0,
    this.totalCollections = 0,
    this.approvalStatus,
    this.reviewComment,
    this.reviewedAt,
    this.reviewedBy,
  }) : this.tags = tags ?? [];

  factory Game.fromJson(Map<String, dynamic> json) {
    // Safely handle different ID formats
    String gameId = '';
    if (json['_id'] != null) {
      gameId = json['_id'] is ObjectId
          ? json['_id'].toHexString()
          : json['_id'].toString();
    } else if (json['id'] != null) {
      gameId = json['id'].toString();
    }

    // Safely handle different authorId formats
    String authorId = '';
    if (json['authorId'] != null) {
      authorId = json['authorId'] is ObjectId
          ? json['authorId'].toHexString()
          : json['authorId'].toString();
    }

    // Parse download links safely
    List<DownloadLink> parseDownloadLinks(dynamic links) {
      if (links == null) return [];
      if (links is List) {
        try {
          return links.map((link) =>
          link is Map<String, dynamic>
              ? DownloadLink.fromJson(link)
              : DownloadLink(id: '', title: '', description: '', url: '')
          ).toList();
        } catch (e) {
          print('Error parsing download links: $e');
          return [];
        }
      }
      return [];
    }

    // Parse tags safely
    List<String> parseTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is List) {
        try {
          return tags.map((tag) => tag.toString()).toList();
        } catch (e) {
          print('Error parsing tags: $e');
          return [];
        }
      }
      if (tags is String) {
        // Handle case where tags might be a comma-separated string
        return tags.split(',').map((tag) => tag.trim()).toList();
      }
      return [];
    }

    // Parse dates safely
    DateTime parseDateTime(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;

      try {
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        print('Error parsing date: $e');
        return DateTime.now();
      }
    }

    // Parse int values safely
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;

      try {
        return int.tryParse(value.toString()) ?? 0;
      } catch (e) {
        print('Error parsing int: $e');
        return 0;
      }
    }

    return Game(
      id: gameId,
      authorId: authorId,
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category']?.toString() ?? '',
      tags: parseTags(json['tags']),
      rating: (json['rating'] != null) ? double.tryParse(json['rating'].toString()) ?? 0.0 : 0.0,
      createTime: parseDateTime(json['createTime']),
      updateTime: parseDateTime(json['updateTime']),
      viewCount: parseIntSafely(json['viewCount']),
      likeCount: parseIntSafely(json['likeCount']),
      likedBy: (json['likedBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      downloadLinks: parseDownloadLinks(json['downloadLinks']),
      musicUrl: json['musicUrl']?.toString(),
      lastViewedAt: json['lastViewedAt'] != null ? parseDateTime(json['lastViewedAt']) : null,
      // 解析收藏统计字段
      wantToPlayCount: parseIntSafely(json['wantToPlayCount']),
      playingCount: parseIntSafely(json['playingCount']),
      playedCount: parseIntSafely(json['playedCount']),
      totalCollections: parseIntSafely(json['totalCollections']),
      approvalStatus: json['approvalStatus']?.toString(),
      reviewComment: json['reviewComment']?.toString(),
      reviewedAt: json['reviewedAt'] != null ? parseDateTime(json['reviewedAt']) : null,
      reviewedBy: json['reviewedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Use 'id' instead of '_id' for consistency with backend API
      'authorId': authorId,
      'title': title,
      'summary': summary,
      'description': description,
      'coverImage': coverImage,
      'images': images,
      'category': category,
      'tags': tags,
      'rating': rating,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'downloadLinks': downloadLinks.map((link) => link.toJson()).toList(),
      'musicUrl': musicUrl,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      // 添加收藏统计字段
      'wantToPlayCount': wantToPlayCount,
      'playingCount': playingCount,
      'playedCount': playedCount,
      'totalCollections': totalCollections,
      'approvalStatus': approvalStatus,
      'reviewComment': reviewComment,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
    };
  }

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
    DateTime? lastViewedAt,
    int? wantToPlayCount,
    int? playingCount,
    int? playedCount,
    int? totalCollections,
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
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      wantToPlayCount: wantToPlayCount ?? this.wantToPlayCount,
      playingCount: playingCount ?? this.playingCount,
      playedCount: playedCount ?? this.playedCount,
      totalCollections: totalCollections ?? this.totalCollections,
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