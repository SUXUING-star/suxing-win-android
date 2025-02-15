// lib/services/cache/avatar_cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';

class AvatarCacheService {
  static const String _boxName = 'avatarCache';
  static const Duration _cacheExpiry = Duration(minutes: 8);

  static final AvatarCacheService _instance = AvatarCacheService._internal();
  factory AvatarCacheService() => _instance;

  Box<Map>? _box;

  AvatarCacheService._internal();

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    // 定期清理过期缓存
    _cleanExpiredCache();
  }

  Future<void> _cleanExpiredCache() async {
    if (_box == null) return;

    final now = DateTime.now();
    final List<String> keysToDelete = [];

    for (var key in _box!.keys) {
      final cacheData = _box!.get(key) as Map?;
      if (cacheData == null) continue;

      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      if (now.difference(timestamp) > _cacheExpiry) {
        keysToDelete.add(key as String);
      }
    }

    await _box!.deleteAll(keysToDelete);
  }

  Future<String?> getAvatar(String userId) async {
    if (_box == null) await init();

    final cacheData = _box!.get(userId) as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'] as String);
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await _box!.delete(userId);
      return null;
    }

    return cacheData['avatar'] as String?;
  }

  Future<void> setAvatar(String userId, String avatarUrl) async {
    if (_box == null) await init();

    await _box!.put(userId, {
      'avatar': avatarUrl,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  // 新增：只清理数据但不关闭box
  Future<void> clearCacheData() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.clear();
      }
    } catch (e) {
      print('Clear avatar cache data error: $e');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    if (_box == null) await init();
    await _box!.clear();
  }

  Future<void> removeAvatar(String userId) async {
    if (_box == null) await init();
    await _box!.delete(userId);
  }
}