// lib/services/ban/user_ban_service.dart

import 'package:mongo_dart/mongo_dart.dart';
import '../../models/user/user_ban.dart';
import '../db_connection_service.dart';
import '../cache/user_ban_cache_service.dart';

class UserBanService {
  static final UserBanService _instance = UserBanService._internal();
  factory UserBanService() => _instance;
  UserBanService._internal();

  final DBConnectionService _dbService = DBConnectionService();
  final UserBanCacheService _cacheService = UserBanCacheService();

  // 移除 late 关键字，直接从 DBConnectionService 获取
  DbCollection get userBans => _dbService.userBans;

  // 如果需要初始化其他内容，可以保留这个方法
  Future<void> initialize() async {
    await _ensureIndexes();
  }

  Future<void> _ensureIndexes() async {
    await userBans.createIndex(
      key: 'userId',
      unique: true,
      name: 'userId_unique',
    );
    await userBans.createIndex(
      key: 'banTime',
      name: 'banTime_index',
    );
  }

  Future<void> banUser({
    required String userId,
    required String reason,
    DateTime? endTime,
    required String bannedBy,
  }) async {
    try {
      final banData = {
        'userId': userId,
        'reason': reason,
        'banTime': DateTime.now(),
        'endTime': endTime,
        'bannedBy': bannedBy,
      };

      final result = await userBans.insertOne(banData);

      if (!result.isSuccess) {
        throw Exception('封禁失败');
      }

      // 清除缓存
      await _cacheService.removeBanCache(userId);
    } catch (e) {
      print('Ban user error: $e');
      rethrow;
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await userBans.deleteOne(where.eq('userId', userId));

      // 清除缓存
      await _cacheService.removeBanCache(userId);
    } catch (e) {
      print('Unban user error: $e');
      rethrow;
    }
  }

  Future<UserBan?> checkUserBan(String userId) async {
    try {
      // 首先尝试从缓存获取
      final cachedBan = await _cacheService.getCachedBan(userId);
      if (cachedBan != null) {
        // 如果是临时封禁且已过期，则删除封禁
        if (!cachedBan.isPermanent && !cachedBan.isActive) {
          await unbanUser(userId);
          return null;
        }
        return cachedBan;
      }

      // 从数据库获取封禁信息
      final ban = await userBans.findOne(where.eq('userId', userId));
      if (ban == null) return null;

      final userBan = UserBan.fromJson(_dbService.convertDocument(ban));

      // 如果是临时封禁且已过期，删除封禁
      if (!userBan.isPermanent && !userBan.isActive) {
        await unbanUser(userId);
        return null;
      }

      // 缓存有效的封禁信息
      await _cacheService.cacheBan(userId, userBan);
      return userBan;
    } catch (e) {
      print('Check user ban error: $e');
      return null;
    }
  }

  Future<List<UserBan>> getAllBans() async {
    try {
      final bans = await userBans.find().toList();
      return bans
          .map((b) => UserBan.fromJson(_dbService.convertDocument(b)))
          .where((ban) => ban.isActive) // 只返回生效中的封禁
          .toList();
    } catch (e) {
      print('Get all bans error: $e');
      return [];
    }
  }
}
