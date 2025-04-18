// lib/blocs/my_posts/my_posts_state.dart
import '../../../../models/post/post.dart'; // 确保导入 Post 模型

// 使用 Equatable 方便状态比较，避免不必要的 UI 重建
import 'package:equatable/equatable.dart';

class MyPostsState extends Equatable {
  final List<Post> posts;
  final bool isLoading; // 标记是否正在加载或刷新
  final String? error;  // 错误信息
  final String? userId; // 当前用户的 ID

  const MyPostsState({
    this.posts = const [], // 默认空列表
    this.isLoading = false, // 初始非加载状态
    this.error,
    this.userId,
  });

  // 使用 copyWith 来创建新状态，保证不可变性
  MyPostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
    String? userId,
    bool clearError = false, // 添加一个标志来显式清除错误
  }) {
    return MyPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      // 如果 clearError 为 true，则将 error 设为 null，否则使用传入的 error 或保持旧 error
      error: clearError ? null : (error ?? this.error),
      userId: userId ?? this.userId,
    );
  }

  // Equatable 需要重写 props
  @override
  List<Object?> get props => [posts, isLoading, error, userId];

  // Equatable 需要重写 stringify (可选, 方便调试)
  @override
  bool get stringify => true;
}