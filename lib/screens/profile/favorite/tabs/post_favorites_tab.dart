// lib/screens/profile/tabs/post_favorites_tab.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../models/post/post.dart';
import '../../../../services/main/forum/forum_service.dart';
import '../../../../widgets/components/screen/forum/card/post_grid_view.dart';
import '../../../../widgets/ui/common/loading_widget.dart';
import '../../../../widgets/ui/common/error_widget.dart';
import '../../../../utils/device/device_utils.dart';

class PostFavoritesTab extends StatefulWidget {
  // 静态刷新方法，供主页面调用
  static void refreshPostData() {
    // 这里使用一个全局键来访问状态
    _postTabKey.currentState?.refreshPosts();
  }

  static final GlobalKey<_PostFavoritesTabState> _postTabKey = GlobalKey<_PostFavoritesTabState>();

  PostFavoritesTab() : super(key: _postTabKey);

  @override
  _PostFavoritesTabState createState() => _PostFavoritesTabState();
}

class _PostFavoritesTabState extends State<PostFavoritesTab> with AutomaticKeepAliveClientMixin {
  final ForumService _forumService = ForumService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _favoritePosts = [];
  String? _error;
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1; // 添加总页数状态
  final int _limit = 10; // 假设每页加载10条，应与 Service 和后端一致
  bool _hasMoreData = true; // 这个可以根据 totalPages 计算


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadFavoritePosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMoreData) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadFavoritePosts({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _error = null;
        _currentPage = 1; // 刷新时重置页码
        _favoritePosts = []; // 刷新时清空列表
      }
    });

    try {
      // --- 调用返回 Map 的 Service 方法 ---
      final result = await _forumService.getUserFavoritePostsPage(
          page: _currentPage, limit: _limit);

      // --- 从 Map 中提取数据 ---
      final List<Post> fetchedPosts = result['posts'] as List<Post>? ?? [];
      final Map<String, dynamic> pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      final int serverPage = pagination['page'] ?? _currentPage;
      final int serverTotalPages = pagination['pages'] ?? 1;

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _favoritePosts = fetchedPosts; // 刷新：直接替换
          } else {
            _favoritePosts.addAll(fetchedPosts); // 加载更多：追加
          }
          _currentPage = serverPage;
          _totalPages = serverTotalPages;
          _hasMoreData = _currentPage < _totalPages; // 根据返回的总页数判断
          _isLoading = false;
          _error = null; // 加载成功清除错误
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载收藏失败: $e';
          // 刷新失败时保持列表为空，加载更多失败时列表保持不变
          if (isRefresh) {
            _favoritePosts = [];
            _hasMoreData = false; // 无法加载，认为没有更多数据
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    // 直接调用 _loadFavoritePosts，它内部会处理页码增加和追加逻辑
    // 但需要确保它不是作为 isRefresh 调用
    // 并且只在还有更多数据时调用
    if (_hasMoreData && !_isLoading) {
      // 页码在 _loadFavoritePosts 内部根据 _currentPage 状态获取
      // 但是我们需要先递增页码的概念
      // 所以这里稍微调整下逻辑，直接在 loadFavoritePosts 里处理追加
      setState(() {
        _currentPage++; // 准备加载下一页
      });
      await _loadFavoritePosts(isRefresh: false); // 调用加载，标记为非刷新
    }
  }

  Future<void> refreshPosts() async {
    return _loadFavoritePosts();
  }
  // --- 新增：处理 PostCard 的删除（取消收藏）请求 ---
  Future<void> _handleUnfavoritePost(String postId) async {
    print("PostFavoritesTab: Handling unfavorite request for $postId");
    // 不显示确认对话框，直接取消收藏
    try {
      // 调用 Service 取消收藏 (toggle 会自动处理状态)
      final success = await _forumService.togglePostFavorite(postId);

      if (success && mounted) {
        AppSnackBar.showSuccess(context, '已取消收藏');
        // 优化：从列表中移除，而不是完全刷新
        setState(() {
          _favoritePosts.removeWhere((post) => post.id.toString() == postId);
          // 如果当前页空了，并且还有上一页，可以考虑返回上一页？或者保持当前页等下次加载。
          // 简单起见，只移除。或者直接调用 refreshPosts()。
        });
        // 可选：调用 refreshPosts() 保证数据完全同步，但会重新加载整页
        // await refreshPosts();
      } else if (!success && mounted) {
        AppSnackBar.showWarning(context, '取消收藏状态未改变');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '取消收藏失败: $e');
      }
    }
  }

  // --- 新增：处理 PostCard 的编辑请求 ---
  void _handleEditPostRequest(Post post) {
    // 在收藏夹里编辑帖子通常是不允许的，应该引导用户去原帖编辑
    print("PostFavoritesTab: Edit requested for ${post.id}, showing info message.");
    AppSnackBar.showInfo(context, '请在帖子详情或我的帖子中进行编辑');
    // 或者可以考虑跳转到帖子详情页
    // NavigationUtils.pushNamed(context, AppRoutes.postDetail, arguments: post.id);
  }

  // --- 新增：处理来自 PostCard 的锁定/解锁请求 ---
  Future<void> _handleToggleLockAction(String postId) async {
    print("PostFavoritesTab: Handling toggle lock action for $postId");
    if (!mounted) return;

    // 可选：显示加载状态
    // setState(() => _isLoading = true);

    try {
      await _forumService.togglePostLock(postId);
      if (!mounted) return;

      AppSnackBar.showSuccess(context, '帖子状态已切换');

      // --- 更新收藏列表中的帖子状态 ---
      setState(() {
        final index = _favoritePosts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final oldPost = _favoritePosts[index];
          final newStatus = oldPost.status == PostStatus.locked
              ? PostStatus.active
              : PostStatus.locked;
          _favoritePosts[index] = oldPost.copyWith(status: newStatus);
          print("PostFavoritesTab: Updated post $postId status in favorites list.");
          // 如果帖子被锁定，它理论上不应该出现在普通用户的收藏夹了
          // 但管理员可能看到。如果非管理员，可以考虑直接移除
          // if (newStatus == PostStatus.locked && !Provider.of<AuthProvider>(context, listen: false).isAdmin) {
          //   _favoritePosts.removeAt(index);
          //   print("PostFavoritesTab: Removed locked post $postId from non-admin favorites.");
          // }
        } else {
          print("PostFavoritesTab: Warning - Post $postId not found in favorites list after toggle.");
          // 可以选择刷新: refreshPosts();
        }
      });

    } catch (e) {
      if (!mounted) return;
      print("PostFavoritesTab: Error toggling lock for post $postId: $e");
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      // 可选：结束加载状态
      // if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isDesktop = DeviceUtils.isDesktop;

    // 处理错误状态
    if (_error != null) {
      return InlineErrorWidget(
        errorMessage: _error!,
        onRetry: _loadFavoritePosts,
      );
    }

    // 处理初始加载状态
    if (_isLoading && _favoritePosts.isEmpty) {
      return LoadingWidget.fullScreen(message: '加载收藏帖子中...');
    }

    // 处理空数据状态
    if (_favoritePosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无收藏的帖子',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: refreshPosts,
              child: Text('刷新'),
            ),
          ],
        ),
      );
    }

    // 显示帖子列表/网格
    return RefreshIndicator(
      onRefresh: refreshPosts, // 下拉刷新回调
      child: PostGridView(
        posts: _favoritePosts,
        scrollController: _scrollController,
        isLoading: _isLoading && _hasMoreData, // 只有加载更多时才传递 isLoading
        hasMoreData: _hasMoreData,
        // onLoadMore: _loadMorePosts, // PostGridView 不直接使用 onLoadMore 回调
        isDesktopLayout: isDesktop, // 根据设备类型判断布局
        // --- 传递实现好的回调函数 ---
        onDeleteAction: _handleUnfavoritePost,
        onEditAction: _handleEditPostRequest,
        onToggleLockAction: _handleToggleLockAction,
      ),
    );
  }
  @override
  bool get wantKeepAlive => true;
}