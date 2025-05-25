// ---------------------------------------------------------------------------
// 文件路径: lib/models/post/post_list_data.dart (示例路径)
// ---------------------------------------------------------------------------

import 'package:suxingchahui/models/post/post.dart'; // 确保 Post 模型的路径正确
import 'package:suxingchahui/models/common/pagination.dart'; // 导入你的 PaginationData 模型

class PostList {
  final List<Post> posts;
  final PaginationData pagination;
  final String? tag; // 可选的标签名称，因为 getPostsPage 和 searchPosts 可能返回

  PostList({
    required this.posts,
    required this.pagination,
    this.tag,
  });

  // 静态工厂方法，用于创建一个空的 PostList 实例
  static PostList empty() {
    return PostList(
      posts: [],
      pagination: PaginationData(
          page: 1, limit: 0, total: 0, pages: 0), // 使用 PaginationData 的空状态
      tag: null,
    );
  }

  factory PostList.fromJson(Map<String, dynamic> json) {
    List<Post> postsList = [];
    // 优先检查 'posts' 键
    if (json['posts'] != null && json['posts'] is List) {
      postsList = (json['posts'] as List)
          .map((postJson) => Post.fromJson(Map<String, dynamic>.from(postJson)))
          .toList();
    }
    // 为 getPostHistoryWithDetails 的 'history' 键做兼容
    else if (json['history'] != null && json['history'] is List) {
      try {
        // 假设 history 列表中的每个 item 也是一个 Post 或可以解析为 Post
        // 注意：如果 history item 的结构与 Post 不同，这里需要更复杂的逻辑或一个专用的 HistoryItem 模型
        postsList = (json['history'] as List)
            .map((itemJson) =>
                Post.fromJson(Map<String, dynamic>.from(itemJson)))
            .toList();
      } catch (e) {
        // 解析失败，postsList 保持为空
      }
    }

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      // 如果API响应中没有 'pagination' 对象，创建一个默认的
      int totalItems = postsList.length;
      int defaultLimit = 20; // 默认每页数量
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: (totalItems == 0)
            ? 0
            : ((defaultLimit <= 0) ? 1 : (totalItems / defaultLimit).ceil()),
      );
    }

    return PostList(
      posts: postsList,
      pagination: paginationData,
      tag: json['tag'] as String?, // 解析可选的 tag
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
    return data;
  }

  PostList copyWith({
    List<Post>? posts,
    PaginationData? pagination,
    String? tag,
    bool clearTag = false,
  }) {
    return PostList(
      posts: posts ?? this.posts,
      pagination: pagination ?? this.pagination,
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }

  @override
  String toString() {
    String result =
        'PostList(posts: ${posts.length} posts, pagination: $pagination';
    if (tag != null) {
      result += ', tag: $tag';
    }
    result += ')';
    return result;
  }
}
