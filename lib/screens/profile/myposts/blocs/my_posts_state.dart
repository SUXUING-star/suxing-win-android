// lib/blocs/my_posts/my_posts_state.dart
import '../../../../models/post/post.dart';

class MyPostsState {
  final List<Post> posts;
  final bool hasMoreData; // 添加 hasMoreData
  final bool isLoading; // 添加一个通用的 isLoading 标记? 或者用 status 判断
  final String? error;
  final String? userId;

  MyPostsState({
    required this.posts,
    this.hasMoreData = true, // 初始假设有更多数据
    this.isLoading = false, // 初始非加载状态
    this.error,
    this.userId,
  });

  MyPostsState copyWith({
    List<Post>? posts,
    bool? hasMoreData,
    bool? isLoading,
    String? error,
    String? userId,
  }) {
    return MyPostsState(
      posts: posts ?? this.posts,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
    );
  }
}