// lib/models/post/post_list_pagination.dart

import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';

class PostListPagination {
  final List<Post> posts;
  final PaginationData pagination;
  final String? tag; // 已有
  final String? query; // 新增：用于搜索结果的查询关键词

  PostListPagination({
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
    List<Post> postsList = [];
    if (json['posts'] != null && json['posts'] is List) {
      postsList = (json['posts'] as List)
          .map((postJson) => Post.fromJson(Map<String, dynamic>.from(postJson)))
          .toList();
    } else if (json['history'] != null && json['history'] is List) {
      try {
        postsList = (json['history'] as List)
            .map((itemJson) =>
                Post.fromJson(Map<String, dynamic>.from(itemJson)))
            .toList();
      } catch (_) {
        // 解析失败，postsList 保持为空
      }
    }

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      int totalItems = postsList.length;
      int defaultLimit =
          PostService.postListLimit; // 使用 PostService 中的常量或一个合理的默认值
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: (totalItems == 0)
            ? 0
            : ((defaultLimit <= 0) ? 1 : (totalItems / defaultLimit).ceil()),
      );
    }

    return PostListPagination(
      posts: postsList,
      pagination: paginationData,
      tag: json['tag'] as String?,
      query: json['query'] as String?, // 解析可选的 query
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
