// lib/services/post_history_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../../models/post_history.dart';
import './../db_connection_service.dart';
import './../user_service.dart';
import '../counter/batch_history_service.dart';
import '../cache/history_cache_service.dart';

class PostHistoryService {
  static final PostHistoryService _instance = PostHistoryService._internal();
  factory PostHistoryService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();
  final BatchHistoryService _batchHistoryService = BatchHistoryService();

  final HistoryCacheService _cacheService = HistoryCacheService();

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
    await _batchHistoryService.addPostHistory(postId);
  }

  Stream<List<PostHistory>> getUserPostHistory() async* {
    while (true) {
      try {
        final userId = await _userService.currentUserId;
        if (userId == null || userId.isEmpty) {
          yield [];
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        // 尝试从缓存获取
        final cachedHistory = await _cacheService.getCachedPostHistory(userId);
        if (cachedHistory != null) {
          yield cachedHistory;
        } else {
          // 从数据库获取
          final userObjectId = ObjectId.fromHexString(userId);
          final historyDocs = await _dbConnectionService.postHistory
              .find(where
              .eq('userId', userObjectId)
              .sortBy('lastViewTime', descending: true))
              .toList();

          final history = historyDocs.map((doc) => PostHistory.fromJson(doc)).toList();

          // 更新缓存
          await _cacheService.cachePostHistory(userId, history);
          yield history;
        }

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