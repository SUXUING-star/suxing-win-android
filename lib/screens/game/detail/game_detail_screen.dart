// Updated version of lib/screens/game/game_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/screen/game/button/edit_button.dart';
import '../../../widgets/components/screen/game/button/like_button.dart';
import '../../../widgets/components/screen/game/game_detail_content.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import '../../../widgets/components/common/error_widget.dart';
import '../../../widgets/components/common/loading_widget.dart';

class GameDetailScreen extends StatefulWidget {
  final String? gameId;

  const GameDetailScreen({Key? key, this.gameId}) : super(key: key);

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameService _gameService = GameService();
  Game? _game;
  String? _error;
  bool _isLoading = false;
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
      if (game == null) {
        throw 'not_found';
      }

      setState(() {
        _game = game;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e == 'not_found') {
          _error = 'not_found';
        } else {
          _error = e.toString();
        }
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
        _refreshCounter++;
      });
    }
  }

  void _incrementViewCount() {
    if (widget.gameId != null) {
      _gameService.incrementGameView(widget.gameId!);
    }
  }

  void _handleLikeChanged() {
    _refreshGameDetails();
  }

  void _handleCommentAdded() {
    _refreshGameDetails();
  }

  // Add a handler for navigation
  void _handleNavigate(String gameId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailScreen(gameId: gameId),
      ),
    );
  }

  Widget _buildMobileLayout(Game game) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
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
                child: GameDetailContent(
                  game: game,
                  onNavigate: _handleNavigate, // Pass the navigation handler
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            EditButton(
              game: game,
              onEditComplete: _refreshGameDetails,
            ),
            const SizedBox(width: 16.0),
            LikeButton(
              game: game,
              gameService: _gameService,
              onLikeChanged: _handleLikeChanged,
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
              onLikeChanged: _handleLikeChanged,
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
        key: ValueKey('game_detail_content_${_refreshCounter}'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GameDetailContent(
            game: game,
            onNavigate: _handleNavigate, // Pass the navigation handler
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameId == null) {
      return const CustomErrorWidget(errorMessage: '无效的游戏ID');
    }

    if (_isLoading) {
      return LoadingWidget.fullScreen(message: '加载中...');
    }

    if (_error != null) {
      if (_error == 'not_found') {
        return NotFoundErrorWidget(onBack: _loadGameDetails);
      } else if (_error == 'network_error') {
        return NetworkErrorWidget(onRetry: _loadGameDetails);
      }
      else {
        return CustomErrorWidget(errorMessage: _error, onRetry: _loadGameDetails);
      }
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop ? _buildDesktopLayout(_game!) : _buildMobileLayout(_game!);
  }
}