// lib/services/message_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../../../models/message/message.dart';
import '../database/db_service.dart';
import '../user/user_service.dart';
import 'cache/message_cache_service.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;

  final DBService _dbConnectionService = DBService();
  final UserService _userService = UserService();
  final MessageCacheService _messageCacheService = MessageCacheService();

  // 缓存刷新间隔
  static const Duration _refreshInterval = Duration(seconds: 30);  // 改为30秒

  MessageService._internal();

  // 获取用户的消息列表
  Stream<List<Message>> getUserMessages() async* {
    try {
      DateTime? lastRefreshTime;

      while (true) {
        final currentUser = await _userService.getCurrentUser();
        final now = DateTime.now();

        // 检查是否需要刷新缓存
        bool shouldRefresh = lastRefreshTime == null ||
            now.difference(lastRefreshTime) >= _refreshInterval;

        if (shouldRefresh) {
          // 从数据库获取最新数据
          final messages = await _dbConnectionService.messages
              .find(where
              .eq('recipientId', ObjectId.fromHexString(currentUser.id))
              .sortBy('createTime', descending: true))
              .map((doc) {
            try {
              return Message.fromJson(doc);
            } catch (e) {
              print('Error converting message: $e');
              print('Problematic document: ${doc.toString()}');
              return null;
            }
          })
              .where((message) => message != null)
              .cast<Message>()
              .toList();

          // 更新缓存
          if (messages.isNotEmpty) {
            await _messageCacheService.setUserMessages(currentUser.id, messages);
          }

          lastRefreshTime = now;
          yield messages;
        } else {
          // 使用缓存数据
          final cachedMessages = await _messageCacheService.getUserMessages(currentUser.id);
          if (cachedMessages != null) {
            yield cachedMessages;
          }
        }

        await Future.delayed(const Duration(seconds: 3)); // 降低轮询频率
      }
    } catch (e) {
      print('Get messages error: $e');
      print('Stack trace: ${e.toString()}');
      yield [];
    }
  }

  // 获取未读消息数量
  Stream<int> getUnreadCount() async* {
    try {
      DateTime? lastRefreshTime;

      while (true) {
        final currentUser = await _userService.getCurrentUser();
        final now = DateTime.now();

        // 检查是否需要刷新缓存
        bool shouldRefresh = lastRefreshTime == null ||
            now.difference(lastRefreshTime) >= _refreshInterval;

        if (shouldRefresh) {
          // 从数据库获取最新数据
          final count = await _dbConnectionService.messages.count(
              where
                  .eq('recipientId', ObjectId.fromHexString(currentUser.id))
                  .eq('isRead', false)
          );

          // 更新缓存
          await _messageCacheService.setUnreadCount(currentUser.id, count);

          lastRefreshTime = now;
          yield count;
        } else {
          // 使用缓存数据
          final cachedCount = await _messageCacheService.getUnreadCount(currentUser.id);
          if (cachedCount != null) {
            yield cachedCount;
          }
        }

        await Future.delayed(const Duration(seconds: 3)); // 降低轮询频率
      }
    } catch (e) {
      print('Get unread count error: $e');
      yield 0;
    }
  }

  // 标记消息为已读
  Future<void> markAsRead(String messageId) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      await _dbConnectionService.messages.updateOne(
        where
            .eq('_id', ObjectId.fromHexString(messageId))
            .eq('recipientId', ObjectId.fromHexString(currentUser.id)),
        {
          r'$set': {
            'isRead': true,
            'readTime': DateTime.now().toIso8601String(), // 修改为ISO字符串
          }
        },
      );

      // 清除相关缓存
      await _messageCacheService.clearUserCache(currentUser.id);
    } catch (e) {
      print('Mark as read error: $e');
      rethrow;
    }
  }

  // 发送消息
  Future<void> sendMessage(String recipientId, String content, String type) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final message = {
        'senderId': ObjectId.fromHexString(currentUser.id),
        'recipientId': ObjectId.fromHexString(recipientId),
        'content': content,
        'type': type,
        'isRead': false,
        'createTime': DateTime.now().toIso8601String(), // 修改为ISO字符串
        'readTime': null,
      };

      await _dbConnectionService.messages.insertOne(message);

      // 清除接收者的相关缓存
      await _messageCacheService.clearUserCache(recipientId);
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }

  // 删除消息
  Future<void> deleteMessage(String messageId) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      await _dbConnectionService.messages.deleteOne(
        where
            .eq('_id', ObjectId.fromHexString(messageId))
            .eq('recipientId', ObjectId.fromHexString(currentUser.id)),
      );

      // 清除相关缓存
      await _messageCacheService.clearUserCache(currentUser.id);
    } catch (e) {
      print('Delete message error: $e');
      rethrow;
    }
  }
}