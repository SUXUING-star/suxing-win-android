// lib/screens/search/search_game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'dart:async';

// Models
import '../../models/game/game.dart';

// Services
import '../../services/main/game/game_service.dart';
import '../../services/main/user/user_service.dart';

// Providers
import '../../providers/auth/auth_provider.dart';

// Widgets
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
// *** 导入 LoadingWidget ***
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/common_game_card.dart';
// import '../../widgets/components/loading/loading_route_observer.dart'; // 已删除

class SearchGameScreen extends StatefulWidget {
  const SearchGameScreen({super.key});

  @override
  _SearchGameScreenState createState() => _SearchGameScreenState();
}

class _SearchGameScreenState extends State<SearchGameScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Game> _searchResults = [];
  String? _error;
  Timer? _debounceTimer;

  // *** 新增：用于控制搜索的加载状态 ***
  bool _isSearching = false;
  // 这个页面没有分页，所以不需要 _isLoadingMore

  // --- 生命周期方法 ---
  @override
  void initState() {
    super.initState();
    print("SearchGameScreen initState called");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchHistory.isEmpty && mounted) {
        print("SearchGameScreen didChangeDependencies: Loading search history");
        _loadSearchHistory(); // 历史加载不需要 LoadingWidget
      }
    });
  }

  @override
  void dispose() {
    print("SearchGameScreen dispose called");
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  // --- 生命周期方法结束 ---

  // --- 搜索历史管理 (无加载状态控制) ---
  Future<void> _loadSearchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || !mounted) {
      return;
    }
    try {
      final userService = context.read<UserService>();
      final history = await userService.loadLocalSearchHistory();
      if (!mounted) return;
      setState(() {
        _searchHistory = history;
        _error = null;
      });
    } catch (e) {
      print("SearchGameScreen: Error loading search history: $e");
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || !mounted) return;
    try {
      final userService = context.read<UserService>();
      await userService.saveLocalSearchHistory(_searchHistory);
    } catch (e) {
      print("SearchGameScreen: Error saving search history: $e");
    }
  }

  void _addToHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || !mounted) return;
    print("SearchGameScreen: Adding '$trimmedQuery' to history.");
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
    print("SearchGameScreen: Removing '$query' from history.");
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  void _clearHistory() {
    if (!mounted) return;
    print("SearchGameScreen: Clearing search history.");
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }
  // --- 搜索历史结束 ---

  // --- 核心搜索逻辑 ---
  Future<void> _performSearch(String query) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      final trimmedQuery = query.trim();
      print("SearchGameScreen: Performing search for '$trimmedQuery'");
      if (!mounted) return;

      // 如果搜索词为空，清空结果并重置状态
      if (trimmedQuery.isEmpty) {
        setState(() {
          _searchResults.clear();
          _error = null;
          _isSearching = false; // 确保搜索状态关闭
        });
        return;
      }

      // *** 开始搜索，设置 _isSearching 为 true ***
      setState(() {
        _error = null; // 清除旧错误
        _isSearching = true; // 显示加载
      });

      // LoadingRouteObserver 相关代码已删除

      try {
        final gameService = context.read<GameService>();
        final results = await gameService.searchGames(trimmedQuery);
        if (!mounted) return;

        print(
            "SearchGameScreen: Search results received. Count: ${results.length}");
        setState(() {
          _searchResults = results;
          _error = null; // 清除错误
          // 加载成功后，isSearching 会在 finally 中重置
        });

        // 搜索成功且有结果时添加到历史
        if (results.isNotEmpty) {
          _addToHistory(trimmedQuery);
        }
      } catch (e, s) {
        print("SearchGameScreen: Search failed: $e\n$s");
        if (!mounted) return;
        setState(() {
          _error = '搜索失败：$e'; // 设置错误信息
          _searchResults.clear(); // 出错清空结果
          // isSearching 会在 finally 中重置
        });
      } finally {
        // *** 无论成功失败，最后都重置 isSearching 状态 ***
        if (mounted) {
          if (_isSearching) setState(() => _isSearching = false); // 重置搜索状态
          print(
              "SearchGameScreen: Search finished, isSearching: $_isSearching");
        }
      }
    });
  }
  // --- 搜索逻辑结束 ---

  // --- 构建 UI ---
  @override
  Widget build(BuildContext context) {
    print("SearchGameScreen: Build method called. isSearching: $_isSearching");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [...CustomAppBar.appBarColors],
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
          // 每次输入变化都触发搜索
          onChanged: _performSearch,
          onSubmitted: (query) {
            print("SearchGameScreen: Submitted search for '$query'");
            // 提交时也触发搜索
            _performSearch(query.trim());
            // 添加历史在 performSearch 成功后处理
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                print("SearchGameScreen: Clearing search input.");
                _searchController.clear();
                // 清空时也触发 performSearch('') 来重置状态并显示历史
                _performSearch('');
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
    // *** 1. 检查是否正在搜索 ***
    if (_isSearching) {
      // print("SearchGameScreen: Displaying search LoadingWidget.");
      // 直接显示加载，因为游戏搜索结果通常是替换式的
      return LoadingWidget.fullScreen(
          message: '正在搜索游戏...'); // 或者 LoadingWidget.inline()
    }

    // *** 2. 检查是否有错误信息 ***
    if (_error != null) {
      // 根据搜索框是否为空判断是哪个错误
      if (_searchController.text.isNotEmpty) {
        // print("SearchGameScreen: Displaying search error widget.");
        return InlineErrorWidget(
          errorMessage: _error!,
          onRetry: () {
            setState(() {
              _error = null;
            }); // 清除错误
            _performSearch(_searchController.text.trim()); // 重试搜索
          },
        );
      } else {
        print("SearchGameScreen: Displaying history error widget.");
        return InlineErrorWidget(
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
      print("SearchGameScreen: Displaying search history.");
      return _buildSearchHistory();
    }

    // *** 4. 显示搜索结果列表 (包括空状态) ***
    print("SearchGameScreen: Displaying search results.");
    return _buildSearchResults();
  }

  // --- _buildSearchHistory (保持不变) ---
  Widget _buildSearchHistory() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      return LoginPromptWidget();
    }
    if (_searchHistory.isEmpty) {
      return const EmptyStateWidget(
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
                  _performSearch(query);
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
    print(
        "SearchGameScreen: Building search results. Count: ${_searchResults.length}");

    // 空状态处理 (保持不变)
    if (!_isSearching && _searchResults.isEmpty && _error == null) {
      print("SearchGameScreen: Displaying empty search results state.");
      return const EmptyStateWidget(
        message: '未找到相关游戏',
        iconData: Icons.search_off,
      );
    }

    // 定义卡片动画参数
    const Duration cardAnimationDuration = Duration(milliseconds: 350);
    const Duration cardDelayIncrement = Duration(milliseconds: 40);

    // 结果列表
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        // --- 使用 FadeInSlideUpItem 包裹卡片 ---
        return FadeInSlideUpItem(
          key: ValueKey(game.id), // 使用 game.id 作为 Key
          duration: cardAnimationDuration,
          delay: cardDelayIncrement * index, // 交错延迟
          child: Padding(
            // 保持原有的 Padding
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CommonGameCard(
              game: game,
              isGridItem: false, // 列表样式
              showTags: true,
              maxTags: 3,
              // CommonGameCard 通常内部处理点击导航
            ),
          ),
        );
      },
    );
  }
// --- 构建 UI 结束 ---
}
