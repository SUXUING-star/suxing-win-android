// lib/screens/search/search_game_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_list_pagination.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'dart:async';

// Services
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';

// Widgets
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

class SearchGameScreen extends StatefulWidget {
  final GameService gameService;
  final UserService userService;
  final WindowStateProvider windowStateProvider;
  const SearchGameScreen({
    super.key,
    required this.gameService,
    required this.userService,
    required this.windowStateProvider,
  });

  @override
  _SearchGameScreenState createState() => _SearchGameScreenState();
}

class _LoadingIndicatorPlaceholder {
  const _LoadingIndicatorPlaceholder();
}

class _SearchGameScreenState extends State<SearchGameScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  GameListPagination? _searchResults; // 改为 GameList?
  String? _error;
  Timer? _debounceTimer;

  bool _isSearching = false; // 首次搜索或刷新时
  bool _isLoadingMore = false; // 加载更多时

  bool _hasInitializedDependencies = false;

  int _currentPage = 1;
  final int _pageSize = 15; // 每页加载数量

  @override
  void initState() {
    super.initState();
    // didChangeDependencies 中加载历史
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchHistory.isEmpty && mounted) {
          _loadSearchHistory();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    if (!mounted) return;
    try {
      final history = await widget.userService.loadLocalSearchHistory();
      if (!mounted) return;
      setState(() {
        _searchHistory = history;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_searchController.text.isEmpty) {
        setState(() {
          _error = '加载搜索历史失败'; // 简化错误信息
        });
      }
    }
  }

  Future<void> _saveSearchHistory() async {
    if (!mounted) return;
    try {
      await widget.userService.saveLocalSearchHistory(_searchHistory);
    } catch (e) {
      // Local save error, usually minor
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

  Future<void> _performSearch(String query, {bool isRefresh = false}) async {
    _debounceTimer?.cancel();
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _searchResults = null; // 清空结果
        _error = null;
        _isSearching = false;
        _isLoadingMore = false;
        _currentPage = 1;
      });
      return;
    }

    // 防抖
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      if (!mounted) return;

      setState(() {
        _error = null;
        if (isRefresh || _currentPage == 1) {
          _isSearching = true; // 首次搜索或刷新时显示主加载
          _searchResults = null; // 刷新时清空旧数据
        } else {
          // 这种情况理论上不会发生，因为这是首次搜索的逻辑
        }
        _isLoadingMore = false; // 重置加载更多状态
        _currentPage = 1; // 总是从第一页开始新的搜索
      });

      try {
        final results = await widget.gameService.searchGames(
          query: trimmedQuery,
          page: _currentPage,
          pageSize: _pageSize,
        );
        if (!mounted) return;

        setState(() {
          _searchResults = results;
          // _isSearching 会在 finally 中处理
        });

        if (results.games.isNotEmpty) {
          _addToHistory(trimmedQuery);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = '搜索失败，请稍后重试';
          _searchResults = null;
        });
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreResults() || !mounted) return;

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    _currentPage++;

    try {
      final results = await widget.gameService.searchGames(
        query: _searchController.text.trim(),
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        if (_searchResults != null) {
          _searchResults = _searchResults!.copyWith(
            games: [..._searchResults!.games, ...results.games],
            pagination: results.pagination, // 更新分页信息
          );
        } else {
          // 这种情况不应该发生，因为加载更多前 _searchResults 应该有值
          _searchResults = results;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _currentPage--; // 失败时回滚页码
      setState(() {
        _error = '加载更多失败';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  bool _hasMoreResults() {
    return _searchResults?.pagination.hasNextPage() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar 已内联
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark
              ], // 示例颜色
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索游戏...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          onChanged: (query) => _performSearch(query), // 每次输入都触发，但有防抖
          onSubmitted: (query) {
            _debounceTimer?.cancel(); // 立即执行搜索，取消防抖
            _performSearch(query.trim(), isRefresh: true);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _performSearch(''); // 清空搜索，显示历史
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      // 首次加载或刷新时
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

    if (_error != null &&
        (_searchResults == null || _searchResults!.games.isEmpty)) {
      // 只有在没有结果时才显示全屏错误
      return CustomErrorWidget(
        // 使用 CustomErrorWidget 以便有重试按钮
        errorMessage: _error!,
        onRetry: () {
          setState(() {
            _error = null;
          });
          if (_searchController.text.isEmpty) {
            _loadSearchHistory();
          } else {
            _performSearch(_searchController.text.trim(), isRefresh: true);
          }
        },
      );
    }

    // 如果有部分结果但加载更多失败，错误会在列表底部显示（如果实现的话）

    if (_searchController.text.isEmpty) {
      return _buildSearchHistory();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty && _error == null) {
      // 只有在历史为空且无错误时显示空状态
      return const EmptyStateWidget(
        message: '暂无搜索历史',
        iconData: Icons.history,
      );
    }
    // 如果有加载历史的错误，_buildBody 已经处理了
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
                  _performSearch(query, isRefresh: true);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null || _searchResults!.games.isEmpty) {
      if (_searchController.text.isNotEmpty &&
          !_isSearching &&
          _error == null) {
        return const EmptyStateWidget(
          message: '未找到相关游戏',
          iconData: Icons.search_off,
        );
      }
      return const SizedBox.shrink();
    }

    // 准备要显示的所有项目，包括游戏和占位符
    final List<Object> displayItems = [..._searchResults!.games];
    if (_hasMoreResults() || _isLoadingMore) {
      displayItems.add(const _LoadingIndicatorPlaceholder());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            !_isLoadingMore &&
            _hasMoreResults()) {
          _loadMoreResults();
        }
        return true;
      },
      // 使用封装好的 AnimatedListView
      child: LazyLayoutBuilder(
          windowStateProvider: widget.windowStateProvider,
          builder: (context, constraints) {
            return AnimatedListView<Object>(
              items: displayItems,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index, item) {
                // 如果项目是游戏
                if (item is Game) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CommonGameCard(
                      game: item,
                      isGridItem: false,
                      showTags: true,
                      maxTags: 3,
                    ),
                  );
                }

                // 如果项目是加载指示器的占位符
                if (item is _LoadingIndicatorPlaceholder) {
                  if (_isLoadingMore) {
                    return const Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: LoadingWidget(message: "加载中..."),
                    );
                  }
                  if (_error != null && _searchResults!.games.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                    );
                  }
                }

                return const SizedBox.shrink();
              },
            );
          }),
    );
  }
}
