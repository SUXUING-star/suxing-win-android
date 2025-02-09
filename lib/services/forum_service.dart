// lib/services/forum_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/post.dart';
import 'db_connection_service.dart';
import 'user_service.dart';
import './history/post_history_service.dart';
import './security/input_sanitizer_service.dart';
import './counter/batch_view_counter_service.dart';
import 'cache/comment_cache_service.dart';

class ForumService {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();
  final PostHistoryService _postHistoryService = PostHistoryService();
  // 防止输入的sql注入
  final InputSanitizerService _sanitizer = InputSanitizerService();
  // 延时增加浏览量
  final BatchViewCounterService _viewCounter = BatchViewCounterService();

  final CommentsCacheService _cacheService = CommentsCacheService();

  ForumService._internal();

  bool _isValidObjectId(String? id) {
    if (id == null) return false;
    try {
      ObjectId.fromHexString(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addToPostHistory(String postId) async {
    try {
      if (!_isValidObjectId(postId)) {
        print('Invalid postId format: $postId');
        return;
      }

      final userId = await _userService.currentUserId;
      if (userId == null) {
        print('Cannot add to history: User not logged in');
        return;
      }

      await _postHistoryService.addPostHistory(postId);
      print('Post history added successfully: $postId');
    } catch (e) {
      print('Add to post history error: $e');
    }
  }

  // 获取帖子列表
  Stream<List<Post>> getPosts({String? tag}) async* {
    try {
      while (true) {
        final query = where
            .eq('status', PostStatus.active.toString().split('.').last)
            .sortBy('createTime', descending: true);

        if (tag != null) {
          query.eq('tags', tag);
        }

        final posts = await _dbConnectionService.posts
            .find(query)
            .map((doc) => Post.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();

        yield posts;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get posts error: $e');
      yield [];
    }
  }

  // 获取某个用户的帖子
  Stream<List<Post>> getUserPosts(String userId) async* {
    try {
      while (true) {
        final posts = await _dbConnectionService.posts
            .find(where
            .eq('authorId', userId)
            .ne('status', PostStatus.deleted.toString().split('.').last)
            .sortBy('createTime', descending: true))
            .map((doc) => Post.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();

        yield posts;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get user posts error: $e');
      yield [];
    }
  }

  // 获取帖子详情
  // 修改 getPost 方法以添加历史记录
  Future<Post?> getPost(String postId) async {
    try {
      final postDoc = await _dbConnectionService.posts.findOne(
          where.eq('_id', ObjectId.fromHexString(postId))
      );

      if (postDoc == null) return null;

      // 使用批量计数服务
      _viewCounter.incrementPostView(postId);

      // 添加到浏览历史
      await addToPostHistory(postId);

      return Post.fromJson(_dbConnectionService.convertDocument(postDoc));
    } catch (e) {
      print('Get post error: $e');
      rethrow;
    }
  }

  // 创建帖子
  Future<void> createPost(String title, String content, List<String> tags) async {
    try {
      final sanitizedTitle = _sanitizer.sanitizeTitle(title);
      final sanitizedContent = _sanitizer.sanitizePostContent(content);
      final sanitizedTags = _sanitizer.sanitizeTags(tags);
      final currentUser = await _userService.getCurrentUser();

      final post = {
        'title': sanitizedTitle,
        'content': sanitizedContent,
        'authorId': currentUser.id,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'viewCount': 0,
        'replyCount': 0,
        'tags': sanitizedTags,
        'status': PostStatus.active.toString().split('.').last,
      };

      await _dbConnectionService.posts.insertOne(post);
    } catch (e) {
      print('Create post error: $e');
      rethrow;
    }
  }

  // 更新帖子
  Future<void> updatePost(String postId, String title, String content, List<String> tags) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final post = await _dbConnectionService.posts.findOne(
          where.eq('_id', ObjectId.fromHexString(postId))
      );

      if (post == null) {
        throw Exception('帖子不存在');
      }

      if (post['authorId'] != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限修改此帖子');
      }

      await _dbConnectionService.posts.updateOne(
        where.eq('_id', ObjectId.fromHexString(postId)),
        {
          r'$set': {
            'title': title,
            'content': content,
            'tags': tags,
            'updateTime': DateTime.now(),
          }
        },
      );
    } catch (e) {
      print('Update post error: $e');
      rethrow;
    }
  }

  // 删除帖子
  Future<void> deletePost(String postId) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final post = await _dbConnectionService.posts.findOne(
          where.eq('_id', ObjectId.fromHexString(postId))
      );

      if (post == null) {
        throw Exception('帖子不存在');
      }

      if (post['authorId'] != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限删除此帖子');
      }

      // 将帖子状态设为已删除
      await _dbConnectionService.posts.updateOne(
        where.eq('_id', ObjectId.fromHexString(postId)),
        {
          r'$set': {
            'status': PostStatus.deleted.toString().split('.').last,
            'updateTime': DateTime.now(),
          }
        },
      );

      // 同时将该帖子下的所有回复设为已删除
      await _dbConnectionService.replies.updateMany(
        where.eq('postId', postId),
        {
          r'$set': {
            'status': ReplyStatus.deleted.toString().split('.').last,
            'updateTime': DateTime.now(),
          }
        },
      );
    } catch (e) {
      print('Delete post error: $e');
      rethrow;
    }
  }

  // 锁定/解锁帖子
  Future<void> togglePostLock(String postId) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      if (!currentUser.isAdmin) {
        throw Exception('只有管理员可以锁定/解锁帖子');
      }

      final post = await _dbConnectionService.posts.findOne(
          where.eq('_id', ObjectId.fromHexString(postId))
      );

      if (post == null) {
        throw Exception('帖子不存在');
      }

      final newStatus = post['status'] == PostStatus.locked.toString().split('.').last
          ? PostStatus.active
          : PostStatus.locked;

      await _dbConnectionService.posts.updateOne(
        where.eq('_id', ObjectId.fromHexString(postId)),
        {
          r'$set': {
            'status': newStatus.toString().split('.').last,
            'updateTime': DateTime.now(),
          }
        },
      );
    } catch (e) {
      print('Toggle post lock error: $e');
      rethrow;
    }
  }

  // 获取帖子的回复
  Stream<List<Reply>> getReplies(String postId) async* {
    try {
      while (true) {
        // 尝试从缓存获取
        final cachedReplies = await _cacheService.getCachedPostReplies(postId);
        if (cachedReplies != null) {
          yield cachedReplies;
        } else {
          // 从数据库获取
          final replies = await _dbConnectionService.replies
              .find(where
              .eq('postId', postId)
              .eq('status', ReplyStatus.active.toString().split('.').last)
              .sortBy('createTime'))
              .map((doc) => Reply.fromJson(_dbConnectionService.convertDocument(doc)))
              .toList();

          // 更新缓存
          await _cacheService.cachePostReplies(postId, replies);
          yield replies;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get replies error: $e');
      yield [];
    }
  }

  // 添加回复
  Future<void> addReply(String postId, String content, {String? parentId}) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      final sanitizedContent = _sanitizer.sanitizeComment(content);

      final post = await _dbConnectionService.posts.findOne(
          where.eq('_id', ObjectId.fromHexString(postId))
      );

      if (post == null) {
        throw Exception('帖子不存在');
      }

      if (post['status'] == PostStatus.locked.toString().split('.').last) {
        throw Exception('帖子已被锁定');
      }

      final reply = {
        'postId': postId,
        'content': sanitizedContent,
        'authorId': currentUser.id,
        'parentId': parentId,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'status': ReplyStatus.active.toString().split('.').last,
      };

      await _dbConnectionService.replies.insertOne(reply);
      await _cacheService.clearPostRepliesCache(postId);  // 清除缓存

      // 更新帖子回复数
      await _dbConnectionService.posts.updateOne(
        where.eq('_id', ObjectId.fromHexString(postId)),
        {r'$inc': {'replyCount': 1}},
      );
    } catch (e) {
      print('Add reply error: $e');
      rethrow;
    }
  }

  // 编辑回复
  Future<void> updateReply(String replyId, String content) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final reply = await _dbConnectionService.replies.findOne(
          where.eq('_id', ObjectId.fromHexString(replyId))
      );
      if (reply != null) {
        await _cacheService.clearPostRepliesCache(reply['postId']);
      }

      if (reply == null) {
        throw Exception('回复不存在');
      }

      if (reply['authorId'] != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限修改此回复');
      }

      await _dbConnectionService.replies.updateOne(
        where.eq('_id', ObjectId.fromHexString(replyId)),
        {
          r'$set': {
            'content': content,
            'updateTime': DateTime.now(),
          }
        },
      );

    } catch (e) {
      print('Update reply error: $e');
      rethrow;
    }
  }

  // 删除回复
  Future<void> deleteReply(String replyId) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final reply = await _dbConnectionService.replies.findOne(
          where.eq('_id', ObjectId.fromHexString(replyId))
      );
      if (reply != null) {
        await _cacheService.clearPostRepliesCache(reply['postId']);
      }

      if (reply == null) {
        throw Exception('回复不存在');
      }

      if (reply['authorId'] != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限删除此回复');
      }

      // 将回复状态设为已删除
      await _dbConnectionService.replies.updateOne(
        where.eq('_id', ObjectId.fromHexString(replyId)),
        {
          r'$set': {
            'status': ReplyStatus.deleted.toString().split('.').last,
            'updateTime': DateTime.now(),
          }
        },
      );

      // 更新帖子回复数
      await _dbConnectionService.posts.updateOne(
        where.eq('_id', ObjectId.fromHexString(reply['postId'])),
        {r'$inc': {'replyCount': -1}},
      );
    } catch (e) {
      print('Delete reply error: $e');
      rethrow;
    }
  }
  Future<List<Post>> getRecentUserPosts(String userId, {int limit = 5}) async {
    try {
      final cursor = _dbConnectionService.posts.find(
          where
              .eq('authorId', userId)
              .ne('status', PostStatus.deleted.toString().split('.').last)
              .sortBy('createTime', descending: true)
              .limit(limit)
      );

      final posts = await cursor
          .map((doc) => Post.fromJson(_dbConnectionService.convertDocument(doc)))
          .toList();

      return posts;
    } catch (e) {
      print('Get recent user posts error: $e');
      return [];
    }
  }
}