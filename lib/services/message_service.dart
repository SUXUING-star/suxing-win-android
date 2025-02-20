// lib/services/message_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/message/message.dart';
import 'db_connection_service.dart';
import 'user_service.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();

  MessageService._internal();

  // 获取用户的消息列表
  Stream<List<Message>> getUserMessages() async* {
    try {
      while (true) {
        final currentUser = await _userService.getCurrentUser();

        // 使用字符串形式的ID进行查询
        final messages = await _dbConnectionService.messages
            .find(where
            .eq('recipientId', ObjectId.fromHexString(currentUser.id))
            .sortBy('createTime', descending: true))
            .map((doc) {
          try {
            print('Processing message document: ${doc.toString()}');
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

        //print('Retrieved ${messages.length} messages for user ${currentUser.id}');
        yield messages;
        await Future.delayed(const Duration(seconds: 1));
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
      while (true) {
        final currentUser = await _userService.getCurrentUser();
        final userId = ObjectId.fromHexString(currentUser.id);

        final count = await _dbConnectionService.messages.count(
            where
                .eq('recipientId', userId)
                .eq('isRead', false)
        );
        yield count;
        await Future.delayed(const Duration(seconds: 1));
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
            'readTime': DateTime.now(),
          }
        },
      );
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
        'senderId': currentUser.id,
        'recipientId': recipientId,
        'content': content,
        'type': type,
        'isRead': false,
        'createTime': DateTime.now(),
        'readTime': null,
      };

      await _dbConnectionService.messages.insertOne(message);
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
    } catch (e) {
      print('Delete message error: $e');
      rethrow;
    }
  }
}


