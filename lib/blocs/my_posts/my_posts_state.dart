// lib/blocs/my_posts/my_posts_state.dart
import '../../models/post/post.dart';

class MyPostsState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  final String? userId;

  MyPostsState({
    required this.posts,
    required this.isLoading,
    this.error,
    this.userId,
  });

  MyPostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
    String? userId,
  }) {
    return MyPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
    );
  }
}