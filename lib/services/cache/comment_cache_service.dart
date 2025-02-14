// lib/services/cache/comments_cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/comment.dart';
import '../../models/post.dart';

class CommentsCacheService {
  static final CommentsCacheService _instance = CommentsCacheService._internal();
  factory CommentsCacheService() => _instance;

  static const String gameCommentsBox = 'game_comments_cache';
  static const String postRepliesBox = 'post_replies_cache';
  static const int cacheExpiration = 5; // 5分钟过期

  late Box<dynamic> _gameCommentsBox;
  late Box<dynamic> _postRepliesBox;

  Box? _cacheBox;

  CommentsCacheService._internal();

  Future<void> init() async {
    _gameCommentsBox = await Hive.openBox(gameCommentsBox);
    _postRepliesBox = await Hive.openBox(postRepliesBox);
  }

  Future<void> dispose() async {
    if (_cacheBox != null && _cacheBox!.isOpen) {
      await _cacheBox!.close();
      _cacheBox = null;
    }
  }

  // 游戏评论缓存
  Future<void> cacheGameComments(String gameId, List<Comment> comments) async {
    try {
      final currentTime = DateTime.now();
      await _gameCommentsBox.put('${gameId}_timestamp', currentTime.toIso8601String());

      final commentsData = comments.map((comment) {
        final Map<String, dynamic> commentMap = comment.toJson();
        // 处理回复列表
        commentMap['replies'] = comment.replies.map((reply) => reply.toJson()).toList();
        return commentMap;
      }).toList();

      await _gameCommentsBox.put(gameId, commentsData);
    } catch (e) {
      print('Cache game comments error: $e');
    }
  }

  Future<List<Comment>?> getCachedGameComments(String gameId) async {
    try {
      final timestamp = _gameCommentsBox.get('${gameId}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
        return null;
      }

      final cachedData = _gameCommentsBox.get(gameId);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final commentMap = Map<String, dynamic>.from(item as Map);
        // 处理回复列表
        if (commentMap['replies'] != null) {
          final List<Map<String, dynamic>> repliesData =
          (commentMap['replies'] as List).map((reply) =>
          Map<String, dynamic>.from(reply as Map)
          ).toList();
          commentMap['replies'] = repliesData;
        }
        return Comment.fromJson(commentMap);
      }).toList();
    } catch (e) {
      print('Get cached game comments error: $e');
      return null;
    }
  }

  // 修改缓存帖子回复的方法
  Future<void> cachePostReplies(String postId, List<Reply> replies) async {
    try {
      final currentTime = DateTime.now();
      await _postRepliesBox.put('${postId}_timestamp', currentTime.toIso8601String());

      final repliesData = replies.map((reply) {
        final replyMap = reply.toJson();
        // 确保所有 ID 都是字符串形式
        replyMap['_id'] = replyMap['_id']?.toString() ?? reply.id;
        replyMap['postId'] = replyMap['postId']?.toString() ?? reply.postId;
        replyMap['authorId'] = replyMap['authorId']?.toString() ?? reply.authorId;
        if (reply.parentId != null) {
          replyMap['parentId'] = reply.parentId.toString();
        }
        return replyMap;
      }).toList();

      await _postRepliesBox.put(postId, repliesData);
    } catch (e) {
      print('Cache post replies error: $e');
    }
  }

  Future<List<Reply>?> getCachedPostReplies(String postId) async {
    try {
      final timestamp = _postRepliesBox.get('${postId}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration) {
        return null;
      }

      final cachedData = _postRepliesBox.get(postId);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final replyMap = Map<String, dynamic>.from(item as Map);
        // 确保数据格式正确
        return Reply.fromJson(replyMap);
      }).toList();
    } catch (e) {
      print('Get cached post replies error: $e');
      return null;
    }
  }

  // 清除缓存
  Future<void> clearGameCommentsCache(String? gameId) async {
    if (gameId != null) {
      await _gameCommentsBox.delete(gameId);
      await _gameCommentsBox.delete('${gameId}_timestamp');
    } else {
      await _gameCommentsBox.clear();
    }
  }

  Future<void> clearPostRepliesCache(String? postId) async {
    if (postId != null) {
      await _postRepliesBox.delete(postId);
      await _postRepliesBox.delete('${postId}_timestamp');
    } else {
      await _postRepliesBox.clear();
    }
  }

  Future<void> clearAllCache() async {
    await _gameCommentsBox.clear();
    await _postRepliesBox.clear();
  }

  // 判断缓存是否过期
  bool isGameCommentsCacheExpired(String gameId) {
    final timestamp = _gameCommentsBox.get('${gameId}_timestamp');
    if (timestamp == null) return true;

    final lastUpdateTime = DateTime.parse(timestamp);
    return DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration;
  }

  bool isPostRepliesCacheExpired(String postId) {
    final timestamp = _postRepliesBox.get('${postId}_timestamp');
    if (timestamp == null) return true;

    final lastUpdateTime = DateTime.parse(timestamp);
    return DateTime.now().difference(lastUpdateTime).inMinutes >= cacheExpiration;
  }
}