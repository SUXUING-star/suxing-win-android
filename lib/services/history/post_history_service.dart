// lib/services/post_history_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../../models/post_history.dart';
import './../db_connection_service.dart';
import './../user_service.dart';

class PostHistoryService {
  static final PostHistoryService _instance = PostHistoryService._internal();
  factory PostHistoryService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();

  PostHistoryService._internal();

  bool _isValidObjectId(String? id) {
    if (id == null) return false;
    try {
      ObjectId.fromHexString(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addPostHistory(String postId) async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) {
        print('Cannot add post history: User not logged in');
        return;
      }

      final userObjectId = ObjectId.fromHexString(userId);
      print('Adding post history - userId: $userId, postId: $postId');

      // 先删除已存在的记录
      await _dbConnectionService.postHistory.deleteMany({
        'userId': userObjectId,
        'postId': postId,
      });

      // 插入新记录
      final newDoc = {
        '_id': ObjectId(),
        'userId': userObjectId,
        'postId': postId,
        'lastViewTime': DateTime.now()
      };

      await _dbConnectionService.postHistory.insertOne(newDoc);
      print('Post history record inserted successfully');

    } catch (e) {
      print('Add post history error: $e');
      rethrow;
    }
  }

  Stream<List<PostHistory>> getUserPostHistory() async* {
    while (true) {
      try {
        final userId = await _userService.currentUserId;
        if (userId == null || userId.isEmpty) {
          print('Cannot get post history: User not logged in');
          yield [];
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        final userObjectId = ObjectId.fromHexString(userId);
        print('Fetching post history for user: $userId');

        final historyDocs = await _dbConnectionService.postHistory
            .find(where
            .eq('userId', userObjectId)
            .sortBy('lastViewTime', descending: true))
            .toList();

        print('Found ${historyDocs.length} post history records');

        final history = historyDocs.map((doc) {
          return PostHistory.fromJson(doc);
        }).toList();

        yield history;
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('Get post history error: $e');
        yield [];
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> clearPostHistory() async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) return;

      await _dbConnectionService.postHistory.deleteMany(
          where.eq('userId', ObjectId.fromHexString(userId))
      );
      print('Post history cleared successfully');
    } catch (e) {
      print('Clear post history error: $e');
      rethrow;
    }
  }
}