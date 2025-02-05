// lib/models/tool.dart
import 'package:mongo_dart/mongo_dart.dart';

class Tool {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final String color;
  final String? type;
  final List<Map<String, dynamic>> downloads;
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

    return Tool(
      id: toolId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString() ?? '#19712C',
      type: json['type']?.toString(),
      downloads: List<Map<String, dynamic>>.from(json['downloads'] ?? []),
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime'] ?? DateTime.now().toIso8601String()),
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
      'downloads': downloads,
      'createTime': createTime.toIso8601String(),
      'isActive': isActive,
    };
  }
}