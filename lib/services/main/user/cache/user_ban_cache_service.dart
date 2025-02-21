// lib/services/cache/user_ban_cache_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';
import '../../../../models/user/user_ban.dart';

class UserBanCacheService {
  static final UserBanCacheService _instance = UserBanCacheService._internal();
  factory UserBanCacheService() => _instance;
  UserBanCacheService._internal();

  final String _redisProxyUrl = AppConfig.redisProxyUrl;
  static const int cacheExpiration = 5; // 5分钟缓存过期

  Future<void> init() async {
    try {
      await clearAllBanCache();
    } catch (e) {
      print('Init ban cache error: $e');
    }
  }

  Future<void> cacheBan(String userId, UserBan ban) async {
    try {
      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/bans'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'key': 'ban_$userId',
          'data': ban.toJson(),
          'expiration': cacheExpiration,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Cache ban error: $e');
    }
  }

  Future<UserBan?> getCachedBan(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/bans/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return UserBan.fromJson(Map<String, dynamic>.from(data['data']));
        }
      }
      return null;
    } catch (e) {
      print('Get cached ban error: $e');
      return null;
    }
  }

  Future<void> removeBanCache(String userId) async {
    try {
      await http.delete(
        Uri.parse('$_redisProxyUrl/cache/bans/$userId'),
      );
    } catch (e) {
      print('Remove ban cache error: $e');
    }
  }

  Future<void> clearAllBanCache() async {
    try {
      await http.delete(
        Uri.parse('$_redisProxyUrl/cache/bans'),
      );
    } catch (e) {
      print('Clear all ban cache error: $e');
    }
  }
}