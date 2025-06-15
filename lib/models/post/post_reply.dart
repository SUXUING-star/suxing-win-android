// lib/models/post/post_reply.dart
import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:suxingchahui/models/util_json.dart';

enum PostReplyStatus {
  active,
  deleted,
}

@immutable
class PostReply {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String? parentId;
  final DateTime createTime;
  final DateTime updateTime;
  final PostReplyStatus status;

  const PostReply({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    this.parentId,
    required this.createTime,
    required this.updateTime,
    this.status = PostReplyStatus.active,
  });

  factory PostReply.fromJson(Map<String, dynamic> json) {
    return PostReply(
      id: UtilJson.parseId(json['_id'] ?? json['id']),
      postId: UtilJson.parseId(json['postId']),
      content: UtilJson.parseStringSafely(json['content']),
      authorId: UtilJson.parseId(json['authorId']),
      parentId: UtilJson.parseNullableId(json['parentId']),
      createTime: UtilJson.parseDateTime(json['createTime']),
      updateTime: UtilJson.parseDateTime(json['updateTime']),
      // 业务逻辑: 从字符串安全解析枚举类型，如果匹配失败则使用默认值 PostReplyStatus.active
      status: PostReplyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PostReplyStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'parentId': parentId,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  // 添加一个新方法用于转换为 MongoDB 文档
  Map<String, dynamic> toMongoDocument() {
    try {
      return {
        '_id': id.isEmpty ? ObjectId() : ObjectId.fromHexString(id),
        'postId': ObjectId.fromHexString(postId),
        'content': content,
        'authorId': ObjectId.fromHexString(authorId),
        'parentId': parentId != null ? ObjectId.fromHexString(parentId!) : null,
        'createTime': createTime,
        'updateTime': updateTime,
        'status': status.toString().split('.').last,
      };
    } catch (e) {
      // print('Error in Reply.toMongoDocument(): $e');
      rethrow;
    }
  }

  static PostReply empty() {
    return PostReply(
      id: '',
      postId: '',
      content: '',
      authorId: '',
      parentId: null,
      createTime: DateTime.fromMillisecondsSinceEpoch(0), // 或者 DateTime.now()
      updateTime: DateTime.fromMillisecondsSinceEpoch(0), // 或者 DateTime.now()
      status: PostReplyStatus.active, // 默认状态
    );
  }

  // UI 判断是否编辑过
  bool get hasBeenEdited {
    const Duration tolerance = Duration(seconds: 1);
    return updateTime.difference(createTime).abs() > tolerance;
  }
}
