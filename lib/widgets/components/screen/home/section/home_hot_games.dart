// lib/widgets/components/screen/home/section/home_hot_games.dart

/// 该文件定义了 HomeHotGames 组件，用于显示主页的热门游戏板块。
/// HomeHotGames 包含加载、错误、空状态和正常显示游戏卡片列表的逻辑。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 动画组件
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 空状态组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由
import 'home_game_card.dart'; // 主页游戏卡片组件
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类

/// `HomeHotGames` 类：主页热门游戏板块组件。
///
/// 该组件负责展示热门游戏，并处理加载、错误和空状态。
class HomeHotGames extends StatelessWidget {
  final List<Game>? games; // 热门游戏列表
  final bool isLoading; // 是否正在加载
  final double screenWidth; // 屏幕宽度
  final String? errorMessage; // 错误消息
  final VoidCallback? onRetry; // 重试回调
  final PageController pageController; // 页面控制器
  final int currentPage; // 当前页码
  final ValueChanged<int> onPageChanged; // 页面变化回调
  final bool playInitialAnimation; // 是否播放初始动画
  final ValueChanged<bool> onUserInteraction; // 用户交互回调

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [games]：热门游戏列表。
  /// [isLoading]：是否正在加载。
  /// [screenWidth]：屏幕宽度。
  /// [errorMessage]：错误消息。
  /// [onRetry]：重试回调。
  /// [pageController]：页面控制器。
  /// [currentPage]：当前页码。
  /// [onPageChanged]：页面变化回调。
  /// [playInitialAnimation]：是否播放初始动画。
  /// [onUserInteraction]：用户交互回调。
  const HomeHotGames({
    super.key,
    required this.games,
    required this.isLoading,
    required this.screenWidth,
    this.errorMessage,
    this.onRetry,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    this.playInitialAnimation = true,
    required this.onUserInteraction,
  });

  static const double cardWidth = 160.0; // 卡片宽度
  static const double cardMargin = 16.0; // 卡片外边距
  static const double containerHeight = 210; // 容器高度

  /// 获取每页显示的卡片数量。
  ///
  /// [context]：Build 上下文。
  /// [screenWidth]：屏幕宽度。
  /// 返回每页的卡片数量。
  static int getCardsPerPage(
    BuildContext context,
    double screenWidth,
  ) {
    if (!context.mounted) return 2; // 未挂载时返回默认值
    double availableWidth = screenWidth - 32 - (8 * 2); // 计算可用宽度
    int cardsPerPage =
        (availableWidth / (HomeHotGames.cardWidth + HomeHotGames.cardMargin))
            .floor(); // 计算每页卡片数量
    return cardsPerPage < 1 ? 1 : cardsPerPage; // 至少返回 1
  }

  /// 获取总页数。
  ///
  /// [cardsPerPage]：每页卡片数量。
  /// [gamesList]：游戏列表。
  /// 返回总页数。
  static int getTotalPages(int cardsPerPage, List<Game>? gamesList) {
    if (gamesList == null || gamesList.isEmpty || cardsPerPage <= 0)
      return 0; // 无数据或无效参数时返回 0
    return (gamesList.length / cardsPerPage).ceil(); // 计算总页数
  }

  /// 构建 Widget。
  ///
  /// 根据加载、错误、空状态和正常状态渲染不同的内容。
  @override
  Widget build(BuildContext context) {
    if (isLoading && games == null) {
      // 加载状态且无数据时
      return const SizedBox(
        height: containerHeight + 80, // 固定高度
        child: LoadingWidget(message: "正在加载热门游戏..."), // 显示加载指示器
      );
    }

    if (errorMessage != null && games == null) {
      // 错误状态且无数据时
      return SizedBox(
        height: containerHeight + 80, // 固定高度
        child: FadeInSlideUpItem(
            child: InlineErrorWidget(
          // 显示错误组件
          errorMessage: errorMessage!,
          onRetry: onRetry,
        )),
      );
    }

    if (!isLoading && (games == null || games!.isEmpty)) {
      // 空状态时
      return SizedBox(
        height: containerHeight + 80, // 固定高度
        child: const FadeInSlideUpItem(
          child: EmptyStateWidget(
            // 显示空状态组件
            message: '暂无热门游戏',
            iconData: Icons.inbox_outlined,
            iconSize: 40,
            iconColor: Colors.grey,
          ),
        ),
      );
    }

    final displayGames = games ?? []; // 待显示的游戏列表
    if (!context.mounted) return const SizedBox.shrink(); // 未挂载时返回空 Widget

    final int cardsCountPerPage = getCardsPerPage(
      // 每页卡片数量
      context,
      screenWidth,
    );
    final int totalGamePages = getTotalPages(
      // 总页数
      cardsCountPerPage,
      displayGames,
    );
    int actualCardsThisPage =
        (screenWidth / (cardWidth + cardMargin)).floor(); // 当前页实际卡片数量
    actualCardsThisPage = actualCardsThisPage < 1 ? 1 : actualCardsThisPage;

    return Stack(
      children: [
        _buildSection(
          title: '热门游戏', // 板块标题
          onMorePressed: () {
            // 查看更多回调
            Navigator.pushNamed(context, AppRoutes.hotGames);
          },
          child: Stack(
            children: [
              SizedBox(
                height: containerHeight, // 固定高度
                child: NotificationListener<ScrollNotification>(
                  // 滚动通知监听器
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollStartNotification) {
                      // 用户开始拖动
                      if (notification.dragDetails != null) {
                        onUserInteraction(true); // 触发用户交互回调
                      }
                    } else if (notification is ScrollEndNotification) {
                      // 用户结束拖动
                      if (notification.dragDetails == null) {}
                      onUserInteraction(false); // 触发用户交互回调
                    }
                    return false; // 继续向上传播通知
                  },
                  child: PageView.builder(
                    // 页面视图
                    controller: pageController, // 页面控制器
                    itemCount: totalGamePages, // 页面数量
                    onPageChanged: onPageChanged, // 页面变化回调
                    itemBuilder: (context, pageIndex) {
                      if (!context.mounted)
                        return const SizedBox.shrink(); // 未挂载时返回空 Widget
                      final startIndex =
                          pageIndex * cardsCountPerPage; // 当前页的起始索引
                      List<Widget> cardWidgets = []; // 卡片 Widget 列表
                      for (int i = 0; i < actualCardsThisPage; i++) {
                        final gameIndex = startIndex + i;
                        if (gameIndex >= displayGames.length) break; // 索引越界时跳出
                        cardWidgets.add(
                          HomeGameCard(
                            game: displayGames[gameIndex],
                          ),
                        );
                      }
                      return Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 8), // 水平外边距
                        child: Center(
                          child: Wrap(
                            // 自动换行布局
                            spacing: cardMargin, // 水平间距
                            runSpacing: cardMargin, // 垂直间距
                            alignment: WrapAlignment.center, // 对齐方式
                            children: cardWidgets, // 卡片列表
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (totalGamePages > 1) // 页数大于 1 时显示导航按钮
                _buildNavigationButtons(context, totalGamePages),
            ],
          ),
        ),
        if (isLoading && displayGames.isNotEmpty) // 加载中且有数据时显示加载指示器
          Positioned.fill(
            child: Container(
              color: Colors.black.withSafeOpacity(0.1), // 半透明背景
              child: const LoadingWidget(size: 30), // 加载指示器
            ),
          ),
      ],
    );
  }

  /// 构建导航按钮。
  ///
  /// [context]：Build 上下文。
  /// [totalGamePages]：总页数。
  /// 返回包含上一页和下一页按钮的 Widget。
  Widget _buildNavigationButtons(BuildContext context, int totalGamePages) {
    final isDesktop =
        DeviceUtils.isDesktopInThisWidth(screenWidth); // 判断是否为桌面宽度
    final buttonSize = !isDesktop ? 32.0 : 40.0; // 按钮尺寸
    final iconSize = !isDesktop ? 18.0 : 24.0; // 图标尺寸
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 主轴对齐
          children: [
            _buildNavigationButton(
              // 上一页按钮
              icon: Icons.arrow_back_ios_new,
              onPressed: (isLoading || currentPage <= 0) // 根据状态禁用按钮
                  ? null
                  : () {
                      if (pageController.hasClients) {
                        pageController.previousPage(
                            // 切换到上一页
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut);
                      }
                    },
              buttonSize: buttonSize,
              iconSize: iconSize,
            ),
            _buildNavigationButton(
              // 下一页按钮
              icon: Icons.arrow_forward_ios,
              onPressed:
                  (isLoading || currentPage >= totalGamePages - 1) // 根据状态禁用按钮
                      ? null
                      : () {
                          if (pageController.hasClients) {
                            pageController.nextPage(
                              // 切换到下一页
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOut,
                            );
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

  /// 构建单个导航按钮。
  ///
  /// [icon]：图标。
  /// [onPressed]：点击回调。
  /// [buttonSize]：按钮尺寸。
  /// [iconSize]：图标尺寸。
  /// 返回一个圆形背景的 IconButton。
  Widget _buildNavigationButton({
    required IconData icon,
    VoidCallback? onPressed,
    required double buttonSize,
    required double iconSize,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // 水平外边距
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: onPressed == null // 根据是否可用设置背景色
            ? Colors.black.withSafeOpacity(0.1)
            : Colors.black.withSafeOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero, // 无内边距
        alignment: Alignment.center, // 居中对齐
        icon: Icon(icon, // 图标
            color: onPressed == null // 根据是否可用设置图标颜色
                ? Colors.white.withSafeOpacity(0.5)
                : Colors.white,
            size: iconSize),
        onPressed: onPressed, // 点击回调
        splashRadius: buttonSize / 2, // 水波纹半径
        tooltip: icon == Icons.arrow_back_ios_new ? '上一页' : '下一页', // 提示文本
      ),
    );
  }

  /// 构建板块。
  ///
  /// [title]：板块标题。
  /// [child]：板块内容。
  /// [onMorePressed]：查看更多回调。
  /// 返回一个包含标题和内容的 Column Widget。
  Widget _buildSection({
    required String title,
    required Widget child,
    required VoidCallback onMorePressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8), // 垂直内边距
          child: Row(
            children: [
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFF1890FF), // 装饰条颜色
                    borderRadius: BorderRadius.circular(3)), // 装饰条圆角
              ),
              const SizedBox(width: 12), // 间距
              Text(
                title, // 标题
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const Spacer(), // 占据剩余空间
              InkWell(
                borderRadius: BorderRadius.circular(8), // 圆角
                onTap: onMorePressed, // 点击回调
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4), // 内边距
                  child: const Row(
                    children: [
                      Text('更多'), // 文本
                      SizedBox(width: 4), // 间距
                      Icon(Icons.arrow_forward_ios, size: 14) // 图标
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // 间距
        child, // 板块内容
      ],
    );
  }
}
