// lib/services/counter/batch_history_service.dart

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../db_service.dart';
import '../../user/user_service.dart';

class BatchHistoryService {
  static final BatchHistoryService _instance = BatchHistoryService._internal();
  factory BatchHistoryService() => _instance;

  final DBService _dbConnectionService = DBService();
  final UserService _userService = UserService();

  // 使用 Map 存储待处理的历史记录
  // Key: userId_itemId, Value: 最新的访问时间
  final Map<String, _HistoryRecord> _gameHistoryQueue = {};
  final Map<String, _HistoryRecord> _postHistoryQueue = {};

  static const int _batchSize = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  Timer? _flushTimer;

  BatchHistoryService._internal() {
    _startPeriodicFlush();
  }

  void _startPeriodicFlush() {
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushAll());
  }

  Future<void> addGameHistory(String gameId) async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) {
        print('Cannot add game history: User not logged in');
        return;
      }

      final key = '${userId}_$gameId';
      _gameHistoryQueue[key] = _HistoryRecord(
        userId: userId,
        itemId: gameId,
        timestamp: DateTime.now(),
      );

      if (_gameHistoryQueue.length >= _batchSize) {
        await _flushGameHistory();
      }
    } catch (e) {
      print('Add game history to queue error: $e');
    }
  }

  Future<void> addPostHistory(String postId) async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) {
        print('Cannot add post history: User not logged in');
        return;
      }

      final key = '${userId}_$postId';
      _postHistoryQueue[key] = _HistoryRecord(
        userId: userId,
        itemId: postId,
        timestamp: DateTime.now(),
      );

      if (_postHistoryQueue.length >= _batchSize) {
        await _flushPostHistory();
      }
    } catch (e) {
      print('Add post history to queue error: $e');
    }
  }

  Future<void> _flushGameHistory() async {
    if (_gameHistoryQueue.isEmpty) return;

    try {
      await _dbConnectionService.runWithErrorHandling(() async {
        final records = Map<String, _HistoryRecord>.from(_gameHistoryQueue);
        _gameHistoryQueue.clear();

        final List<Map<String, Object>> operations = [];

        for (final record in records.values) {
          operations.add({
            'deleteOne': {
              'filter': {
                'userId': ObjectId.fromHexString(record.userId),
                'gameId': record.itemId,
              }
            }
          });

          operations.add({
            'insertOne': {
              'document': {
                '_id': ObjectId(),
                'userId': ObjectId.fromHexString(record.userId),
                'gameId': record.itemId,
                'lastViewTime': record.timestamp
              }
            }
          });
        }

        if (operations.isNotEmpty) {
          await _dbConnectionService.gameHistory.bulkWrite(operations);
        }
      });
    } catch (e) {
      print('Flush game history error: $e');
      // 如果更新失败，将记录加回队列
      _gameHistoryQueue.addAll(_gameHistoryQueue);
    }
  }

  Future<void> _flushPostHistory() async {
    if (_postHistoryQueue.isEmpty) return;

    try {
      await _dbConnectionService.runWithErrorHandling(() async {
        final records = Map<String, _HistoryRecord>.from(_postHistoryQueue);
        _postHistoryQueue.clear();

        final List<Map<String, Object>> operations = [];

        for (final record in records.values) {
          operations.add({
            'deleteOne': {
              'filter': {
                'userId': ObjectId.fromHexString(record.userId),
                'postId': record.itemId,
              }
            }
          });

          operations.add({
            'insertOne': {
              'document': {
                '_id': ObjectId(),
                'userId': ObjectId.fromHexString(record.userId),
                'postId': record.itemId,
                'lastViewTime': record.timestamp
              }
            }
          });
        }

        if (operations.isNotEmpty) {
          await _dbConnectionService.postHistory.bulkWrite(operations);
        }
      });
    } catch (e) {
      print('Flush post history error: $e');
      // 如果更新失败，将记录加回队列
      _postHistoryQueue.addAll(_postHistoryQueue);
    }
  }

  Future<void> _flushAll() async {
    await _flushGameHistory();
    await _flushPostHistory();
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await _flushAll();
  }

  int get gameHistoryQueueLength => _gameHistoryQueue.length;
  int get postHistoryQueueLength => _postHistoryQueue.length;
}

class _HistoryRecord {
  final String userId;
  final String itemId;
  final DateTime timestamp;

  _HistoryRecord({
    required this.userId,
    required this.itemId,
    required this.timestamp,
  });
}