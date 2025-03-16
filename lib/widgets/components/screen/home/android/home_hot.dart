import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import '../../../../../../routes/app_routes.dart';
import 'home_game_card.dart';
import '../../../../../utils/device/device_utils.dart';

class HomeHot extends StatefulWidget {
  final Stream<List<Game>>? gamesStream;
  const HomeHot({Key? key, this.gamesStream}) : super(key: key);
  @override
  _HomeHotState createState() => _HomeHotState();
}

class _HomeHotState extends State<HomeHot> {
  final GameService _gameService = GameService();
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  // 保存数据以避免重复请求
  List<Game>? _cachedGames;
  bool _isLoading = false;
  String? _errorMessage;

  static const double cardWidth = 160.0;
  static const double cardMargin = 16.0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 如果没有数据且未在加载，加载数据
    if (_cachedGames == null && !_isLoading) {
      _loadGames();
    }
  }

  @override
  void didUpdateWidget(HomeHot oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当流改变时重新加载数据
    if (widget.gamesStream != oldWidget.gamesStream) {
      _loadGames();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 加载游戏数据
  void _loadGames() {
    // 如果外部提供了流，使用外部流
    if (widget.gamesStream != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 从流中只取第一个事件
      widget.gamesStream!.first.then((games) {
        if (mounted) {
          setState(() {
            _cachedGames = games;
            _isLoading = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = '加载失败：$error';
            _isLoading = false;
          });
        }
      });
    }
    // 否则从本地缓存或服务获取
    else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 使用优化的getHotGames方法，利用Redis缓存
      _gameService.getHotGames().first.then((games) {
        if (mounted) {
          setState(() {
            _cachedGames = games;
            _isLoading = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = '加载失败：$error';
            _isLoading = false;
          });
        }
      });
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_pageController.hasClients || _cachedGames == null || _cachedGames!.isEmpty) {
        return;
      }

      final currentPage = (_pageController.page ?? 0).round();
      final cardsPerPage = _getCardsPerPage(context);
      final totalPages = _getTotalPages(cardsPerPage, _cachedGames!);

      if (currentPage >= totalPages - 1) {
        _pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.nextPage(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  int _getCardsPerPage(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth = screenWidth - 32; // 减去左右padding
    int cardsPerPage = (availableWidth / (cardWidth + cardMargin)).floor();
    return cardsPerPage < 2 ? 2 : cardsPerPage;
  }

  int _getTotalPages(int cardsPerPage, List<Game> games) {
    if (cardsPerPage == 0) return 0;
    return (games.length / cardsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    // 显示加载状态
    if (_isLoading && _cachedGames == null) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 显示错误
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    // 没有数据
    if (_cachedGames == null || _cachedGames!.isEmpty) {
      return _buildEmptyState('暂无热门游戏');
    }

    // 显示游戏列表
    final games = _cachedGames!;
    final cardsPerPage = _getCardsPerPage(context);
    final totalPages = _getTotalPages(cardsPerPage, games);

    return _buildSection(
      title: '热门游戏',
      onMorePressed: () {
        Navigator.pushNamed(context, AppRoutes.hotGames);
      },
      child: Stack(
        children: [
          Container(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              onPageChanged: (int page) {
                if (mounted) {
                  setState(() => _currentPage = page);
                }
              },
              itemBuilder: (context, pageIndex) {
                final startIndex = pageIndex * cardsPerPage;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8), // 减少水平边距
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(cardsPerPage, (index) {
                      final gameIndex = startIndex + index;
                      if (gameIndex >= games.length) {
                        return SizedBox(width: cardWidth + cardMargin);
                      }
                      return HomeGameCard(
                        game: games[gameIndex],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.gameDetail,
                          arguments: games[gameIndex],
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          if (totalPages > 1) _buildNavigationButtons(totalPages),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(int totalPages) {
    // 根据平台决定按钮大小
    final buttonSize = DeviceUtils.isAndroid ? 32.0 : 40.0;
    final iconSize = DeviceUtils.isAndroid ? 18.0 : 24.0;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationButton(
            icon: Icons.arrow_back_ios,
            onPressed: _currentPage > 0 ? () {
              _pageController.previousPage(
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              );
            } : null,
            buttonSize: buttonSize,
            iconSize: iconSize,
          ),
          _buildNavigationButton(
            icon: Icons.arrow_forward_ios,
            onPressed: _currentPage < totalPages - 1 ? () {
              _pageController.nextPage(
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              );
            } : null,
            buttonSize: buttonSize,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    VoidCallback? onPressed,
    required double buttonSize,
    required double iconSize,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: onPressed == null
            ? Colors.grey.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: onPressed,
        splashRadius: buttonSize / 2,
        tooltip: icon == Icons.arrow_back_ios ? '上一页' : '下一页',
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required VoidCallback onMorePressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onMorePressed,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '更多',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}