// lib/services/db_connection_service.dart

import 'package:mongo_dart/mongo_dart.dart';
import '../config/app_config.dart';
import '../providers/connection/db_state_provider.dart';
import 'dart:async';
import 'dart:io';
import 'cert/ssl_cert_service.dart';
import './limiter/db_rate_limiter_service.dart';

class DBConnectionService {
  //限流服务
  final DBRateLimiterService _rateLimiter = DBRateLimiterService();
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
  late DbCollection gameHistory;
  late DbCollection postHistory;
  late DbCollection messages;  // 添加消息集合

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  bool _isInitializing = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  Timer? _healthCheckTimer;
  DBStateProvider? _dbStateProvider;
  Timer? _connectivityTimer;
  bool _isCheckingConnectivity = false;

  void setStateProvider(DBStateProvider provider) {
    _dbStateProvider = provider;
  }

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      await _connect();
      if (!_isConnected) {
        throw Exception('服务器连接失败，请检查网络后重试。');
      }
      _startHealthCheck();
      _startConnectivityCheck();
    } catch (e) {
      _isConnected = false;
      print('Database initialization failed'); // 保留原始错误日志供调试
      _handleConnectionFailure('服务器连接失败，请检查网络连接。');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  void _startConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (!_isCheckingConnectivity && !_isConnected) {
        _isCheckingConnectivity = true;
        try {
          await _connect();
        } finally {
          _isCheckingConnectivity = false;
        }
      }
    });
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      if (_isConnected) {
        try {
          // 执行一个简单的查询来检查连接状态
          await users.findOne({
            '_id': ObjectId.fromHexString('000000000000000000000000')
          }).timeout(Duration(seconds: 5));
        } catch (e) {
          print('Health check failed: $e');
          _handleConnectionFailure('数据库连接已断开，即将重启应用');
        }
      }
    });
  }

  void _handleConnectionFailure(String error) {
    _isConnected = false;
    _stopHealthCheck();

    // 直接触发状态更新，这将启动3秒自动重启计时器
    _dbStateProvider?.triggerReset(error);
  }

  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  Future<void> _connect() async {
    if (_isConnected) return;

    try {
      final uri = AppConfig.mongodbUri;
      final database = AppConfig.mongodbDatabase;
      final username = AppConfig.mongodbUsername;
      final password = AppConfig.mongodbPassword;

      final connectionString = 'mongodb://$username:$password@${uri.replaceAll('mongodb://', '')}/$database'
          '?authSource=admin'
          '&tls=true'
          '&tlsAllowInvalidCertificates=true';

      _db = await Db.create(connectionString);
      await _db.open().timeout(Duration(seconds: 5));

      // 初始化所有集合
      users = _db.collection('users');
      games = _db.collection('games');
      favorites = _db.collection('favorites');
      comments = _db.collection('comments');
      posts = _db.collection('posts');
      replies = _db.collection('replies');
      links = _db.collection('links');
      tools = _db.collection('tools');
      gameHistory = _db.collection('game_history');
      postHistory = _db.collection('post_history');
      messages = _db.collection('messages');  // 添加消息集合初始化

      await _ensureIndexes();

      _isConnected = true;
      _reconnectAttempts = 0;
      _dbStateProvider?.setConnectionState(true);
      print('MongoDB connected successfully');
    } catch (e) {
      _isConnected = false;
      print('MongoDB connection error: $e'); // 保留原始错误日志供调试
      _dbStateProvider?.setConnectionState(false);
      throw Exception(_formatConnectionError(e));
    }
  }

  Future<void> _handleReconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _handleConnectionFailure('无法连接到数据库，请检查网络连接后重启应用。');
      return;
    }

    _reconnectAttempts++;
    _dbStateProvider?.setConnectionState(false,
        error: '正在尝试重新连接... (${_reconnectAttempts}/$maxReconnectAttempts)'
    );

    final waitTime = Duration(seconds: 1 << _reconnectAttempts);
    await Future.delayed(waitTime);
  }

  Future<void> close() async {
    _stopHealthCheck();
    if (_isConnected) {
      await _db.close();
      _isConnected = false;
      _dbStateProvider?.setConnectionState(false);
      await SSLCertService().cleanup();
    }
  }

  Future<T> runWithErrorHandling<T>(Future<T> Function() operation) async {
    if (!_isConnected) {
      await initialize().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('数据库连接超时');
        },
      );
    }

    try {
      // 获取令牌
      final hasToken = await _rateLimiter.acquireToken('query');
      if (!hasToken) {
        throw Exception('数据库操作繁忙，请稍后重试');
      }

      final result = await operation().timeout(Duration(seconds: 10));

      // 释放令牌
      _rateLimiter.releaseToken('query');
      return result;
    } catch (e) {
      if (e is TimeoutException ||
          e.toString().contains('No master connection') ||
          e.toString().contains('connection closed') ||
          e.toString().contains('信号灯超时')) {
        _isConnected = false;
        _handleConnectionFailure('数据库连接已断开，需要重启应用。');
        throw Exception('数据库连接已断开，请重启应用');
      }
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
        // 游戏历史记录索引
        gameHistory.createIndex(keys: {
          'userId': 1,
          'gameId': 1,
        }, unique: true),
        gameHistory.createIndex(keys: {
          'userId': 1,
          'lastViewTime': -1,
        }),

        // 帖子历史记录索引
        postHistory.createIndex(keys: {
          'userId': 1,
          'postId': 1,
        }, unique: true),
        postHistory.createIndex(keys: {
          'userId': 1,
          'lastViewTime': -1,
        }),
        // 消息相关索引
        messages.createIndex(keys: {
          'recipientId': 1,
          'createTime': -1
        }),
        messages.createIndex(keys: {
          'recipientId': 1,
          'isRead': 1
        }),
        messages.createIndex(keys: {
          'senderId': 1
        }),
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

  String _formatConnectionError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return '网络连接异常，请检查网络后重试。';
    }
    if (error.toString().contains('timeout')) {
      return '服务器响应超时，请稍后重试。';
    }
    if (error.toString().contains('authentication failed')) {
      return '服务器连接失败，请重启应用。';
    }
    return '数据库连接失败，请检查网络连接。';
  }

}
