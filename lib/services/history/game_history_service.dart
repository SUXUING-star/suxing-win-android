// lib/services/game_history_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../../models/game_history.dart';
import './../db_connection_service.dart';
import './../user_service.dart';
import '../counter/batch_history_service.dart';
import '../cache/history_cache_service.dart';

class GameHistoryService {
  static final GameHistoryService _instance = GameHistoryService._internal();
  factory GameHistoryService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final BatchHistoryService _batchHistoryService = BatchHistoryService();
  final UserService _userService = UserService();

  final HistoryCacheService _cacheService = HistoryCacheService();

  GameHistoryService._internal();

  bool _isValidObjectId(String? id) {
    if (id == null) return false;
    try {
      ObjectId.fromHexString(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addGameHistory(String gameId) async {
    await _batchHistoryService.addGameHistory(gameId);
  }

  Stream<List<GameHistory>> getUserGameHistory() async* {
    while (true) {
      try {
        final userId = await _userService.currentUserId;
        if (userId == null || userId.isEmpty) {
          yield [];
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        // 尝试从缓存获取
        final cachedHistory = await _cacheService.getCachedGameHistory(userId);
        if (cachedHistory != null) {
          yield cachedHistory;
        } else {
          // 从数据库获取
          final userObjectId = ObjectId.fromHexString(userId);
          final historyDocs = await _dbConnectionService.gameHistory
              .find(where
              .eq('userId', userObjectId)
              .sortBy('lastViewTime', descending: true))
              .toList();

          final history = historyDocs.map((doc) => GameHistory.fromJson(doc)).toList();

          // 更新缓存
          await _cacheService.cacheGameHistory(userId, history);
          yield history;
        }

        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('Get game history error: $e');
        yield [];
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> clearGameHistory() async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) return;

      await _dbConnectionService.gameHistory.deleteMany(
          where.eq('userId', ObjectId.fromHexString(userId))
      );
      print('Game history cleared successfully');
    } catch (e) {
      print('Clear game history error: $e');
      rethrow;
    }
  }
}