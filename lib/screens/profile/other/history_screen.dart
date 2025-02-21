// lib/screens/profile/history_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../models/post/post.dart';
import '../../../models/game/game_history.dart';
import '../../../models/post/post_history.dart';
import '../../../services/main/game/game_service.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../services/main/history/game_history_service.dart';
import '../../../services/main/history/post_history_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/load/loading_route_observer.dart';
import '../../../widgets/common/custom_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GameService _gameService = GameService();
  final ForumService _forumService = ForumService();
  final PostHistoryService _postHistoryService = PostHistoryService();
  final GameHistoryService _gameHistoryService = GameHistoryService();

  List<GameHistory>? _gameHistory;
  List<PostHistory>? _postHistory;
  Map<String, Game> _gameCache = {};
  Map<String, Post> _postCache = {};
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget
          .observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadHistory().then((_) {
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadHistory() async {
    try {
      final gameHistory = await _gameHistoryService.getUserGameHistory().first;
      final postHistory = await _postHistoryService.getUserPostHistory().first;

      // 注意这里改用 gameId 和 postId
      final gameIds = gameHistory.map((h) => h.gameId).toSet().toList();
      final games =
          await Future.wait(gameIds.map((id) => _gameService.getGameById(id)));

      final postIds = postHistory.map((h) => h.postId).toSet().toList();
      final posts =
          await Future.wait(postIds.map((id) => _forumService.getPost(id)));

      _gameCache = {
        for (var game in games.where((g) => g != null)) game!.id: game
      };

      _postCache = {
        for (var post in posts.where((p) => p != null)) post!.id: post
      };

      setState(() {
        _gameHistory = gameHistory;
        _postHistory = postHistory;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _gameHistory = [];
        _postHistory = [];
      });
    }
  }

  Future<void> _refreshHistory() async {
    final loadingObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadHistory();
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '浏览历史'),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_gameHistory == null || _postHistory == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_gameHistory!.isEmpty && _postHistory!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无浏览记录'),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: '游戏浏览历史'),
              Tab(text: '帖子浏览历史'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGameHistoryList(),
                _buildPostHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHistoryList() {
    return ListView.builder(
      itemCount: _gameHistory!.length,
      itemBuilder: (context, index) {
        final historyItem = _gameHistory![index];
        final game = _gameCache[historyItem.gameId];

        if (game == null) return SizedBox.shrink();

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(game.coverImage),
            ),
            title: Text(game.title),
            subtitle: Text('上次浏览: ${_formatDate(historyItem.lastViewTime)}'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.gameDetail,
                arguments: game,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostHistoryList() {
    return ListView.builder(
      itemCount: _postHistory!.length,
      itemBuilder: (context, index) {
        final historyItem = _postHistory![index];
        final post = _postCache[historyItem.postId];

        if (post == null) return SizedBox.shrink();

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(post.title),
            subtitle: Text('上次浏览: ${_formatDate(historyItem.lastViewTime)}'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.postDetail,
                arguments: post.id,
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
