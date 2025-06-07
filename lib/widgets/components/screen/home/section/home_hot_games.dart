// lib/widgets/components/screen/home/section/home_hot_games.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'home_game_card.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

// 改为 StatelessWidget
class HomeHotGames extends StatelessWidget {
  final List<Game>? games;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final PageController pageController; // 由 HomeScreen 传入和管理
  final int currentPage; // 当前页码，由 HomeScreen 传入
  final ValueChanged<int> onPageChanged; // 页面变化回调给 HomeScreen
  final bool playInitialAnimation; // 控制首次加载动画
  final ValueChanged<bool> onUserInteraction;

  const HomeHotGames({
    super.key,
    required this.games,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    this.playInitialAnimation = true, // 默认为 true
    required this.onUserInteraction, // 接收回调
  });

  static const double cardWidth = 160.0;
  static const double cardMargin = 16.0;
  static const double containerHeight = 210;

  // 辅助方法移到这里，因为它们是纯计算
  static int getCardsPerPage(BuildContext context) {
    if (!context.mounted) return 2;
    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth =
        screenWidth - 32 - (8 * 2); // 32是父级padding, 8*2是PageView内部margin
    int cardsPerPage = (availableWidth / (cardWidth + cardMargin)).floor();
    return cardsPerPage < 1 ? 1 : cardsPerPage;
  }

  static int getTotalPages(int cardsPerPage, List<Game>? gamesList) {
    if (gamesList == null || gamesList.isEmpty || cardsPerPage <= 0) return 0;
    return (gamesList.length / cardsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 加载状态 (如果 games 为 null 且在加载中)
    if (isLoading && games == null) {
      return SizedBox(
        height: containerHeight + 80, // 保持和之前一致的高度
        child: LoadingWidget.inline(message: "正在加载热门游戏..."),
      );
    }

    // 2. 错误状态 (如果 games 为 null 且有错误信息)
    if (errorMessage != null && games == null) {
      return SizedBox(
        height: containerHeight + 80,
        child: FadeInSlideUpItem(
            // 可以保留动画
            child: InlineErrorWidget(
          errorMessage: errorMessage!,
          onRetry: onRetry, // 使用 HomeScreen 传递的 onRetry
        )),
      );
    }

    // 3. 空状态 (非加载中，无错误，但数据为空或null)
    // 注意：这里 games 可能为 null，即使 isLoading 为 false，表示加载完成但无数据
    if (!isLoading && (games == null || games!.isEmpty)) {
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
    final displayGames = games ?? []; // 使用 HomeScreen 传来的数据
    if (!context.mounted) return const SizedBox.shrink();

    final int cardsCountPerPage =
        getCardsPerPage(context); // 动态计算或由 HomeScreen 传入
    final int totalGamePages = getTotalPages(
      cardsCountPerPage,
      displayGames,
    );

    return Stack(
      children: [
        _buildSection(
          title: '热门游戏',
          onMorePressed: () {
            Navigator.pushNamed(context, AppRoutes.hotGames);
          },
          child: Stack(
            children: [
              SizedBox(
                height: containerHeight,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollStartNotification) {
                      // 用户开始拖动
                      if (notification.dragDetails != null) {
                        // 确保是用户拖拽触发的
                        onUserInteraction(true);
                      }
                    } else if (notification is ScrollEndNotification) {
                      // 用户结束拖动
                      if (notification.dragDetails == null) {
                        // 确保是拖拽结束，而不是程序化滚动结束
                      }
                      // HomeScreen 那边会处理计时器的重置
                      onUserInteraction(false);
                    }
                    return false; // false 表示继续向上传播通知
                  },
                  child: PageView.builder(
                    controller: pageController, // 使用 HomeScreen 传入的 controller
                    itemCount: totalGamePages,
                    onPageChanged: onPageChanged, // 回调给 HomeScreen
                    itemBuilder: (context, pageIndex) {
                      final startIndex = pageIndex * cardsCountPerPage;
                      if (!context.mounted) return const SizedBox.shrink();
                      return Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 8), // PageView item 的边距
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (!context.mounted) {
                              return const SizedBox.shrink();
                            }
                            double availableWidth = constraints.maxWidth;
                            int actualCardsThisPage =
                                (availableWidth / (cardWidth + cardMargin))
                                    .floor();
                            actualCardsThisPage = actualCardsThisPage < 1
                                ? 1
                                : actualCardsThisPage;

                            List<Widget> cardWidgets = [];
                            for (int i = 0; i < actualCardsThisPage; i++) {
                              final gameIndex = startIndex + i;
                              if (gameIndex >= displayGames.length) break;
                              cardWidgets.add(
                                HomeGameCard(
                                  game: displayGames[gameIndex],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.gameDetail,
                                    arguments: displayGames[gameIndex],
                                  ),
                                ),
                              );
                            }
                            return Center(
                              child: Wrap(
                                spacing: cardMargin,
                                runSpacing: cardMargin,
                                alignment: WrapAlignment.center,
                                children: cardWidgets,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (totalGamePages > 1)
                _buildNavigationButtons(context, totalGamePages),
            ],
          ),
        ),
        // 加载指示器 (如果正在加载且有数据显示)
        if (isLoading && displayGames.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withSafeOpacity(0.1),
              child: LoadingWidget.inline(size: 30),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, int totalGamePages) {
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
              // isLoading 也由 HomeScreen 控制，如果 HomeScreen 在加载，按钮也应禁用
              onPressed: (isLoading || currentPage <= 0)
                  ? null
                  : () {
                      if (pageController.hasClients) {
                        pageController.previousPage(
                            duration: Duration(milliseconds: 800),
                            curve: Curves.easeInOut);
                      }
                    },
              buttonSize: buttonSize,
              iconSize: iconSize,
            ),
            _buildNavigationButton(
              icon: Icons.arrow_forward_ios,
              onPressed: (isLoading || currentPage >= totalGamePages - 1)
                  ? null
                  : () {
                      if (pageController.hasClients) {
                        pageController.nextPage(
                            duration: Duration(milliseconds: 800),
                            curve: Curves.easeInOut);
                      }
                    },
              buttonSize: buttonSize,
              iconSize: iconSize,
            ),
          ],
        ),
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
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: onPressed == null
            ? Colors.black.withSafeOpacity(0.1)
            : Colors.black.withSafeOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        icon: Icon(icon,
            color: onPressed == null
                ? Colors.white.withSafeOpacity(0.5)
                : Colors.white,
            size: iconSize),
        onPressed: onPressed,
        splashRadius: buttonSize / 2,
        tooltip: icon == Icons.arrow_back_ios_new ? '上一页' : '下一页',
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required VoidCallback onMorePressed,
    // context 不再需要作为参数，因为 StatelessWidget 可以直接访问
  }) {
    // 获取 context 的 Theme
    // final theme = Theme.of(context); // 如果需要用 Theme.of(context)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          // decoration: BoxDecoration(...) // 如果需要边框
          child: Row(
            children: [
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                    // color: theme.primaryColor, // 示例
                    color: Color(0xFF1890FF), // 假设一个主色调
                    borderRadius: BorderRadius.circular(3)),
              ),
              SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900])),
              Spacer(),
              InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onMorePressed,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(children: [
                        Text('更多'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 14)
                      ]))),
            ],
          ),
        ),
        SizedBox(height: 16),
        child,
      ],
    );
  }
}
