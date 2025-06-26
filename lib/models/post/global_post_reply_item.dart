// lib/models/post/global_post_reply_item.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/post/post_reply.dart'; // 确认此引入是否仍必要，如果fromReply不再需要PostReply作为参数，则可能不需要
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GlobalPostReplyItem {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyPostId = 'postId';
  static const String jsonKeyPostTitle = 'postTitle';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyAuthorId = 'authorId';
  static const String jsonKeyCreateTime = 'createTime';

  final String id;
  final String postId;
  final String? postTitle;
  final String content;
  final String authorId;
  final DateTime createTime;

  const GlobalPostReplyItem({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.content,
    required this.authorId,
    required this.createTime,
  });

  GlobalPostReplyItem copyWith({
    String? id,
    String? postId,
    String? postTitle, // 允许 copy 时修改
    String? content,
    String? authorId,
    DateTime? createTime,
    // 以下字段在原始 copyWith 中不存在，但在此处也保留（以防未来需要）
    // String? parentId,
    // DateTime? updateTime,
    // String? status,
  }) {
    return GlobalPostReplyItem(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle, // 如果不传 postTitle，则保持原来的
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      createTime: createTime ?? this.createTime,
    );
  }

  factory GlobalPostReplyItem.fromJson(Map<String, dynamic> json) {
    return GlobalPostReplyItem(
      id: UtilJson.parseId(json[jsonKeyId]), // 使用常量
      postId: UtilJson.parseId(json[jsonKeyPostId]), // 使用常量
      postTitle:
          UtilJson.parseNullableStringSafely(json[jsonKeyPostTitle]), // 使用常量
      content: UtilJson.parseStringSafely(json[jsonKeyContent]), // 使用常量
      authorId: UtilJson.parseId(json[jsonKeyAuthorId]), // 使用常量
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用常量
      jsonKeyPostId: postId, // 使用常量
      jsonKeyPostTitle: postTitle, // 使用常量
      jsonKeyContent: content, // 使用常量
      jsonKeyAuthorId: authorId, // 使用常量
      jsonKeyCreateTime: createTime.toIso8601String(), // 使用常量
    };
  }

  factory GlobalPostReplyItem.fromReply(
      GlobalPostReplyItem originalGlobalReply, PostReply newReply) {
    return GlobalPostReplyItem(
      id: originalGlobalReply.id,
      postId: originalGlobalReply.postId,
      postTitle: originalGlobalReply.postTitle,
      content: newReply.content,
      authorId: originalGlobalReply.authorId,
      createTime: originalGlobalReply.createTime,
    );
  }
}
