// lib/models/post/post_reply_pagination.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/post/post_reply.dart';
import 'package:suxingchahui/models/common/pagination.dart';


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
    List<PostReply> repliesList = [];
    if (json['replies'] is List) {
      repliesList = (json['replies'] as List)
          .map((item) {
            // 确保列表中的每个元素都是 Map 类型再进行解析
            if (item is Map<String, dynamic>) {
              return PostReply.fromJson(item);
            }
            return null;
          })
          .whereType<PostReply>() // 过滤掉解析失败的 null 项
          .toList();
    }

    PaginationData paginationData;
    if (json['pagination'] is Map<String, dynamic>) {
      paginationData =
          PaginationData.fromJson(json['pagination'] as Map<String, dynamic>);
    } else {
      // 业务逻辑: 如果后端响应中缺少分页信息，则根据返回的列表长度在前端生成一个默认的分页对象
      int totalItems = repliesList.length;
      int defaultLimit = 10; // 回复列表的默认每页数量
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: totalItems == 0 ? 0 : (totalItems / defaultLimit).ceil(),
      );
    }

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
