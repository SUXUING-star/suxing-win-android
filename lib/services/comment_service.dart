// lib/services/comment_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/comment.dart';
import 'db_connection_service.dart';
import 'user_service.dart';
import './security/input_sanitizer_service.dart';
import './cache/comment_cache_service.dart';

class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();
  // 输入sql注入转译服务
  final InputSanitizerService _sanitizer = InputSanitizerService();

  final CommentsCacheService _cacheService = CommentsCacheService();


  CommentService._internal();

  // 获取游戏的评论列表
  Stream<List<Comment>> getGameComments(String gameId) async* {
    try {
      while (true) {
        // 尝试从缓存获取
        final cachedComments = await _cacheService.getCachedGameComments(gameId);
        if (cachedComments != null) {
          yield cachedComments;
        } else {
          // 从数据库获取所有评论
          final allComments = await _dbConnectionService.comments
              .find(where.eq('gameId', ObjectId.fromHexString(gameId)))
              .map((doc) => Comment.fromJson(_dbConnectionService.convertDocument(doc)))
              .toList();

          // 将评论组织成树形结构
          final Map<String, Comment> commentMap = {};
          final List<Comment> topLevelComments = [];

          // 建立评论 ID 到评论对象的映射
          for (var comment in allComments) {
            commentMap[comment.id] = comment;
          }

          // 组织评论层级
          for (var comment in allComments) {
            if (comment.parentId == null) {
              topLevelComments.add(comment);
            } else {
              final parentComment = commentMap[comment.parentId];
              if (parentComment != null) {
                parentComment.replies.add(comment);
              }
            }
          }

          // 按创建时间排序
          topLevelComments.sort((a, b) => b.createTime.compareTo(a.createTime));

          // 更新缓存
          await _cacheService.cacheGameComments(gameId, topLevelComments);
          yield topLevelComments;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get comments error: $e');
      yield [];
    }
  }


  // 添加评论时清除缓存
  Future<void> addComment(String gameId, String content, {String? parentId}) async {
    try {
      final sanitizedContent = _sanitizer.sanitizeComment(content);
      final currentUser = await _userService.getCurrentUser();

      final comment = {
        'gameId': ObjectId.fromHexString(gameId),
        'userId': ObjectId.fromHexString(currentUser.id),
        'content': sanitizedContent,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'isEdited': false,
        'parentId': parentId != null ? ObjectId.fromHexString(parentId) : null,
      };

      await _dbConnectionService.comments.insertOne(comment);
      // 清除该游戏的评论缓存
      await _cacheService.clearGameCommentsCache(gameId);
    } catch (e) {
      print('Add comment error: $e');
      rethrow;
    }
  }

  // 更新评论时清除缓存
  Future<void> updateComment(String commentId, String content) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      final commentObjId = ObjectId.fromHexString(commentId);

      final comment = await _dbConnectionService.comments.findOne(
          where.eq('_id', commentObjId)
      );

      if (comment == null) {
        throw Exception('评论不存在');
      }

      if (comment['userId'] is ObjectId) {
        if (comment['userId'].toHexString() != currentUser.id) {
          throw Exception('无权限修改此评论');
        }
      } else {
        if (comment['userId'] != currentUser.id) {
          throw Exception('无权限修改此评论');
        }
      }

      await _dbConnectionService.comments.updateOne(
        where.eq('_id', commentObjId),
        {
          r'$set': {
            'content': content,
            'updateTime': DateTime.now(),
            'isEdited': true,
          }
        },
      );

      // 清除该游戏的评论缓存
      final gameId = comment['gameId'].toHexString();
      await _cacheService.clearGameCommentsCache(gameId);
    } catch (e) {
      print('Update comment error: $e');
      rethrow;
    }
  }

  // 删除评论时清除缓存
  Future<void> deleteComment(String commentId) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      final commentObjId = ObjectId.fromHexString(commentId);

      final comment = await _dbConnectionService.comments.findOne(
          where.eq('_id', commentObjId)
      );

      if (comment == null) {
        throw Exception('评论不存在');
      }

      String commentUserId = comment['userId'] is ObjectId
          ? comment['userId'].toHexString()
          : comment['userId'];

      if (commentUserId != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限删除此评论');
      }

      // 删除评论及其所有回复
      await _dbConnectionService.comments.deleteMany({
        r'$or': [
          {'_id': commentObjId},
          {'parentId': commentObjId},
        ]
      });

      // 清除该游戏的评论缓存
      final gameId = comment['gameId'].toHexString();
      await _cacheService.clearGameCommentsCache(gameId);
    } catch (e) {
      print('Delete comment error: $e');
      rethrow;
    }
  }

  // 获取评论数量
  Future<int> getCommentCount(String gameId) async {
    try {
      return await _dbConnectionService.comments
          .count(where.eq('gameId', ObjectId.fromHexString(gameId)));
    } catch (e) {
      print('Get comment count error: $e');
      return 0;
    }
  }
}