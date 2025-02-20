// lib/services/cache/comments_cache_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/comment/comment.dart';
import '../../models/post/post.dart';
import '../../config/app_config.dart';

class CommentsCacheService {
  static final CommentsCacheService _instance = CommentsCacheService
      ._internal();

  factory CommentsCacheService() => _instance;

  static const String gameCommentsBox = 'game_comments_cache';
  static const String postRepliesBox = 'post_replies_cache';
  static const int cacheExpiration = 5; // 5分钟过期

  final String _redisProxyUrl = AppConfig.redisProxyUrl;
  late Box<dynamic> _gameCommentsBox;
  late Box<dynamic> _postRepliesBox;

  CommentsCacheService._internal();

  Future<void> init() async {
    _gameCommentsBox = await Hive.openBox(gameCommentsBox);
    _postRepliesBox = await Hive.openBox(postRepliesBox);
  }

  // 游戏评论缓存
  Future<void> cacheGameComments(String gameId, List<Comment> comments) async {
    try {
      // 本地缓存
      await _cacheLocalGameComments(gameId, comments);

      // Redis缓存
      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/comments/game'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'gameId': gameId,
          'data': comments.map((c) => c.toJson()).toList(),
          'expiration': cacheExpiration * 60,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Cache game comments error: $e');
    }
  }

  Future<void> _cacheLocalGameComments(String gameId,
      List<Comment> comments) async {
    try {
      final currentTime = DateTime.now();
      await _gameCommentsBox.put(
          '${gameId}_timestamp', currentTime.toIso8601String());

      final commentsData = comments.map((comment) {
        final Map<String, dynamic> commentMap = comment.toJson();
        commentMap['replies'] =
            comment.replies.map((reply) => reply.toJson()).toList();
        return commentMap;
      }).toList();

      await _gameCommentsBox.put(gameId, commentsData);
    } catch (e) {
      print('Local cache error: $e');
    }
  }

  Future<List<Comment>?> getCachedGameComments(String gameId) async {
    try {
      // 尝试从Redis获取
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/comments/game/$gameId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final comments = (responseData['data'] as List)
              .map((item) => Comment.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          // 同步到本地缓存
          await _cacheLocalGameComments(gameId, comments);
          return comments;
        }
      }

      // 如果Redis没有数据，尝试从本地缓存获取
      return await _getLocalCachedGameComments(gameId);
    } catch (e) {
      print('Get cached game comments error: $e');
      return await _getLocalCachedGameComments(gameId);
    }
  }

  Future<List<Comment>?> _getLocalCachedGameComments(String gameId) async {
    try {
      final timestamp = _gameCommentsBox.get('${gameId}_timestamp');
      if (timestamp == null) return null;

      final lastUpdateTime = DateTime.parse(timestamp);
      if (DateTime
          .now()
          .difference(lastUpdateTime)
          .inMinutes >= cacheExpiration) {
        return null;
      }

      final cachedData = _gameCommentsBox.get(gameId);
      if (cachedData == null) return null;

      return (cachedData as List).map((item) {
        final commentMap = Map<String, dynamic>.from(item as Map);

        // 处理回复列表
        if (commentMap['replies'] != null) {
          final List<Map<String, dynamic>> repliesData =
          (commentMap['replies'] as List).map((reply) {
            // 确保 ID 字段正确转换
            final replyMap = Map<String, dynamic>.from(reply as Map);
            if (replyMap['_id'] != null) {
              replyMap['id'] = replyMap['_id'];
              replyMap.remove('_id');
            }
            return replyMap;
          }).toList();
          commentMap['replies'] = repliesData;
        } else {
          commentMap['replies'] = [];
        }

        // 确保主评论的 ID 字段正确
        if (commentMap['_id'] != null) {
          commentMap['id'] = commentMap['_id'];
          commentMap.remove('_id');
        }

        // 确保日期字段正确转换
        if (commentMap['createTime'] is String) {
          commentMap['createTime'] = DateTime.parse(commentMap['createTime']);
        }
        if (commentMap['updateTime'] is String) {
          commentMap['updateTime'] = DateTime.parse(commentMap['updateTime']);
        }

        return Comment.fromJson(commentMap);
      }).toList()
        ..sort((a, b) => b.createTime.compareTo(a.createTime)); // 按时间倒序排序
    } catch (e) {
      print('Get local cached game comments error: $e');
      return null;
    }
  }
  // 缓存帖子回复
  Future<void> cachePostReplies(String postId, List<Reply> replies) async {
    try {
      // 本地缓存
      await _cacheLocalPostReplies(postId, replies);

      // Redis缓存
      final response = await http.post(
        Uri.parse('$_redisProxyUrl/cache/comments/post'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'postId': postId,
          'data': replies.map((reply) {
            final replyMap = reply.toJson();
            replyMap['_id'] = replyMap['_id']?.toString() ?? reply.id;
            replyMap['postId'] = replyMap['postId']?.toString() ?? reply.postId;
            replyMap['authorId'] = replyMap['authorId']?.toString() ?? reply.authorId;
            if (reply.parentId != null) {
              replyMap['parentId'] = reply.parentId.toString();
            }
            return replyMap;
          }).toList(),
          'expiration': cacheExpiration * 60,
        }),
      );

      if (response.statusCode != 200) {
        print('Redis cache failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Cache post replies error: $e');
    }
  }

  Future<void> _cacheLocalPostReplies(String postId, List<Reply> replies) async {
    try {
      final currentTime = DateTime.now();
      await _postRepliesBox.put('${postId}_timestamp', currentTime.toIso8601String());

      final repliesData = replies.map((reply) {
        final replyMap = reply.toJson();
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
      print('Local cache error: $e');
    }
  }

  Future<List<Reply>?> getCachedPostReplies(String postId) async {
    try {
      // 尝试从Redis获取
      final response = await http.get(
        Uri.parse('$_redisProxyUrl/cache/comments/post/$postId'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final replies = (responseData['data'] as List)
              .map((item) => Reply.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          // 同步到本地缓存
          await _cacheLocalPostReplies(postId, replies);
          return replies;
        }
      }

      // 如果Redis没有数据，尝试从本地缓存获取
      return await _getLocalCachedPostReplies(postId);
    } catch (e) {
      print('Get cached post replies error: $e');
      return await _getLocalCachedPostReplies(postId);
    }
  }

  Future<List<Reply>?> _getLocalCachedPostReplies(String postId) async {
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
        return Reply.fromJson(replyMap);
      }).toList();
    } catch (e) {
      print('Get local cached post replies error: $e');
      return null;
    }
  }

  // 清除缓存方法
  Future<void> clearGameCommentsCache(String? gameId) async {
    try {
      if (gameId != null) {
        // 清除本地缓存
        await _gameCommentsBox.delete(gameId);
        await _gameCommentsBox.delete('${gameId}_timestamp');

        // 清除Redis缓存
        await http.delete(Uri.parse('$_redisProxyUrl/cache/comments/game/$gameId'));
      } else {
        // 清除所有游戏评论缓存
        await _gameCommentsBox.clear();
        await http.delete(Uri.parse('$_redisProxyUrl/cache/comments/game'));
      }
    } catch (e) {
      print('Clear game comments cache error: $e');
    }
  }

  Future<void> clearPostRepliesCache(String? postId) async {
    try {
      if (postId != null) {
        // 清除本地缓存
        await _postRepliesBox.delete(postId);
        await _postRepliesBox.delete('${postId}_timestamp');

        // 清除Redis缓存
        await http.delete(Uri.parse('$_redisProxyUrl/cache/comments/post/$postId'));
      } else {
        // 清除所有帖子回复缓存
        await _postRepliesBox.clear();
        await http.delete(Uri.parse('$_redisProxyUrl/cache/comments/post'));
      }
    } catch (e) {
      print('Clear post replies cache error: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      // 清除本地缓存
      await _gameCommentsBox.clear();
      await _postRepliesBox.clear();

      // 清除Redis缓存
      await http.delete(Uri.parse('$_redisProxyUrl/cache/comments/game'));
      await http.delete(Uri.parse('$_redisProxyUrl/cache/comments/post'));
    } catch (e) {
      print('Clear all comments cache error: $e');
    }
  }
}