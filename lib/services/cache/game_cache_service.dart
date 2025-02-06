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

      // 确保转换为正确的数据类型
      final gameDataList = games.map((game) {
        final json = game.toJson();
        // 确保所有值都是正确的类型
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

      // 如果缓存超过10分钟，返回null触发刷新
      if (difference >= cacheExpiration) {
        return null;
      }

      final cachedData = _box.get(key);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        // 确保将数据转换为正确的类型
        final gameMap = Map<String, dynamic>.from(item as Map);
        // 转换嵌套的数据结构
        if (gameMap['downloadLinks'] != null) {
          gameMap['downloadLinks'] = (gameMap['downloadLinks'] as List).map((link) {
            return Map<String, dynamic>.from(link as Map);
          }).toList();
        }
        return Game.fromJson(gameMap);
      }).toList();
    } catch (e) {
      print('Get cached games error: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    await _box.clear();
  }

  bool isCacheExpired(String key) {
    final timestamp = _box.get('${key}_timestamp');
    if (timestamp == null) return true;

    final lastUpdateTime = DateTime.parse(timestamp);
    final currentTime = DateTime.now();
    return currentTime.difference(lastUpdateTime).inMinutes >= cacheExpiration;
  }
}