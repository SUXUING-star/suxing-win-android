// lib/services/cache/forum_cache_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../models/post/post.dart';
import '../../config/app_config.dart';

class ForumCacheService {
  static final ForumCacheService _instance = ForumCacheService._internal();
  factory ForumCacheService() => _instance;
  ForumCacheService._internal();

  static const String boxName = 'forum_cache';
  static const int cacheExpiration = 10; // 10分钟过期
  late Box<dynamic> _box;
  final String _redisProxyUrl = AppConfig.redisProxyUrl;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);

    // 启动时清理可能损坏的缓存
    try {
      final keys = _box.keys.toList();
      for (final key in keys) {
        if (key.toString().endsWith('_timestamp')) continue;

        final timestamp = _box.get('${key}_timestamp');
        if (timestamp == null) {
          // 没有时间戳的缓存数据，清除
          await _box.delete(key);
          continue;
        }

        try {
          final lastUpdateTime = DateTime.parse(timestamp.toString());
          if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
            // 过期的缓存，清除
            await _box.delete(key);
            await _box.delete('${key}_timestamp');
          }
        } catch (e) {
          // 时间戳格式错误，清除
          await _box.delete(key);
          await _box.delete('${key}_timestamp');
        }
      }
    } catch (e) {
      print('Clean cache on init error: $e');
    }
  }

  // 缓存帖子列表
  Future<void> cachePosts(String key, List<Post> posts) async {
    try {
      // 本地缓存
      await _cacheLocalPosts(key, posts);
      // Redis缓存
      await _cacheRedisPosts(key, posts);
    } catch (e) {
      print('Cache posts error: $e');
      rethrow;
    }
  }

  // 本地缓存实现
  Future<void> _cacheLocalPosts(String key, List<Post> posts) async {
    try {
      final currentTime = DateTime.now();
      await _box.put('${key}_timestamp', currentTime.toIso8601String());

      final postDataList = posts.map((post) {
        final json = post.toJson();
        // 确保所有ID字段都转换为字符串
        json['id'] = post.id.toString();
        json['_id'] = post.id.toString();
        json['authorId'] = post.authorId.toString();

        // 处理可能包含的 ObjectId 字段
        if (json['replyToId'] != null) {
          json['replyToId'] = json['replyToId'].toString();
        }
        return json;
      }).toList();

      await _box.put(key, postDataList);
    } catch (e) {
      print('Cache local posts error: $e');
    }
  }

  // Redis缓存实现
  Future<void> _cacheRedisPosts(String key, List<Post> posts) async {
    try {
      final postsData = posts.map((post) {
        final json = post.toJson();
        // 确保包含id字段
        json['id'] = post.id;
        // 同时保留_id以保持兼容性
        json['_id'] = post.id;
        json['authorId'] = post.authorId;
        return json;
      }).toList();

      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/forum'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'key': key,
          'data': postsData,
          'expiration': cacheExpiration,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Cache Redis posts error: $e');
    }
  }


  // 获取缓存的帖子列表
  Future<List<Post>?> getCachedPosts(String key) async {
    try {
      // 先尝试从本地缓存获取
      var posts = await _getLocalCachedPosts(key);
      if (posts != null) {
        return posts;
      }

      // 本地缓存未命中，尝试从Redis获取
      posts = await _getRedisCachedPosts(key);
      if (posts != null) {
        // 将Redis中的数据同步到本地缓存
        await _cacheLocalPosts(key, posts);
      }

      return posts;
    } catch (e) {
      print('Get cached posts error: $e');
      return null;
    }
  }

  // 从本地缓存获取帖子
  Future<List<Post>?> _getLocalCachedPosts(String key) async {
    try {
      final timestamp = _box.get('${key}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
        await _box.delete(key);
        await _box.delete('${key}_timestamp');
        return null;
      }

      final cachedData = _box.get(key);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        try {
          final Map<String, dynamic> stringKeyMap = {};
          (item as Map).forEach((key, value) {
            // 确保所有ID类型的字段都转换为字符串
            if (key.toString().endsWith('Id') || key.toString() == '_id') {
              stringKeyMap[key.toString()] = value?.toString();
            } else {
              stringKeyMap[key.toString()] = value;
            }
          });

          // 处理时间字段
          if (stringKeyMap['createTime'] != null && stringKeyMap['createTime'] is! DateTime) {
            stringKeyMap['createTime'] = DateTime.parse(stringKeyMap['createTime'].toString());
          }
          if (stringKeyMap['updateTime'] != null && stringKeyMap['updateTime'] is! DateTime) {
            stringKeyMap['updateTime'] = DateTime.parse(stringKeyMap['updateTime'].toString());
          }

          return Post.fromJson(stringKeyMap);
        } catch (e) {
          print('Error converting cached post: $e');
          print('Problematic data: $item');
          return null;
        }
      }).where((post) => post != null).cast<Post>().toList();
    } catch (e) {
      print('Get local cached posts error: $e');
      await _box.delete(key);
      await _box.delete('${key}_timestamp');
      return null;
    }
  }


  // 从Redis缓存获取帖子
  Future<List<Post>?> _getRedisCachedPosts(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/forum/$key'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List).map((item) {
            final Map<String, dynamic> post = Map<String, dynamic>.from(item);
            // 确保id字段存在且正确
            if (post['_id'] != null) {
              post['id'] = post['_id'].toString();
            } else if (post['id'] != null) {
              post['_id'] = post['id'].toString();
            }
            return Post.fromJson(post);
          }).toList();
        }
      }
      return null;
    } catch (e) {
      print('Get Redis cached posts error: $e');
      return null;
    }
  }

  Future<void> clearCache([String? key]) async {
    try {
      // 清除本地缓存
      if (_box.isOpen) {
        if (key != null) {
          await _box.delete(key);
          await _box.delete('${key}_timestamp');
          print('Cleared local cache for key: $key');
        } else {
          await _box.clear();
          print('Cleared all local cache');
        }
      }

      // 清除Redis缓存
      try {
        if (key != null) {
          await http.delete(Uri.parse('$_redisProxyUrl/cache/forum/$key'));
        } else {
          await http.delete(Uri.parse('$_redisProxyUrl/cache/forum'));
        }
      } catch (e) {
        print('Clear Redis cache error: $e');
      }
    } catch (e) {
      print('Clear cache error: $e');
      rethrow;
    }
  }


  // 检查本地缓存是否过期
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
        Uri.parse('$_redisProxyUrl/cache/forum/$key/status'),
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