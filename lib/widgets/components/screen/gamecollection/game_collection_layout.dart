// lib/widgets/components/screen/gamecollection/game_collection_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_with_collection.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'game_review_panel.dart'; // Review 面板组件

class _LoadingMorePlaceholder {
  const _LoadingMorePlaceholder();
}

class _LoadMoreButtonPlaceholder {
  const _LoadMoreButtonPlaceholder();
}

class GameCollectionLayout extends StatelessWidget {
  final GameCollectionCounts? collectionCounts;
  final List<GameWithCollection> collectedGames;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final VoidCallback onGoToDiscover;
  final GameWithCollection? selectedGameForReview;
  final Function(GameWithCollection) onGameTapForReview;
  final VoidCallback onCloseReviewPanel;
  final WindowStateProvider windowStateProvider;

  const GameCollectionLayout({
    super.key,
    required this.collectionCounts,
    required this.collectedGames,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onLoadMore,
    required this.onGoToDiscover,
    this.selectedGameForReview,
    required this.onGameTapForReview,
    required this.onCloseReviewPanel,
    required this.windowStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return LazyLayoutBuilder(
      windowStateProvider: windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return isDesktopLayout
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final bool hasReviewPanel = selectedGameForReview != null;

    // 定义各区域的flex值
    const int statsFlex = 1;
    const int listFlexWithReview = 4; // 当Review面板可见时，列表的flex
    const int listFlexWithoutReview = 6; // 当Review面板不可见时，列表的flex
    const int reviewFlex = 2; // Review面板的flex

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：统计信息
        Expanded(
          flex: statsFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildCollectionStatistics(context, isDesktop: true),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        // 中间：游戏卡片列表
        Expanded(
          flex: hasReviewPanel ? listFlexWithReview : listFlexWithoutReview,
          child: _buildGamesContent(context, isDesktop: true),
        ),
        // 右侧：Review 面板 (如果 selectedGameForReview 不为 null)
        if (hasReviewPanel) ...[
          const VerticalDivider(width: 1, thickness: 0.5),
          Expanded(
            flex: reviewFlex,
            child: GameReviewPanel(
              gameWithCollection: selectedGameForReview!,
              onClose: onCloseReviewPanel,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // 移动端：统计信息在上方
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildCollectionStatistics(context, isDesktop: false),
        ),
        // 移动端：游戏卡片列表在下方
        Expanded(
          child: _buildGamesContent(context, isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildCollectionStatistics(BuildContext context,
      {required bool isDesktop}) {
    if (collectionCounts == null) {
      return const SizedBox.shrink();
    }

    if (isDesktop) {
      // 桌面端统计信息样式
      final cardPadding = const EdgeInsets.all(16);
      final titleStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );

      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('收藏统计', style: titleStyle),
              const SizedBox(height: 16),
              _buildStatRow(context,
                  isDesktop: isDesktop,
                  statusType: GameCollectionStatus.wantToPlay,
                  value: collectionCounts!.wantToPlay.toString()),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: isDesktop,
                  statusType: GameCollectionStatus.playing,
                  value: collectionCounts!.playing.toString()),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: isDesktop,
                  statusType: GameCollectionStatus.played,
                  value: collectionCounts!.played.toString()),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: isDesktop,
                  statusType: GameCollectionStatus.all,
                  value: collectionCounts!.total.toString()),
            ],
          ),
        ),
      );
    } else {
      // 移动端可折叠统计信息样式
      final titleStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );
      final totalCountStyle = TextStyle(
        fontSize: 14,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withSafeOpacity(0.85),
      );

      return Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: const PageStorageKey<String>(
              'game_collection_stats_expansion_tile'),
          title: Text('收藏统计', style: titleStyle),
          trailing:
              Text('总计: ${collectionCounts!.total}', style: totalCountStyle),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          childrenPadding:
              const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          children: <Widget>[
            _buildStatRow(context,
                isDesktop: isDesktop,
                statusType: GameCollectionStatus.wantToPlay,
                value: collectionCounts!.wantToPlay.toString()),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: isDesktop,
                statusType: GameCollectionStatus.playing,
                value: collectionCounts!.playing.toString()),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: isDesktop,
                statusType: GameCollectionStatus.played,
                value: collectionCounts!.played.toString()),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(
    BuildContext context, {
    required bool isDesktop,
    required String statusType,
    required String value,
  }) {
    late final GameCollectionStatusTheme theme;

    switch (statusType) {
      case GameCollectionStatus.wantToPlay:
        theme = GameCollectionStatusUtils.wantToPlayTheme;
        break;
      case GameCollectionStatus.playing:
        theme = GameCollectionStatusUtils.playingTheme;
        break;
      case GameCollectionStatus.played:
        theme = GameCollectionStatusUtils.playedTheme;
        break;
      case GameCollectionStatus.all:
        theme = GameCollectionStatusUtils.totalTheme;
        break;
      default:
        theme = GameCollectionStatusUtils.getTheme(null);
    }

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
                color: theme.textColor.withSafeOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(theme.icon, color: theme.textColor, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(theme.text, style: titleTextStyle),
                const SizedBox(height: 2),
                Text(value, style: valueTextStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesContent(BuildContext context, {required bool isDesktop}) {
    if ((collectionCounts?.total ?? 0) == 0 &&
        collectedGames.isEmpty &&
        !isLoadingMore) {
      return Center(
        child: EmptyStateWidget(
          message: '还没有任何游戏收藏',
          iconData: Icons.sentiment_dissatisfied_outlined,
          action: FunctionalButton(
              label: '去发现游戏',
              onPressed: onGoToDiscover,
              icon: Icons.explore_outlined),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double actualAvailableWidthForGames = constraints.maxWidth;

        if (actualAvailableWidthForGames <= 0) {
          return const SizedBox.shrink();
        }

        final int crossAxisCount =
            DeviceUtils.calculateGameCardsInGameListPerRow(
          context,
          directAvailableWidth: actualAvailableWidthForGames,
          withPanels: isDesktop && selectedGameForReview != null,
          isCompact: true,
          leftPanelVisible: isDesktop,
          rightPanelVisible: isDesktop && selectedGameForReview != null,
        );

        final double cardRatio = DeviceUtils.calculateGameCardRatio(
          context,
          directAvailableWidth: actualAvailableWidthForGames,
          directCardsPerRow: crossAxisCount,
          showTags: true,
          withPanels: isDesktop && selectedGameForReview != null,
          leftPanelVisible: false,
          rightPanelVisible: isDesktop && selectedGameForReview != null,
        );

        // 准备要显示的所有项目
        final List<Object> displayItems = [...collectedGames];
        if (isLoadingMore) {
          displayItems.add(const _LoadingMorePlaceholder());
        } else if (hasMore && collectedGames.isNotEmpty) {
          displayItems.add(const _LoadMoreButtonPlaceholder());
        }

        // Badge 样式参数
        final double statusBadgeFontSize = isDesktop ? 10 : 11;
        final EdgeInsets statusBadgePadding = isDesktop
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
        final Radius statusBadgeTopRightRadius =
            Radius.circular(isDesktop ? 10 : 8);
        final Radius statusBadgeBottomLeftRadius =
            Radius.circular(isDesktop ? 8 : 10);
        final Offset statusBadgeShadowOffset =
            isDesktop ? const Offset(-1, 1) : const Offset(-1, 1);
        final double statusBadgeShadowBlur = isDesktop ? 4 : 3;

        // 使用 AnimatedContentGrid
        return AnimatedContentGrid<Object>(
          gridKey: const ValueKey('game_collection_final_grid'),
          items: displayItems,
          crossAxisCount: crossAxisCount,
          childAspectRatio: cardRatio,
          crossAxisSpacing: isDesktop ? 16.0 : 8.0,
          mainAxisSpacing: isDesktop ? 16.0 : 12.0,
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
          itemBuilder: (context, index, item) {
            // 如果是游戏
            if (item is GameWithCollection) {
              final gameWithCollection = item;
              final game = gameWithCollection.game;
              if (game == null) return const SizedBox.shrink();

              final String currentStatusString =
                  gameWithCollection.collection.status;

              final GameCollectionStatusTheme statusTheme =
                  GameCollectionStatusUtils.getTheme(currentStatusString);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CommonGameCard(
                    game: game,
                    isGridItem: crossAxisCount > 1,
                    onTapOverride: isDesktop
                        ? () => onGameTapForReview(gameWithCollection)
                        : () => NavigationUtils.pushNamed(
                            context, AppRoutes.gameDetail,
                            arguments: game),
                  ),
                  Positioned(
                    top: crossAxisCount > 1 ? 0 : -1,
                    right: crossAxisCount > 1 ? 0 : -1,
                    child: Container(
                      padding: statusBadgePadding,
                      decoration: BoxDecoration(
                        color: statusTheme.textColor,
                        borderRadius: BorderRadius.only(
                          topRight: statusBadgeTopRightRadius,
                          bottomLeft: statusBadgeBottomLeftRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withSafeOpacity(0.3),
                            blurRadius: statusBadgeShadowBlur,
                            offset: statusBadgeShadowOffset,
                          )
                        ],
                      ),
                      child: Text(
                        statusTheme.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: statusBadgeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // 如果是加载指示器
            if (item is _LoadingMorePlaceholder) {
              return const LoadingWidget(message: "加载更多...");
            }

            // 如果是加载更多按钮
            if (item is _LoadMoreButtonPlaceholder) {
              return Center(
                child: FunctionalButton(
                  onPressed: onLoadMore,
                  label: '加载更多收藏',
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
