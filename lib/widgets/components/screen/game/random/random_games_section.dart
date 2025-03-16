import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import '../../../../common/image/safe_cached_image.dart';

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
  bool _isMounted = false; // 添加一个变量跟踪组件挂载状态

  @override
  void initState() {
    super.initState();
    _isMounted = true; // 设置组件为已挂载
    _loadRandomGames();
  }

  @override
  void dispose() {
    _isMounted = false; // 组件销毁时标记为未挂载
    super.dispose();
  }

  Future<void> _loadRandomGames() async {
    if (!_isMounted) return; // 检查组件是否仍然挂载

    setState(() {
      _isLoading = true;
    });

    try {
      final games = await _gameService.getRandomGames(
        limit: 3,
        excludeId: widget.currentGameId,
      );

      // 检查组件是否仍然挂载，防止在setState前组件已销毁
      if (!_isMounted) return;

      setState(() {
        _randomGames = games;
        _isLoading = false;
      });
    } catch (e) {
      // 检查组件是否仍然挂载，防止在setState前组件已销毁
      if (!_isMounted) return;

      setState(() {
        _isLoading = false;
      });
      print('Error loading random games: $e');
    }
  }

  // 添加一个安全的setState方法
  void setStateIfMounted(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 4/3,
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
                    child: SafeCachedImage(
                      imageUrl: game.coverImage,
                      fit: BoxFit.cover,
                      memCacheWidth: 320,
                      // 使用空的错误处理器避免错误级联
                      onError: (url, error) {
                        // 仅在组件仍然挂载时记录错误
                        if (_isMounted) {
                          print('随机游戏图片加载失败: $url, 错误: $error');
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 40),
                child: Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.2,
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
              height: 190,
              child: _randomGames.isEmpty
                  ? const Center(child: Text('暂无推荐游戏'))
                  : ListView.builder(
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