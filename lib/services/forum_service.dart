// lib/services/forum_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/post.dart';
import 'db_connection_service.dart';
import 'user_service.dart';

class ForumService {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final UserService _userService = UserService();

  ForumService._internal();

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
  Future<Post?> getPost(String postId) async {
    try {
      final postDoc = await _dbConnectionService.posts.findOne(
          where.eq('_id', ObjectId.fromHexString(postId))
      );

      if (postDoc == null) return null;

      // 增加浏览量
      await _dbConnectionService.posts.updateOne(
        where.eq('_id', ObjectId.fromHexString(postId)),
        {r'$inc': {'viewCount': 1}},
      );

      return Post.fromJson(_dbConnectionService.convertDocument(postDoc));
    } catch (e) {
      print('Get post error: $e');
      rethrow;
    }
  }

  // 创建帖子
  Future<void> createPost(String title, String content, List<String> tags) async {
    try {
      final currentUser = await _userService.getCurrentUser();

      final post = {
        'title': title,
        'content': content,
        'authorId': currentUser.id,
        'authorName': currentUser.username,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'viewCount': 0,
        'replyCount': 0,
        'tags': tags,
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
        final replies = await _dbConnectionService.replies
            .find(where
            .eq('postId', postId)
            .eq('status', ReplyStatus.active.toString().split('.').last)
            .sortBy('createTime'))
            .map((doc) => Reply.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();

        yield replies;
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
        'content': content,
        'authorId': currentUser.id,
        'authorName': currentUser.username,
        'parentId': parentId,
        'createTime': DateTime.now(),
        'updateTime': DateTime.now(),
        'status': ReplyStatus.active.toString().split('.').last,
      };

      await _dbConnectionService.replies.insertOne(reply);

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
}