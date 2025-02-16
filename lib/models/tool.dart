import 'package:mongo_dart/mongo_dart.dart';
class ToolDownload {
  final String name;
  final String description;
  final String url;

  ToolDownload({
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

  Tool({
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
    String toolId = json['_id'] is ObjectId
        ? json['_id'].toHexString()
        : (json['_id']?.toString() ?? json['id']?.toString() ?? '');

    List<ToolDownload> parseDownloads(dynamic downloads) {
      if (downloads == null) return [];
      if (downloads is List) {
        return downloads.map((item) => ToolDownload.fromJson(item)).toList();
      }
      return [];
    }

    return Tool(
      id: toolId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString() ?? '#19712C',
      type: json['type']?.toString(),
      downloads: parseDownloads(json['downloads']),
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(
          json['createTime'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
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