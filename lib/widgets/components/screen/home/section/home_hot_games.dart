// lib/widgets/components/screen/home/section/home_hot_games.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'dart:async';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart'; // 引入 Service
import '../../../../../../routes/app_routes.dart';
import 'home_game_card.dart';
import '../../../../../utils/device/device_utils.dart';

class HomeHotGames extends StatefulWidget {
  // 移除 Stream 参数
  const HomeHotGames({super.key}); // 使用 Key
  @override
  _HomeHotGamesState createState() => _HomeHotGamesState();
}

class _HomeHotGamesState extends State<HomeHotGames> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  // 恢复内部状态
  List<Game>? _cachedGames;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialLoading = true; // 控制动画

  // 用于自动滚动的最新游戏列表缓存
  List<Game>? _latestGamesForAutoScroll; // 这个也需要更新

  static const double cardWidth = 160.0;
  static const double cardMargin = 16.0;
  static const double containerHeight = 210;

  @override
  void initState() {
    super.initState();
    print("HomeHotGames initState triggered (Key: ${widget.key})"); // Debug log
    _fetchData(); // initState 获取数据
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 获取数据的 Future 方法
  Future<void> _fetchData() async {
    if (!mounted) return;
    if (_isLoading) {
      print("HomeHotGames _fetchData called while loading, ignoring.");
      return;
    }
    print("HomeHotGames _fetchData called");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isInitialLoading = true;
    });

    try {
      // *** 核心：调用 Service 的 Stream 方法，并用 .first 获取 Future<List<Game>> ***
      final gameService = context.read<GameService>();
      final games = await gameService.getHotGames();

      if (mounted) {
        if (games.isNotEmpty){
          setState(() {
            _cachedGames = games;
            _latestGamesForAutoScroll = games; // 更新给自动滚动
            _isInitialLoading = false;
            if (_pageController.hasClients && _pageController.page != 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pageController.hasClients) {
                  _pageController.jumpToPage(0);
                  setState(() { _currentPage = 0; });
                }
              });
            }
          });
        }else{
          _errorMessage = "加载发生错误";
          setState(() {
            _isLoading= true;
            _isInitialLoading = true;
          });
        }

      }
    } catch (error, stackTrace) {
      print("HomeHotGames _fetchData error: $error\n$stackTrace");
      if (mounted) {
        setState(() {
          _errorMessage = '加载热门游戏失败'; // 简化错误信息
          _isInitialLoading = false;
          _cachedGames = null;
          _latestGamesForAutoScroll = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 确保 isLoading 被重置
        });
      }
    }
  }

  // _startAutoScroll, _getCardsPerPage, _getTotalPages 保持不变，使用 _latestGamesForAutoScroll
  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) { timer.cancel(); return; }
      if (!_pageController.hasClients ||
          _latestGamesForAutoScroll == null || // 使用这个变量
          _latestGamesForAutoScroll!.isEmpty) { return; }

      final currentPage = (_pageController.page ?? 0).round();
      if (!context.mounted) return;

      final cardsPerPage = _getCardsPerPage(context);
      final totalPages = _getTotalPages(cardsPerPage, _latestGamesForAutoScroll!); // 使用这个变量
      if (totalPages <= 1) return;

      if (currentPage >= totalPages - 1) {
        _pageController.animateToPage(0, duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      } else {
        _pageController.nextPage(duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }
  int _getCardsPerPage(BuildContext context) {
    if (!context.mounted) return 2;
    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth = screenWidth - 32 - (8 * 2);
    int cardsPerPage = (availableWidth / (cardWidth + cardMargin)).floor();
    return cardsPerPage < 1 ? 1 : cardsPerPage;
  }
  int _getTotalPages(int cardsPerPage, List<Game> games) {
    if (games.isEmpty || cardsPerPage <= 0) return 0;
    return (games.length / cardsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    // 移除 StreamBuilder，使用内部状态构建 UI

    // 1. 加载状态
    if (_isLoading && _cachedGames == null) { // 首次加载时显示
      return SizedBox(
        height: containerHeight + 80,
        child: LoadingWidget.inline(message: "正在加载热门游戏..."),
      );
    }

    // 2. 错误状态
    if (_errorMessage != null && _cachedGames == null) { // 错误且无数据显示错误
      return SizedBox(
        height: containerHeight + 80,
        child: FadeInSlideUpItem(
            child: InlineErrorWidget(
              errorMessage: _errorMessage!,
              onRetry: _fetchData,
            )
        ),
      );
    }

    // 3. 空状态 (非加载中，无错误，但数据为空)
    if (!_isLoading && (_cachedGames == null || _cachedGames!.isEmpty)) {
      return SizedBox(
        height: containerHeight + 80,
        child: FadeInSlideUpItem(
          child: EmptyStateWidget(
              message: '暂无热门游戏',
              iconData: Icons.inbox_outlined,
              iconSize: 40,
              iconColor: Colors.grey),
        ),
      );
    }

    // 4. 正常显示内容 (即使在加载中，如果有旧数据也显示)
    final games = _cachedGames ?? []; // 使用缓存数据，如果为 null 则用空列表
    if (!context.mounted) return SizedBox.shrink();
    final cardsPerPage = _getCardsPerPage(context);
    final totalPages = _getTotalPages(cardsPerPage, games);

    // --- UI 构建逻辑基本不变，使用 games 和 _isInitialLoading ---
    return Stack( // 用 Stack 可以在列表上层显示 Loading 指示器
      children: [
        _buildSection(
          title: '热门游戏',
          onMorePressed: () {
            NavigationUtils.pushNamed(context, AppRoutes.hotGames);
          },
          child: Stack(
            children: [
              SizedBox(
                height: containerHeight,
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
                    if (!context.mounted) return SizedBox.shrink();
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (!context.mounted) return SizedBox.shrink();
                          double availableWidth = constraints.maxWidth;
                          int actualCardsPerPage =
                          (availableWidth / (cardWidth + cardMargin)).floor();
                          actualCardsPerPage =
                          actualCardsPerPage < 1 ? 1 : actualCardsPerPage;

                          List<Widget> cardWidgets = [];
                          for (int index = 0; index < actualCardsPerPage; index++) {
                            final gameIndex = startIndex + index;
                            if (gameIndex >= games.length) {
                              break;
                            } else {
                              cardWidgets.add(
                                FadeInSlideUpItem(
                                  delay: _isInitialLoading // 使用状态控制动画
                                      ? Duration(milliseconds: 50 * index)
                                      : Duration.zero,
                                  duration: Duration(milliseconds: 300),
                                  child: HomeGameCard(
                                    game: games[gameIndex],
                                    onTap: () => NavigationUtils.pushNamed(
                                      context,
                                      AppRoutes.gameDetail,
                                      arguments: games[gameIndex],
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                          // 如果卡片数量不足一页，可以添加占位符或调整对齐
                          return Center( child: Wrap(spacing: cardMargin, runSpacing: cardMargin, alignment: WrapAlignment.center, children: cardWidgets));
                        },
                      ),
                    );
                  },
                ),
              ),
              if (totalPages > 1) _buildNavigationButtons(totalPages),
            ],
          ),
        ),
        // --- 加载指示器 (如果正在加载且有数据显示) ---
        if (_isLoading && _cachedGames != null && _cachedGames!.isNotEmpty)
          Positioned.fill(
              child: Container(
                  color: Colors.black.withSafeOpacity(0.1),
                  child: Center(child: LoadingWidget.inline(size: 30))
              )
          ),
      ],
    );
  }

  // _buildNavigationButtons, _buildNavigationButton, _buildSection 保持不变
  Widget _buildNavigationButtons(int totalPages) {
    final buttonSize = DeviceUtils.isAndroid ? 32.0 : 40.0;
    final iconSize = DeviceUtils.isAndroid ? 18.0 : 24.0;
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavigationButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: (_isLoading || _currentPage <= 0) // 加载中或在第一页禁用
                  ? null
                  : () => _pageController.previousPage(duration: Duration(milliseconds: 800), curve: Curves.easeInOut),
              buttonSize: buttonSize,
              iconSize: iconSize,
            ),
            _buildNavigationButton(
              icon: Icons.arrow_forward_ios,
              onPressed: (_isLoading || _currentPage >= totalPages - 1) // 加载中或在最后一页禁用
                  ? null
                  : () => _pageController.nextPage(duration: Duration(milliseconds: 800), curve: Curves.easeInOut),
              buttonSize: buttonSize,
              iconSize: iconSize,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildNavigationButton(
      {required IconData icon,
        VoidCallback? onPressed,
        required double buttonSize,
        required double iconSize}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: buttonSize, height: buttonSize,
      decoration: BoxDecoration(
        color: onPressed == null
            ? Colors.black.withSafeOpacity(0.1)
            : Colors.black.withSafeOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        icon: Icon(
            icon,
            color: onPressed == null ? Colors.white.withSafeOpacity(0.5) : Colors.white,
            size: iconSize
        ),
        onPressed: onPressed,
        splashRadius: buttonSize / 2,
        tooltip: icon == Icons.arrow_back_ios_new ? '上一页' : '下一页',
      ),
    );
  }
  Widget _buildSection(
      {required String title,
        required Widget child,
        required VoidCallback onMorePressed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container( width: 6, height: 22, decoration: BoxDecoration( color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(3))),
              SizedBox(width: 12),
              Text(title, style: TextStyle( fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey[900])),
              Spacer(),
              InkWell( borderRadius: BorderRadius.circular(8), onTap: onMorePressed, child: Padding( padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [ Text('更多'), SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 14) ]))),
            ],
          ),
        ),
        SizedBox(height: 16),
        child,
      ],
    );
  }
}