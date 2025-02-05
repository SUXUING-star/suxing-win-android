// lib/services/game_service.dart
import 'package:mongo_dart/mongo_dart.dart';

import '../models/game.dart';
import 'db_connection_service.dart';
import 'user_service.dart'; // 引入 UserService

class GameService {
  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService(); // 引入 UserService

  Stream<List<Game>> getGames() async* {
    try {
      while (true) {
        final games = await _dbConnectionService.games
            .find()
            .map((game) =>
            Game.fromJson(_dbConnectionService.convertDocument(game)))
            .toList();
        yield games;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get games error: $e');
      yield [];
    }
  }

  Stream<List<Game>> getHotGames() async* {
    try {
      while (true) {
        final cursor = _dbConnectionService.games.find(
            where.sortBy('viewCount', descending: true).limit(10));

        final games = await cursor
            .map((game) =>
            Game.fromJson(_dbConnectionService.convertDocument(game)))
            .toList();
        yield games;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get hot games error: $e');
      yield [];
    }
  }

  Stream<List<Game>> getLatestGames() async* {
    try {
      while (true) {
        final cursor = _dbConnectionService.games.find(
            where.sortBy('createTime', descending: true).limit(10));

        final games = await cursor
            .map((game) =>
            Game.fromJson(_dbConnectionService.convertDocument(game)))
            .toList();
        yield games;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get latest games error: $e');
      yield [];
    }
  }

  Stream<List<Game>> getGamesSortedByViews() async* {
    try {
      while (true) {
        final cursor = _dbConnectionService.games.find(
            where.sortBy('viewCount', descending: true)
        );

        final games = await cursor
            .map((game) => Game.fromJson(_dbConnectionService.convertDocument(game)))
            .toList();
        yield games;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get games sorted by views error: $e');
      yield [];
    }
  }

  Stream<List<Game>> getGamesSortedByRating() async* {
    try {
      while (true) {
        final cursor = _dbConnectionService.games.find(
            where.sortBy('rating', descending: true)
        );

        final games = await cursor
            .map((game) => Game.fromJson(_dbConnectionService.convertDocument(game)))
            .toList();
        yield games;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get games sorted by rating error: $e');
      yield [];
    }
  }

  Future<void> addGame(Game game) async {
    try {
      final gameDoc = game.toJson();
      gameDoc['createTime'] = DateTime.now();
      gameDoc['updateTime'] = DateTime.now();
      gameDoc['viewCount'] = 0;
      gameDoc['likeCount'] = 0;
      await _dbConnectionService.games.insertOne(gameDoc);
    } catch (e) {
      print('Add game error: $e');
      rethrow;
    }
  }

  Future<void> updateGame(Game game) async {
    try {
      final gameDoc = game.toJson();
      gameDoc['updateTime'] = DateTime.now();
      await _dbConnectionService.games.replaceOne(
        where.eq('_id', ObjectId.fromHexString(game.id)),
        gameDoc,
      );
    } catch (e) {
      print('Update game error: $e');
      rethrow;
    }
  }

  Future<void> deleteGame(String id) async {
    try {
      await _dbConnectionService.games
          .deleteOne(where.eq('_id', ObjectId.fromHexString(id)));
      // 删除相关的收藏记录
      await _dbConnectionService.favorites.deleteMany(where.eq('gameId', id));
    } catch (e) {
      print('Delete game error: $e');
      rethrow;
    }
  }

  Future<void> incrementGameView(String gameId) async {
    try {
      final postDoc = await _dbConnectionService.games.findOne(
          where.eq('_id', ObjectId.fromHexString(gameId)));

      if (postDoc == null) {
        throw Exception('游戏不存在');
      }

      await _dbConnectionService.games.updateOne(
          where.eq('_id', ObjectId.fromHexString(gameId)),
          {r'$inc': {'viewCount': 1}});
    } catch (e) {
      print('Increment view error: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String gameId) async {
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final userObjectId = ObjectId.fromHexString(userId);
      final gameObjectId = ObjectId.fromHexString(gameId);

      final existingFavorite = await _dbConnectionService.favorites.findOne({
        'userId': userObjectId,
        'gameId': gameId // 使用字符串类型的 gameId
      });

      if (existingFavorite != null) {
        await _dbConnectionService.favorites
            .deleteOne(where.id(existingFavorite['_id']));
        await _dbConnectionService.games.updateOne(
            where.eq('_id', gameObjectId), {r'$inc': {'likeCount': -1}});
      } else {
        await _dbConnectionService.favorites.insertOne({
          'userId': userObjectId,
          'gameId': gameId, // 使用字符串类型的 gameId
          'createTime': DateTime.now(),
        });
        await _dbConnectionService.games.updateOne(
            where.eq('_id', gameObjectId), {r'$inc': {'likeCount': 1}});
      }
    } catch (e) {
      print('Toggle favorite error: $e');
      rethrow;
    }
  }

  Stream<List<String>> getUserFavorites() async* {
    try {
      while (true) {
        final userId = await _userService.currentUserId;
        if (userId == null) {
          yield [];
          return;
        }

        final userObjectId = ObjectId.fromHexString(userId);
        final favorites = await _dbConnectionService.favorites
            .find(where.eq('userId', userObjectId))
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

  Future<List<Game>> searchGames(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final results = await _dbConnectionService.games.find({
        r'$or': [
          {'title': {r'$regex': query, r'$options': 'i'}},
          {'summary': {r'$regex': query, r'$options': 'i'}},
          {'description': {r'$regex': query, r'$options': 'i'}},
        ]
      }).toList();

      return results
          .map((doc) =>
          Game.fromJson(_dbConnectionService.convertDocument(doc)))
          .toList();
    } catch (e) {
      print('Search error: $e');
      rethrow;
    }
  }

  // 新增方法：通过ID获取游戏信息
  Future<Game?> getGameById(String id) async {
    try {
      final gameDoc = await _dbConnectionService.games
          .findOne(where.eq('_id', ObjectId.fromHexString(id)));

      if (gameDoc == null) {
        return null;
      }

      return Game.fromJson(_dbConnectionService.convertDocument(gameDoc));
    } catch (e) {
      print('Get game by id error: $e');
      return null;
    }
  }

  // 添加分页查询方法
  Future<List<Game>> getGamesPaginated({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'createTime',
    bool descending = true
  }) async {
    try {
      final skip = (page - 1) * pageSize;

      final cursor = _dbConnectionService.games.find(
          where.sortBy(sortBy, descending: descending)
              .skip(skip)
              .limit(pageSize)
      );

      final games = await cursor
          .map((game) => Game.fromJson(_dbConnectionService.convertDocument(game)))
          .toList();

      return games;
    } catch (e) {
      print('Get paginated games error: $e');
      return [];
    }
  }

// 获取总游戏数量的方法
  Future<int> getTotalGamesCount() async {
    try {
      return await _dbConnectionService.games.count();
    } catch (e) {
      print('Get total games count error: $e');
      return 0;
    }
  }
}