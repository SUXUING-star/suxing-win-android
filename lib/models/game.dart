// lib/models/game.dart
import 'package:mongo_dart/mongo_dart.dart';

class Game {
  final String id;
  final String title;
  final String summary;     // 摘要
  final String description; // 详细描述
  final String coverImage;  // 头图
  final List<String> images; // 文章内部图片列表
  final String category;
  final double rating;
  final DateTime createTime;
  final DateTime updateTime;
  final int viewCount;
  final int likeCount;
  final List<String> likedBy;
  final List<Map<String, dynamic>> downloadLinks; // [{id: "...", title: "...", description: "...", url: "..."}]
  final String? musicUrl;

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
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // 处理 MongoDB 的 _id 字段
    String gameId = json['_id'] is ObjectId
        ? json['_id'].toHexString()
        : (json['_id']?.toString() ?? json['id']?.toString() ?? '');

    // 处理下载链接数组
    List<Map<String, dynamic>> parseDownloadLinks(dynamic links) {
      if (links == null) return [];
      if (links is List) {
        return links.map((link) {
          if (link is Map) {
            var linkMap = <String, dynamic>{};
            if (link['_id'] is ObjectId) {
              linkMap['id'] = link['_id'].toHexString();
            } else {
              linkMap['id'] = link['id']?.toString() ?? '';
            }
            linkMap['title'] = link['title']?.toString() ?? '';
            linkMap['description'] = link['description']?.toString() ?? '';
            linkMap['url'] = link['url']?.toString() ?? '';
            return linkMap;
          }
          return <String, dynamic>{};
        }).toList();
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
      'downloadLinks': downloadLinks,
      'musicUrl': musicUrl,
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
    List<Map<String, dynamic>>? downloadLinks,
    String? musicUrl,
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
    );
  }
}