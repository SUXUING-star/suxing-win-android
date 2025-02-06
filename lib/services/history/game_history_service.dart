// lib/services/game_history_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../../models/game_history.dart';
import './../db_connection_service.dart';
import './../user_service.dart';

class GameHistoryService {
  static final GameHistoryService _instance = GameHistoryService._internal();
  factory GameHistoryService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();

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
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) {
        print('Cannot add game history: User not logged in');
        return;
      }
      print("Save game history - gameId: $gameId, userId: $userId");

      final userObjectId = ObjectId.fromHexString(userId);

      // 先删除已存在的记录
      await _dbConnectionService.gameHistory.deleteMany({
        'userId': userObjectId,
        'gameId': gameId,
      });

      // 插入新记录
      final newDoc = {
        '_id': ObjectId(),
        'userId': userObjectId,
        'gameId': gameId,
        'lastViewTime': DateTime.now()
      };

      await _dbConnectionService.gameHistory.insertOne(newDoc);
      print('Game history record inserted successfully');

    } catch (e) {
      print('Add game history error: $e');
      rethrow;
    }
  }

  Stream<List<GameHistory>> getUserGameHistory() async* {
    while (true) {
      try {
        final userId = await _userService.currentUserId;
        if (userId == null || userId.isEmpty) {
          print('Cannot get game history: User not logged in');
          yield [];
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        final userObjectId = ObjectId.fromHexString(userId);
        print('Fetching game history for user: $userId');

        final historyDocs = await _dbConnectionService.gameHistory
            .find(where
            .eq('userId', userObjectId)
            .sortBy('lastViewTime', descending: true))
            .toList();

        print('Found ${historyDocs.length} game history records');

        final history = historyDocs.map((doc) {
          return GameHistory.fromJson(doc);
        }).toList();

        yield history;
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