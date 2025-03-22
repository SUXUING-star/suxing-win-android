// lib/blocs/my_posts/my_posts_event.dart
abstract class MyPostsEvent {}

class LoadMyPostsEvent extends MyPostsEvent {}

class DeletePostEvent extends MyPostsEvent {
  final String postId;
  DeletePostEvent(this.postId);
}

class RefreshMyPostsEvent extends MyPostsEvent {}