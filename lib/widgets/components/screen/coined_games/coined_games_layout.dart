// lib/widgets/components/screen/coined_games/coined_games_layout.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

/// 投币游戏展示布局
class CoinedGamesLayout extends StatelessWidget {
  // 直接改成 StatelessWidget，更简洁
  final WindowStateProvider windowStateProvider;
  final List<Game> coinedGames;
  final PaginationData? paginationData;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetryInitialLoad;
  final VoidCallback onLoadMore;
  final ScrollController scrollController;

  static const int leftFlex = 1;
  static const int rightFlex = 4;

  const CoinedGamesLayout({
    super.key,
    required this.windowStateProvider,
    required this.coinedGames,
    required this.paginationData,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    this.errorMessage,
    required this.onRetryInitialLoad,
    required this.onLoadMore,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingInitial) {
      return const FadeInItem(
        child: LoadingWidget(
          isOverlay: true,
          message: "正在查询投币记录...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    }

    if (errorMessage != null && coinedGames.isEmpty) {
      return Center(
        child: FunctionalButton(
          label: '加载失败: $errorMessage. 点击重试',
          onPressed: onRetryInitialLoad,
        ),
      );
    }

    if (coinedGames.isEmpty) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '你还没有投币过任何游戏哦',
          iconData: Icons.monetization_on_outlined,
          iconColor: Colors.grey[400],
          iconSize: 64,
        ),
      );
    }

    return LazyLayoutBuilder(
      windowStateProvider: windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return isDesktopLayout
            ? _buildDesktopLayout(context, isDesktopLayout, screenWidth)
            : _buildMobileLayout(context, isDesktopLayout, screenWidth);
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDesktopLayout,
    double screenWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: leftFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildGameCoinedStatistics(context, isDesktopLayout),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: rightFlex,
          child: _buildCoinedGamesContent(
            context,
            isDesktop: isDesktopLayout,
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    bool isDesktopLayout,
    double screenWidth,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildGameCoinedStatistics(context, isDesktopLayout),
        ),
        Expanded(
          child: _buildCoinedGamesContent(
            context,
            isDesktop: isDesktopLayout,
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildGameCoinedStatistics(BuildContext context, bool isDesktop) {
    final cardPadding =
        isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12);
    final titleStyle = TextStyle(
      fontSize: isDesktop ? 18 : 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.titleLarge?.color,
    );

    return Card(
      elevation: isDesktop ? 2 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
      ),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('投币游戏统计', style: titleStyle),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              isDesktop: isDesktop,
              icon: Icons.monetization_on,
              title: '总投币游戏',
              value: paginationData?.total.toString() ??
                  coinedGames.length.toString(),
              color: Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context,
      {required bool isDesktop,
      required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    final titleTextStyle = TextStyle(
        color:
            Theme.of(context).textTheme.bodyMedium?.color?.withSafeOpacity(0.7),
        fontSize: isDesktop ? 14 : 13);
    final valueTextStyle = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isDesktop ? 16 : 15,
        color: Theme.of(context).textTheme.bodyLarge?.color);
    final iconSize = isDesktop ? 22.0 : 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withSafeOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleTextStyle),
                const SizedBox(height: 2),
                Text(value, style: valueTextStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinedGamesContent(BuildContext context,
      {required bool isDesktop, required double screenWidth}) {
    double availableWidth;
    if (isDesktop) {
      availableWidth = screenWidth * rightFlex / (leftFlex + rightFlex);
    } else {
      availableWidth = screenWidth;
    }

    final crossAxisCount = DeviceUtils.calculateGameCardsInGameListPerRow(
      context,
      directAvailableWidth: availableWidth,
      isCompact: true,
    );
    final cardRatio = DeviceUtils.calculateGameCardRatio(
      context,
      directAvailableWidth: availableWidth,
    );

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      children: [
        AnimatedContentGrid<Game>(
          items: coinedGames,
          crossAxisCount: crossAxisCount,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index, gameItem) {
            return CommonGameCard(
              game: gameItem,
              isGridItem: true, // Grid布局效果更好
              showTags: true,
              maxTags: isDesktop ? 2 : 3,
            );
          },
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: LoadingWidget(message: "正在加载更多"),
          ),
        if (!isLoadingMore && (paginationData?.hasNextPage() ?? false))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: FunctionalButton(
                onPressed: onLoadMore,
                label: '加载更多',
              ),
            ),
          ),
      ],
    );
  }
}
