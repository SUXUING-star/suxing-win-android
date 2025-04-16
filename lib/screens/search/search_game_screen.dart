// lib/screens/search/search_game_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/components/common_game_card.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart';
import '../../services/main/user/user_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/components/loading/loading_route_observer.dart';
import 'dart:async';

class SearchGameScreen extends StatefulWidget {
  @override
  _SearchGameScreenState createState() => _SearchGameScreenState();
}

class _SearchGameScreenState extends State<SearchGameScreen> {
  final GameService _gameService = GameService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Game> _searchResults = [];
  String? _error;
  Timer? _debounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Removed loading observer logic from here as it's handled in performSearch
      _loadSearchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    try {
      final history = await _userService.loadLocalSearchHistory();
      if (!mounted) return; // Check if the widget is still in the tree
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载搜索历史失败: $e';
      });
    } finally {
      // if (mounted) loadingObserver.hideLoading();
    }
  }

  Future<void> _saveSearchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    try {
      await _userService.saveLocalSearchHistory(_searchHistory);
    } catch (e) {
      if (!mounted) return;
    }
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    _saveSearchHistory(); // Save after state update
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory(); // Save after state update
  }

  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory(); // Save after state update
  }

  Future<void> _performSearch(String query) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searchResults.clear();
          _error = null;
        });
        return;
      }

      // Ensure the loading observer is accessible
      LoadingRouteObserver? loadingObserver;
      try {
        loadingObserver = Navigator.of(context)
            .widget.observers
            .whereType<LoadingRouteObserver>()
            .first;
      } catch (e) {
        print("LoadingRouteObserver not found: $e");
        // Handle cases where the observer might not be present (e.g., during tests or unusual navigation)
      }


      loadingObserver?.showLoading();

      try {
        final results = await _gameService.searchGames(trimmedQuery);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _error = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = '搜索失败：$e';
          _searchResults.clear(); // Clear results on error
        });
      } finally {
        if (mounted) {
          loadingObserver?.hideLoading();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. 设置背景透明，让 flexibleSpace 显示出来
        backgroundColor: Colors.transparent,
        // 2. 去掉阴影，与 CustomAppBar 统一
        elevation: 0,
        // 3. 添加 flexibleSpace 并复制 CustomAppBar 的渐变背景
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF6AB7F0), // 与 CustomAppBar 相同的颜色
                Color(0xFF4E9DE3), // 与 CustomAppBar 相同的颜色
              ],
            ),
          ),
        ),
        // 保留原来的 TextField 作为 title
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索游戏...',
            // 确保提示文字在渐变背景上可见
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none, // 去掉下划线，更简洁
          ),
          // 确保输入文字在渐变背景上可见
          style: TextStyle(color: Colors.white),
          onChanged: _performSearch,
          onSubmitted: (query) {
            _addToHistory(query.trim());
            _performSearch(query.trim());
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch(''); // Clear results
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Prioritize showing error if it exists
    if (_error != null && _searchController.text.isNotEmpty) {
      // Show specific error for search failure
      return InlineErrorWidget(
        errorMessage: _error!,
        onRetry: () {
          setState(() { _error = null; }); // Clear error before retry
          _performSearch(_searchController.text.trim());
        },
      );
    }
    // Show history error only if search bar is empty
    else if (_error != null && _searchController.text.isEmpty) {
      return InlineErrorWidget(
        errorMessage: _error!,
        onRetry: () {
          setState(() { _error = null; }); // Clear error before retry
          _loadSearchHistory();
        },
      );
    }


    if (_searchController.text.isEmpty) {
      return _buildSearchHistory();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchHistory() {
    // Check login status for displaying history
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      return  LoginPromptWidget();
    }


    if (_searchHistory.isEmpty) {
      return EmptyStateWidget(
        message: '暂无搜索历史',
        iconData: Icons.history, // Use history icon
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjusted padding
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
            padding: EdgeInsets.symmetric(horizontal: 8), // Padding for list items
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
                      TextPosition(offset: _searchController.text.length)); // Move cursor to end
                  _performSearch(query);
                  // Optional: Add to history again to move it to top?
                  // _addToHistory(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- MODIFIED METHOD ---
  Widget _buildSearchResults() {
    // Use EmptyStateWidget for no search results (and no error)
    // Note: Error state is handled in _buildBody() now
    if (_searchResults.isEmpty && _error == null) {
      // Check _error == null to ensure we don't show this *and* an error widget
      return EmptyStateWidget(
        message: '未找到相关游戏',
        iconData: Icons.search_off, // Icon indicating nothing found
      );
    }

    return ListView.builder(
      // Add padding around the list for better spacing from screen edges
      padding: const EdgeInsets.all(8.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        // Replace ListTile with BaseGameCard
        return Padding(
          // Add padding below each card for spacing within the list
          padding: const EdgeInsets.only(bottom: 12.0), // Increased spacing
          child: CommonGameCard(
            game: game,
            isGridItem: false, // Use the list (horizontal) layout
            showTags: true,    // Show tags in the card (default is true)
            maxTags: 3,        // Example: Show up to 3 tags
            // adaptForPanels: false, // Default, adjust if needed
            // forceCompact: false, // Default, adjust if needed
          ),
        );
      },
    );
  }
// --- END OF MODIFIED METHOD ---
}