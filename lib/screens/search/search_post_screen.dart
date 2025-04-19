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
// *** 导入 LoadingWidget ***
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/post_card.dart';
// import 'package:suxingchahui/widgets/components/loading/loading_route_observer.dart'; // 已删除
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

  // *** 新增：用于控制初始搜索或新关键词搜索的加载状态 ***
  bool _isSearching = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchHistory.isEmpty && mounted) {
        print("SearchPostScreen didChangeDependencies: Loading search history");
        _loadSearchHistory(); // 历史加载不需要显示 LoadingWidget
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
    // 仅当不是初始搜索加载中时，才触发加载更多
    if (!_isSearching && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages &&
        _searchController.text.isNotEmpty) {
      print("SearchPostScreen: Scroll listener triggered load more");
      _loadMoreResults();
    }
  }
  // --- 滚动监听结束 ---


  // --- 搜索历史管理 (无加载状态控制) ---
  Future<void> _loadSearchHistory() async {
    print("SearchPostScreen: Attempting to load search history...");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || !mounted) {
      print("SearchPostScreen: Not logged in or not mounted, skipping history load.");
      return;
    }
    try {
      final history = await _userService.loadLocalSearchHistory();
      if (!mounted) return;
      print("SearchPostScreen: Search history loaded: $history");
      setState(() { _searchHistory = history; _error = null; });
    } catch (e) {
      print("SearchPostScreen: Error loading search history: $e");
      if (!mounted) return;
      // 仅在搜索框为空时显示历史错误
      if (_searchController.text.isEmpty) {
        setState(() { _error = '加载搜索历史失败: $e'; });
      }
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
      if (!mounted) return;

      // 如果搜索词为空，清空结果并重置状态，不显示加载
      if (trimmedQuery.isEmpty) {
        setState(() {
          _searchResults.clear(); _error = null; _currentPage = 1; _totalPages = 1;
          _isSearching = false; // 确保搜索状态关闭
          _isLoadingMore = false;
        });
        return;
      }

      // *** 根据 isNewSearch 设置加载状态 ***
      if (isNewSearch) {
        // 新搜索：显示 _isSearching 的加载，重置所有相关状态
        setState(() {
          _searchResults.clear(); _currentPage = 1; _totalPages = 1; _error = null;
          _isLoadingMore = false; // 重置加载更多状态
          _isSearching = true; // *** 显示初始搜索加载 ***
        });
      } else if (!_isLoadingMore) {
        // 加载更多：如果当前不在加载更多，则设置 _isLoadingMore 为 true
        setState(() => _isLoadingMore = true);
      }

      // LoadingRouteObserver 相关代码已删除

      try {
        print("SearchPostScreen: Calling ForumService.searchPosts...");
        final resultsData = await _forumService.searchPosts(
          keyword: trimmedQuery, page: _currentPage, limit: _limit,
        );
        if (!mounted) return;

        final List<Post> newPosts = resultsData['posts'];
        final pagination = resultsData['pagination'];
        final int serverTotalPages = pagination['pages'] ?? 1;
        print("SearchPostScreen: Search results received. Posts: ${newPosts.length}, Total Pages: $serverTotalPages");

        setState(() {
          if (isNewSearch) { _searchResults = newPosts; }
          else { _searchResults.addAll(newPosts); }
          _totalPages = serverTotalPages;
          _error = null; // 清除错误
          // 加载成功后，如果是新搜索，则 _isSearching 会在 finally 中重置
          // 如果是加载更多，则 _isLoadingMore 会在 finally 中重置
        });

        // 只有在新搜索且成功时才添加到历史记录
        if (isNewSearch) { _addToHistory(trimmedQuery); }

      } catch (e, s) {
        print("SearchPostScreen: Search failed: $e\n$s");
        if (!mounted) return;
        setState(() {
          _error = '搜索失败：$e'; // 设置错误信息
          if (isNewSearch) { _searchResults.clear(); } // 新搜索出错清空结果
          // 出错时也要重置加载状态，这在 finally 中处理
        });
      } finally {
        // *** 无论成功失败，最后都重置对应的加载状态 ***
        if (mounted) {
          if (isNewSearch) {
            if (_isSearching) setState(() => _isSearching = false); // 重置初始搜索状态
          } else {
            if (_isLoadingMore) setState(() => _isLoadingMore = false); // 重置加载更多状态
          }
          print("SearchPostScreen: Search finished, isSearching: $_isSearching, isLoadingMore: $_isLoadingMore");
        }
      }
    });
  }
  // --- 搜索逻辑结束 ---


  // --- 加载更多逻辑 ---
  Future<void> _loadMoreResults() async {
    // 增加 _isSearching 判断，初始搜索时不允许加载更多
    if (_isLoadingMore || _isSearching || _currentPage >= _totalPages) {
      print("SearchPostScreen: Load more skipped. isLoadingMore: $_isLoadingMore, isSearching: $_isSearching, currentPage: $_currentPage, totalPages: $_totalPages");
      return;
    }
    _currentPage++; // 先增加页码
    print("SearchPostScreen: Loading page $_currentPage of $_totalPages");
    // 调用 performSearch 时，isNewSearch 设为 false，它内部会设置 _isLoadingMore = true
    await _performSearch(_searchController.text.trim(), isNewSearch: false);
  }
  // --- 加载更多结束 ---


  // --- PostCard 回调处理方法 (删除 Observer 相关代码) ---
  Future<void> _handleDeletePostAction(String postId) async {
    print("SearchPostScreen: Handling delete action for post $postId");
    if (!mounted) return;
    // LoadingRouteObserver 相关代码已删除
    try {
      await CustomConfirmDialog.show(
        context: context,
        title: '确认删除',
        message: '确定要删除这篇帖子吗？此操作不可恢复。',
        confirmButtonText: '删除',
        confirmButtonColor: Colors.red,
        iconData: Icons.delete_forever_outlined,
        iconColor: Colors.red,
        onConfirm: () async {
          print("SearchPostScreen: Delete confirmed for post $postId. Calling service...");
          // *** 这里可以考虑加一个临时的按钮加载状态，但不影响全局 ***
          try {
            await _forumService.deletePost(postId);
            if (!mounted) return;
            print("SearchPostScreen: Post $postId deleted successfully from service.");
            setState(() { _searchResults.removeWhere((p) => p.id == postId); });
            AppSnackBar.showSuccess(context, '帖子已删除');
          } catch (e) {
            print("SearchPostScreen: Error deleting post $postId: $e");
            if (mounted) AppSnackBar.showError(context, '删除失败: $e');
            rethrow;
          }
        },
      );
      print("SearchPostScreen: Delete process completed successfully for post $postId.");
    } catch (e) {
      print("SearchPostScreen: Error during delete confirmation/action for post $postId: $e");
    }
  }

  void _handleEditPostAction(Post postToEdit) {
    print("SearchPostScreen: Handling edit action for post ${postToEdit.id}");
    if (!mounted) return;
    NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: postToEdit.id,
    ).then((updated) {
      if (updated == true && mounted) {
        print("SearchPostScreen: Returned from edit post with update signal. Refreshing search...");
        // 强制刷新当前搜索结果
        _performSearch(_searchController.text.trim(), isNewSearch: true);
      } else {
        print("SearchPostScreen: Returned from edit post without update signal.");
      }
    });
  }

  Future<void> _handleToggleLockAction(String postId) async {
    print("SearchPostScreen: Handling toggle lock action for $postId");
    if (!mounted) return;
    // LoadingRouteObserver 相关代码已删除
    // *** 可以考虑加一个临时的按钮加载状态 ***
    try {
      await _forumService.togglePostLock(postId);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '帖子状态已切换');
      // 更新列表中的状态
      setState(() {
        final index = _searchResults.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final oldPost = _searchResults[index];
          final newStatus = oldPost.status == PostStatus.locked
              ? PostStatus.active
              : PostStatus.locked;
          _searchResults[index] = oldPost.copyWith(status: newStatus);
          print("SearchPostScreen: Updated post $postId status in search results to $newStatus.");
        }
      });
    } catch (e) {
      print("SearchPostScreen: Error toggling lock for post $postId: $e");
      if (mounted) AppSnackBar.showError(context, '操作失败: $e');
    }
  }
  // --- 回调处理方法结束 ---


  // --- 构建 UI ---
  @override
  Widget build(BuildContext context) {
    print("SearchPostScreen: Build method called. isSearching: $_isSearching, isLoadingMore: $_isLoadingMore");
    return Scaffold(
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
          // 每次输入变化都触发新的搜索
          onChanged:(query) => _performSearch(query, isNewSearch: true),
          onSubmitted: (query) {
            print("SearchPostScreen: Submitted search for '$query'");
            // 提交时也触发新搜索
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
                // 清空时也触发 performSearch('') 来重置状态并显示历史
                _performSearch('', isNewSearch: true);
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
    // *** 1. 检查是否正在进行新的搜索 ***
    // 只有在新搜索且当前结果为空时才显示全屏加载
    if (_isSearching && _searchResults.isEmpty) {
      // print("SearchPostScreen: Displaying initial search LoadingWidget.");
      return LoadingWidget.fullScreen(message: '正在搜索...'); // 或者 LoadingWidget.inline()
    }

    // *** 2. 检查是否有错误信息 ***
    if (_error != null) {
      // 如果搜索框有内容，显示搜索错误
      if (_searchController.text.isNotEmpty) {
        print("SearchPostScreen: Displaying search error widget.");
        return InlineErrorWidget(
          errorMessage: _error!,
          onRetry: () {
            setState(() { _error = null; }); // 清除错误
            _performSearch(_searchController.text.trim(), isNewSearch: true); // 重试
          },
        );
      }
      // 如果搜索框为空，显示历史加载错误
      else {
        print("SearchPostScreen: Displaying history error widget.");
        return InlineErrorWidget(
          errorMessage: _error!,
          onRetry: () {
            setState(() { _error = null; }); // 清除错误
            _loadSearchHistory(); // 重试加载历史
          },
        );
      }
    }

    // *** 3. 如果搜索框为空，显示历史记录 ***
    if (_searchController.text.isEmpty) {
      print("SearchPostScreen: Displaying search history.");
      return _buildSearchHistory();
    }

    // *** 4. 显示搜索结果列表 (包括空状态和加载更多) ***
    print("SearchPostScreen: Displaying search results.");
    return _buildSearchResults();
  }

  // --- _buildSearchHistory (保持不变) ---
  Widget _buildSearchHistory() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      return LoginPromptWidget();
    }
    if (_searchHistory.isEmpty) {
      return EmptyStateWidget( message: '暂无搜索历史', iconData: Icons.history, );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('搜索历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_searchHistory.isNotEmpty)
                TextButton( onPressed: _clearHistory, child: Text('清空'), ),
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
  }

  // --- 构建搜索结果 UI ---
  Widget _buildSearchResults() {
    print("SearchPostScreen: Building search results. Count: ${_searchResults.length}, isLoadingMore: $_isLoadingMore");

    // *** 空状态处理: 仅在非初始搜索、非加载更多、无错误且结果为空时显示 ***
    if (!_isSearching && _searchResults.isEmpty && !_isLoadingMore && _error == null) {
      print("SearchPostScreen: Displaying empty search results state.");
      return EmptyStateWidget( message: '未找到相关帖子', iconData: Icons.search_off, );
    }

    // 结果列表 + 加载更多指示器
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      // itemCount 包含加载指示器的位置
      itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 加载更多指示器 (显示在列表末尾)
        if (index == _searchResults.length) {
          // 只有在 _isLoadingMore 为 true 时才显示
          return _isLoadingMore
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0), // 给加载指示器一些垂直空间
            child: Center(child: CircularProgressIndicator()),
          )
              : const SizedBox.shrink(); // 否则返回空 SizedBox
        }

        // 帖子卡片 (确保 index 在范围内)
        if (index < _searchResults.length) {
          final post = _searchResults[index];
          return Padding( // 给卡片之间加点间距
            padding: const EdgeInsets.only(bottom: 8.0),
            child: PostCard(
              key: ValueKey(post.id), // 使用 ValueKey 提高性能
              post: post,
              onDeleteAction: _handleDeletePostAction,
              onEditAction: _handleEditPostAction,
              onToggleLockAction: _handleToggleLockAction,
            ),
          );
        }
        // 安全返回，理论上不应到达这里
        return Container();
      },
    );
  }
// --- 构建 UI 结束 ---
}