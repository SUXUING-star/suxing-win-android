// lib/services/cache/game_cache_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/game.dart';

class GameCacheService {
  static final GameCacheService _instance = GameCacheService._internal();
  factory GameCacheService() => _instance;
  GameCacheService._internal();

  static const String boxName = 'games_cache';
  static const int cacheExpiration = 10;
  late Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  Future<void> cacheGames(String key, List<Game> games) async {
    try {
      final currentTime = DateTime.now();
      await _box.put('${key}_timestamp', currentTime.toIso8601String());

      // 优化数据结构，分离图片URL和其他数据
      final gameDataList = games.map((game) {
        final json = game.toJson();
        // 存储图片URL的引用
        _box.put('${key}_image_${game.id}', json['coverImage']);
        // 移除大型数据以减少主缓存大小
        json['coverImage'] = game.id; // 仅存储ID引用
        return Map<String, dynamic>.from(json);
      }).toList();

      await _box.put(key, gameDataList);
    } catch (e) {
      print('Cache games error: $e');
      rethrow;
    }
  }

  Future<List<Game>?> getCachedGames(String key) async {
    try {
      final timestamp = _box.get('${key}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      final currentTime = DateTime.now();
      final difference = currentTime.difference(lastUpdateTime).inMinutes;

      if (difference >= cacheExpiration) {
        return null;
      }

      final cachedData = _box.get(key);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final gameMap = Map<String, dynamic>.from(item as Map);
        // 恢复图片URL
        final gameId = gameMap['coverImage'];
        gameMap['coverImage'] = _box.get('${key}_image_${gameId}');

        if (gameMap['downloadLinks'] != null) {
          gameMap['downloadLinks'] = (gameMap['downloadLinks'] as List)
              .map((link) => Map<String, dynamic>.from(link as Map))
              .toList();
        }
        return Game.fromJson(gameMap);
      }).toList();
    } catch (e) {
      print('Get cached games error: $e');
      return null;
    }
  }

  Future<void> clearCacheData() async {
    try {
      if (_box.isOpen) {
        await _box.clear();
      }
    } catch (e) {
      print('Clear games cache data error: $e');
      rethrow;
    }
  }

  // 修改现有的clearCache方法
  Future<void> clearCache() async {
    try {
      if (_box.isOpen) {
        await _box.clear();
      }
    } catch (e) {
      print('Clear games cache error: $e');
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
}