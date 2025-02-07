// lib/services/game_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/game.dart';
import 'db_connection_service.dart';
import 'user_service.dart';
import './history/game_history_service.dart';
import './cache/game_cache_service.dart';

class GameService {
  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService(); // 引入 UserService
  final GameCacheService _cacheService = GameCacheService();
  final GameHistoryService _gameHistoryService = GameHistoryService();

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
      // 先尝试从缓存获取数据
      final cachedGames = await _cacheService.getCachedGames('hot_games');
      if (cachedGames != null) {
        yield cachedGames;
      }

      // 设置一个较长的刷新间隔，比如30秒
      while (true) {
        try {
          final cursor = _dbConnectionService.games.find(
              where.sortBy('viewCount', descending: true).limit(10));

          final games = await cursor
              .map((game) => Game.fromJson(_dbConnectionService.convertDocument(game)))
              .toList();

          // 更新缓存
          await _cacheService.cacheGames('hot_games', games);
          yield games;

          // 增加刷新间隔到30秒
          await Future.delayed(const Duration(seconds: 30));
        } catch (e) {
          print('Get hot games error in loop: $e');
          // 出错时等待后重试
          await Future.delayed(const Duration(seconds: 30));
        }
      }
    } catch (e) {
      print('Get hot games initial error: $e');
      yield [];
    }
  }

  Stream<List<Game>> getLatestGames() async* {
    while (true) {
      try {
        // 尝试从缓存获取数据
        final cachedGames = await _cacheService.getCachedGames('latest_games');
        if (cachedGames != null) {
          yield cachedGames;
        } else {
          // 如果缓存不存在或过期，从数据库获取
          final cursor = _dbConnectionService.games.find(
              where.sortBy('createTime', descending: true).limit(10));

          final games = await cursor
              .map((game) => Game.fromJson(_dbConnectionService.convertDocument(game)))
              .toList();

          // 更新缓存
          await _cacheService.cacheGames('latest_games', games);
          yield games;
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('Get latest games error: $e');
        yield [];
      }
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

  // 修改会影响缓存的方法
  Future<void> addGame(Game game) async {
    try {
      final gameDoc = game.toJson();
      gameDoc['_id'] = ObjectId.fromHexString(game.id);
      gameDoc['createTime'] = DateTime.now();
      gameDoc['updateTime'] = DateTime.now();
      gameDoc['viewCount'] = 0;
      gameDoc['likeCount'] = 0;
      await _dbConnectionService.games.insertOne(gameDoc);
      await _cacheService.clearCache();
    } catch (e) {
      print('Add game error: $e');
      rethrow;
    }
  }

  Future<void> updateGame(Game game) async {
    try {
      final gameDoc = game.toJson();
      // 移除 _id，因为它不应该被更新
      gameDoc.remove('_id');
      gameDoc['updateTime'] = DateTime.now();

      final objectId = ObjectId.fromHexString(game.id);
      final result = await _dbConnectionService.games.updateOne(
        where.eq('_id', objectId),
        {
          r'$set': gameDoc,
        },
      );

      if (result.nModified == 0) {
        throw Exception('游戏更新失败：没有找到匹配的文档');
      }

      await _cacheService.clearCache();
    } catch (e, stackTrace) {
      print('Update game error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  Future<void> deleteGame(String id) async {
    try {
      await _dbConnectionService.games
          .deleteOne(where.eq('_id', ObjectId.fromHexString(id)));
      await _dbConnectionService.favorites.deleteMany(where.eq('gameId', id));
      await _cacheService.clearCache(); // 清除所有缓存
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
  bool _isValidObjectId(String? id) {
    if (id == null) return false;
    try {
      ObjectId.fromHexString(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addToGameHistory(String gameId) async {
    try {
      if (!_isValidObjectId(gameId)) {
        print('Invalid gameId format: $gameId');
        return;
      }

      final userId = await _userService.currentUserId;
      if (userId == null) {
        print('Cannot add to history: User not logged in');
        return;
      }

      // 验证游戏是否存在
      final gameObjectId = ObjectId.fromHexString(gameId);
      final gameExists = await _dbConnectionService.games.findOne(
          where.eq('_id', gameObjectId)
      );

      if (gameExists == null) {
        print('Game not found in database: $gameId');
        return;
      }

      // 使用 gameExists['_id'].toHexString() 获取正确格式的 ID
      final normalizedGameId = gameExists['_id'].toHexString();
      print('Normalized gameId: $normalizedGameId');

      await _gameHistoryService.addGameHistory(normalizedGameId);

      // 使用新的 gameHistory 集合进行验证
      final verifyHistory = await _dbConnectionService.gameHistory.findOne({
        'userId': ObjectId.fromHexString(userId),
        'gameId': normalizedGameId,  // 注意这里改成 gameId 而不是 itemId
      });

      if (verifyHistory != null) {
        print('Successfully added game to history');
      } else {
        print('Failed to verify game history record');
        print('Verification query: userId=${userId}, gameId=${normalizedGameId}');
      }

    } catch (e, stackTrace) {
      print('Add to game history error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // 更新分页查询方法以支持缓存
  Future<List<Game>> getGamesPaginated({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'createTime',
    bool descending = true
  }) async {
    try {
      final cacheKey = 'paginated_games_${page}_${pageSize}_${sortBy}_${descending}';

      // 尝试从缓存获取数据
      final cachedGames = await _cacheService.getCachedGames(cacheKey);
      if (cachedGames != null) {
        return cachedGames;
      }

      final skip = (page - 1) * pageSize;
      final cursor = _dbConnectionService.games.find(
          where.sortBy(sortBy, descending: descending)
              .skip(skip)
              .limit(pageSize)
      );

      final games = await cursor
          .map((game) => Game.fromJson(_dbConnectionService.convertDocument(game)))
          .toList();

      // 更新缓存
      await _cacheService.cacheGames(cacheKey, games);
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