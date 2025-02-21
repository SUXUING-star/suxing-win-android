// lib/services/cache/message_cache_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart' ;
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import '../../../../config/app_config.dart';
import '../../../../models/message/message.dart';

class MessageCacheService {
  static final MessageCacheService _instance = MessageCacheService._internal();
  factory MessageCacheService() => _instance;

  // Hive boxes
  static const String _messageBoxName = 'messageCache';
  static const String _unreadCountBoxName = 'unreadCountCache';
  static const Duration _localCacheExpiry = Duration(minutes: 5);

  // Redis configuration
  final String _redisProxyUrl = AppConfig.redisProxyUrl;
  static const Duration _redisCacheExpiry = Duration(minutes: 10);

  Box<Map>? _messageBox;
  Box<int>? _unreadCountBox;

  MessageCacheService._internal();

  Future<void> init() async {
    _messageBox = await Hive.openBox<Map>(_messageBoxName);
    _unreadCountBox = await Hive.openBox<int>(_unreadCountBoxName);
    // Schedule periodic cache cleanup
    _cleanExpiredCache();
  }

  // Clean expired local cache
  // Clean unread count cache
  Future<void> _cleanExpiredCache() async {
    if (_messageBox == null || _unreadCountBox == null) return;

    final now = DateTime.now();
    final List<String> messageKeysToDelete = [];
    final List<String> unreadCountKeysToDelete = [];

    // Clean message cache
    for (var key in _messageBox!.keys) {
      final cacheData = _messageBox!.get(key) as Map?;
      if (cacheData == null) continue;

      final timestamp = DateTime.parse(cacheData['timestamp'].toString());
      if (now.difference(timestamp) > _localCacheExpiry) {
        messageKeysToDelete.add(key as String);
      }
    }

    // Clean unread count cache
    for (var key in _unreadCountBox!.keys) {
      final cacheData = _unreadCountBox!.get(key);
      if (cacheData == null) continue;

      // 修改此处:将 key 字符串转换为 DateTime
      final timestamp = key.toString().split('_').last;
      if (now.difference(DateTime.parse(timestamp)) > _localCacheExpiry) {
        unreadCountKeysToDelete.add(key as String);
      }
    }

    await _messageBox!.deleteAll(messageKeysToDelete);
    await _unreadCountBox!.deleteAll(unreadCountKeysToDelete);
  }

  // 转换消息对象为可缓存的格式
  Map<String, dynamic> _convertMessageToJson(Message message) {
    return {
      '_id': ObjectId.fromHexString(message.id),
      'senderId': ObjectId.fromHexString(message.senderId),
      'recipientId': ObjectId.fromHexString(message.recipientId),
      'content': message.content,
      'type': message.type,
      'isRead': message.isRead,
      'createTime': message.createTime.toIso8601String(),
      'readTime': message.readTime?.toIso8601String(),
      'gameId': message.gameId != null ? ObjectId.fromHexString(message.gameId!) : null,
      'postId': message.postId != null ? ObjectId.fromHexString(message.postId!) : null,
    };
  }

  // 设置用户消息的缓存(公开方法)
  Future<void> setUserMessages(String userId, List<Message> messages) async {
    try {
      // 转换消息列表为可缓存的格式
      final messageJsonList = messages.map(_convertMessageToJson).toList();

      // 更新本地缓存
      await _setLocalMessages(userId, messages);

      // 更新Redis缓存
      await _setRedisMessages(userId, messages);
    } catch (e) {
      print('Set user messages cache error: $e');
    }
  }

  // 设置未读消息数量的缓存(公开方法)
  Future<void> setUnreadCount(String userId, int count) async {
    try {
      // 更新本地缓存
      await _setLocalUnreadCount(userId, count);

      // 更新Redis缓存
      await _setRedisUnreadCount(userId, count);
    } catch (e) {
      print('Set unread count cache error: $e');
    }
  }

  // Get user messages from Redis
  Future<List<Message>?> _getRedisMessages(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/messages/user/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final List<dynamic> messageList = responseData['data'];
          return messageList.map((msgData) => Message.fromJson(msgData)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Get Redis messages error: $e');
      return null;
    }
  }

  // Get messages from local cache
  Future<List<Message>?> _getLocalMessages(String userId) async {
    if (_messageBox == null) await init();

    final cacheData = _messageBox!.get(userId) as Map?;
    if (cacheData == null) return null;

    final timestamp = DateTime.parse(cacheData['timestamp'].toString());
    if (DateTime.now().difference(timestamp) > _localCacheExpiry) {
      await _messageBox!.delete(userId);
      return null;
    }

    try {
      final List<dynamic> messageList = (cacheData['data'] as List).cast<Map>();
      return messageList.map((msgData) => Message.fromJson(msgData)).toList();
    } catch (e) {
      print('Error converting cached messages: $e');
      await _messageBox!.delete(userId);
      return null;
    }
  }

  // Set messages in Redis
  Future<void> _setRedisMessages(String userId, List<Message> messages) async {
    try {
      final messageJsonList = messages.map(_convertMessageToJson).toList();
      await http.post(
        Uri.parse('$_redisProxyUrl/cache/messages/user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'messages': messageJsonList,
          'expiration': _redisCacheExpiry.inSeconds,
        }),
      );
    } catch (e) {
      print('Set Redis messages error: $e');
    }
  }

  // Set messages in local cache
  Future<void> _setLocalMessages(String userId, List<Message> messages) async {
    if (_messageBox == null) await init();

    final messageJsonList = messages.map(_convertMessageToJson).toList();
    await _messageBox!.put(userId, {
      'data': messageJsonList,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Redis operations for unread count
  Future<int?> _getRedisUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/messages/unread/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return responseData['data']['count'] as int;
        }
      }
      return null;
    } catch (e) {
      print('Get Redis unread count error: $e');
      return null;
    }
  }

  Future<void> _setRedisUnreadCount(String userId, int count) async {
    try {
      await http.post(
        Uri.parse('$_redisProxyUrl/cache/messages/unread'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'count': count,
          'expiration': _redisCacheExpiry.inSeconds,
        }),
      );
    } catch (e) {
      print('Set Redis unread count error: $e');
    }
  }

  // Local cache operations for unread count
  Future<int?> _getLocalUnreadCount(String userId) async {
    if (_unreadCountBox == null) await init();

    final key = '${userId}_${DateTime.now().toIso8601String()}';
    final count = _unreadCountBox!.get(key);
    if (count == null) return null;

    final timestamp = DateTime.parse(key.split('_').last);
    if (DateTime.now().difference(timestamp) > _localCacheExpiry) {
      await _unreadCountBox!.delete(key);
      return null;
    }

    return count;
  }

  Future<void> _setLocalUnreadCount(String userId, int count) async {
    if (_unreadCountBox == null) await init();

    final key = '${userId}_${DateTime.now().toIso8601String()}';
    await _unreadCountBox!.put(key, count);
  }

  // Get user messages (public method)
  Future<List<Message>?> getUserMessages(String userId) async {
    try {
      // Try Redis first
      final redisMessages = await _getRedisMessages(userId);
      if (redisMessages != null) {
        // Update local cache
        await _setLocalMessages(userId, redisMessages);
        return redisMessages;
      }

      // Try local cache if Redis fails
      return await _getLocalMessages(userId);
    } catch (e) {
      print('Get cached messages error: $e');
      return null;
    }
  }

  // Get unread count (public method)
  Future<int?> getUnreadCount(String userId) async {
    try {
      // Try Redis first
      final redisCount = await _getRedisUnreadCount(userId);
      if (redisCount != null) {
        // Update local cache
        await _setLocalUnreadCount(userId, redisCount);
        return redisCount;
      }

      // Try local cache if Redis fails
      return await _getLocalUnreadCount(userId);
    } catch (e) {
      print('Get cached unread count error: $e');
      return null;
    }
  }

  // Clear cache for specific user
  Future<void> clearUserCache(String userId) async {
    try {
      // Clear Redis cache
      await http.delete(Uri.parse('$_redisProxyUrl/cache/messages/user/$userId'));
      await http.delete(Uri.parse('$_redisProxyUrl/cache/messages/unread/$userId'));

      // Clear local cache
      if (_messageBox != null && _messageBox!.isOpen) {
        await _messageBox!.delete(userId);
      }
      if (_unreadCountBox != null && _unreadCountBox!.isOpen) {
        final unreadCountKeys = _unreadCountBox!.keys
            .where((key) => (key as String).startsWith(userId))
            .toList();
        await _unreadCountBox!.deleteAll(unreadCountKeys);
      }
    } catch (e) {
      print('Clear user message cache error: $e');
    }
  }

  // Close Hive boxes
  Future<void> closeBoxes() async {
    try {
      if (_messageBox != null && _messageBox!.isOpen) {
        await _messageBox!.close();
        _messageBox = null;
      }
      if (_unreadCountBox != null && _unreadCountBox!.isOpen) {
        await _unreadCountBox!.close();
        _unreadCountBox = null;
      }
    } catch (e) {
      print('Close message cache boxes error: $e');
    }
  }
}