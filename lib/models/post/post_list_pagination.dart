// lib/models/post/post_list_pagination.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/util_json.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';

@immutable
class PostListPagination {
  final List<Post> posts;
  final PaginationData pagination;
  final String? tag; // 已有
  final String? query; // 新增：用于搜索结果的查询关键词

  const PostListPagination({
    required this.posts,
    required this.pagination,
    this.tag,
    this.query, // 构造函数中设为可选
  });

  static PostListPagination empty() {
    return PostListPagination(
      posts: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
      tag: null,
      query: null, // 空状态时 query 也为 null
    );
  }

  factory PostListPagination.fromJson(Map<String, dynamic> json) {
    final postsList = UtilJson.parseObjectList<Post>(
      json['posts'] ?? json['history'], // 传入原始的 list 数据
      (itemJson) => Post.fromJson(itemJson), // 告诉它怎么把一个 item 的 json 转成 Game 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: postsList, // 把游戏列表传进去，用于计算兜底分页
    );

    return PostListPagination(
      posts: postsList,
      pagination: paginationData,
      tag: UtilJson.parseNullableStringSafely(json['tag']),
      query: UtilJson.parseNullableStringSafely(json['query']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'posts': posts.map((post) => post.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
    if (tag != null) {
      data['tag'] = tag;
    }
    if (query != null) {
      // 如果 query 不为 null，则加入到 JSON
      data['query'] = query;
    }
    return data;
  }

  PostListPagination copyWith({
    List<Post>? posts,
    PaginationData? pagination,
    String? tag,
    String? query, // copyWith 中添加 query
    bool clearTag = false,
    bool clearQuery = false, // 用于显式清除 query
  }) {
    return PostListPagination(
      posts: posts ?? this.posts,
      pagination: pagination ?? this.pagination,
      tag: clearTag ? null : (tag ?? this.tag),
      query: clearQuery ? null : (query ?? this.query),
    );
  }

  @override
  String toString() {
    String result =
        'PostList(posts: ${posts.length} posts, pagination: $pagination';
    if (tag != null) result += ', tag: $tag';
    if (query != null) result += ', query: "$query"';
    result += ')';
    return result;
  }
}
