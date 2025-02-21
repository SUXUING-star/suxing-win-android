// lib/services/cache/info_cache_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';

class InfoCacheService {
  static final InfoCacheService _instance = InfoCacheService._internal();
  factory InfoCacheService() => _instance;

  // Hive boxes
  static const String _infoBoxName = 'userInfoCache';
  static const String _avatarBoxName = 'avatarCache';
  static const Duration _localCacheExpiry = Duration(minutes: 8);

  // Redis 相关
  final String _redisProxyUrl = AppConfig.redisProxyUrl;
  static const Duration _redisCacheExpiry = Duration(minutes: 15);

  Box<Map>? _infoBox;
  Box<Map>? _avatarBox;

  InfoCacheService._internal();

  Future<void> init() async {
    _infoBox = await Hive.openBox<Map>(_infoBoxName);
    _avatarBox = await Hive.openBox<Map>(_avatarBoxName);
    // 定期清理过期缓存
    _cleanExpiredCache();
  }

  // 清理过期的本地缓存
  Future<void> _cleanExpiredCache() async {
    if (_infoBox == null || _avatarBox == null) return;

    final now = DateTime.now();
    final List<String> infoKeysToDelete = [];
    final List<String> avatarKeysToDelete = [];

    // 清理用户信息缓存
    for (var key in _infoBox!.keys) {
      final cacheData = _infoBox!.get(key) as Map?;
      if (cacheData == null) continue;

      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      if (now.difference(timestamp) > _localCacheExpiry) {
        infoKeysToDelete.add(key as String);
      }
    }

    // 清理头像缓存
    for (var key in _avatarBox!.keys) {
      final cacheData = _avatarBox!.get(key) as Map?;
      if (cacheData == null) continue;

      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      if (now.difference(timestamp) > _localCacheExpiry) {
        avatarKeysToDelete.add(key as String);
      }
    }

    await _infoBox!.deleteAll(infoKeysToDelete);
    await _avatarBox!.deleteAll(avatarKeysToDelete);
  }

  // 获取用户信息（先查Redis，再查本地缓存）
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      // 1. 尝试从Redis获取
      final redisData = await _getRedisUserInfo(userId);
      if (redisData != null) {
        // 更新本地缓存
        await _setLocalUserInfo(userId, redisData);
        return redisData;
      }

      // 2. Redis没有，尝试从本地缓存获取
      final localData = await _getLocalUserInfo(userId);
      if (localData != null) {
        // 异步更新Redis缓存
        _setRedisUserInfo(userId, localData);
        return localData;
      }

      return null;
    } catch (e) {
      print('Get user info error: $e');
      return null;
    }
  }

  // 修改从Redis获取用户信息的方法
  Future<Map<String, dynamic>?> _getRedisUserInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/info/user/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          // 确保返回正确的类型
          return _convertToStringKeyMap(responseData['data'] as Map);
        }
      }
      return null;
    } catch (e) {
      print('Get Redis user info error: $e');
      return null;
    }
  }

  // 添加类型转换工具方法
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

// 修改从本地缓存获取用户信息的方法
  Future<Map<String, dynamic>?> _getLocalUserInfo(String userId) async {
    if (_infoBox == null) await init();

    final cacheData = _infoBox!.get(userId) as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _localCacheExpiry) {
      await _infoBox!.delete(userId);
      return null;
    }

    try {
      // 确保返回正确的类型
      return _convertToStringKeyMap(cacheData['data'] as Map);
    } catch (e) {
      print('Error converting cached user info: $e');
      await _infoBox!.delete(userId);
      return null;
    }
  }

  // 设置Redis用户信息缓存
  Future<void> _setRedisUserInfo(String userId, Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse('$_redisProxyUrl/cache/info/user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'data': data,
          'expiration': _redisCacheExpiry.inSeconds,
        }),
      );
    } catch (e) {
      print('Set Redis user info error: $e');
    }
  }

  // 修改设置本地用户信息的方法
  Future<void> _setLocalUserInfo(String userId, Map<String, dynamic> data) async {
    if (_infoBox == null) await init();

    // 确保存储的数据类型正确
    final Map<String, dynamic> cacheData = {
      'data': _convertToStringKeyMap(data),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _infoBox!.put(userId, cacheData);
  }

  // 公开的设置用户信息方法
  Future<void> setUserInfo(String userId, Map<String, dynamic> data) async {
    try {
      // 同时更新Redis和本地缓存
      await Future.wait([
        _setRedisUserInfo(userId, data),
        _setLocalUserInfo(userId, data)
      ]);
    } catch (e) {
      print('Set user info error: $e');
    }
  }

  // 获取头像（先查Redis，再查本地缓存）
  Future<String?> getAvatar(String userId) async {
    try {
      // 1. 尝试从Redis获取
      final redisAvatar = await _getRedisAvatar(userId);
      if (redisAvatar != null) {
        // 更新本地缓存
        await _setLocalAvatar(userId, redisAvatar);
        return redisAvatar;
      }

      // 2. Redis没有，尝试从本地缓存获取
      final localAvatar = await _getLocalAvatar(userId);
      if (localAvatar != null) {
        // 异步更新Redis缓存
        _setRedisAvatar(userId, localAvatar);
        return localAvatar;
      }

      return null;
    } catch (e) {
      print('Get avatar error: $e');
      return null;
    }
  }

  // 从Redis获取头像
  Future<String?> _getRedisAvatar(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/info/avatar/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return responseData['data']['avatar'];
        }
      }
      return null;
    } catch (e) {
      print('Get Redis avatar error: $e');
      return null;
    }
  }

  // 修改从本地缓存获取头像的方法
  Future<String?> _getLocalAvatar(String userId) async {
    if (_avatarBox == null) await init();

    final cacheData = _avatarBox!.get(userId) as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _localCacheExpiry) {
      await _avatarBox!.delete(userId);
      return null;
    }

    try {
      final convertedData = _convertToStringKeyMap(cacheData);
      return convertedData['avatar'] as String?;
    } catch (e) {
      print('Error converting cached avatar: $e');
      await _avatarBox!.delete(userId);
      return null;
    }
  }

  // 设置Redis头像缓存
  Future<void> _setRedisAvatar(String userId, String avatarUrl) async {
    try {
      await http.post(
        Uri.parse('$_redisProxyUrl/cache/info/avatar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'avatar': avatarUrl,
          'expiration': _redisCacheExpiry.inSeconds,
        }),
      );
    } catch (e) {
      print('Set Redis avatar error: $e');
    }
  }

  // 设置本地头像缓存
  Future<void> _setLocalAvatar(String userId, String avatarUrl) async {
    if (_avatarBox == null) await init();

    await _avatarBox!.put(userId, {
      'avatar': avatarUrl,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }


  // 删除指定用户的所有缓存
  Future<void> removeUserCache(String userId) async {
    try {
      // 删除Redis缓存
      await http.delete(Uri.parse('$_redisProxyUrl/cache/info/user/$userId'));
      await http.delete(Uri.parse('$_redisProxyUrl/cache/info/avatar/$userId'));

      // 删除本地缓存
      if (_infoBox != null && _infoBox!.isOpen) {
        await _infoBox!.delete(userId);
      }
      if (_avatarBox != null && _avatarBox!.isOpen) {
        await _avatarBox!.delete(userId);
      }
    } catch (e) {
      print('Remove user cache error: $e');
    }
  }

  // 清理所有缓存数据
  Future<void> clearAllCache() async {
    try {
      // 清理Redis缓存
      await http.delete(Uri.parse('$_redisProxyUrl/cache/info/all'));

      // 清理本地缓存
      if (_infoBox != null && _infoBox!.isOpen) {
        await _infoBox!.clear();
      }
      if (_avatarBox != null && _avatarBox!.isOpen) {
        await _avatarBox!.clear();
      }
    } catch (e) {
      print('Clear all cache error: $e');
    }
  }

  // 关闭所有本地缓存盒子
  Future<void> closeBoxes() async {
    try {
      if (_infoBox != null && _infoBox!.isOpen) {
        await _infoBox!.close();
        _infoBox = null;
      }
      if (_avatarBox != null && _avatarBox!.isOpen) {
        await _avatarBox!.close();
        _avatarBox = null;
      }
    } catch (e) {
      print('Close boxes error: $e');
    }
  }
}