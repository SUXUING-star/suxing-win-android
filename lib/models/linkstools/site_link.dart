// lib/models/linkstools/site_link.dart
import 'package:mongo_dart/mongo_dart.dart';

// 为了避免不混淆第三方库的link包
class SiteLink {
  final String id;
  final String title;
  final String description;
  final String url;
  final String icon;
  final String color;
  final DateTime createTime;
  final int order;
  final bool isActive;

  SiteLink({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
    required this.createTime,
    this.order = 0,
    this.isActive = true,
  });

  factory SiteLink.fromJson(Map<String, dynamic> json) {
    String linkId = json['_id'] is ObjectId
        ? json['_id'].toHexString()
        : (json['_id']?.toString() ?? json['id']?.toString() ?? '');

    return SiteLink(
      id: linkId,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'IconWorld',
      color: json['color']?.toString() ?? '#228b6e',
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime'] ?? DateTime.now().toIso8601String()),
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'url': url,
      'icon': icon,
      'color': color,
      'createTime': createTime.toIso8601String(),
      'order': order,
      'isActive': isActive,
    };
  }
}