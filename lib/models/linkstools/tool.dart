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
    // 不要递归调用Tool.fromJson，这可能是问题所在
    // 始终确保传入的是Map<String, dynamic>而不是Tool对象

    // 处理ID
    String toolId = '';
    var idValue = json['_id'] ?? json['id'];

    if (idValue is ObjectId) {
      toolId = idValue.toHexString();
    } else if (idValue is String) {
      toolId = idValue;
    } else if (idValue is Map && idValue.containsKey('\$oid')) {
      toolId = idValue['\$oid'].toString();
    }

    // 处理下载
    List<ToolDownload> downloads = [];
    if (json['downloads'] != null && json['downloads'] is List) {
      for (var item in json['downloads']) {
        if (item is Map) {
          try {
            var downloadMap = Map<String, dynamic>.from(item);
            downloads.add(ToolDownload.fromJson(downloadMap));
          } catch (e) {
            print('Error parsing download: $e');
          }
        }
      }
    }

    // 处理日期
    DateTime createTime = DateTime.now();
    var dateValue = json['createTime'];
    if (dateValue != null) {
      if (dateValue is DateTime) {
        createTime = dateValue;
      } else if (dateValue is String) {
        try {
          createTime = DateTime.parse(dateValue);
        } catch (e) {
          // 使用当前时间作为默认值
        }
      }
    }

    return Tool(
      id: toolId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString() ?? '#19712C',
      type: json['type']?.toString(),
      downloads: downloads,
      createTime: createTime,
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