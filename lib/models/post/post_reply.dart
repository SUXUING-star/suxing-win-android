// lib/models/post/post_reply.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';


enum PostReplyStatus {
  active,
  deleted,
}

@immutable
class PostReply implements ToJsonExtension {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId =
      '_id'; // MongoDB 默认的 _id 字段，用于 fromJson 和 toMongoDocument
  static const String jsonKeyPostId = 'postId';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyAuthorId = 'authorId';
  static const String jsonKeyParentId = 'parentId';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeyStatus = 'status';

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
      id: UtilJson.parseId(json[jsonKeyMongoId] ?? json[jsonKeyId]), // 使用常量
      postId: UtilJson.parseId(json[jsonKeyPostId]), // 使用常量
      content: UtilJson.parseStringSafely(json[jsonKeyContent]), // 使用常量
      authorId: UtilJson.parseId(json[jsonKeyAuthorId]), // 使用常量
      parentId: UtilJson.parseNullableId(json[jsonKeyParentId]), // 使用常量
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
      updateTime: UtilJson.parseDateTime(json[jsonKeyUpdateTime]), // 使用常量
      // 业务逻辑: 从字符串安全解析枚举类型，如果匹配失败则使用默认值 PostReplyStatus.active
      status: PostReplyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json[jsonKeyStatus], // 使用常量
        orElse: () => PostReplyStatus.active,
      ),
    );
  }

  static List<PostReply> fromListJson(dynamic json) {
    return UtilJson.parseObjectList<PostReply>(
      json, // 使用常量
      (itemJson) =>
          PostReply.fromJson(itemJson), // 告诉它怎么把一个 item 的 json 转成 PostReply 对象
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用常量，通常用于客户端表示或通用JSON序列化
      jsonKeyPostId: postId, // 使用常量
      jsonKeyContent: content, // 使用常量
      jsonKeyAuthorId: authorId, // 使用常量
      jsonKeyParentId: parentId, // 使用常量
      jsonKeyCreateTime: createTime.toIso8601String(), // 使用常量
      jsonKeyUpdateTime: updateTime.toIso8601String(), // 使用常量
      jsonKeyStatus: status.toString().split('.').last, // 使用常量
    };
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
