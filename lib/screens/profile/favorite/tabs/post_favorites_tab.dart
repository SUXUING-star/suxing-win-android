// lib/screens/profile/tabs/post_favorites_tab.dart
import 'package:flutter/material.dart';
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
  bool _hasMoreData = true;

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

  Future<void> _loadFavoritePosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _forumService.getUserFavoritePosts(page: 1);

      if (mounted) {
        setState(() {
          _favoritePosts = posts;
          _currentPage = 1;
          _hasMoreData = posts.length >= 10; // 假设每页10条
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _favoritePosts = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final morePosts = await _forumService.getUserFavoritePosts(page: nextPage);

      if (mounted) {
        setState(() {
          if (morePosts.isNotEmpty) {
            _favoritePosts.addAll(morePosts);
            _currentPage = nextPage;
            _hasMoreData = morePosts.length >= 10;
          } else {
            _hasMoreData = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载更多失败: $e')),
        );
      }
    }
  }

  Future<void> refreshPosts() async {
    return _loadFavoritePosts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isDesktop = DeviceUtils.isDesktop;

    // 处理错误状态
    if (_error != null) {
      return CustomErrorWidget(
        errorMessage: _error!,
        onRetry: _loadFavoritePosts,
        title: '加载错误',
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
      onRefresh: refreshPosts,
      child: PostGridView(
        posts: _favoritePosts,
        scrollController: _scrollController,
        isLoading: _isLoading,
        hasMoreData: _hasMoreData,
        onLoadMore: _loadMorePosts,
        isDesktopLayout: isDesktop,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}