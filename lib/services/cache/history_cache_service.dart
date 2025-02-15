// lib/services/cache/history_cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import '../../models/game_history.dart';
import '../../models/post_history.dart';

// ObjectId adapter
class ObjectIdAdapter extends TypeAdapter<ObjectId> {
  @override
  final typeId = 0; // 使用一个唯一的 typeId

  @override
  ObjectId read(BinaryReader reader) {
    return ObjectId.fromHexString(reader.readString());
  }

  @override
  void write(BinaryWriter writer, ObjectId obj) {
    writer.writeString(obj.toHexString());
  }
}

class HistoryCacheService {
  static final HistoryCacheService _instance = HistoryCacheService._internal();
  factory HistoryCacheService() => _instance;
  HistoryCacheService._internal();

  static const String gameHistoryBox = 'game_history_cache';
  static const String postHistoryBox = 'post_history_cache';
  static const int cacheExpiration = 5; // 5分钟过期

  late Box<dynamic> _gameHistoryBox;
  late Box<dynamic> _postHistoryBox;

  Future<void> init() async {
    // 注册 ObjectId 适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ObjectIdAdapter());
    }

    _gameHistoryBox = await Hive.openBox(gameHistoryBox);
    _postHistoryBox = await Hive.openBox(postHistoryBox);
  }

  // 游戏历史缓存
  Future<void> cacheGameHistory(String userId, List<GameHistory> history) async {
    try {
      final currentTime = DateTime.now();
      await _gameHistoryBox.put('${userId}_timestamp', currentTime.toIso8601String());

      final historyDataList = history.map((item) {
        final json = item.toJson();
        // 转换 ObjectId 为字符串
        json['_id'] = json['_id'].toHexString();
        json['userId'] = json['userId'].toHexString();
        return json;
      }).toList();

      await _gameHistoryBox.put(userId, historyDataList);
    } catch (e) {
      print('Cache game history error: $e');
    }
  }

  Future<List<GameHistory>?> getCachedGameHistory(String userId) async {
    try {
      final timestamp = _gameHistoryBox.get('${userId}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
        return null;
      }

      final cachedData = _gameHistoryBox.get(userId);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final historyMap = Map<String, dynamic>.from(item as Map);
        // 转换回 ObjectId
        historyMap['_id'] = ObjectId.fromHexString(historyMap['_id']);
        historyMap['userId'] = ObjectId.fromHexString(historyMap['userId']);
        return GameHistory.fromJson(historyMap);
      }).toList();
    } catch (e) {
      print('Get cached game history error: $e');
      return null;
    }
  }

  /// 帖子历史缓存
  Future<void> cachePostHistory(String userId, List<PostHistory> history) async {
    try {
      final currentTime = DateTime.now();
      await _postHistoryBox.put('${userId}_timestamp', currentTime.toIso8601String());

      final historyDataList = history.map((item) {
        final json = item.toJson();
        // 转换 ObjectId 为字符串
        json['_id'] = json['_id'].toHexString();
        json['userId'] = json['userId'].toHexString();
        return json;
      }).toList();

      await _postHistoryBox.put(userId, historyDataList);
    } catch (e) {
      print('Cache post history error: $e');
    }
  }

  Future<List<PostHistory>?> getCachedPostHistory(String userId) async {
    try {
      final timestamp = _postHistoryBox.get('${userId}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
        return null;
      }

      final cachedData = _postHistoryBox.get(userId);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final historyMap = Map<String, dynamic>.from(item as Map);
        // 转换回 ObjectId
        historyMap['_id'] = ObjectId.fromHexString(historyMap['_id']);
        historyMap['userId'] = ObjectId.fromHexString(historyMap['userId']);
        return PostHistory.fromJson(historyMap);
      }).toList();
    } catch (e) {
      print('Get cached post history error: $e');
      return null;
    }
  }

  // 清除缓存
  Future<void> clearGameHistoryCache() async {
    await _gameHistoryBox.clear();
  }

  Future<void> clearPostHistoryCache() async {
    await _postHistoryBox.clear();
  }

  Future<void> clearCacheData() async {
    try {
      if (_gameHistoryBox.isOpen) {
        await _gameHistoryBox.clear();
      }
      if (_postHistoryBox.isOpen) {
        await _postHistoryBox.clear();
      }
    } catch (e) {
      print('Clear history cache data error: $e');
      rethrow;
    }
  }

  // 修改现有的clearAllCache方法
  Future<void> clearAllCache() async {
    try {
      await clearGameHistoryCache();
      await clearPostHistoryCache();
    } catch (e) {
      print('Clear all history cache error: $e');
      rethrow;
    }
  }

  // 检查缓存是否过期方法保持不变
  bool isGameHistoryCacheExpired(String userId) {
    final timestamp = _gameHistoryBox.get('${userId}_timestamp');
    if (timestamp == null) return true;

    final lastUpdateTime = DateTime.parse(timestamp);
    return DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration;
  }

  bool isPostHistoryCacheExpired(String userId) {
    final timestamp = _postHistoryBox.get('${userId}_timestamp');
    if (timestamp == null) return true;

    final lastUpdateTime = DateTime.parse(timestamp);
    return DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration;
  }
}