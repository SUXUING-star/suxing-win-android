// lib/widgets/components/screen/home/section/home_hot.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'dart:async';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import '../../../../../../routes/app_routes.dart';
import 'home_game_card.dart';
import '../../../../../utils/device/device_utils.dart';

// --- 结束引入 ---

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

  List<Game>? _cachedGames;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialLoading = true; // 新增：控制卡片动画

  static const double cardWidth = 160.0;
  static const double cardMargin = 16.0;
  static const double containerHeight = 210;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    // initState 不直接加载，等待 didChangeDependencies 或 didUpdateWidget
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首次构建或依赖变化时，如果没数据且未加载，则加载
    if (_cachedGames == null && !_isLoading) {
      _loadGames();
    }
  }

  @override
  void didUpdateWidget(HomeHot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 流变化时重新加载
    if (widget.gamesStream != oldWidget.gamesStream) {
      _isInitialLoading = true; // 重置动画标志
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
    if (!mounted) return; // 增加检查

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // 不重置 _isInitialLoading，除非是流变化触发
    });

    Stream<List<Game>>? streamToUse =
        widget.gamesStream ?? _gameService.getHotGames();

    streamToUse.first.then((games) {
      if (mounted) {
        setState(() {
          _cachedGames = games;
          _isLoading = false;
          if (_isInitialLoading) _isInitialLoading = false; // 加载完成，首次动画条件满足
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败：$error';
          _isLoading = false;
          _isInitialLoading = false; // 加载失败也结束首次加载状态
        });
      }
    });
  }

  // _startAutoScroll, _getCardsPerPage, _getTotalPages 保持不变
  void _startAutoScroll() {
    _timer?.cancel(); // 先取消旧的 timer
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_pageController.hasClients ||
          _cachedGames == null ||
          _cachedGames!.isEmpty) {
        return;
      }
      // 自动滚动逻辑... (保持不变)
      final currentPage = (_pageController.page ?? 0).round();
      // 使用 context 安全地获取 MediaQuery
      if (!context.mounted) return;
      final cardsPerPage = _getCardsPerPage(context);
      final totalPages = _getTotalPages(cardsPerPage, _cachedGames!);

      if (currentPage >= totalPages - 1) {
        // 动画滚动到第一页
        _pageController.animateToPage(0,
            duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      } else {
        _pageController.nextPage(
            duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }

  int _getCardsPerPage(BuildContext context) {
    // 确保 context 仍然有效
    if (!context.mounted) return 2; // 返回默认值或合适的值
    double screenWidth = MediaQuery.of(context).size.width;
    // 减去 HomeHot 组件可能的左右 padding (假设是 16*2)
    double availableWidth =
        screenWidth - 32 - (8 * 2); // 再减去 PageView 内部的 margin
    int cardsPerPage = (availableWidth / (cardWidth + cardMargin)).floor();
    return cardsPerPage < 1 ? 1 : cardsPerPage; // 至少显示1个
  }

  int _getTotalPages(int cardsPerPage, List<Game> games) {
    if (games.isEmpty || cardsPerPage <= 0)
      return 0; // 处理 cardsPerPage 为 0 或负数的情况
    return (games.length / cardsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    // --- 修改这里：为不同状态添加动画 ---
    // 1. 加载状态
    if (_isLoading && _cachedGames == null) {
      // 保持容器高度，避免页面跳动
      return SizedBox(
        height: containerHeight + 80, // 加上标题和间距的高度估算值
        child: LoadingWidget.inline(message: "正在加载"),
      );
    }

    // 2. 错误状态
    if (_errorMessage != null) {
      return SizedBox(
        height: containerHeight + 80,
        child: FadeInSlideUpItem(child: _buildError(_errorMessage!)),
      );
    }

    // 3. 空状态
    if (_cachedGames == null || _cachedGames!.isEmpty) {
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
    // --- 结束修改 ---

    // 4. 正常显示内容
    final games = _cachedGames!;
    // 确保 context 有效再计算
    if (!context.mounted) return SizedBox.shrink();
    final cardsPerPage = _getCardsPerPage(context);
    final totalPages = _getTotalPages(cardsPerPage, games);

    // 整个 Section 的动画由 HomeScreen 控制，这里动画化内部元素
    return _buildSection(
      title: '热门游戏',
      onMorePressed: () {
        NavigationUtils.pushNamed(context, AppRoutes.hotGames);
      },
      // --- 修改这里：PageView 内容添加动画 ---
      child: Stack(
        children: [
          Container(
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
                // 确保 context 有效
                if (!context.mounted) return SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (!context.mounted) return SizedBox.shrink();
                      double availableWidth = constraints.maxWidth;
                      // 重新计算实际每页卡片数
                      int actualCardsPerPage =
                          (availableWidth / (cardWidth + cardMargin)).floor();
                      actualCardsPerPage =
                          actualCardsPerPage < 1 ? 1 : actualCardsPerPage;

                      List<Widget> cardWidgets = [];
                      for (int index = 0; index < actualCardsPerPage; index++) {
                        final gameIndex = startIndex + index;
                        if (gameIndex >= games.length) {
                          // cardWidgets.add(SizedBox(width: cardWidth)); // 占位符不需要动画
                        } else {
                          // *** 修改这里：为 HomeGameCard 添加动画 ***
                          cardWidgets.add(
                            FadeInSlideUpItem(
                              // 首次加载时应用交错动画，否则直接出现 (无延迟)
                              delay: _isInitialLoading
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
                          // *** 结束修改 ***
                        }
                      }

                      // 使用 Wrap 确保间距正确且居中
                      return Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: cardMargin,
                          runSpacing: cardMargin, // 如果卡片可能换行
                          children: cardWidgets,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // 导航按钮保持不变，不需要动画
          if (totalPages > 1) _buildNavigationButtons(totalPages),
        ],
      ),
      // --- 结束修改 ---
    );
  }

  // _buildNavigationButtons, _buildNavigationButton, _buildSection, _buildError 保持不变
  Widget _buildNavigationButtons(int totalPages) {
    // 样式根据平台决定，保持不变
    final buttonSize = DeviceUtils.isAndroid ? 32.0 : 40.0;
    final iconSize = DeviceUtils.isAndroid ? 18.0 : 24.0;
    return Positioned.fill(
      // 使用 Positioned.fill 简化布局
      child: Align(
        // 使用 Align 控制按钮位置（可选）
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavigationButton(
              icon: Icons.arrow_back_ios_new, // 使用更新的图标
              onPressed: _currentPage > 0
                  ? () => _pageController.previousPage(
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeInOut)
                  : null,
              buttonSize: buttonSize, iconSize: iconSize,
            ),
            _buildNavigationButton(
              icon: Icons.arrow_forward_ios,
              onPressed: _currentPage < totalPages - 1
                  ? () => _pageController.nextPage(
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeInOut)
                  : null,
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
      margin: EdgeInsets.symmetric(horizontal: 4), // 调整按钮外边距
      width: buttonSize, height: buttonSize,
      decoration: BoxDecoration(
        color: onPressed == null
            ? Colors.grey.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero, // 去除默认 padding
        alignment: Alignment.center, // 确保图标居中
        icon: Icon(icon, color: Colors.white, size: iconSize),
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
    // 标题和更多按钮的布局保持不变
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8), // 保持内边距
          // 移除底部边框，让 Section 之间只有间距
          // decoration: BoxDecoration( border: Border( bottom: BorderSide(...) ) ),
          child: Row(
            children: [
              Container(
                  /* 左侧装饰条 */ width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(3))),
              SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900])),
              Spacer(),
              InkWell(
                  /* 更多按钮 */ borderRadius: BorderRadius.circular(8),
                  onTap: onMorePressed,
                  child: Padding(
                      /* ... */ padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(children: [
                        Text('更多'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 14)
                      ]))),
            ],
          ),
        ),
        SizedBox(height: 16), // 标题和内容之间的间距
        child, // 包含 PageView 的子 Widget
      ],
    );
  }

  Widget _buildError(String message) {
    // 错误显示保持不变
    return InlineErrorWidget(
        icon: Icons.error_outline,
        iconSize: 40,
        iconColor: Colors.red,
        errorMessage: message,
        onRetry: _loadGames); // 添加重试按钮
  }
}
