// lib/services/cache/history_cache_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/game/game_history.dart';
import '../../models/post/post_history.dart';

class HistoryCacheService {
  static final HistoryCacheService _instance = HistoryCacheService._internal();
  factory HistoryCacheService() => _instance;

  // Hive boxes
  static const String _gameHistoryBoxName = 'gameHistoryCache';
  static const String _postHistoryBoxName = 'postHistoryCache';
  static const Duration _localCacheExpiry = Duration(minutes: 5);

  // Redis 相关
  final String _redisProxyUrl = AppConfig.redisProxyUrl;
  static const Duration _redisCacheExpiry = Duration(minutes: 10);

  Box<Map>? _gameHistoryBox;
  Box<Map>? _postHistoryBox;

  HistoryCacheService._internal();

  Future<void> init() async {
    _gameHistoryBox = await Hive.openBox<Map>(_gameHistoryBoxName);
    _postHistoryBox = await Hive.openBox<Map>(_postHistoryBoxName);
    // 定期清理过期缓存
    _cleanExpiredCache();
  }

  // 清理过期的本地缓存
  Future<void> _cleanExpiredCache() async {
    if (_gameHistoryBox == null || _postHistoryBox == null) return;

    final now = DateTime.now();
    final List<String> gameKeysToDelete = [];
    final List<String> postKeysToDelete = [];

    // 清理游戏历史缓存
    for (var key in _gameHistoryBox!.keys) {
      final cacheData = _gameHistoryBox!.get(key) as Map?;
      if (cacheData == null) continue;

      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      if (now.difference(timestamp) > _localCacheExpiry) {
        gameKeysToDelete.add(key as String);
      }
    }

    // 清理帖子历史缓存
    for (var key in _postHistoryBox!.keys) {
      final cacheData = _postHistoryBox!.get(key) as Map?;
      if (cacheData == null) continue;

      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      if (now.difference(timestamp) > _localCacheExpiry) {
        postKeysToDelete.add(key as String);
      }
    }

    await _gameHistoryBox!.deleteAll(gameKeysToDelete);
    await _postHistoryBox!.deleteAll(postKeysToDelete);
  }

  // 获取游戏历史
  Future<List<GameHistory>?> getCachedGameHistory(String userId) async {
    try {
      // 1. 尝试从Redis获取
      final redisData = await _getRedisGameHistory(userId);
      if (redisData != null) {
        // 更新本地缓存
        await _setLocalGameHistory(userId, redisData);
        return redisData;
      }

      // 2. Redis没有，尝试从本地缓存获取
      final localData = await _getLocalGameHistory(userId);
      if (localData != null) {
        // 异步更新Redis缓存
        _setRedisGameHistory(userId, localData);
        return localData;
      }

      return null;
    } catch (e) {
      print('Get game history error: $e');
      return null;
    }
  }

  // 从Redis获取游戏历史
  Future<List<GameHistory>?> _getRedisGameHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/history/game/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((item) => GameHistory.fromJson(item))
              .toList();
        }
      }
      return null;
    } catch (e) {
      print('Get Redis game history error: $e');
      return null;
    }
  }

  // 从本地缓存获取游戏历史
  Future<List<GameHistory>?> _getLocalGameHistory(String userId) async {
    if (_gameHistoryBox == null) await init();

    final cacheData = _gameHistoryBox!.get(userId) as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'] as String);
    if (DateTime.now().difference(timestamp) > _localCacheExpiry) {
      await _gameHistoryBox!.delete(userId);
      return null;
    }

    return (cacheData['data'] as List)
        .map((item) => GameHistory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // 缓存游戏历史
  Future<void> cacheGameHistory(String userId, List<GameHistory> history) async {
    try {
      // 同时更新Redis和本地缓存
      await Future.wait([
        _setRedisGameHistory(userId, history),
        _setLocalGameHistory(userId, history)
      ]);
    } catch (e) {
      print('Cache game history error: $e');
    }
  }

  // 设置Redis游戏历史缓存
  Future<void> _setRedisGameHistory(String userId, List<GameHistory> history) async {
    try {
      await http.post(
        Uri.parse('$_redisProxyUrl/cache/history/game'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'data': history.map((item) => item.toJson()).toList(),
          'expiration': _redisCacheExpiry.inSeconds,
        }),
      );
    } catch (e) {
      print('Set Redis game history error: $e');
    }
  }

  // 设置本地游戏历史缓存
  Future<void> _setLocalGameHistory(String userId, List<GameHistory> history) async {
    if (_gameHistoryBox == null) await init();

    final jsonData = history.map((item) {
      final json = item.toJson();
      // 将 ObjectId 转换为字符串
      json['_id'] = json['_id'].toHexString();
      json['userId'] = json['userId'].toHexString();
      return json;
    }).toList();

    await _gameHistoryBox!.put(userId, {
      'data': jsonData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }


  // 帖子历史相关方法
  Future<List<PostHistory>?> getCachedPostHistory(String userId) async {
    try {
      // 1. 尝试从Redis获取
      final redisData = await _getRedisPostHistory(userId);
      if (redisData != null) {
        // 更新本地缓存
        await _setLocalPostHistory(userId, redisData);
        return redisData;
      }

      // 2. Redis没有，尝试从本地缓存获取
      final localData = await _getLocalPostHistory(userId);
      if (localData != null) {
        // 异步更新Redis缓存
        _setRedisPostHistory(userId, localData);
        return localData;
      }

      return null;
    } catch (e) {
      print('Get post history error: $e');
      return null;
    }
  }

  Future<List<PostHistory>?> _getRedisPostHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/history/post/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((item) => PostHistory.fromJson(item))
              .toList();
        }
      }
      return null;
    } catch (e) {
      print('Get Redis post history error: $e');
      return null;
    }
  }

  Future<List<PostHistory>?> _getLocalPostHistory(String userId) async {
    if (_postHistoryBox == null) await init();

    final cacheData = _postHistoryBox!.get(userId) as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'] as String);
    if (DateTime.now().difference(timestamp) > _localCacheExpiry) {
      await _postHistoryBox!.delete(userId);
      return null;
    }

    return (cacheData['data'] as List)
        .map((item) => PostHistory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> cachePostHistory(String userId, List<PostHistory> history) async {
    try {
      await Future.wait([
        _setRedisPostHistory(userId, history),
        _setLocalPostHistory(userId, history)
      ]);
    } catch (e) {
      print('Cache post history error: $e');
    }
  }

  Future<void> _setRedisPostHistory(String userId, List<PostHistory> history) async {
    try {
      await http.post(
        Uri.parse('$_redisProxyUrl/cache/history/post'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'data': history.map((item) => item.toJson()).toList(),
          'expiration': _redisCacheExpiry.inSeconds,
        }),
      );
    } catch (e) {
      print('Set Redis post history error: $e');
    }
  }

  Future<void> _setLocalPostHistory(String userId, List<PostHistory> history) async {
    if (_postHistoryBox == null) await init();

    final jsonData = history.map((item) {
      final json = item.toJson();
      // 将 ObjectId 转换为字符串
      json['_id'] = json['_id'].toHexString();
      json['userId'] = json['userId'].toHexString();
      return json;
    }).toList();

    await _postHistoryBox!.put(userId, {
      'data': jsonData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 清除指定用户的所有缓存
  Future<void> clearUserCache(String userId) async {
    try {
      // 清除Redis缓存
      await http.delete(Uri.parse('$_redisProxyUrl/cache/history/game/$userId'));
      await http.delete(Uri.parse('$_redisProxyUrl/cache/history/post/$userId'));

      // 清除本地缓存
      if (_gameHistoryBox != null && _gameHistoryBox!.isOpen) {
        await _gameHistoryBox!.delete(userId);
      }
      if (_postHistoryBox != null && _postHistoryBox!.isOpen) {
        await _postHistoryBox!.delete(userId);
      }
    } catch (e) {
      print('Clear user cache error: $e');
    }
  }

  // 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      // 清除Redis缓存
      await http.delete(Uri.parse('$_redisProxyUrl/cache/history/all'));

      // 清除本地缓存
      if (_gameHistoryBox != null && _gameHistoryBox!.isOpen) {
        await _gameHistoryBox!.clear();
      }
      if (_postHistoryBox != null && _postHistoryBox!.isOpen) {
        await _postHistoryBox!.clear();
      }
    } catch (e) {
      print('Clear all cache error: $e');
    }
  }

  // 关闭所有本地缓存盒子
  Future<void> closeBoxes() async {
    try {
      if (_gameHistoryBox != null && _gameHistoryBox!.isOpen) {
        await _gameHistoryBox!.close();
        _gameHistoryBox = null;
      }
      if (_postHistoryBox != null && _postHistoryBox!.isOpen) {
        await _postHistoryBox!.close();
        _postHistoryBox = null;
      }
    } catch (e) {
      print('Close boxes error: $e');
    }
  }
}