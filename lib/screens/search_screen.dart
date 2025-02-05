// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/game_service.dart'; // 引入 GameService
import '../services/user_service.dart'; // 引入 UserService
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GameService _gameService = GameService(); // 使用 GameService
  final UserService _userService = UserService(); // 使用 UserService
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Game> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;  // 使用 isLoggedIn 检查登录状态

    try {
      final history = await _userService.getSearchHistory();  // 移除参数

      setState(() {
        _searchHistory = history;  // history 已经是 List<String> 类型，不需要转换
      });
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    try {
      await _userService.saveSearchHistory(_searchHistory);
    } catch (e) {
      print('Error saving search history: $e');
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
    _saveSearchHistory();
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }

  Future<void> _performSearch(String query) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults.clear();
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final results = await _gameService.searchGames(query);
        setState(() {
          _searchResults = results;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败：$e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索游戏...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          onChanged: _performSearch,
          onSubmitted: (query) {
            _addToHistory(query);
            _performSearch(query);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildSearchHistory();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Text('无搜索历史', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
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
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => _removeFromHistory(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text('未找到相关游戏', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              game.coverImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(game.title),
          subtitle: Text(
            game.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/game/detail',
              arguments: game,
            );
          },
        );
      },
    );
  }
}