// lib/models/linkstools/tool.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class ToolDownload {
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
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
    };
  }
}

@immutable
class Tool {
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
    if (json['downloads'] is List) {
      downloads = (json['downloads'] as List)
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
      id: UtilJson.parseId(json['_id'] ?? json['id']),
      name: UtilJson.parseStringSafely(json['name']),
      description: UtilJson.parseStringSafely(json['description']),
      icon: UtilJson.parseNullableStringSafely(json['icon']),
      // 业务逻辑: 如果后端未提供颜色，默认为 '#19712C'
      color: UtilJson.parseStringSafely(json['color'] ?? '#19712C'),
      type: UtilJson.parseNullableStringSafely(json['type']),
      downloads: downloads,
      createTime: UtilJson.parseDateTime(json['createTime']),
      // 业务逻辑: 如果后端未提供 isActive，默认为 true
      isActive: UtilJson.parseBoolSafely(json['isActive'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'type': type,
      'downloads': downloads.map((d) => d.toJson()).toList(),
      'createTime': createTime.toIso8601String(),
      'isActive': isActive,
    };
  }
}
