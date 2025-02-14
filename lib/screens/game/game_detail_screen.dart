import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/toaster.dart';
import '../../widgets/game/game_detail_content.dart';
import 'edit_game_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final String? gameId;  // 改为可空类型

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

  void _toggleLike(BuildContext context, bool isLiked) async {
    if (_game == null) return;

    try {
      await _gameService.toggleLike(_game!.id);
      Toaster.show(
        context,
        message: isLiked ? '已取消点赞' : '点赞成功',
      );
    } catch (e) {
      Toaster.show(
        context,
        message: '操作失败，请稍后重试',
        isError: true,
      );
    }
  }

  Widget _buildFavoriteButton(BuildContext context) {
    if (_isLoading || _game == null) {
      return const SizedBox.shrink();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return FloatingActionButton(
            onPressed: () {
              Toaster.show(
                context,
                message: '请先登录后再操作',
                isError: true,
              );
              Navigator.pushNamed(context, '/login');
            },
            child: const Icon(Icons.favorite_border),
            backgroundColor: Theme.of(context).primaryColor,
          );
        }

        return StreamBuilder<List<String>>(
          stream: _gameService.getUserFavorites(),
          initialData: const [],
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final isFavorite = snapshot.data!.contains(_game!.id);

            return FloatingActionButton(
              onPressed: () => _toggleLike(context, isFavorite),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              backgroundColor: isFavorite ? Colors.red : Theme.of(context).primaryColor,
            );
          },
        );
      },
    );
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
        Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAdmin) {
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGameScreen(game: game),
                    ),
                  ).then((_) => _refreshGameDetails());
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 首先检查 gameId 是否为空
    if (widget.gameId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('无效的游戏ID')),
      );
    }

    // 2. 检查加载状态
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3. 检查错误状态
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('错误')),
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


    // 5. 显示游戏详情
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
          key: PageStorageKey('game_detail'),
          slivers: [
            _buildSliverAppBar(_game!),
            SliverToBoxAdapter(
              child: GameDetailContent(game: _game!),
            ),
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _buildFavoriteButton(context),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}