// lib/screens/game/game_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/screen/game/button/edit_button.dart';
import '../../../widgets/components/screen/game/button/like_button.dart';
import '../../../widgets/components/screen/game/game_detail_content.dart';
import '../../../widgets/common/custom_app_bar.dart';

class GameDetailScreen extends StatefulWidget {
  final String? gameId;

  const GameDetailScreen({
    Key? key,
    this.gameId,
  }) : super(key: key);

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameService _gameService = GameService();
  Game? _game;
  String? _error;
  bool _isLoading = false;

  // 用来强制刷新界面的计数器
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    if (widget.gameId != null) {
      _loadGameDetails();
      _incrementViewCount();
      _addToHistory();
    } else {
      setState(() {
        _error = '无效的游戏ID';
      });
    }
  }

  void _addToHistory() {
    if (widget.gameId != null) {
      _gameService.addToGameHistory(widget.gameId!);
    }
  }

  Future<void> _loadGameDetails() async {
    if (widget.gameId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final game = await _gameService.getGameById(widget.gameId!);
      if (game == null) throw Exception('游戏不存在');

      setState(() {
        _game = game;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshGameDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await _loadGameDetails();
      _incrementViewCount();
      _addToHistory();
    } finally {
      setState(() {
        _isLoading = false;
        // 增加刷新计数器以强制重建界面
        _refreshCounter++;
      });
    }
  }

  void _incrementViewCount() {
    if (widget.gameId != null) {
      _gameService.incrementGameView(widget.gameId!);
    }
  }

  // 处理点赞后刷新界面
  void _handleLikeChanged() {
    _refreshGameDetails();
  }

  // 处理评论后刷新界面
  void _handleCommentAdded() {
    _refreshGameDetails();
  }

  Widget _buildMobileLayout(Game game) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
          // 使用计数器作为Key的一部分，强制刷新
          key: ValueKey('game_detail_${_refreshCounter}'),
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      game.coverImage,
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // 实现分享功能
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverToBoxAdapter(
                // 已保持GameDetailContent不变，仅在需要刷新的地方处理
                child: GameDetailContent(game: game),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Stack(
          children: [
            EditButton(
              game: game,
              onEditComplete: _refreshGameDetails,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: LikeButton(
                  game: game,
                  gameService: _gameService,
                  onLikeChanged: _handleLikeChanged, // 这里添加点赞变化回调
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDesktopLayout(Game game) {
    return Scaffold(
      appBar: CustomAppBar(
        title: game.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 实现分享功能
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LikeButton(
              game: game,
              gameService: _gameService,
              onLikeChanged: _handleLikeChanged, // 这里添加点赞变化回调
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: EditButton(
              game: game,
              onEditComplete: _refreshGameDetails,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // 使用计数器作为Key的一部分，强制刷新
        key: ValueKey('game_detail_content_${_refreshCounter}'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GameDetailContent(game: game),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: const Center(child: Text('无效的游戏ID')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadGameDetails,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop ? _buildDesktopLayout(_game!) : _buildMobileLayout(_game!);
  }
}