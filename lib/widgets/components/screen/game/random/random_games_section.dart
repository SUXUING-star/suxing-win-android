import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'random_game_card.dart';

class RandomGamesSection extends StatefulWidget {
  final String currentGameId;
  final GameService gameService;

  const RandomGamesSection({
    super.key,
    required this.currentGameId,
    required this.gameService,
  });

  @override
  _RandomGamesSectionState createState() => _RandomGamesSectionState();
}

class _RandomGamesSectionState extends State<RandomGamesSection> {
  List<Game> _randomGames = [];
  bool _isLoading = true;
  bool _hasInitializedDependencies = false;
  late String _currentGameId;
  String? _errMsg;

  @override
  void initState() {
    super.initState();
    _errMsg = null;
    _currentGameId = widget.currentGameId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadRandomGames();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _errMsg = null;
  }

  @override
  void didUpdateWidget(covariant RandomGamesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentGameId != widget.currentGameId ||
        oldWidget.currentGameId != widget.currentGameId) {
      setState(() {
        _currentGameId = widget.currentGameId;
      });
      _loadRandomGames();
    }
  }

  Future<void> _loadRandomGames() async {
    // 使用内建的 mounted 属性
    if (!mounted) return; // 检查是否挂载

    setState(() {
      _isLoading = true;
      _errMsg = null;
    });

    try {
      final games = await widget.gameService.getRandomGames(
        excludeId: widget.currentGameId,
      );

      if (!mounted) return; // 在 await 后、setState 前检查

      setState(() {
        _randomGames = games;
        _isLoading = false;
        _errMsg = null;
      });
    } catch (e) {
      if (!mounted) return; // 在 catch 块内的 setState 前检查

      setState(() {
        _isLoading = false;
        _errMsg = e.toString();
      });
      // print('Error loading random games: $e');
    }
  }

  void _handleRetry() {
    if (!mounted) return;

    _loadRandomGames();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingWidget.inline(
        size: 24,
      );
    }
    if (_errMsg != null) {
      return InlineErrorWidget(
        onRetry: () => _handleRetry(),
        retryText: "尝试重试",
        errorMessage: _errMsg,
      );
    }

    if (_randomGames.isEmpty) {
      return const EmptyStateWidget(message: "暂无推荐");
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
            color: Colors.black.withSafeOpacity(0.05),
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
                  margin: EdgeInsets.only(
                      right: index < _randomGames.length - 1 ? cardMargin : 0),
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
