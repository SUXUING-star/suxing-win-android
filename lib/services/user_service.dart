// lib/services/user_service.dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';
import 'db_connection_service.dart';
import 'cache/avatar_cache_service.dart';
import 'cache/history_cache_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final AvatarCacheService _avatarCache = AvatarCacheService();
  final HistoryCacheService _cacheService  = HistoryCacheService();
  Box<String>? _authBox;

  UserService._internal();

  Future<Box<String>> _getAuthBox() async {
    if (_authBox == null) {
      _authBox = await Hive.openBox<String>('authBox');
    }
    return _authBox!;
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
      await _setCurrentUserId(userId);

      return User.fromJson(_dbConnectionService.convertDocument(userDoc));
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
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

  Future<void> signOut() async {
    await _setCurrentUserId(null);
    // 在用户登出时
    await HistoryCacheService().clearAllCache();
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

      // 如果更新了头像，清除该用户的头像缓存
      if (avatar != null) {
        await _avatarCache.removeAvatar(currentId);
      }
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
  Future<Map<String, dynamic>> getUserInfoById(String userId) async {
    try {
      final userDoc = await _dbConnectionService.users.findOne(
        where.eq('_id', ObjectId.fromHexString(userId)),
      );

      if (userDoc != null) {
        return {
          'username': userDoc['username'],
          'avatar': userDoc['avatar'],
        };
      }
      return {'username': '未知用户', 'avatar': null};
    } catch (e) {
      print('Get user info by id error: $e');
      return {'username': '未知用户', 'avatar': null};
    }
  }

  Future<Map<String, dynamic>?> safegetUserById(String userId) async {
    try {
      final userDoc = await _dbConnectionService.users.findOne(
        where.eq('_id', ObjectId.fromHexString(userId)),
      );

      if (userDoc != null) {
        // 移除敏感信息
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