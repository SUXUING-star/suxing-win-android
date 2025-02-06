import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/screens/game/add_game_screen.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/toaster.dart';
import '../../widgets/game/game_detail_content.dart';
import 'edit_game_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({
    Key? key,
    required this.game,
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
    _loadGameDetails();
    _incrementViewCount();
    _addToHistory();
  }

  void _addToHistory() {
    _gameService.addToGameHistory(widget.game.id);
  }

  Future<void> _loadGameDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final game = await _gameService.getGameById(widget.game.id);
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
    _gameService.incrementGameView(widget.game.id);
  }

  void _toggleLike(BuildContext context, bool isLiked) async {
    final game = _game ?? widget.game;
    try {
      await _gameService.toggleLike(game.id);
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
    // 确保在构建FAB之前已经完成了必要的初始化
    if (_isLoading) {
      return const SizedBox.shrink(); // 加载时不显示FAB
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
            backgroundColor: Theme
                .of(context)
                .primaryColor,
          );
        }

        return StreamBuilder<List<String>>(
          stream: _gameService.getUserFavorites(),
          initialData: const [], // 添加初始数据
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink(); // 数据加载时不显示FAB
            }

            final game = _game ?? widget.game;
            final isFavorite = snapshot.data!.contains(game.id);

            return FloatingActionButton(
              onPressed: () => _toggleLike(context, isFavorite),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              backgroundColor: isFavorite ? Colors.red : Theme
                  .of(context)
                  .primaryColor,
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
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

    final game = _game ?? widget.game;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
          // 添加key以帮助Flutter正确重建widget
          key: PageStorageKey('game_detail'),
          slivers: [
            _buildSliverAppBar(game),
            SliverToBoxAdapter(
              child: GameDetailContent(game: game),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFavoriteButton(context),
    );
  }
}