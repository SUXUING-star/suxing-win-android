// lib/services/cache/game_cache_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../models/game/game.dart';
import '../../../../config/app_config.dart';

class GameCacheService {
  static final GameCacheService _instance = GameCacheService._internal();
  factory GameCacheService() => _instance;
  GameCacheService._internal();

  static const String boxName = 'games_cache';
  static const int cacheExpiration = 10;
  late Box<dynamic> _box;
  final String _redisProxyUrl = AppConfig.redisProxyUrl;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  Future<void> cacheGames(String key, List<Game> games) async {
    try {
      // 本地缓存
      await _cacheLocalGames(key, games);
      // Redis缓存
      await _cacheRedisGames(key, games);
    } catch (e) {
      print('Cache games error: $e');
      rethrow;
    }
  }

  // 本地缓存实现
  Future<void> _cacheLocalGames(String key, List<Game> games) async {
    try {
      final currentTime = DateTime.now();
      await _box.put('${key}_timestamp', currentTime.toIso8601String());

      final gameDataList = games.map((game) {
        final json = game.toJson();
        // 确保 id 被转换为字符串
        json['id'] = game.id.toString();
        // 存储图片URL的引用
        _box.put('${key}_image_${game.id}', json['coverImage']);
        // 移除大型数据以减少主缓存大小
        json['coverImage'] = game.id.toString();
        return Map<String, dynamic>.from(json);
      }).toList();

      await _box.put(key, gameDataList);
    } catch (e) {
      print('Cache local games error: $e');
    }
  }


  // Redis缓存实现
  Future<void> _cacheRedisGames(String key, List<Game> games) async {
    try {
      final gamesData = games.map((game) => game.toJson()).toList();
      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/games'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'key': key,
          'data': gamesData,
          'expiration': cacheExpiration,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Cache Redis games error: $e');
      // Redis 缓存失败不影响整体功能
    }
  }

  Future<List<Game>?> getCachedGames(String key) async {
    try {
      // 先尝试从本地缓存获取
      var games = await _getLocalCachedGames(key);
      if (games != null) {
        return games;
      }

      // 本地缓存未命中，尝试从Redis获取
      games = await _getRedisCachedGames(key);
      if (games != null) {
        // 将Redis中的数据同步到本地缓存
        await _cacheLocalGames(key, games);
      }

      return games;
    } catch (e) {
      print('Get cached games error: $e');
      return null;
    }
  }

  Future<List<Game>?> _getLocalCachedGames(String key) async {
    try {
      final timestamp = _box.get('${key}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
        return null;
      }

      final cachedData = _box.get(key);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final gameMap = Map<String, dynamic>.from(item as Map);
        // 确保id是字符串类型
        gameMap['id'] = gameMap['id'].toString();
        // 恢复图片URL
        final gameId = gameMap['coverImage'];
        gameMap['coverImage'] = _box.get('${key}_image_$gameId');

        if (gameMap['downloadLinks'] != null) {
          gameMap['downloadLinks'] = (gameMap['downloadLinks'] as List)
              .map((link) => Map<String, dynamic>.from(link as Map))
              .toList();
        }
        return Game.fromJson(gameMap);
      }).toList();
    } catch (e) {
      print('Get local cached games error: $e');
      return null;
    }
  }

  Future<List<Game>?> _getRedisCachedGames(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/games/$key'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((item) => Game.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
      return null;
    } catch (e) {
      print('Get Redis cached games error: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      // 清除本地缓存
      if (_box.isOpen) {
        await _box.clear();
      }

      // 清除Redis缓存
      try {
        await http.delete(Uri.parse('$_redisProxyUrl/cache/games'));
      } catch (e) {
        print('Clear Redis cache error: $e');
      }
    } catch (e) {
      print('Clear cache error: $e');
      rethrow;
    }
  }

  bool isCacheExpired(String key) {
    final timestamp = _box.get('${key}_timestamp');
    if (timestamp == null) return true;

    final lastUpdateTime = DateTime.parse(timestamp);
    final currentTime = DateTime.now();
    return currentTime.difference(lastUpdateTime).inMinutes >= cacheExpiration;
  }

  // 检查Redis缓存是否过期
  Future<bool> isRedisCacheExpired(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/games/$key/status'),
      );

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
}