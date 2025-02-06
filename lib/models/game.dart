// lib/models/game.dart
import 'package:mongo_dart/mongo_dart.dart';

class Game {
  final String id;
  final String title;
  final String summary;
  final String description;
  final String coverImage;
  final List<String> images;
  final String category;
  final double rating;
  final DateTime createTime;
  final DateTime updateTime;
  final int viewCount;
  final int likeCount;
  final List<String> likedBy;
  final List<DownloadLink> downloadLinks;
  final String? musicUrl;
  final DateTime? lastViewedAt; // 添加这个字段

  Game({
    required this.id,
    required this.title,
    required this.summary,
    required this.description,
    required this.coverImage,
    required this.images,
    required this.category,
    required this.rating,
    required this.createTime,
    required this.updateTime,
    required this.viewCount,
    required this.likeCount,
    required this.likedBy,
    required this.downloadLinks,
    this.musicUrl,
    this.lastViewedAt, // 添加这个参数
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    String gameId = json['_id'] is ObjectId
        ? json['_id'].toHexString()
        : (json['_id']?.toString() ?? json['id']?.toString() ?? '');

    List<DownloadLink> parseDownloadLinks(dynamic links) {
      if (links == null) return [];
      if (links is List) {
        return links.map((link) => DownloadLink.fromJson(link)).toList();
      }
      return [];
    }

    return Game(
      id: gameId,
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime'] ?? DateTime.now().toIso8601String()),
      updateTime: json['updateTime'] is DateTime
          ? json['updateTime']
          : DateTime.parse(json['updateTime'] ?? DateTime.now().toIso8601String()),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      downloadLinks: parseDownloadLinks(json['downloadLinks']),
      musicUrl: json['musicUrl']?.toString(),
      lastViewedAt: json['lastViewedAt'] != null
          ? (json['lastViewedAt'] is DateTime
          ? json['lastViewedAt']
          : DateTime.parse(json['lastViewedAt']))
          : null, // 解析 lastViewedAt
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'summary': summary,
      'description': description,
      'coverImage': coverImage,
      'images': images,
      'category': category,
      'rating': rating,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'downloadLinks': downloadLinks.map((link) => link.toJson()).toList(),
      'musicUrl': musicUrl,
      'lastViewedAt': lastViewedAt?.toIso8601String(), // 添加 lastViewedAt
    };
  }

  Game copyWith({
    String? id,
    String? title,
    String? summary,
    String? description,
    String? coverImage,
    List<String>? images,
    String? category,
    double? rating,
    DateTime? createTime,
    DateTime? updateTime,
    int? viewCount,
    int? likeCount,
    List<String>? likedBy,
    List<DownloadLink>? downloadLinks,
    String? musicUrl,
    DateTime? lastViewedAt, // 添加这个参数
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      downloadLinks: downloadLinks ?? this.downloadLinks,
      musicUrl: musicUrl ?? this.musicUrl,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt, // 添加这一行
    );
  }
}
class DownloadLink {
  final String id;
  final String title;
  final String description;
  final String url;

  DownloadLink({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
    };
  }
}