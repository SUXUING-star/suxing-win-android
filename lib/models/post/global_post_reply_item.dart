// lib/models/post/global_post_reply_item.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GlobalPostReplyItem {
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
    String? parentId,
    DateTime? updateTime,
    String? status,
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
      id: UtilJson.parseId(json['id']),
      postId: UtilJson.parseId(json['postId']),
      postTitle: UtilJson.parseNullableStringSafely(json['postTitle']),
      content: UtilJson.parseStringSafely(json['content']),
      authorId: UtilJson.parseId(json['authorId']),
      createTime: UtilJson.parseDateTime(json['createTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'postTitle': postTitle,
      'content': content,
      'authorId': authorId,
      'createTime': createTime.toIso8601String(),
    };
  }
}
