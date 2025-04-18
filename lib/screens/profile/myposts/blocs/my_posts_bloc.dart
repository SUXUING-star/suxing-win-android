// lib/screens/profile/my_posts/blocs/my_posts_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suxingchahui/models/post/post.dart'; // 导入 Post 模型
import '../../../../services/main/forum/forum_service.dart';
import '../../../../services/main/user/user_service.dart';
import 'my_posts_event.dart';
import 'my_posts_state.dart';

class MyPostsBloc extends Bloc<MyPostsEvent, MyPostsState> {
  final ForumService _forumService;
  final UserService _userService;

  MyPostsBloc(this._forumService, this._userService)
      : super(const MyPostsState()) { // 使用 const 构造函数初始化状态
    // 注册事件处理器
    on<LoadMyPostsEvent>(_onLoadMyPosts);
    on<RefreshMyPostsEvent>(_onRefreshMyPosts); // 刷新事件
    on<DeletePostEvent>(_onDeletePost);
    on<TogglePostLockEvent>(_onTogglePostLock); // 注册新事件
    on<ClearPostsErrorEvent>(_onClearError); // 可选：注册清除错误事件
  }

  // 处理加载或刷新事件
  Future<void> _commonLoadOrRefresh(Emitter<MyPostsState> emit) async {
    // 如果不是首次加载，且已经在加载中，则跳过 (防止重复刷新)
    if (state.isLoading && state.userId != null) return;

    emit(state.copyWith(isLoading: true, clearError: true)); // 开始加载，清除旧错误
    try {
      final userId = await _userService.currentUserId;
      if (userId == null || userId.isEmpty) {
        // 如果未登录，发出包含错误的状态
        emit(state.copyWith(isLoading: false, posts: [], userId: null, error: '请先登录'));
        return;
      }

      // 假设 getUserPosts().first 获取所有帖子
      // 注意: 如果帖子非常多，这里性能会有问题，需要改成 getUserPostsPage
      final posts = await _forumService.getUserPosts(userId).first;
      emit(state.copyWith(isLoading: false, posts: posts, userId: userId));
      print("MyPostsBloc: Loaded/Refreshed posts for user $userId. Count: ${posts.length}");

    } catch (e) {
      print("MyPostsBloc: Error loading/refreshing posts: $e");
      emit(state.copyWith(isLoading: false, error: '加载我的帖子失败: $e'));
    }
  }

  // 处理首次加载事件
  Future<void> _onLoadMyPosts(LoadMyPostsEvent event, Emitter<MyPostsState> emit) async {
    // 首次加载时，无论如何都要执行
    emit(state.copyWith(isLoading: true, clearError: true)); // 强制开始加载
    await _commonLoadOrRefresh(emit);
  }

  // 处理刷新事件
  Future<void> _onRefreshMyPosts(RefreshMyPostsEvent event, Emitter<MyPostsState> emit) async {
    // 刷新时，调用通用加载逻辑
    await _commonLoadOrRefresh(emit);
  }


  // 处理删除帖子事件 (优化：直接更新状态)
  Future<void> _onDeletePost(DeletePostEvent event, Emitter<MyPostsState> emit) async {
    // 可选：发出一个短暂的处理中状态，或者直接尝试删除
    // emit(state.copyWith(isLoading: true)); // 不建议用全局 isLoading

    // 先保存当前帖子列表，以便出错时恢复
    final List<Post> currentPosts = List.from(state.posts);

    try {
      // 尝试从当前状态中移除帖子，给用户即时反馈
      final updatedPosts = state.posts.where((post) => post.id != event.postId).toList();
      emit(state.copyWith(posts: updatedPosts, clearError: true));
      print("MyPostsBloc: Optimistically removed post ${event.postId} from state.");

      // 调用 Service 执行实际删除
      await _forumService.deletePost(event.postId);
      print("MyPostsBloc: Successfully deleted post ${event.postId} via service.");
      // 删除成功，状态已经更新，无需其他操作

    } catch (e) {
      print("MyPostsBloc: Error deleting post ${event.postId}: $e");
      // 删除失败，恢复之前的帖子列表，并发出错误状态
      emit(state.copyWith(posts: currentPosts, error: '删除帖子失败: $e'));
    } finally {
      // 确保 isLoading (如果使用的话) 被重置
      // emit(state.copyWith(isLoading: false));
    }
  }

  // --- 新增：处理切换锁定状态事件 ---
  Future<void> _onTogglePostLock(TogglePostLockEvent event, Emitter<MyPostsState> emit) async {
    // 找到需要更新的帖子在当前状态列表中的索引
    final postIndex = state.posts.indexWhere((p) => p.id == event.postId);

    if (postIndex == -1) {
      // 如果帖子不在当前列表中（异常情况），记录警告并可能触发刷新
      print("MyPostsBloc: Warning - Post ${event.postId} not found in state for lock toggle.");
      // 可以选择忽略，或者触发一次刷新来同步状态
      // add(RefreshMyPostsEvent());
      return;
    }

    final Post postToUpdate = state.posts[postIndex];
    // 先保存当前状态，以便出错时回滚
    final MyPostsState previousState = state;

    // 乐观更新 UI：立即切换状态并发出新状态
    final PostStatus newStatus = postToUpdate.status == PostStatus.locked
        ? PostStatus.active
        : PostStatus.locked;
    final Post updatedPostOptimistic = postToUpdate.copyWith(status: newStatus);

    final List<Post> updatedListOptimistic = List.from(state.posts);
    updatedListOptimistic[postIndex] = updatedPostOptimistic;
    emit(state.copyWith(posts: updatedListOptimistic, clearError: true));
    print("MyPostsBloc: Optimistically toggled lock for post ${event.postId} in state.");


    try {
      // 调用 Service 执行实际的切换操作
      await _forumService.togglePostLock(event.postId);
      print("MyPostsBloc: Successfully toggled lock for post ${event.postId} via service.");
      // 成功，状态已经更新，无需操作

    } catch (e) {
      print("MyPostsBloc: Error toggling lock for post ${event.postId}: $e");
      // 操作失败，回滚到之前的状态，并发出错误
      emit(previousState.copyWith(error: '切换帖子状态失败: $e'));
    }
  }

  // 可选：处理清除错误事件
  Future<void> _onClearError(ClearPostsErrorEvent event, Emitter<MyPostsState> emit) async {
    emit(state.copyWith(clearError: true));
  }
}