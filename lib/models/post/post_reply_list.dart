// ---------------------------------------------------------------------------
// 文件路径: lib/models/post/post_reply_list_data.dart (示例路径)
// ---------------------------------------------------------------------------

import 'package:suxingchahui/models/post/post_reply.dart'; // 确保 PostReply 模型的路径正确
import 'package:suxingchahui/models/common/pagination.dart'; // 导入你的 PaginationData 模型

class PostReplyList {
  final List<PostReply> replies;
  final PaginationData pagination;

  PostReplyList({
    required this.replies,
    required this.pagination,
  });

  // 静态工厂方法，用于创建一个空的 PostReplyList 实例
  static PostReplyList empty() {
    return PostReplyList(
      replies: [],
      pagination: PaginationData(
          page: 1, limit: 0, total: 0, pages: 0), // 使用 PaginationData 的空状态
    );
  }

  factory PostReplyList.fromJson(Map<String, dynamic> json) {
    List<PostReply> repliesList = [];
    if (json['replies'] != null && json['replies'] is List) {
      repliesList = (json['replies'] as List)
          .map((replyJson) =>
              PostReply.fromJson(Map<String, dynamic>.from(replyJson)))
          .toList();
    }

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      int totalItems = repliesList.length;
      int defaultLimit = 10; // 回复通常每页数量较少
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: (totalItems == 0)
            ? 0
            : ((defaultLimit <= 0) ? 1 : (totalItems / defaultLimit).ceil()),
      );
    }

    return PostReplyList(
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

  PostReplyList copyWith({
    List<PostReply>? replies,
    PaginationData? pagination,
  }) {
    return PostReplyList(
      replies: replies ?? this.replies,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'PostReplyList(replies: ${replies.length} replies, pagination: $pagination)';
  }
}
