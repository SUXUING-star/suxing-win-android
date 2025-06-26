// lib/models/linkstools/site_link.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

// 为了避免不混淆第三方库的link包
@immutable
class SiteLink {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id'; // MongoDB 默认的 _id 字段，用于 fromJson
  static const String jsonKeyTitle = 'title';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyUrl = 'url';
  static const String jsonKeyIcon = 'icon';
  static const String jsonKeyColor = 'color';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyOrder = 'order';
  static const String jsonKeyIsActive = 'isActive';

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
      id: UtilJson.parseId(
          json[jsonKeyMongoId] ?? json[jsonKeyId]), // fromJson 兼容 _id 和 id
      title: UtilJson.parseStringSafely(json[jsonKeyTitle]),
      description: UtilJson.parseStringSafely(json[jsonKeyDescription]),
      url: UtilJson.parseStringSafely(json[jsonKeyUrl]),
      // 业务逻辑: 如果后端未提供图标或颜色，使用预设的默认值
      icon: UtilJson.parseStringSafely(json[jsonKeyIcon] ?? 'IconWorld'),
      color: UtilJson.parseStringSafely(json[jsonKeyColor] ?? '#228b6e'),
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]),
      order: UtilJson.parseIntSafely(json[jsonKeyOrder]),
      // 业务逻辑: 如果后端未提供 isActive，默认为 true
      isActive:
          UtilJson.parseBoolSafely(json[jsonKeyIsActive], defaultValue: true),
    );
  }

  // toJson 一般用于缓存或通用数据表示，使用普通 'id' 键
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用 jsonKeyId (即 'id')
      jsonKeyTitle: title,
      jsonKeyDescription: description,
      jsonKeyUrl: url,
      jsonKeyIcon: icon,
      jsonKeyColor: color,
      jsonKeyCreateTime: createTime.toIso8601String(),
      jsonKeyOrder: order,
      jsonKeyIsActive: isActive,
    };
  }

  // 新增 toRequestJson，不包含 ID，只包含可提交给后端用于创建/更新的字段
  Map<String, dynamic> toRequestJson() {
    return {
      jsonKeyTitle: title,
      jsonKeyDescription: description,
      jsonKeyUrl: url,
      jsonKeyIcon: icon,
      jsonKeyColor: color,
      jsonKeyOrder: order,
      jsonKeyIsActive: isActive,
      // 'id' 和 'createTime' 通常由后端生成或在 URL 中传递，不放在请求体中
    };
  }
}
