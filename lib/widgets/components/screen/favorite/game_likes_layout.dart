// lib/widgets/components/screen/favorite/game_likes_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';
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

class GameLikesLayout extends StatefulWidget {
  final WindowStateProvider windowStateProvider;
  final List<Game> favoriteGames;
  final PaginationData? paginationData;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetryInitialLoad;
  final VoidCallback onLoadMore;
  final Function(String gameId) onToggleLike;
  final ScrollController scrollController;

  static const int leftFlex = 1;
  static const int rightFlex = 4;

  const GameLikesLayout({
    super.key,
    required this.windowStateProvider,
    required this.favoriteGames,
    required this.paginationData,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    this.errorMessage,
    required this.onRetryInitialLoad,
    required this.onLoadMore,
    required this.onToggleLike,
    required this.scrollController,
  });

  @override
  _GameLikesLayoutState createState() => _GameLikesLayoutState();
}

class _GameLikesLayoutState extends State<GameLikesLayout>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isLoadingInitial) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (widget.errorMessage != null && widget.favoriteGames.isEmpty) {
      return Center(
        child: FunctionalButton(
          label: '加载失败: ${widget.errorMessage}. 点击重试',
          onPressed: widget.onRetryInitialLoad,
        ),
      );
    }

    if (widget.favoriteGames.isEmpty) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '暂无收藏的游戏',
          iconData: Icons.star_border,
          iconColor: Colors.grey[400],
          iconSize: 64,
        ),
      );
    }

    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
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
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildGameLikesStatistics(
              context,
              isDesktopLayout,
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: 4,
          child: _buildFavoritesContent(
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
          child: _buildGameLikesStatistics(
            context,
            isDesktopLayout,
          ),
        ),
        Expanded(
          child: _buildFavoritesContent(
            context,
            isDesktop: isDesktopLayout,
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildGameLikesStatistics(BuildContext context, bool isDesktop) {
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
            Text('收藏游戏统计', style: titleStyle),
            const SizedBox(height: 16),
            _buildStatRow(context,
                isDesktop: isDesktop,
                icon: Icons.star,
                title: '总收藏数',
                value: widget.paginationData?.total.toString() ??
                    widget.favoriteGames.length.toString(),
                color: Colors.blueAccent),
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

  Widget _buildFavoritesContent(BuildContext context,
      {required bool isDesktop, required double screenWidth}) {
    // 保持外部的 ListView 结构
    double availableWidth;
    if (isDesktop) {
      availableWidth = screenWidth *
          GameLikesLayout.rightFlex /
          (GameLikesLayout.leftFlex + GameLikesLayout.rightFlex);
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
      controller: widget.scrollController,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      children: [
        // 使用升级后的 AnimatedContentGrid
        AnimatedContentGrid<Game>(
          items: widget.favoriteGames,
          crossAxisCount: crossAxisCount,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
          padding: EdgeInsets.zero,
          // 外部 ListView 已有 padding
          shrinkWrap: true,
          // 关键：使其在 ListView 内正常工作
          physics: const NeverScrollableScrollPhysics(),
          // 关键：禁用其内部滚动
          itemBuilder: (context, index, gameItem) {
            return _buildGameCard(gameItem, isDesktop);
          },
        ),

        // 加载更多的逻辑保持不变
        if (widget.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: LoadingWidget(message: "正在加载更多"),
          ),
        if (!widget.isLoadingMore &&
            (widget.paginationData?.hasNextPage() ?? false) &&
            widget.favoriteGames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: FunctionalButton(
                onPressed: widget.onLoadMore,
                label: '加载更多',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameCard(Game gameItem, bool isDesktop) {
    return Stack(
      children: [
        CommonGameCard(
          game: gameItem,
          isGridItem: isDesktop,
          showTags: true,
          maxTags: isDesktop ? 2 : 3,
        ),
        Positioned(
          top: isDesktop ? 8 : 4,
          right: isDesktop ? 8 : 4,
          child: IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            iconSize: isDesktop ? 20 : 24,
            onPressed: () => widget.onToggleLike(gameItem.id),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withSafeOpacity(0.4),
              minimumSize: Size.zero,
              padding: EdgeInsets.all(isDesktop ? 4 : 6),
            ),
          ),
        ),
      ],
    );
  }
}
