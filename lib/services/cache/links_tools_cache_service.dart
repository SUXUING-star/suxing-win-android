// lib/services/cache/links_tools_cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/link.dart';
import '../../models/tool.dart';

class LinksToolsCacheService {
  static const String _linksBoxName = 'linksCache';
  static const String _toolsBoxName = 'toolsCache';
  static const Duration _cacheExpiry = Duration(minutes: 15);

  static final LinksToolsCacheService _instance = LinksToolsCacheService._internal();
  factory LinksToolsCacheService() => _instance;

  Box<Map>? _linksBox;
  Box<Map>? _toolsBox;

  LinksToolsCacheService._internal();

  Future<void> init() async {
    _linksBox = await Hive.openBox<Map>(_linksBoxName);
    _toolsBox = await Hive.openBox<Map>(_toolsBoxName);
    // 定期清理过期缓存
    await _cleanExpiredCache();
  }

  Future<void> _cleanExpiredCache() async {
    if (_linksBox == null || _toolsBox == null) return;

    final now = DateTime.now();

    // 清理 links 缓存
    final linksData = _linksBox!.get('links') as Map?;
    if (linksData != null) {
      final timestamp = DateTime.parse(linksData['timestamp'] as String);
      if (now.difference(timestamp) > _cacheExpiry) {
        await _linksBox!.delete('links');
      }
    }

    // 清理 tools 缓存
    final toolsData = _toolsBox!.get('tools') as Map?;
    if (toolsData != null) {
      final timestamp = DateTime.parse(toolsData['timestamp'] as String);
      if (now.difference(timestamp) > _cacheExpiry) {
        await _toolsBox!.delete('tools');
      }
    }
  }

  Future<List<Link>?> getLinks() async {
    if (_linksBox == null) await init();

    final cacheData = _linksBox!.get('links') as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'] as String);
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _linksBox!.delete('links');
      return null;
    }

    final linksList = (cacheData['data'] as List).cast<Map>();
    return linksList.map((map) => Link.fromJson(Map<String, dynamic>.from(map))).toList();
  }

  Future<List<Tool>?> getTools() async {
    if (_toolsBox == null) await init();

    final cacheData = _toolsBox!.get('tools') as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'] as String);
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _toolsBox!.delete('tools');
      return null;
    }

    final toolsList = (cacheData['data'] as List).cast<Map>();
    return toolsList.map((map) => Tool.fromJson(Map<String, dynamic>.from(map))).toList();
  }

  Future<void> setLinks(List<Link> links) async {
    if (_linksBox == null) await init();

    await _linksBox!.put('links', {
      'data': links.map((link) => link.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setTools(List<Tool> tools) async {
    if (_toolsBox == null) await init();

    await _toolsBox!.put('tools', {
      'data': tools.map((tool) => tool.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearCache() async {
    if (_linksBox == null || _toolsBox == null) await init();
    await _linksBox!.clear();
    await _toolsBox!.clear();
  }
}