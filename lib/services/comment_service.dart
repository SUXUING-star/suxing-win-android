// lib/services/comment_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/comment.dart';
import 'db_connection_service.dart';
import 'user_service.dart';

class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();

  CommentService._internal();

  // 获取游戏的评论列表
  Stream<List<Comment>> getGameComments(String gameId) async* {
    try {
      while (true) {
        // 获取主评论
        final comments = await _dbConnectionService.comments
            .find(where
            .eq('gameId', ObjectId.fromHexString(gameId))
            .eq('parentId', null)
            .sortBy('createTime', descending: true)
        )
            .map((doc) => Comment.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();

        // 获取每个评论的回复
        for (var comment in comments) {
          final replies = await _dbConnectionService.comments
              .find(where
              .eq('parentId', comment.id)
              .sortBy('createTime')
          )
              .map((doc) => Comment.fromJson(_dbConnectionService.convertDocument(doc)))
              .toList();

          comment.replies.addAll(replies);
        }

        yield comments;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get comments error: $e');
      yield [];
    }
  }

  // 添加评论
  Future<void> addComment(String gameId, String content, {String? parentId}) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final comment = {
        'gameId': ObjectId.fromHexString(gameId),
        'userId': ObjectId.fromHexString(currentUser.id),
        'content': content,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'isEdited': false,
        'username': currentUser.username,
        'parentId': parentId != null ? ObjectId.fromHexString(parentId) : null,
      };

      await _dbConnectionService.comments.insertOne(comment);
    } catch (e) {
      print('Add comment error: $e');
      rethrow;
    }
  }

  // 更新评论
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
        // 如果 userId 是 ObjectId，转换为字符串进行比较
        if (comment['userId'].toHexString() != currentUser.id) {
          throw Exception('无权限修改此评论');
        }
      } else {
        // 如果 userId 已经是字符串
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
    } catch (e) {
      print('Update comment error: $e');
      rethrow;
    }
  }

  // 删除评论
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