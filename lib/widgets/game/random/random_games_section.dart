import 'package:flutter/material.dart';
import '../../../models/game.dart';
import '../../../services/game_service.dart';

class RandomGamesSection extends StatefulWidget {
  final String currentGameId;

  const RandomGamesSection({
    Key? key,
    required this.currentGameId,
  }) : super(key: key);

  @override
  _RandomGamesSectionState createState() => _RandomGamesSectionState();
}

class _RandomGamesSectionState extends State<RandomGamesSection> {
  final GameService _gameService = GameService();
  List<Game> _randomGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRandomGames();
  }

  Future<void> _loadRandomGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final games = await _gameService.getRandomGames(
        limit: 3,
        excludeId: widget.currentGameId,
      );
      setState(() {
        _randomGames = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading random games: $e');
    }
  }

  Widget _buildGameCard(Game game) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushReplacementNamed(
            context,
            '/game/detail',
            arguments: game.id,
          );
        },
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          // 移除 Column 的 height 限制，让它自然扩展
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 添加这个确保列只占用必要的空间
            children: [
              AspectRatio(
                aspectRatio: 4/3, // 使用固定的宽高比
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      game.coverImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 40), // 限制标题最大高度
                child: Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.2, // 减小行高
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.thumb_up,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    game.likeCount.toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_randomGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: 0.9,
      child: Container(
        //margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '猜你喜欢',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190, // 增加容器高度
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _randomGames.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  return _buildGameCard(_randomGames[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}