// lib/services/cache/links_tools_cache_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../models/linkstools/link.dart';
import '../../models/linkstools/tool.dart';
import '../../config/app_config.dart';

class LinksToolsCacheService {
  static const String _linksBoxName = 'linksCache';
  static const String _toolsBoxName = 'toolsCache';
  static const Duration _cacheExpiry = Duration(minutes: 15);

  static final LinksToolsCacheService _instance = LinksToolsCacheService._internal();
  factory LinksToolsCacheService() => _instance;

  final String _redisProxyUrl = AppConfig.redisProxyUrl;
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

    // 清理本地缓存
    for (final box in [_linksBox!, _toolsBox!]) {
      final data = box.get('data');
      if (data != null) {
        final timestamp = DateTime.parse(data['timestamp'].toString());
        if (now.difference(timestamp) > _cacheExpiry) {
          await box.clear();
        }
      }
    }
  }

  Future<List<Link>?> getLinks() async {
    try {
      // 尝试从Redis获取
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/links'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final links = (responseData['data'] as List)
              .map((item) => Link.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          // 同步到本地缓存
          await _cacheLocalLinks(links);
          return links;
        }
      }

      // 如果Redis没有数据，尝试从本地缓存获取
      return await _getLocalLinks();
    } catch (e) {
      print('Get cached links error: $e');
      return await _getLocalLinks();
    }
  }

  Future<void> _cacheLocalLinks(List<Link> links) async {
    if (_linksBox == null) await init();

    final linksData = {
      'data': links.map((link) => link.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _linksBox!.put('data', linksData);
  }

  Future<List<Link>?> _getLocalLinks() async {
    if (_linksBox == null) await init();

    final cacheData = _linksBox!.get('data');
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _linksBox!.delete('data');
      return null;
    }

    try {
      return (cacheData['data'] as List)
          .map((item) {
        // 确保转换为 Map<String, dynamic>
        final convertedItem = _convertToStringKeyMap(item as Map);
        return Link.fromJson(convertedItem);
      })
          .toList();
    } catch (e) {
      print('Error parsing cached links: $e');
      await _linksBox!.delete('data');
      return null;
    }
  }

  Future<List<Tool>?> getTools() async {
    try {
      // 尝试从Redis获取
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/tools'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final tools = (responseData['data'] as List)
              .map((item) => Tool.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          // 同步到本地缓存
          await _cacheLocalTools(tools);
          return tools;
        }
      }

      // 如果Redis没有数据，尝试从本地缓存获取
      return await _getLocalTools();
    } catch (e) {
      print('Get cached tools error: $e');
      return await _getLocalTools();
    }
  }

  Future<void> _cacheLocalTools(List<Tool> tools) async {
    if (_toolsBox == null) await init();

    final toolsData = {
      'data': tools.map((tool) => tool.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _toolsBox!.put('data', toolsData);
  }

  Future<List<Tool>?> _getLocalTools() async {
    if (_toolsBox == null) await init();

    final cacheData = _toolsBox!.get('data');
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _toolsBox!.delete('data');
      return null;
    }

    try {
      return (cacheData['data'] as List)
          .map((item) {
        // 确保转换为 Map<String, dynamic>
        final convertedItem = _convertToStringKeyMap(item as Map);
        return Tool.fromJson(convertedItem);
      })
          .toList();
    } catch (e) {
      print('Error parsing cached tools: $e');
      await _toolsBox!.delete('data');
      return null;
    }
  }

  Future<void> setLinks(List<Link> links) async {
    try {
      // 本地缓存
      await _cacheLocalLinks(links);

      // Redis缓存
      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/links'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': links.map((link) => link.toJson()).toList(),
          'expiration': _cacheExpiry.inSeconds,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Set links error: $e');
    }
  }

  Future<void> setTools(List<Tool> tools) async {
    try {
      // 本地缓存
      await _cacheLocalTools(tools);

      // Redis缓存
      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/tools'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': tools.map((tool) => tool.toJson()).toList(),
          'expiration': _cacheExpiry.inSeconds,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Set tools error: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      // 清除本地缓存
      if (_linksBox != null && _linksBox!.isOpen) {
        await _linksBox!.clear();
      }
      if (_toolsBox != null && _toolsBox!.isOpen) {
        await _toolsBox!.clear();
      }

      // 清除Redis缓存
      try {
        await Future.wait([
          http.delete(Uri.parse('$_redisProxyUrl/cache/links')),
          http.delete(Uri.parse('$_redisProxyUrl/cache/tools')),
        ]);
      } catch (e) {
        print('Clear Redis cache error: $e');
      }
    } catch (e) {
      print('Clear cache error: $e');
    }
  }

  // 清除数据但不关闭 boxes
  Future<void> clearCacheData() async {
    try {
      // 清除本地缓存
      if (_linksBox != null && _linksBox!.isOpen) {
        await _linksBox!.clear();
      }
      if (_toolsBox != null && _toolsBox!.isOpen) {
        await _toolsBox!.clear();
      }

      // 清除Redis缓存
      try {
        await Future.wait([
          http.delete(Uri.parse('$_redisProxyUrl/cache/links')),
          http.delete(Uri.parse('$_redisProxyUrl/cache/tools')),
        ]);
      } catch (e) {
        print('Clear Redis cache data error: $e');
      }
    } catch (e) {
      print('Clear cache data error: $e');
      rethrow;
    }
  }

  // 判断缓存是否过期
  bool isCacheExpired(String key) {
    if (key == 'links' && _linksBox != null) {
      final data = _linksBox!.get('data');
      if (data != null) {
        final timestamp = DateTime.parse(data['timestamp'].toString());
        return DateTime.now().difference(timestamp) > _cacheExpiry;
      }
    } else if (key == 'tools' && _toolsBox != null) {
      final data = _toolsBox!.get('data');
      if (data != null) {
        final timestamp = DateTime.parse(data['timestamp'].toString());
        return DateTime.now().difference(timestamp) > _cacheExpiry;
      }
    }
    return true;
  }

  // 从路由获取缓存状态
  Future<bool> isRedisCacheExpired(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/${key}/status'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['expired'] ?? true;
      }
      return true;
    } catch (e) {
      print('Check Redis cache expiration error: $e');
      return true;
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
}