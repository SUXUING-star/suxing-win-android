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
    await _cleanExpiredCache();
  }

  Future<void> _cleanExpiredCache() async {
    if (_linksBox == null || _toolsBox == null) return;

    final now = DateTime.now();

    // 清理 links 缓存
    final linksData = _linksBox!.get('links');
    if (linksData != null) {
      final timestamp = DateTime.parse(linksData['timestamp'].toString());
      if (now.difference(timestamp) > _cacheExpiry) {
        await _linksBox!.delete('links');
      }
    }

    // 清理 tools 缓存
    final toolsData = _toolsBox!.get('tools');
    if (toolsData != null) {
      final timestamp = DateTime.parse(toolsData['timestamp'].toString());
      if (now.difference(timestamp) > _cacheExpiry) {
        await _toolsBox!.delete('tools');
      }
    }
  }

  Map<String, dynamic> _convertToStringKeyMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        value = _convertToStringKeyMap(value);
      } else if (value is List) {
        value = _convertList(value);
      }
      return MapEntry(key.toString(), value);
    });
  }

  List _convertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _convertToStringKeyMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  Future<List<Link>?> getLinks() async {
    if (_linksBox == null) await init();

    final cacheData = _linksBox!.get('links');
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _linksBox!.delete('links');
      return null;
    }

    try {
      final linksList = (cacheData['data'] as List).map((item) {
        final convertedMap = _convertToStringKeyMap(item as Map);
        return Link.fromJson(convertedMap);
      }).toList();

      return linksList;
    } catch (e) {
      print('Error parsing cached links: $e');
      await _linksBox!.delete('links');
      return null;
    }
  }

  Future<List<Tool>?> getTools() async {
    if (_toolsBox == null) await init();

    final cacheData = _toolsBox!.get('tools');
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _toolsBox!.delete('tools');
      return null;
    }

    try {
      final toolsList = (cacheData['data'] as List).map((item) {
        final convertedMap = _convertToStringKeyMap(item as Map);
        return Tool.fromJson(convertedMap);
      }).toList();

      return toolsList;
    } catch (e) {
      print('Error parsing cached tools: $e');
      await _toolsBox!.delete('tools');
      return null;
    }
  }

  Future<void> setLinks(List<Link> links) async {
    if (_linksBox == null) await init();

    final linksData = {
      'data': links.map((link) => link.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _linksBox!.put('links', linksData);
  }

  Future<void> setTools(List<Tool> tools) async {
    if (_toolsBox == null) await init();

    final toolsData = {
      'data': tools.map((tool) => tool.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _toolsBox!.put('tools', toolsData);
  }

  Future<void> clearCacheData() async {
    try {
      if (_linksBox != null && _linksBox!.isOpen) {
        await _linksBox!.clear();
      }
      if (_toolsBox != null && _toolsBox!.isOpen) {
        await _toolsBox!.clear();
      }
    } catch (e) {
      print('Clear links tools cache data error: $e');
      rethrow;
    }
  }

  // 修改现有的clearCache方法
  Future<void> clearCache() async {
    if (_linksBox == null || _toolsBox == null) await init();
    await _linksBox!.clear();
    await _toolsBox!.clear();
  }
}