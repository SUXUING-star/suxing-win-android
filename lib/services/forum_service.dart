// lib/services/forum_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/post/post.dart';
import '../models/message/message.dart';
import 'db_connection_service.dart';
import 'user_service.dart';
import './history/post_history_service.dart';
import './security/input_sanitizer_service.dart';
import './counter/batch_view_counter_service.dart';
import 'cache/comment_cache_service.dart';
import 'cache/forum_cache_service.dart';

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
  final ForumCacheService _forumCacheService = ForumCacheService();  // 新增缓存服务

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
        //print('Cannot add to history: User not logged in');
        return;
      }

      await _postHistoryService.addPostHistory(postId);
      print('Post history added successfully: $postId');
    } catch (e) {
      print('Add to post history error: $e');
    }
  }

  // 获取帖子列表
  // 修改获取帖子列表方法，添加缓存逻辑
  Stream<List<Post>> getPosts({String? tag}) async* {
    try {
      while (true) {
        final cacheKey = tag != null ? 'posts_tag_$tag' : 'all_posts';

        // 尝试从缓存获取
        final cachedPosts = await _forumCacheService.getCachedPosts(cacheKey);
        if (cachedPosts != null) {
          yield cachedPosts;
          // 如果缓存未过期，增加轮询间隔
          if (!await _forumCacheService.isRedisCacheExpired(cacheKey)) {
            await Future.delayed(const Duration(seconds: 5));
            continue;
          }
        }

        // 缓存未命中或已过期，从数据库获取
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

        // 更新缓存
        await _forumCacheService.cachePosts(cacheKey, posts);

        yield posts;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get posts error: $e');
      yield [];
    }
  }

  // 修改获取用户帖子列表方法，添加缓存逻辑
  Stream<List<Post>> getUserPosts(String userId) async* {
    try {
      while (true) {
        final cacheKey = 'user_posts_$userId';

        // 尝试从缓存获取
        final cachedPosts = await _forumCacheService.getCachedPosts(cacheKey);
        if (cachedPosts != null) {
          yield cachedPosts;
          if (!await _forumCacheService.isRedisCacheExpired(cacheKey)) {
            await Future.delayed(const Duration(seconds: 5));
            continue;
          }
        }

        // 缓存未命中或已过期，从数据库获取
        final posts = await _dbConnectionService.posts
            .find(where
            .eq('authorId', userId)
            .ne('status', PostStatus.deleted.toString().split('.').last)
            .sortBy('createTime', descending: true))
            .map((doc) => Post.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();

        // 更新缓存
        await _forumCacheService.cachePosts(cacheKey, posts);

        yield posts;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get user posts error: $e');
      yield [];
    }
  }


  // 修改获取帖子详情方法，添加缓存逻辑
  Future<Post?> getPost(String postId) async {
    try {

      if (postId.isEmpty) {
        throw Exception('Invalid post ID');
      }

      final cacheKey = 'post_${postId.trim()}';  // 确保 key 格式正确

      // 尝试从缓存获取
      final cachedPosts = await _forumCacheService.getCachedPosts(cacheKey);
      if (cachedPosts != null && cachedPosts.isNotEmpty) {
        // 使用批量计数服务
        _viewCounter.incrementPostView(postId);
        // 添加到浏览历史
        await addToPostHistory(postId);
        return cachedPosts.first;
      }

      // 缓存未命中，从数据库获取
      final postDoc = await _dbConnectionService.posts
          .findOne(where.eq('_id', ObjectId.fromHexString(postId.trim())));

      if (postDoc == null) return null;

      // 使用批量计数服务
      _viewCounter.incrementPostView(postId);
      // 添加到浏览历史
      await addToPostHistory(postId);

      final post = Post.fromJson(_dbConnectionService.convertDocument(postDoc));

      // 更新缓存
      if (post != null) {
        await _forumCacheService.cachePosts(cacheKey, [post]);
      }

      return post;
    } catch (e) {
      print('Get post error: $e');
      return null;  // 返回 null 而不是抛出异常，这样可以优雅地处理错误
    }
  }


  // 创建帖子
  Future<void> createPost(
      String title, String content, List<String> tags) async {
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

      // 清除相关缓存
      await _forumCacheService.clearCache('all_posts');
      if (tags.isNotEmpty) {
        for (final tag in tags) {
          await _forumCacheService.clearCache('posts_tag_$tag');
        }
      }
      await _forumCacheService.clearCache('user_posts_${currentUser.id}');
      await _forumCacheService.clearCache('recent_user_posts_${currentUser.id}_5');
    } catch (e) {
      print('Create post error: $e');
      rethrow;
    }
  }

  // 更新帖子
  Future<void> updatePost(
      String postId, String title, String content, List<String> tags) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final post = await _dbConnectionService.posts
          .findOne(where.eq('_id', ObjectId.fromHexString(postId)));

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

      // 清除相关缓存
      await _forumCacheService.clearCache('post_$postId');
      await _forumCacheService.clearCache('all_posts');
      if (tags.isNotEmpty) {
        for (final tag in tags) {
          await _forumCacheService.clearCache('posts_tag_$tag');
        }
      }
      await _forumCacheService.clearCache('user_posts_${currentUser.id}');
      await _forumCacheService.clearCache('recent_user_posts_${currentUser.id}_5');
    } catch (e) {
      print('Update post error: $e');
      rethrow;
    }
  }

  // 删除帖子
  Future<void> deletePost(String postId) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      final postObjId = ObjectId.fromHexString(postId);

      final post = await _dbConnectionService.posts
          .findOne(where.eq('_id', postObjId));

      if (post == null) {
        throw Exception('帖子不存在');
      }

      if (post['authorId'] != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限删除此帖子');
      }

      // 直接从数据库中删除帖子
      await _dbConnectionService.posts.deleteOne(
        where.eq('_id', postObjId),
      );

      // 同时删除该帖子下的所有回复
      await _dbConnectionService.replies.deleteMany(
        where.eq('postId', postId),
      );
      // 清除相关缓存
      await _forumCacheService.clearCache('post_$postId');
      await _forumCacheService.clearCache('all_posts');
      if (post != null && post['tags'] != null) {
        for (final tag in post['tags']) {
          await _forumCacheService.clearCache('posts_tag_$tag');
        }
      }
      await _forumCacheService.clearCache('user_posts_${currentUser.id}');
      await _forumCacheService.clearCache('recent_user_posts_${currentUser.id}_5');
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

      final post = await _dbConnectionService.posts
          .findOne(where.eq('_id', ObjectId.fromHexString(postId)));

      if (post == null) {
        throw Exception('帖子不存在');
      }

      final newStatus =
      post['status'] == PostStatus.locked.toString().split('.').last
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
  // 在 ForumService 类中更新处理回复的方法
  Stream<List<Reply>> getReplies(String postId) async* {
    try {
      while (true) {
        // 尝试从缓存获取
        final cachedReplies = await _cacheService.getCachedPostReplies(postId);
        if (cachedReplies != null) {
          yield cachedReplies;
        } else {
          // 从数据库获取
          final postObjId = ObjectId.fromHexString(postId);
          final replies = await _dbConnectionService.replies
              .find(where
              .eq('postId', postObjId)
              .sortBy('createTime'))
              .map((doc) => Reply.fromJson(_dbConnectionService.convertDocument(doc)))
              .toList();

          // 更新缓存
          await _cacheService.cachePostReplies(postId, replies);
          yield replies;
        }
        // 增加轮询间隔到 5 秒
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      print('Get replies error: $e');
      yield [];
    }
  }

  // 在 ForumService 类中修改 addReply 方法
  Future<void> addReply(String postId, String content, {String? parentId}) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      final sanitizedContent = _sanitizer.sanitizeComment(content);

      // 准备所有需要的 ObjectId
      final postObjId = ObjectId.fromHexString(postId);
      final authorObjId = ObjectId.fromHexString(currentUser.id);
      final newReplyId = ObjectId();

      final post = await _dbConnectionService.posts.findOne(where.eq('_id', postObjId));

      if (post == null) {
        throw Exception('帖子不存在');
      }

      if (post['status'] == PostStatus.locked.toString().split('.').last) {
        throw Exception('帖子已被锁定');
      }

      // 准备回复数据
      final Map<String, dynamic> reply = {
        '_id': newReplyId,
        'postId': postObjId,
        'content': sanitizedContent,
        'authorId': authorObjId,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'status': ReplyStatus.active.toString().split('.').last,
      };

      // 处理父回复相关逻辑
      if (parentId != null) {
        final parentObjId = ObjectId.fromHexString(parentId);
        final parentReply = await _dbConnectionService.replies.findOne(where.eq('_id', parentObjId));

        if (parentReply != null) {
          reply['parentId'] = parentObjId;
          final parentUserId = parentReply['authorId'];

          // 只有在回复不是自己的评论时才发送消息
          if (parentUserId != authorObjId) {
            final parentUserObjId = parentUserId is ObjectId
                ? parentUserId
                : ObjectId.fromHexString(parentUserId.toString());

            // 检查父回复作者是否是帖子作者，避免重复通知
            if (parentUserObjId.toHexString() != post['authorId'].toString()) {
              final message = Message.createPostReplyMessage(
                senderId: currentUser.id,
                recipientId: parentUserObjId.toHexString(),
                postId: postId,
                postTitle: post['title'],
                content: sanitizedContent,
              );

              await _dbConnectionService.messages.insertOne(message);
            }
          }
        }
      } else {
        // 直接回复帖子的情况
        final postAuthorId = post['authorId'].toString();
        final currentUserId = authorObjId.toHexString();

        // 只有在回复不是自己的帖子时才发送消息
        if (postAuthorId != currentUserId) {
          final postAuthorObjId = post['authorId'] is ObjectId
              ? post['authorId']
              : ObjectId.fromHexString(post['authorId'].toString());

          final message = Message.createPostReplyMessage(
            senderId: currentUser.id,
            recipientId: postAuthorObjId.toHexString(),
            postTitle: post['title'],
            postId: postId,
            content: sanitizedContent,
          );

          await _dbConnectionService.messages.insertOne(message);
        }
      }

      // 插入回复
      await _dbConnectionService.replies.insertOne(reply);
      await _cacheService.clearPostRepliesCache(postId);

      // 更新帖子回复数
      await _dbConnectionService.posts.updateOne(
        where.eq('_id', postObjId),
        {r'$inc': {'replyCount': 1}},
      );
    } catch (e) {
      print('Add reply error: $e');
      rethrow;
    }
  }

  // 编辑回复
  // 更新回复内容
  Future<void> updateReply(String replyId, String content) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      final replyObjId = ObjectId.fromHexString(replyId);

      final reply = await _dbConnectionService.replies.findOne(
          where.eq('_id', replyObjId)
      );

      if (reply == null) {
        throw Exception('回复不存在');
      }

      // 清除缓存
      final postId = reply['postId'] is ObjectId
          ? reply['postId'].toHexString()
          : reply['postId'];
      await _cacheService.clearPostRepliesCache(postId);

      // 权限检查
      final replyAuthorId = reply['authorId'] is ObjectId
          ? reply['authorId'].toHexString()
          : reply['authorId'].toString();

      if (replyAuthorId != currentUser.id && !currentUser.isAdmin) {
        throw Exception('无权限修改此回复');
      }

      // 更新回复内容
      await _dbConnectionService.replies.updateOne(
        where.eq('_id', replyObjId),
        {
          r'$set': {
            'content': content,
            'updateTime': DateTime.now(),
            'isEdited': true
          }
        },
      );
    } catch (e) {
      print('Update reply error: $e');
      rethrow;
    }
  }

  Future<void> deleteReply(String replyId) async {
    try {
      print('Attempting to delete reply with ID: $replyId');

      final currentUser = await _userService.getCurrentUser();
      final replyObjId = ObjectId.fromHexString(replyId);

      // 查找回复
      final reply = await _dbConnectionService.replies.findOne(
          where.eq('_id', replyObjId)
      );

      if (reply == null) {
        print('Reply not found: $replyId');
        throw Exception('回复不存在');
      }

      // 获取 postId 用于后续操作
      final postId = reply['postId'] is ObjectId
          ? reply['postId']
          : ObjectId.fromHexString(reply['postId']);

      // 删除相关的消息通知
      await _dbConnectionService.messages.deleteMany(
          where
              .eq('type', 'post_reply')
              .eq('senderId', reply['authorId'])
              .eq('postId', postId.toHexString())
      );

      // 获取这个回复下的所有子回复数量
      final childrenCount = await _dbConnectionService.replies.count(
          where.eq('parentId', replyObjId)
      );

      // 删除子回复相关的消息
      final childReplies = await _dbConnectionService.replies
          .find(where.eq('parentId', replyObjId))
          .toList();

      for (final childReply in childReplies) {
        await _dbConnectionService.messages.deleteMany(
            where
                .eq('type', 'post_reply')
                .eq('senderId', childReply['authorId'])
                .eq('postId', postId.toHexString())
        );
      }

      // 删除子回复
      await _dbConnectionService.replies.deleteMany(
          where.eq('parentId', replyObjId)
      );

      // 删除回复本身
      await _dbConnectionService.replies.deleteOne(
          where.eq('_id', replyObjId)
      );

      // 清除缓存
      await _cacheService.clearPostRepliesCache(postId.toHexString());

      // 更新帖子回复数（减去主回复和所有子回复的数量）
      await _dbConnectionService.posts.updateOne(
        where.eq('_id', postId),
        {r'$inc': {'replyCount': -(childrenCount + 1)}},
      );

      print('Successfully deleted reply: $replyId');
    } catch (e) {
      print('Delete reply error: $e');
      print('Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }




  // 修改获取最近用户帖子方法，添加缓存逻辑
  Future<List<Post>> getRecentUserPosts(String userId, {int limit = 5}) async {
    try {
      final cacheKey = 'recent_user_posts_${userId}_$limit';

      // 尝试从缓存获取
      final cachedPosts = await _forumCacheService.getCachedPosts(cacheKey);
      if (cachedPosts != null) {
        return cachedPosts;
      }

      // 缓存未命中，从数据库获取
      final cursor = _dbConnectionService.posts.find(where
          .eq('authorId', userId)
          .ne('status', PostStatus.deleted.toString().split('.').last)
          .sortBy('createTime', descending: true)
          .limit(limit));

      final posts = await cursor
          .map((doc) => Post.fromJson(_dbConnectionService.convertDocument(doc)))
          .toList();

      // 更新缓存
      await _forumCacheService.cachePosts(cacheKey, posts);

      return posts;
    } catch (e) {
      print('Get recent user posts error: $e');
      return [];
    }
  }
}
