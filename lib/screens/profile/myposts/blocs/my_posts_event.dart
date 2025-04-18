// lib/blocs/my_posts/my_posts_event.dart
abstract class MyPostsEvent {}

class LoadMyPostsEvent extends MyPostsEvent {}

class DeletePostEvent extends MyPostsEvent {
  final String postId;
  DeletePostEvent(this.postId);
}

// --- 新增：切换帖子锁定状态事件 ---
class TogglePostLockEvent extends MyPostsEvent {
  final String postId;
  TogglePostLockEvent(this.postId);
}

class RefreshMyPostsEvent extends MyPostsEvent {}

class ClearPostsErrorEvent extends MyPostsEvent {}