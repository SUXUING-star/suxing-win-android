// lib/services/db_connection_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../config/app_config.dart';
import 'dart:async';

class DBConnectionService {
  static final DBConnectionService _instance = DBConnectionService._internal();
  factory DBConnectionService() => _instance;
  DBConnectionService._internal();

  late Db _db;
  late DbCollection users;
  late DbCollection games;
  late DbCollection favorites;
  late DbCollection comments;
  late DbCollection posts;
  late DbCollection replies;
  late DbCollection links;
  late DbCollection tools;
  late DbCollection gameHistory;  // 新增
  late DbCollection postHistory;  // 新增

  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  Future<void> initialize() async {
    await _connect();
  }

  Future<void> _connect() async {
    if (_isConnected) return;

    try {
      final uri = AppConfig.mongodbUri;
      final database = AppConfig.mongodbDatabase;
      final username = AppConfig.mongodbUsername;
      final password = AppConfig.mongodbPassword;

      final connectionString = 'mongodb://$username:$password@${uri.replaceAll('mongodb://', '')}/$database?authSource=admin';
      _db = await Db.create(connectionString);
      await _db.open();

      users = _db.collection('users');
      games = _db.collection('games');
      favorites = _db.collection('favorites');
      comments = _db.collection('comments');
      posts = _db.collection('posts');
      replies = _db.collection('replies');
      links = _db.collection('links');
      tools = _db.collection('tools');
      gameHistory = _db.collection('game_history');  // 新增
      postHistory = _db.collection('post_history');  // 新增

      await _ensureIndexes();

      _isConnected = true;
      _reconnectAttempts = 0;
      print('MongoDB connected successfully');
    } catch (e) {
      print('MongoDB connection error: $e');
      await _reconnect();
    }
  }

  Future<void> _reconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached. Please check your database connection.');
      return;
    }

    _reconnectAttempts++;
    final waitTime = Duration(seconds: 1 << _reconnectAttempts); // Exponential backoff
    print('Attempting to reconnect in ${waitTime.inSeconds} seconds...');
    await Future.delayed(waitTime);
    await _connect();
  }

  Future<void> _ensureIndexes() async {
    try {
      await Future.wait([
        // 用户相关索引
        users.createIndex(key: 'email', unique: true),
        users.createIndex(key: 'username'),

        // 游戏相关索引
        games.createIndex(key: 'createTime'),
        games.createIndex(key: 'viewCount'),
        games.createIndex(key: 'title'),

        // 收藏相关索引
        favorites.createIndex(keys: {'userId': 1, 'gameId': 1}, unique: true),

        // 评论相关索引
        comments.createIndex(keys: {'gameId': 1, 'createTime': -1}),
        comments.createIndex(keys: {'userId': 1}),
        comments.createIndex(keys: {'parentId': 1}),

        // 论坛帖子相关索引
        posts.createIndex(keys: {'createTime': -1}),
        posts.createIndex(keys: {'authorId': 1}),
        posts.createIndex(keys: {'tags': 1}),
        posts.createIndex(keys: {'status': 1}),
        posts.createIndex(keys: {'viewCount': -1}),

        // 帖子回复相关索引
        replies.createIndex(keys: {'postId': 1, 'createTime': 1}),
        replies.createIndex(keys: {'authorId': 1}),
        replies.createIndex(keys: {'parentId': 1}),
        replies.createIndex(keys: {'status': 1}),

        // 外部链接相关索引
        links.createIndex(keys: {'category': 1}),
        links.createIndex(keys: {'createTime': -1}),

        // 工具相关索引
        tools.createIndex(keys: {'category': 1}),
        tools.createIndex(keys: {'createTime': -1}),
        // 游戏历史记录索引
        gameHistory.createIndex(
            keys: {
              'userId': 1,
              'gameId': 1,
            },
            unique: true
        ),
        gameHistory.createIndex(
            keys: {
              'userId': 1,
              'lastViewTime': -1,
            }
        ),

        // 帖子历史记录索引
        postHistory.createIndex(
            keys: {
              'userId': 1,
              'postId': 1,
            },
            unique: true
        ),
        postHistory.createIndex(
            keys: {
              'userId': 1,
              'lastViewTime': -1,
            }
        ),
      ]);
    } catch (e) {
      print('Error creating indexes: $e');
      // 不要在这里抛出异常，而是继续尝试连接
    }
  }

  Map<String, dynamic> convertDocument(Map<String, dynamic> doc) {
    if (doc.isEmpty) return {};

    try {
      return {
        'id': doc['_id'] is ObjectId ? doc['_id'].toHexString() : doc['_id'],
        ...Map.from(doc)..remove('_id'),
      };
    } catch (e) {
      print('Convert document error: $e');
      return {};
    }
  }

  Future<void> close() async {
    if (_isConnected) {
      await _db.close();
      _isConnected = false;
    }
  }

  Future<T> runWithErrorHandling<T>(Future<T> Function() operation) async {
    if (!_isConnected) {
      await _connect();
    }

    try {
      return await operation();
    } catch (e) {
      if (e.toString().contains('No master connection')) {
        _isConnected = false;
        await _reconnect();
        // 重试操作
        return await operation();
      }
      rethrow;
    }
  }

}