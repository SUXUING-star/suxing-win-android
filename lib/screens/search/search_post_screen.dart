// lib/screens/search/search_post_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'dart:async';

// Models
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/post_list_pagination.dart';
import 'package:suxingchahui/services/main/user/cache/search_history_cache_service.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';

// Services
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';

// Providers
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
// Widgets
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

class SearchPostScreen extends StatefulWidget {
  final SearchHistoryCacheService searchHistoryCacheService;
  final PostService postService;
  final UserFollowService followService;
  final AuthProvider authProvider;
  final UserInfoService infoService;
  final WindowStateProvider windowStateProvider;
  const SearchPostScreen({
    super.key,
    required this.postService,
    required this.searchHistoryCacheService,
    required this.followService,
    required this.authProvider,
    required this.infoService,
    required this.windowStateProvider,
  });

  @override
  _SearchPostScreenState createState() => _SearchPostScreenState();
}

class _LoadingIndicatorPlaceholder {
  const _LoadingIndicatorPlaceholder();
}

class _SearchPostScreenState extends State<SearchPostScreen> {
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

  bool _isSearching = false;
  bool _hasInitializedDependencies = false;

  // --- 生命周期方法 ---
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchHistory.isEmpty && mounted) {
          _loadSearchHistory(); // 历史加载不需要 LoadingWidget
        }
      });
    }
  }

  @override
  void dispose() {
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
    if (!_isSearching &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages &&
        _searchController.text.isNotEmpty) {
      _loadMoreResults();
    }
  }

  // --- 搜索历史管理 (无加载状态控制) ---
  Future<void> _loadSearchHistory() async {
    if (!mounted) {
      return;
    }
    // 这个搜索记录不需要登录！！！！！！！！
    // 完全本地共享
    try {
      final history = await widget.searchHistoryCacheService.loadLocalHistory();
      if (!mounted) return;
      setState(() {
        _searchHistory = history;
        _error = null;
      });
    } catch (e) {
      // print("SearchPostScreen: Error loading search history: $e");
      if (!mounted) return;
      // 仅在搜索框为空时显示历史错误
      if (_searchController.text.isEmpty) {
        setState(() {
          _error = '加载搜索历史失败: $e';
        });
      }
    }
  }

  Future<void> _saveSearchHistory() async {
    if (!mounted) return;
    // 这个搜索记录不需要登录！！！！！！！！
    // 完全本地共享
    try {
      await widget.searchHistoryCacheService.saveLocalHistory(_searchHistory);
    } catch (e) {
      // print("SearchPostScreen: Error saving search history: $e");
    }
  }

  void _addToHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || !mounted) return;
    setState(() {
      _searchHistory.remove(trimmedQuery);
      _searchHistory.insert(0, trimmedQuery);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    _saveSearchHistory();
  }

  void _removeFromHistory(String query) {
    if (!mounted) return;
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  void _clearHistory() {
    if (!mounted) return;
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }
  // --- 搜索历史结束 ---

  // --- 核心搜索逻辑 ---
  Future<void> _performSearch(String query, {bool isNewSearch = true}) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      final trimmedQuery = query.trim();
      if (!mounted) return;

      // 如果搜索词为空，清空结果并重置状态，不显示加载
      if (trimmedQuery.isEmpty) {
        setState(() {
          _searchResults.clear();
          _error = null;
          _currentPage = 1;
          _totalPages = 1;
          _isSearching = false; // 确保搜索状态关闭
          _isLoadingMore = false;
        });
        return;
      }

      // *** 根据 isNewSearch 设置加载状态 ***
      if (isNewSearch) {
        // 新搜索：显示 _isSearching 的加载，重置所有相关状态
        setState(() {
          _searchResults.clear();
          _currentPage = 1;
          _totalPages = 1;
          _error = null;
          _isLoadingMore = false; // 重置加载更多状态
          _isSearching = true; // *** 显示初始搜索加载 ***
        });
      } else if (!_isLoadingMore) {
        // 加载更多：如果当前不在加载更多，则设置 _isLoadingMore 为 true
        setState(() => _isLoadingMore = true);
      }

      // LoadingRouteObserver 相关代码已删除

      try {
        final PostListPagination resultsData =
            await widget.postService.searchPosts(
          query: trimmedQuery,
          page: _currentPage,
          limit: _limit,
        );
        if (!mounted) return;

        final List<Post> newPosts = resultsData.posts;
        final pagination = resultsData.pagination;
        final int serverTotalPages = pagination.pages;

        setState(() {
          if (isNewSearch) {
            _searchResults = newPosts;
          } else {
            _searchResults.addAll(newPosts);
          }
          _totalPages = serverTotalPages;
          _error = null; // 清除错误
          // 加载成功后，如果是新搜索，则 _isSearching 会在 finally 中重置
          // 如果是加载更多，则 _isLoadingMore 会在 finally 中重置
        });

        // 只有在新搜索且成功时才添加到历史记录
        if (isNewSearch) {
          _addToHistory(trimmedQuery);
        }
      } catch (e) {
        // print("SearchPostScreen: Search failed: $e\n$s");
        if (!mounted) return;
        setState(() {
          _error = '搜索失败：$e'; // 设置错误信息
          if (isNewSearch) {
            _searchResults.clear();
          } // 新搜索出错清空结果
          // 出错时也要重置加载状态，这在 finally 中处理
        });
      } finally {
        // *** 无论成功失败，最后都重置对应的加载状态 ***
        if (mounted) {
          if (isNewSearch) {
            if (_isSearching) setState(() => _isSearching = false); // 重置初始搜索状态
          } else {
            if (_isLoadingMore) {
              setState(() => _isLoadingMore = false); // 重置加载更多状态
            }
          }
        }
      }
    });
  }
  // --- 搜索逻辑结束 ---

  // --- 加载更多逻辑 ---
  Future<void> _loadMoreResults() async {
    // 增加 _isSearching 判断，初始搜索时不允许加载更多
    if (_isLoadingMore || _isSearching || _currentPage >= _totalPages) {
      return;
    }
    _currentPage++; // 先增加页码
    // 调用 performSearch 时，isNewSearch 设为 false，它内部会设置 _isLoadingMore = true
    await _performSearch(_searchController.text.trim(), isNewSearch: false);
  }

  // --- 回调处理方法结束 ---

  // --- 构建 UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                ...GlobalConstants.defaultAppBarColors,
              ],
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索帖子...',
            hintStyle: TextStyle(
              color: Colors.grey,
            ),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          // 每次输入变化都触发新的搜索
          onChanged: (query) => _performSearch(query, isNewSearch: true),
          onSubmitted: (query) {
            // 提交时也触发新搜索
            _performSearch(query.trim(), isNewSearch: true);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
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
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "正在搜索...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    // *** 2. 检查是否有错误信息 ***
    if (_error != null) {
      // 如果搜索框有内容，显示搜索错误
      if (_searchController.text.isNotEmpty) {
        return CustomErrorWidget(
          errorMessage: _error!,
          onRetry: () {
            setState(() {
              _error = null;
            }); // 清除错误
            _performSearch(_searchController.text.trim(),
                isNewSearch: true); // 重试
          },
        );
      }
      // 如果搜索框为空，显示历史加载错误
      else {
        return CustomErrorWidget(
          errorMessage: _error!,
          onRetry: () {
            setState(() {
              _error = null;
            }); // 清除错误
            _loadSearchHistory(); // 重试加载历史
          },
        );
      }
    }

    // *** 3. 如果搜索框为空，显示历史记录 ***
    if (_searchController.text.isEmpty) {
      return _buildSearchHistory();
    }

    // *** 4. 显示搜索结果列表 (包括空状态和加载更多) ***
    return _buildSearchResults();
  }

  // --- _buildSearchHistory (保持不变) ---
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return EmptyStateWidget(
        message: '暂无搜索历史',
        iconData: Icons.history,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('搜索历史',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_searchHistory.isNotEmpty)
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
                  _searchController.text = query;
                  _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length));
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
    if (!_isSearching &&
        _searchResults.isEmpty &&
        !_isLoadingMore &&
        _error == null) {
      return const EmptyStateWidget(
        message: '未找到相关帖子',
        iconData: Icons.search_off,
      );
    }

    // 准备要显示的所有项目，包括帖子和加载指示器的占位符
    final List<Object> displayItems = [..._searchResults];
    if (_isLoadingMore) {
      displayItems.add(const _LoadingIndicatorPlaceholder());
    }

    // 使用封装好的 AnimatedListView
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return AnimatedListView<Object>(
          listKey: ValueKey('search_post_results_${_searchController.text}'),
          // 提供一个Key
          items: displayItems,
          physics: const AlwaysScrollableScrollPhysics(),
          // 确保可滚动
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index, item) {
            // 如果项目是帖子
            if (item is Post) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: BasePostCard(
                  availableWidth: screenWidth,
                  currentUser: widget.authProvider.currentUser,
                  post: item,
                  followService: widget.followService,
                  infoService: widget.infoService,
                  onDeleteAction: null,
                  onEditAction: null,
                  onToggleLockAction: null,
                ),
              );
            }

            // 如果项目是加载指示器的占位符
            if (item is _LoadingIndicatorPlaceholder) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: LoadingWidget(),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
