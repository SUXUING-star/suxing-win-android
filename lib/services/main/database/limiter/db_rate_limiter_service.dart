// lib/services/limiter/db_rate_limiter_service.dart

import 'dart:async';
import 'dart:collection';

class DBRateLimiterService {
  static final DBRateLimiterService _instance = DBRateLimiterService._internal();
  factory DBRateLimiterService() => _instance;

  // 不同操作类型的限流器
  final Map<String, _TokenBucket> _buckets = {};

  // 默认配置
  static const Map<String, _RateLimitConfig> _defaultConfigs = {
    'read': _RateLimitConfig(
      maxTokens: 100,    // 最多100个并发读操作
      refillRate: 50,    // 每秒恢复50个令牌
      burstSize: 150,    // 突发允许150个操作
    ),
    'write': _RateLimitConfig(
      maxTokens: 50,     // 最多50个并发写操作
      refillRate: 20,    // 每秒恢复20个令牌
      burstSize: 70,     // 突发允许70个操作
    ),
    'query': _RateLimitConfig(
      maxTokens: 30,     // 最多30个并发查询操作
      refillRate: 15,    // 每秒恢复15个令牌
      burstSize: 45,     // 突发允许45个操作
    ),
  };

  // 等待队列
  final Map<String, Queue<Completer<void>>> _waitingQueues = {};

  DBRateLimiterService._internal() {
    _initializeBuckets();
  }

  void _initializeBuckets() {
    _defaultConfigs.forEach((type, config) {
      _buckets[type] = _TokenBucket(config);
      _waitingQueues[type] = Queue<Completer<void>>();
    });
  }

  // 请求令牌
  Future<bool> acquireToken(String operationType) async {
    final bucket = _buckets[operationType];
    if (bucket == null) return true; // 如果没有配置限流，直接允许

    if (bucket.tryAcquire()) {
      return true;
    }

    // 如果没有令牌，加入等待队列
    final completer = Completer<void>();
    _waitingQueues[operationType]?.add(completer);

    // 设置超时
    try {
      await completer.future.timeout(
        Duration(seconds: 5),
        onTimeout: () {
          _waitingQueues[operationType]?.remove(completer);
          throw TimeoutException('数据库操作等待超时');
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // 释放令牌
  void releaseToken(String operationType) {
    final bucket = _buckets[operationType];
    if (bucket == null) return;

    // 检查等待队列
    final waitingQueue = _waitingQueues[operationType];
    if (waitingQueue != null && waitingQueue.isNotEmpty) {
      final completer = waitingQueue.removeFirst();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  // 重置限流器配置
  void updateConfig(String operationType, _RateLimitConfig config) {
    _buckets[operationType]?.updateConfig(config);
  }

  // 获取当前可用令牌数
  int getAvailableTokens(String operationType) {
    return _buckets[operationType]?.availableTokens ?? -1;
  }

  // 获取等待队列长度
  int getWaitingQueueLength(String operationType) {
    return _waitingQueues[operationType]?.length ?? 0;
  }
}

// 令牌桶实现
class _TokenBucket {
  _RateLimitConfig _config;
  int _availableTokens;
  DateTime _lastRefillTime;

  _TokenBucket(this._config)
      : _availableTokens = _config.maxTokens,
        _lastRefillTime = DateTime.now();

  int get availableTokens => _availableTokens;

  bool tryAcquire() {
    _refill();
    if (_availableTokens > 0) {
      _availableTokens--;
      return true;
    }
    return false;
  }

  void _refill() {
    final now = DateTime.now();
    final duration = now.difference(_lastRefillTime);
    final tokensToAdd = (_config.refillRate * duration.inSeconds).floor();

    if (tokensToAdd > 0) {
      _availableTokens = (_availableTokens + tokensToAdd)
          .clamp(0, _config.burstSize);
      _lastRefillTime = now;
    }
  }

  void updateConfig(_RateLimitConfig newConfig) {
    _config = newConfig;
    _refill();
    _availableTokens = _availableTokens.clamp(0, newConfig.burstSize);
  }
}

// 限流配置
class _RateLimitConfig {
  final int maxTokens;    // 最大令牌数
  final int refillRate;   // 每秒补充令牌数
  final int burstSize;    // 突发大小

  const _RateLimitConfig({
    required this.maxTokens,
    required this.refillRate,
    required this.burstSize,
  });
}
