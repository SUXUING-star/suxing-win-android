// lib/models/linkstools/tool.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class ToolDownload {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyName = 'name';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyUrl = 'url';

  final String name;
  final String description;
  final String url;

  const ToolDownload({
    required this.name,
    required this.description,
    required this.url,
  });

  factory ToolDownload.fromJson(Map<String, dynamic> json) {
    return ToolDownload(
      name: json[jsonKeyName]?.toString() ?? '', // 使用常量
      description: json[jsonKeyDescription]?.toString() ?? '', // 使用常量
      url: json[jsonKeyUrl]?.toString() ?? '', // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyName: name, // 使用常量
      jsonKeyDescription: description, // 使用常量
      jsonKeyUrl: url, // 使用常量
    };
  }
}

@immutable
class Tool {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id'; // MongoDB 默认的 _id 字段，用于 fromJson
  static const String jsonKeyName = 'name';
  static const String jsonKeyDescription = 'description';
  static const String jsonKeyIcon = 'icon';
  static const String jsonKeyColor = 'color';
  static const String jsonKeyType = 'type';
  static const String jsonKeyDownloads = 'downloads';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyIsActive = 'isActive';

  final String id;
  final String name;
  final String description;
  final String? icon;
  final String color;
  final String? type;
  final List<ToolDownload> downloads;
  final DateTime createTime;
  final bool isActive;

  const Tool({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.color,
    this.type,
    required this.createTime,
    this.downloads = const [],
    this.isActive = true,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    List<ToolDownload> downloads = [];
    if (json[jsonKeyDownloads] is List) {
      // 使用常量
      downloads = (json[jsonKeyDownloads] as List) // 使用常量
          .map((item) {
            if (item is Map<String, dynamic>) {
              return ToolDownload.fromJson(item);
            }
            return null;
          })
          .whereType<ToolDownload>()
          .toList();
    }

    return Tool(
      id: UtilJson.parseId(
          json[jsonKeyMongoId] ?? json[jsonKeyId]), // fromJson 兼容 _id 和 id
      name: UtilJson.parseStringSafely(json[jsonKeyName]), // 使用常量
      description: UtilJson.parseStringSafely(json[jsonKeyDescription]), // 使用常量
      icon: UtilJson.parseNullableStringSafely(json[jsonKeyIcon]), // 使用常量
      // 业务逻辑: 如果后端未提供颜色，默认为 '#19712C'
      color:
          UtilJson.parseStringSafely(json[jsonKeyColor] ?? '#19712C'), // 使用常量
      type: UtilJson.parseNullableStringSafely(json[jsonKeyType]), // 使用常量
      downloads: downloads,
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
      // 业务逻辑: 如果后端未提供 isActive，默认为 true
      isActive: UtilJson.parseBoolSafely(json[jsonKeyIsActive],
          defaultValue: true), // 使用常量
    );
  }

  // toJson 一般用于缓存或通用数据表示，使用普通 'id' 键
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用 jsonKeyId (即 'id')
      jsonKeyName: name, // 使用常量
      jsonKeyDescription: description, // 使用常量
      jsonKeyIcon: icon, // 使用常量
      jsonKeyColor: color, // 使用常量
      jsonKeyType: type, // 使用常量
      jsonKeyDownloads: downloads.map((d) => d.toJson()).toList(), // 使用常量
      jsonKeyCreateTime: createTime.toIso8601String(), // 使用常量
      jsonKeyIsActive: isActive, // 使用常量
    };
  }

  // 新增 toRequestJson，不包含 ID，只包含可提交给后端用于创建/更新的字段
  Map<String, dynamic> toRequestJson() {
    return {
      jsonKeyName: name, // 使用常量
      jsonKeyDescription: description, // 使用常量
      jsonKeyIcon: icon, // 使用常量
      jsonKeyColor: color, // 使用常量
      jsonKeyType: type, // 使用常量
      jsonKeyDownloads: downloads.map((d) => d.toJson()).toList(), // 使用常量
      // 'id' 和 'createTime' 通常由后端生成或在 URL 中传递，不放在请求体中
      jsonKeyIsActive: isActive, // 使用常量，如果 isActive 是可编辑的
    };
  }
}
