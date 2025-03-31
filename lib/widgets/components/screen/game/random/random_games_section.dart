import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import 'random_game_card.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRandomGames() async {
    // 使用内建的 mounted 属性
    if (!mounted) return; // 检查是否挂载

    setState(() {
      _isLoading = true;
    });

    try {
      final games = await _gameService.getRandomGames(
        limit: 5,
        excludeId: widget.currentGameId,
      );

      // ----> 关键修改点 (用 mounted 替换 _isMounted) <----
      if (!mounted) return; // 在 await 后、setState 前检查

      setState(() {
        _randomGames = games;
        _isLoading = false;
      });
    } catch (e) {
      // ----> 关键修改点 (用 mounted 替换 _isMounted) <----
      if (!mounted) return; // 在 catch 块内的 setState 前检查

      setState(() {
        _isLoading = false;
      });
      print('Error loading random games: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_randomGames.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取屏幕宽度以计算卡片宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    // 调整卡片宽度和边距
    final double cardWidth = isDesktop ? 180.0 : 140.0;
    final double cardMargin = 12.0;
    final double sectionHeight = isDesktop ? 200.0 : 180.0;

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
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

          // 游戏列表 - 固定高度
          SizedBox(
            height: sectionHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _randomGames.length,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(right: index < _randomGames.length - 1 ? cardMargin : 0),
                  child: RandomGameCard(
                    game: _randomGames[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}