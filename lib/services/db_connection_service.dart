// lib/services/db_connection_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../config/app_config.dart';

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
  late DbCollection history;

  Future<void> initialize() async {
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
      history = _db.collection('history');

      await _ensureIndexes();
    } catch (e) {
      print('MongoDB connection error: $e');
      rethrow;
    }
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
        // 历史记录相关索引
        history.createIndex(keys: {'userId': 1, 'gameId': 1}, unique: true),
        history.createIndex(keys: {'userId': 1, 'lastViewTime': -1}),
      ]);
    } catch (e) {
      print('Error creating indexes: $e');
      rethrow;
    }
  }

  Map<String, dynamic> convertDocument(Map<String, dynamic> doc) {
    if (doc.isEmpty) return {};

    try {
      return {
        'id': doc['_id'] != null ? doc['_id'].toHexString() : null,
        ...Map.from(doc)..remove('_id'),
      };
    } catch (e) {
      print('Convert document error: $e');
      return {};
    }
  }

  Future<void> close() async {
    await _db.close();
  }
}