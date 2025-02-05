// lib/services/history_service.dart
import '../models/history.dart';
import './db_connection_service.dart';
import './user_service.dart';
import 'package:mongo_dart/mongo_dart.dart';  // 添加这行导入

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();

  HistoryService._internal();

  Future<void> addHistory(String gameId) async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) return;

      final userObjectId = ObjectId.fromHexString(userId);
      final gameObjectId = ObjectId.fromHexString(gameId);

      await _dbConnectionService.history.updateOne(
        where.eq('userId', userObjectId).eq('gameId', gameObjectId),
        {
          r'$set': {
            'lastViewTime': DateTime.now(),
          }
        },
        upsert: true,
      );
    } catch (e) {
      print('Add history error: $e');
      rethrow;
    }
  }

  Stream<List<History>> getUserHistory() async* {
    try {
      while (true) {
        final userId = await _userService.currentUserId;
        if (userId == null) {
          yield [];
          return;
        }

        final userObjectId = ObjectId.fromHexString(userId);

        final history = await _dbConnectionService.history
            .find(where.eq('userId', userObjectId).sortBy('lastViewTime', descending: true))
            .map((doc) => History.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();

        yield history;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get history error: $e');
      yield [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) return;

      await _dbConnectionService.history.deleteMany(
          where.eq('userId', ObjectId.fromHexString(userId))
      );
    } catch (e) {
      print('Clear history error: $e');
      rethrow;
    }
  }
}