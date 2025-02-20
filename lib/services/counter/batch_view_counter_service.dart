// lib/services/counter/batch_view_counter_service.dart

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../db_connection_service.dart';

class BatchViewCounterService {
  static final BatchViewCounterService _instance = BatchViewCounterService._internal();
  factory BatchViewCounterService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final Map<String, int> _gameViewCounts = {};
  final Map<String, int> _postViewCounts = {};

  static const int _batchSize = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  Timer? _flushTimer;

  BatchViewCounterService._internal() {
    _startPeriodicFlush();
  }

  void _startPeriodicFlush() {
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushAll());
  }

  void incrementGameView(String gameId) {
    _gameViewCounts[gameId] = (_gameViewCounts[gameId] ?? 0) + 1;

    if (_gameViewCounts.length >= _batchSize) {
      _flushGameViews();
    }
  }

  void incrementPostView(String postId) {
    _postViewCounts[postId] = (_postViewCounts[postId] ?? 0) + 1;

    if (_postViewCounts.length >= _batchSize) {
      _flushPostViews();
    }
  }

  Future<void> _flushGameViews() async {
    if (_gameViewCounts.isEmpty) return;

    try {
      await _dbConnectionService.runWithErrorHandling(() async {
        final Map<String, int> countsToUpdate = Map.from(_gameViewCounts);
        _gameViewCounts.clear();

        final List<Map<String, Object>> bulkUpdates = countsToUpdate.entries.map((entry) => {
          'updateOne': {
            'filter': {'_id': ObjectId.fromHexString(entry.key)} as Map<String, Object>,
            'update': {r'$inc': {'viewCount': entry.value}} as Map<String, Object>
          } as Map<String, Object>
        }).toList();

        if (bulkUpdates.isNotEmpty) {
          await _dbConnectionService.games.bulkWrite(bulkUpdates);
        }
      });
    } catch (e) {
      print('Flush game views error: $e');
      _gameViewCounts.addAll(_gameViewCounts);
    }
  }

  Future<void> _flushPostViews() async {
    if (_postViewCounts.isEmpty) return;

    try {
      await _dbConnectionService.runWithErrorHandling(() async {
        final Map<String, int> countsToUpdate = Map.from(_postViewCounts);
        _postViewCounts.clear();

        final List<Map<String, Object>> bulkUpdates = countsToUpdate.entries.map((entry) => {
          'updateOne': {
            'filter': {'_id': ObjectId.fromHexString(entry.key)} as Map<String, Object>,
            'update': {r'$inc': {'viewCount': entry.value}} as Map<String, Object>
          } as Map<String, Object>
        }).toList();

        if (bulkUpdates.isNotEmpty) {
          await _dbConnectionService.posts.bulkWrite(bulkUpdates);
        }
      });
    } catch (e) {
      print('Flush post views error: $e');
      _postViewCounts.addAll(_postViewCounts);
    }
  }

  Future<void> _flushAll() async {
    await _flushGameViews();
    await _flushPostViews();
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await _flushAll();
  }
}