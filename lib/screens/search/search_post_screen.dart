// lib/screens/search/search_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Models
import 'package:suxingchahui/models/post/post.dart';

// Services
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';

// Providers
import 'package:suxingchahui/providers/auth/auth_provider.dart';

// Widgets
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/post_card.dart';
import 'package:suxingchahui/widgets/components/loading/loading_route_observer.dart';
// *** 导入你提供的确认对话框 ***
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

// Utils & Routes
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/routes/app_routes.dart';

class SearchPostScreen extends StatefulWidget {
  @override
  _SearchPostScreenState createState() => _SearchPostScreenState();
}

class _SearchPostScreenState extends State<SearchPostScreen> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Post> _searchResults = [];
  String? _error;
  Timer? _debounceTimer;

  // 分页状态
  int _currentPage = 1;
  final int _limit = 15;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // --- 生命周期方法 ---
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    print("SearchPostScreen initState called");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保只在必要时加载历史记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchHistory.isEmpty && mounted) {
        print("SearchPostScreen didChangeDependencies: Loading search history");
        _loadSearchHistory();
      }
    });
  }

  @override
  void dispose() {
    print("SearchPostScreen dispose called");
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  // --- 生命周期方法结束 ---


  // --- 滚动监听 ---
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages &&
        _searchController.text.isNotEmpty) {
      print("SearchPostScreen: Scroll listener triggered load more");
      _loadMoreResults();
    }
  }
  // --- 滚动监听结束 ---


  // --- 搜索历史管理 ---
  Future<void> _loadSearchHistory() async {
    print("SearchPostScreen: Attempting to load search history...");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || !mounted) {
      print("SearchPostScreen: Not logged in or not mounted, skipping history load.");
      return;
    }
    // 这里可以加个加载状态，如果需要的话
    try {
      final history = await _userService.loadLocalSearchHistory();
      if (!mounted) return;
      print("SearchPostScreen: Search history loaded: $history");
      setState(() { _searchHistory = history; _error = null; });
    } catch (e) {
      print("SearchPostScreen: Error loading search history: $e");
      if (!mounted) return;
      setState(() { _error = '加载搜索历史失败: $e'; });
    }
  }

  Future<void> _saveSearchHistory() async {
    print("SearchPostScreen: Saving search history: $_searchHistory");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || !mounted) return;
    try {
      await _userService.saveLocalSearchHistory(_searchHistory);
      print("SearchPostScreen: Search history saved successfully.");
    } catch (e) { print("SearchPostScreen: Error saving search history: $e"); }
  }

  void _addToHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || !mounted) return;
    print("SearchPostScreen: Adding '$trimmedQuery' to history.");
    setState(() {
      _searchHistory.remove(trimmedQuery);
      _searchHistory.insert(0, trimmedQuery);
      if (_searchHistory.length > 10) { _searchHistory.removeLast(); }
    });
    _saveSearchHistory();
  }

  void _removeFromHistory(String query) {
    if (!mounted) return;
    print("SearchPostScreen: Removing '$query' from history.");
    setState(() { _searchHistory.remove(query); });
    _saveSearchHistory();
  }

  void _clearHistory() {
    if (!mounted) return;
    print("SearchPostScreen: Clearing search history.");
    setState(() { _searchHistory.clear(); });
    _saveSearchHistory();
  }
  // --- 搜索历史结束 ---


  // --- 核心搜索逻辑 ---
  Future<void> _performSearch(String query, {bool isNewSearch = true}) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      final trimmedQuery = query.trim();
      print("SearchPostScreen: Performing search for '$trimmedQuery', isNewSearch: $isNewSearch");

      if (trimmedQuery.isEmpty) {
        if (!mounted) return;
        print("SearchPostScreen: Query is empty, clearing results.");
        setState(() {
          _searchResults.clear(); _error = null; _currentPage = 1; _totalPages = 1;
        });
        return;
      }

      if (isNewSearch) {
        if (!mounted) return;
        print("SearchPostScreen: New search, resetting state.");
        setState(() {
          _searchResults.clear(); _currentPage = 1; _totalPages = 1; _error = null; _isLoadingMore = false;
        });
      }

      if (!isNewSearch && _isLoadingMore) {
        print("SearchPostScreen: Already loading more, skipping duplicate request.");
        return; // 防止重复触发加载更多
      }

      LoadingRouteObserver? loadingObserver = _getLoadingObserver();
      if (isNewSearch) { loadingObserver?.showLoading(); }
      else { if (mounted) setState(() => _isLoadingMore = true); }

      try {
        print("SearchPostScreen: Calling ForumService.searchPosts...");
        final resultsData = await _forumService.searchPosts(
          keyword: trimmedQuery, page: _currentPage, limit: _limit,
        );
        if (!mounted) return; // 异步操作后检查 mounted

        final List<Post> newPosts = resultsData['posts'];
        final pagination = resultsData['pagination'];
        final int serverTotalPages = pagination['pages'] ?? 1;
        print("SearchPostScreen: Search results received. Posts: ${newPosts.length}, Total Pages: $serverTotalPages");

        setState(() {
          if (isNewSearch) { _searchResults = newPosts; }
          else { _searchResults.addAll(newPosts); }
          _totalPages = serverTotalPages;
          _error = null;
        });

        if (isNewSearch) { _addToHistory(trimmedQuery); }

      } catch (e, s) {
        print("SearchPostScreen: Search failed: $e\n$s");
        if (!mounted) return;
        setState(() { _error = '搜索失败：$e'; if (isNewSearch) { _searchResults.clear(); } });
      } finally {
        if (mounted) {
          if (isNewSearch) { loadingObserver?.hideLoading(); }
          // 确保 isLoadingMore 状态被重置
          setState(() => _isLoadingMore = false);
          print("SearchPostScreen: Search finished, isLoadingMore set to false.");
        }
      }
    });
  }
  // --- 搜索逻辑结束 ---


  // --- 加载更多逻辑 ---
  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || _currentPage >= _totalPages) {
      print("SearchPostScreen: Load more skipped. isLoadingMore: $_isLoadingMore, currentPage: $_currentPage, totalPages: $_totalPages");
      return;
    }

    setState(() {
      // _isLoadingMore = true; // 在 performSearch 开始时设置
      _currentPage++;
    });
    print("SearchPostScreen: Loading page $_currentPage of $_totalPages");
    await _performSearch(_searchController.text.trim(), isNewSearch: false);
  }
  // --- 加载更多结束 ---


  // --- 获取 LoadingObserver ---
  LoadingRouteObserver? _getLoadingObserver() {
    LoadingRouteObserver? loadingObserver;
    try {
      loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;
    } catch (e) {
      print("SearchPostScreen: LoadingRouteObserver not found: $e");
    }
    return loadingObserver;
  }
  // --- 获取 LoadingObserver 结束 ---


  // ========================================
  // == PostCard 回调处理方法 (从 build 中抽出) ==
  // ========================================

  /// 处理删除帖子的操作 (由 PostCard 的 onDeleteAction 调用)
  Future<void> _handleDeletePostAction(String postId) async {
    print("SearchPostScreen: Handling delete action for post $postId");
    if (!mounted) return;

    LoadingRouteObserver? loadingObserver = _getLoadingObserver(); // 先获取 observer

    try {
      // *** 使用 CustomConfirmDialog.show 静态方法 ***
      // 它返回 Future<void>，确认时正常完成，取消或出错时可能抛异常
      await CustomConfirmDialog.show(
        context: context,
        title: '确认删除',
        message: '确定要删除这篇帖子吗？此操作不可恢复。',
        confirmButtonText: '删除',
        confirmButtonColor: Colors.red, // 删除用红色按钮
        iconData: Icons.delete_forever_outlined, // 删除图标
        iconColor: Colors.red,
        // *** onConfirm 是一个异步函数 ***
        onConfirm: () async {
          print("SearchPostScreen: Delete confirmed for post $postId. Calling service...");
          // 在确认回调内部执行删除操作
          if (mounted) loadingObserver?.showLoading(); // 显示加载
          try {
            await _forumService.deletePost(postId);
            if (!mounted) return;
            print("SearchPostScreen: Post $postId deleted successfully from service.");
            // 从当前搜索结果中移除
            setState(() {
              _searchResults.removeWhere((p) => p.id == postId);
            });
            AppSnackBar.showSuccess(context, '帖子已删除');
          } catch (e) {
            print("SearchPostScreen: Error deleting post $postId: $e");
            if (mounted) AppSnackBar.showError(context, '删除失败: $e');
            // 如果 service 抛出异常，CustomConfirmDialog.show 的 future 会带错误完成
            rethrow; // 将异常继续抛出，以便外部 catch 块处理
          } finally {
            if (mounted) loadingObserver?.hideLoading(); // 隐藏加载
          }
        },
      );
      // 如果 CustomConfirmDialog.show 正常完成（意味着 onConfirm 也成功了）
      print("SearchPostScreen: Delete process completed successfully for post $postId.");

    } catch (e) {
      // 捕获 onConfirm 内部抛出的异常，或者 CustomConfirmDialog.show 本身的异常
      print("SearchPostScreen: Error during delete confirmation/action for post $postId: $e");
      // 可以在这里显示一个通用的错误提示，虽然 onConfirm 内部已经显示了
      // AppSnackBar.showError(context, '操作失败');
      // 确保加载状态被隐藏
      if (mounted) loadingObserver?.hideLoading();
    }
  }

  /// 处理编辑帖子的操作 (由 PostCard 的 onEditAction 调用)
  void _handleEditPostAction(Post postToEdit) {
    print("SearchPostScreen: Handling edit action for post ${postToEdit.id}");
    if (!mounted) return;

    NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost, // *** 使用路由常量 ***
      arguments: postToEdit.id, // *** 传递 postId ***
    ).then((updated) {
      if (updated == true && mounted) {
        print("SearchPostScreen: Returned from edit post with update signal. Refreshing search...");
        _performSearch(_searchController.text.trim(), isNewSearch: true); // 强制刷新
      } else {
        print("SearchPostScreen: Returned from edit post without update signal.");
      }
    });
  }

  // --- 新增：处理来自 PostCard 的锁定/解锁请求 ---
  Future<void> _handleToggleLockAction(String postId) async {
    print("SearchPostScreen: Handling toggle lock action for $postId");
    if (!mounted) return;

    LoadingRouteObserver? loadingObserver = _getLoadingObserver();
    loadingObserver?.showLoading(); // 显示加载指示

    try {
      await _forumService.togglePostLock(postId);
      if (!mounted) return;

      AppSnackBar.showSuccess(context, '帖子状态已切换');

      // --- 更新搜索结果列表中的帖子状态 ---
      setState(() {
        final index = _searchResults.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final oldPost = _searchResults[index];
          final newStatus = oldPost.status == PostStatus.locked
              ? PostStatus.active
              : PostStatus.locked;
          _searchResults[index] = oldPost.copyWith(status: newStatus);
          print("SearchPostScreen: Updated post $postId status in search results.");
        } else {
          // 如果没找到，可能需要重新搜索？但通常此时帖子还在列表里
          print("SearchPostScreen: Warning - Post $postId not found in search results after toggle.");
          // 可以选择刷新：_performSearch(_searchController.text.trim(), isNewSearch: true);
        }
      });

    } catch (e) {
      if (!mounted) return;
      print("SearchPostScreen: Error toggling lock for post $postId: $e");
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      if (mounted) loadingObserver?.hideLoading();
    }
  }

  // ========================================
  // == 回调处理方法结束 ==
  // ========================================


  // --- 构建 UI ---
  @override
  Widget build(BuildContext context) {
    print("SearchPostScreen: Build method called.");
    return Scaffold(
      // --- AppBar ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ Color(0xFF6AB7F0), Color(0xFF4E9DE3), ],
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索帖子...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          onChanged:(query) => _performSearch(query, isNewSearch: true), // 每次输入都触发新搜索
          onSubmitted: (query) {
            print("SearchPostScreen: Submitted search for '$query'");
            _performSearch(query.trim(), isNewSearch: true);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                print("SearchPostScreen: Clearing search input.");
                _searchController.clear();
                _performSearch('', isNewSearch: true); // 清空时也触发搜索（显示历史）
              },
            ),
        ],
      ),
      // --- Body ---
      body: _buildBody(),
    );
  }

  // --- _buildBody ---
  Widget _buildBody() {
    //print("SearchPostScreen: Building body. Error: $_error, Query: ${_searchController.text}");
    // 错误优先显示
    if (_error != null && _searchController.text.isNotEmpty) {
      //print("SearchPostScreen: Displaying search error widget.");
      return InlineErrorWidget( errorMessage: _error!, onRetry: () { setState(() { _error = null; }); _performSearch(_searchController.text.trim(), isNewSearch: true); }, );
    } else if (_error != null && _searchController.text.isEmpty) {
      //print("SearchPostScreen: Displaying history error widget.");
      return InlineErrorWidget( errorMessage: _error!, onRetry: () { setState(() { _error = null; }); _loadSearchHistory(); }, );
    }
    // 搜索框为空，显示历史
    if (_searchController.text.isEmpty) {
      //print("SearchPostScreen: Displaying search history.");
      return _buildSearchHistory();
    }
    // 显示搜索结果
    //print("SearchPostScreen: Displaying search results.");
    return _buildSearchResults();
  }

  // --- _buildSearchHistory ---
  Widget _buildSearchHistory() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      //print("SearchPostScreen: Displaying login prompt for history.");
      return LoginPromptWidget();
    }
    if (_searchHistory.isEmpty) {
      //rint("SearchPostScreen: Displaying empty history state.");
      return EmptyStateWidget( message: '暂无搜索历史', iconData: Icons.history, );
    }
    //print("SearchPostScreen: Building history list with ${_searchHistory.length} items.");
    // --- 完整历史列表 UI ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('搜索历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _clearHistory,
                child: Text('清空'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: Icon(Icons.history, color: Colors.grey[600]),
                title: Text(query),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                  onPressed: () => _removeFromHistory(query),
                ),
                onTap: () {
                  //print("SearchPostScreen: Tapped history item '$query'.");
                  _searchController.text = query;
                  _searchController.selection = TextSelection.fromPosition( TextPosition(offset: _searchController.text.length));
                  _performSearch(query, isNewSearch: true);
                },
              );
            },
          ),
        ),
      ],
    );
    // --- 历史列表 UI 结束 ---
  }

  // --- 构建搜索结果 UI (使用 PostCard 和抽出的回调) ---
  Widget _buildSearchResults() {
    //print("SearchPostScreen: Building search results. Count: ${_searchResults.length}, isLoadingMore: $_isLoadingMore, Error: $_error");
    // 空状态（非加载中且无错误）
    if (_searchResults.isEmpty && !_isLoadingMore && _error == null) {
      //print("SearchPostScreen: Displaying empty search results state.");
      return EmptyStateWidget( message: '未找到相关帖子', iconData: Icons.search_off, );
    }
    // 结果列表 + 加载更多指示器
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index == _searchResults.length && _isLoadingMore) {
          //print("SearchPostScreen: Displaying loading more indicator.");
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // 帖子卡片
        if (index < _searchResults.length) {
          final post = _searchResults[index];
          return PostCard(
            key: ValueKey(post.id),
            post: post,
            // --- 传递所有需要的回调 ---
            onDeleteAction: _handleDeletePostAction,
            onEditAction: _handleEditPostAction,
            onToggleLockAction: _handleToggleLockAction, // <-- 传递新回调
          );
        }
        // 安全返回
        return Container();
      },
    );
  }
// --- 构建 UI 结束 ---

} // End of _SearchPostScreenState