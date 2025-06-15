// lib/models/linkstools/site_link.dart
import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:suxingchahui/models/util_json.dart';

// 为了避免不混淆第三方库的link包
@immutable
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

  const SiteLink({
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
    return SiteLink(
      id: UtilJson.parseId(json['_id'] ?? json['id']),
      title: UtilJson.parseStringSafely(json['title']),
      description: UtilJson.parseStringSafely(json['description']),
      url: UtilJson.parseStringSafely(json['url']),
      // 业务逻辑: 如果后端未提供图标或颜色，使用预设的默认值
      icon: UtilJson.parseStringSafely(json['icon'] ?? 'IconWorld'),
      color: UtilJson.parseStringSafely(json['color'] ?? '#228b6e'),
      createTime: UtilJson.parseDateTime(json['createTime']),
      order: UtilJson.parseIntSafely(json['order']),
      // 业务逻辑: 如果后端未提供 isActive，默认为 true
      isActive: UtilJson.parseBoolSafely(json['isActive'], defaultValue: true),
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
