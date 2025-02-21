// lib/blocs/my_posts/my_posts_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/main/forum/forum_service.dart';
import '../../services/main/user/user_service.dart';
import 'my_posts_event.dart';
import 'my_posts_state.dart';

class MyPostsBloc extends Bloc<MyPostsEvent, MyPostsState> {
  final ForumService _forumService;
  final UserService _userService;

  MyPostsBloc(this._forumService, this._userService)
      : super(MyPostsState(posts: [], isLoading: false)) {
    on<LoadMyPostsEvent>(_onLoadMyPosts);
    on<DeletePostEvent>(_onDeletePost);
    on<RefreshMyPostsEvent>(_onRefreshMyPosts);
  }

  Future<void> _onLoadMyPosts(
      LoadMyPostsEvent event, Emitter<MyPostsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final userId = await _userService.currentUserId;
      if (userId == null) {
        emit(state.copyWith(
            isLoading: false, error: '请先登录', posts: [], userId: null));
        return;
      }

      final posts = await _forumService.getUserPosts(userId).first;
      emit(state.copyWith(isLoading: false, posts: posts, userId: userId));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: '加载失败：$e', posts: [], userId: null));
    }
  }

  Future<void> _onDeletePost(
      DeletePostEvent event, Emitter<MyPostsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _forumService.deletePost(event.postId);
      add(RefreshMyPostsEvent());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '删除失败：$e'));
    }
  }

  Future<void> _onRefreshMyPosts(
      RefreshMyPostsEvent event, Emitter<MyPostsState> emit) async {
    if (state.userId != null) {
      emit(state.copyWith(isLoading: true, error: null));
      try {
        final posts = await _forumService.getUserPosts(state.userId!).first;
        emit(state.copyWith(isLoading: false, posts: posts));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: '刷新失败：$e'));
      }
    }
  }
}