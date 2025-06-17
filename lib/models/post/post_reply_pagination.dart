// lib/models/post/post_reply_pagination.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/post/post_reply.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class PostReplyPagination {
  final List<PostReply> replies;
  final PaginationData pagination;

  const PostReplyPagination({
    required this.replies,
    required this.pagination,
  });

  // 静态工厂方法，用于创建一个空的 PostReplyList 实例
  static PostReplyPagination empty() {
    return PostReplyPagination(
      replies: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
    );
  }

  factory PostReplyPagination.fromJson(Map<String, dynamic> json) {
    final repliesList = UtilJson.parseObjectList<PostReply>(
      json['replies'], // 传入原始的 list 数据
      (itemJson) =>
          PostReply.fromJson(itemJson), // 告诉它怎么把一个 item 的 json 转成 Game 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: repliesList, // 把游戏列表传进去，用于计算兜底分页
    );

    return PostReplyPagination(
      replies: repliesList,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  PostReplyPagination copyWith({
    List<PostReply>? replies,
    PaginationData? pagination,
  }) {
    return PostReplyPagination(
      replies: replies ?? this.replies,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'PostReplyList(replies: ${replies.length} replies, pagination: $pagination)';
  }
}
