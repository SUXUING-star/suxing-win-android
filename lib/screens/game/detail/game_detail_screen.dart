// lib/screens/game/game_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/screen/game/button/edit_button.dart';
import '../../../widgets/components/screen/game/button/like_button.dart';
import '../../../widgets/components/screen/game/game_detail_content.dart';
import '../../../widgets/components/screen/game/coverImage/game_cover_image.dart';

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
      });
    }
  }

  void _incrementViewCount() {
    if (widget.gameId != null) {
      _gameService.incrementGameView(widget.gameId!);
    }
  }

  Widget _buildSliverAppBar(Game game) {
    return SliverAppBar(
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
            GameCoverImage(imageUrl: game.coverImage),
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
          key: const PageStorageKey('game_detail'),
          slivers: [
            _buildSliverAppBar(_game!),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80), // 给底部留出空间
              sliver: SliverToBoxAdapter(
                child: GameDetailContent(game: _game!),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // 给 FAB 添加底部边距
        child: Stack(
          children: [
            EditButton(
              game: _game!,
              onEditComplete: _refreshGameDetails,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: LikeButton(
                  game: _game!,
                  gameService: _gameService,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // 改变 FAB 位置
    );
  }
}
