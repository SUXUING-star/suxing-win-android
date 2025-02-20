// lib/services/user_service.dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user/user.dart';
import '../models/user/user_ban.dart';
import 'db_connection_service.dart';
import 'cache/info_cache_service.dart';
import 'cache/history_cache_service.dart';
import 'ban/user_ban_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final InfoCacheService _infoCache = InfoCacheService();
  final HistoryCacheService _historyCache = HistoryCacheService();
  final UserBanService _banService = UserBanService();
  Box<String>? _authBox;

  UserService._internal();


  Future<Box<String>> _getAuthBox() async {
    if (_authBox == null || !_authBox!.isOpen) {
      _authBox = await Hive.openBox<String>('authBox');
    }
    return _authBox!;
  }

  // 新增：清理数据但不关闭box
  Future<void> clearAuthData() async {
    try {
      final box = await _getAuthBox();
      if (box.isOpen) {
        await box.clear();
      }
    } catch (e) {
      print('Clear auth data error: $e');
    }
  }

  // 新增：关闭box
  Future<void> closeBox() async {
    try {
      if (_authBox != null && _authBox!.isOpen) {
        await _authBox!.close();
        _authBox = null;
      }
    } catch (e) {
      print('Close auth box error: $e');
    }
  }

  Future<String?> get currentUserId async => (await _getAuthBox()).get('currentUserId');

  Future<void> _setCurrentUserId(String? userId) async {
    final box = await _getAuthBox();
    if (userId != null) {
      await box.put('currentUserId', userId);
    } else {
      await box.delete('currentUserId');
    }
  }

  Future<User> getCurrentUser() async {
    final currentId = await currentUserId;
    if (currentId == null) {
      throw Exception('No user logged in');
    }

    try {
      final userDoc = await _dbConnectionService.users.findOne(
          where.eq('_id', ObjectId.fromHexString(currentId))
      );

      if (userDoc == null) {
        throw Exception('User not found');
      }

      return User.fromJson(_dbConnectionService.convertDocument(userDoc));
    } catch (e) {
      print('Get current user error: $e');
      rethrow;
    }
  }

  // 在登录时检查封禁状态
  Future<User> signIn(String email, String password) async {
    try {
      final userDoc = await _dbConnectionService.users.findOne(where.eq('email', email));
      if (userDoc == null) {
        throw Exception('用户不存在或密码错误');
      }

      final salt = userDoc['salt'] as String;
      final storedHash = userDoc['hash'] as String;
      final hashedPassword = _hashPassword(password, salt: salt);

      if (storedHash != hashedPassword) {
        throw Exception('用户不存在或密码错误');
      }

      final userId = userDoc['_id'].toHexString();

      // 检查用户是否被封禁
      final ban = await _banService.checkUserBan(userId);
      if (ban != null) {
        throw UserBanException(ban);
      }

      await _setCurrentUserId(userId);
      return User.fromJson(_dbConnectionService.convertDocument(userDoc));
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }
  // 检查当前用户是否被封禁
  Future<void> checkCurrentUserBan() async {
    final userId = await currentUserId;
    if (userId == null) return;

    final ban = await _banService.checkUserBan(userId);
    if (ban != null) {
      throw UserBanException(ban);
    }
  }

  Future<User> signUp(String email, String password, String username) async {
    try {
      final existingUser = await _dbConnectionService.users.findOne(where.eq('email', email));
      if (existingUser != null) {
        throw Exception('该邮箱已被注册');
      }

      final salt = _generateSalt();
      final hash = _hashPassword(password, salt: salt);

      final user = {
        'email': email,
        'hash': hash,
        'salt': salt,
        'username': username,
        'createTime': DateTime.now(),
        'isAdmin': false,
      };

      final writeResult = await _dbConnectionService.users.insertOne(user);
      if (!writeResult.isSuccess) {
        throw Exception('注册失败');
      }

      final userId = writeResult.id.toHexString();
      await _setCurrentUserId(userId);

      return User.fromJson(_dbConnectionService.convertDocument({...user, '_id': writeResult.id}));
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // 修改登出方法，确保清理所有缓存
  Future<void> signOut() async {
    try {
      await clearAuthData();
      await _historyCache.clearAllCache();
      await _infoCache.clearAllCache();
    } catch (e) {
      print('Sign out error: $e');
    }
  }



  Future<void> resetPassword(String email, String newPassword) async {
    try {
      final salt = _generateSalt();
      final hash = _hashPassword(newPassword, salt: salt);

      final result = await _dbConnectionService.users.updateOne(
        where.eq('email', email),
        {
          r'$set': {
            'hash': hash,
            'salt': salt,
          }
        },
      );

      if (result.isSuccess && result.nModified == 0) {
        throw Exception('用户不存在');
      }
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
  Future<bool> checkEmailExists(String email) async {
    try {
      final existingUser = await _dbConnectionService.users.findOne(where.eq('email', email));
      return existingUser != null;
    } catch (e) {
      print('Check email exists error: $e');
      rethrow;
    }
  }

  String _hashPassword(String password, {String? salt}) {
    final currentSalt = salt ?? _generateSalt();
    final passwordBytes = utf8.encode(password);
    final saltBytes = hex.decode(currentSalt);
    final key = _pbkdf2(passwordBytes, saltBytes, 1000, 64);
    return hex.encode(key);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return hex.encode(bytes);
  }

  List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int keylen) {
    final hmac = Hmac(sha512, password);
    final output = List<int>.filled(keylen, 0);
    var offset = 0;
    var blockIndex = 1;

    while (offset < keylen) {
      final blockData = List<int>.from(salt);
      blockData.addAll([
        (blockIndex >> 24) & 0xFF,
        (blockIndex >> 16) & 0xFF,
        (blockIndex >> 8) & 0xFF,
        blockIndex & 0xFF
      ]);

      var lastBlock = hmac.convert(blockData).bytes;
      var block = List<int>.from(lastBlock);

      for (var i = 1; i < iterations; i++) {
        lastBlock = hmac.convert(lastBlock).bytes;
        for (var j = 0; j < block.length; j++) {
          block[j] ^= lastBlock[j];
        }
      }

      final remain = keylen - offset;
      final toCopy = remain > block.length ? block.length : remain;
      output.setRange(offset, offset + toCopy, block);

      offset += toCopy;
      blockIndex++;
    }

    return output;
  }

  Stream<User?> getCurrentUserProfile() async* {
    try {
      while (true) {
        final currentId = await currentUserId;
        if (currentId == null) {
          yield null;
          return;
        }

        final userDoc = await _dbConnectionService.users.findOne(
            where.eq('_id', ObjectId.fromHexString(currentId))
        );

        yield userDoc != null ? User.fromJson(_dbConnectionService.convertDocument(userDoc)) : null;
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      print('Get user profile error: $e');
      yield null;
    }
  }

  Stream<List<String>> getUserFavorites() async* {
    try {
      while (true) {
        final currentId = await currentUserId;
        if (currentId == null) {
          yield [];
          return;
        }

        final favorites = await _dbConnectionService.favorites
            .find(where.eq('userId', currentId))
            .map((f) => f['gameId'].toString())
            .toList();
        yield favorites;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get favorites error: $e');
      yield [];
    }
  }

  Future<void> toggleFavorite(String gameId) async {
    final currentId = await currentUserId;
    if (currentId == null) throw Exception('User not logged in');

    try {
      final existingFavorite = await _dbConnectionService.favorites.findOne({
        'userId': currentId,
        'gameId': gameId
      });

      if (existingFavorite != null) {
        await _dbConnectionService.favorites.deleteOne(where.id(existingFavorite['_id']));
      } else {
        await _dbConnectionService.favorites.insertOne({
          'userId': currentId,
          'gameId': gameId,
          'createTime': DateTime.now(),
        });
      }
    } catch (e) {
      print('Toggle favorite error: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({String? username, String? avatar}) async {
    final currentId = await currentUserId;
    if (currentId == null) throw Exception('User not logged in');

    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatar != null) updates['avatar'] = avatar;

      await _dbConnectionService.users.updateOne(
          where.eq('_id', ObjectId.fromHexString(currentId)),
          {r'$set': updates}
      );

      // 如果更新了信息，清除该用户的缓存
      await _infoCache.removeUserCache(currentId);
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  Future<List<String>> getSearchHistory() async {
    try {
      final currentId = await currentUserId;
      if (currentId == null) return [];

      final user = await _dbConnectionService.users.findOne(
          where.eq('_id', ObjectId.fromHexString(currentId))
      );

      if (user != null && user['searchHistory'] != null) {
        return List<String>.from(user['searchHistory']);
      }
      return [];
    } catch (e) {
      print('Get search history error: $e');
      return [];
    }
  }

  Future<void> saveSearchHistory(List<String> history) async {
    try {
      final currentId = await currentUserId;
      if (currentId == null) return;

      await _dbConnectionService.users.updateOne(
          where.eq('_id', ObjectId.fromHexString(currentId)),
          {r'$set': {'searchHistory': history}}
      );
    } catch (e) {
      print('Save search history error: $e');
      rethrow;
    }
  }
  // 在 UserService 中添加处理 ObjectId 的工具方法
  ObjectId _parseObjectId(String id) {
    try {
      //print('Received ID format: $id');

      // 处理 ObjectId("xxx") 格式
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        // 提取引号内的内容
        String hexString = id.substring(id.indexOf('"') + 1, id.lastIndexOf('"'));
        //print('Extracted hex string: $hexString');
        return ObjectId.fromHexString(hexString);
      }

      // 处理纯 24 位十六进制
      if (id.length == 24) {
        return ObjectId.fromHexString(id);
      }

      throw FormatException('Invalid ObjectId format: $id');
    } catch (e) {
      print('Parse ObjectId error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserInfoById(String userId) async {
    try {
      // 首先尝试从缓存获取
      final cachedInfo = await _infoCache.getUserInfo(userId);
      if (cachedInfo != null) {
        return cachedInfo;
      }

      // 缓存未命中，从数据库获取
      final objId = _parseObjectId(userId);
      final userDoc = await _dbConnectionService.users.findOne(
        where.eq('_id', objId),
      );

      if (userDoc != null) {
        final userInfo = {
          'username': userDoc['username'],
          'avatar': userDoc['avatar'],
        };

        // 异步更新缓存
        _infoCache.setUserInfo(userId, userInfo);

        return userInfo;
      }
      return {'username': '未知用户', 'avatar': null};
    } catch (e) {
      print('Get user info by id error: $e');
      return {'username': '未知用户', 'avatar': null};
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final users = await _dbConnectionService.users
          .find()
          .map((doc) {
        // 确保 _id 被正确转换
        final convertedDoc = _dbConnectionService.convertDocument(doc);
        convertedDoc['_id'] = doc['_id'].toHexString(); // 显式转换 ObjectId 到字符串
        return convertedDoc;
      })
          .toList();
      return users;
    } catch (e) {
      print('Get all users error: $e');
      rethrow;
    }
  }

  // 更新用户管理员状态
  Future<void> updateUserAdminStatus(String userId, bool isAdmin) async {
    try {
      // 处理可能的 null 或空字符串
      if (userId == null || userId.isEmpty) {
        throw Exception('无效的用户ID');
      }

      final objId = _parseObjectId(userId);
      final result = await _dbConnectionService.users.updateOne(
        where.eq('_id', objId),
        {r'$set': {'isAdmin': isAdmin}},
      );

      if (!result.isSuccess) {
        throw Exception('更新失败');
      }
    } catch (e) {
      print('Update user admin status error: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>?> safegetUserById(String userId) async {
    try {
      print('safegetUserById received userId: $userId'); // 添加日志
      final objId = _parseObjectId(userId);

      final userDoc = await _dbConnectionService.users.findOne(
        where.eq('_id', objId),
      );

      if (userDoc != null) {
        userDoc.remove('hash');
        userDoc.remove('salt');
        userDoc.remove('email');
        return _dbConnectionService.convertDocument(userDoc);
      }
      return null;
    } catch (e) {
      print('Get user by id error: $e');
      return null;
    }
  }
}

class UserBanException implements Exception {
  final UserBan ban;
  UserBanException(this.ban);

  @override
  String toString() {
    if (ban.isPermanent) {
      return '您的账号已被永久封禁\n原因：${ban.reason}';
    }
    return '您的账号已被临时封禁至 ${ban.endTime}\n原因：${ban.reason}';
  }
}