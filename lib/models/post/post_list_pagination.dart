// lib/models/post/post_list_pagination.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

@immutable
class PostListPagination {
  // 1. 定义 JSON 字段的 static const String 常量
  static const String jsonKeyPosts = 'posts';
  static const String jsonKeyHistoryFallback = 'history'; // posts 字段的备用名
  static const String jsonKeyPagination = 'pagination';
  static const String jsonKeyTag = 'tag';
  static const String jsonKeyQuery = 'query';

  final List<Post> posts;
  final PaginationData pagination;
  final String? tag;
  final String? query;

  const PostListPagination({
    required this.posts,
    required this.pagination,
    this.tag,
    this.query,
  });

  static PostListPagination empty() {
    return PostListPagination(
      posts: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
      tag: null,
      query: null,
    );
  }

  // 2. 添加一个静态的查验接口函数
  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// PostListPagination 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'posts' 键 (或其备用 'history')，且其值为 [List] 类型。
  /// 3. 必须包含 'pagination' 键，且其值为 [Map] 类型。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 [Map<String, dynamic>]
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查帖子列表字段的存在和类型
    final dynamic postsData =
        json[jsonKeyPosts] ?? json[jsonKeyHistoryFallback];
    if (postsData is! List) {
      return false;
    }

    // 3. 检查分页信息字段的存在和类型
    final dynamic paginationData = json[jsonKeyPagination];
    if (paginationData is! Map) {
      return false;
    }

    // 所有必要条件都满足
    return true;
  }

  factory PostListPagination.fromJson(Map<String, dynamic> json) {
    final postsList = Post.fromListJson(
      json[jsonKeyPosts] ?? json[jsonKeyHistoryFallback], // 使用常量
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: postsList, // 把帖子列表传进去，用于计算兜底分页
    );

    return PostListPagination(
      posts: postsList,
      pagination: paginationData,
      tag: UtilJson.parseNullableStringSafely(json[jsonKeyTag]), // 使用常量
      query: UtilJson.parseNullableStringSafely(json[jsonKeyQuery]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyPosts: posts.toListJson(), // 使用常量
      jsonKeyPagination: pagination.toJson(), // 使用常量
    };
    if (tag != null) {
      data[jsonKeyTag] = tag; // 使用常量
    }
    if (query != null) {
      data[jsonKeyQuery] = query; // 使用常量
    }
    return data;
  }

  PostListPagination copyWith({
    List<Post>? posts,
    PaginationData? pagination,
    String? tag,
    String? query,
    bool clearTag = false,
    bool clearQuery = false,
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
