// lib/widgets/components/screen/gamecollection/game_collection_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_with_collection.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'game_review_panel.dart'; // Review 面板组件

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
  });

  static const Map<String, String> _statusTextMap = {
    GameCollectionStatus.wantToPlay: '想玩',
    GameCollectionStatus.playing: '在玩',
    GameCollectionStatus.played: '已玩',
  };

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktopScreen(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
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
                  isDesktop: true,
                  icon: Icons.favorite_border,
                  title: '想玩',
                  value: collectionCounts!.wantToPlay.toString(),
                  color: Colors.blueAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.gamepad_outlined,
                  title: '在玩',
                  value: collectionCounts!.playing.toString(),
                  color: Colors.green),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.check_circle_outline,
                  title: '已玩',
                  value: collectionCounts!.played.toString(),
                  color: Colors.purpleAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.collections_bookmark_outlined,
                  title: '总计',
                  value: collectionCounts!.total.toString(),
                  color: Colors.orangeAccent),
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
                isDesktop: false,
                icon: Icons.favorite_border,
                title: '想玩',
                value: collectionCounts!.wantToPlay.toString(),
                color: Colors.blueAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.gamepad_outlined,
                title: '在玩',
                value: collectionCounts!.playing.toString(),
                color: Colors.green),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.check_circle_outline,
                title: '已玩',
                value: collectionCounts!.played.toString(),
                color: Colors.purpleAccent),
          ],
        ),
      );
    }
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

  Widget _buildGamesContent(BuildContext context, {required bool isDesktop}) {
    // 处理空状态
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

    // 计算 GridView 的 itemCount
    final itemCount = collectedGames.length +
        (isLoadingMore || (hasMore && collectedGames.isNotEmpty) ? 1 : 0);

    // 定义 GridView 的通用样式参数
    final gridPadding = EdgeInsets.all(isDesktop ? 16 : 12);
    final crossAxisSpacing = isDesktop ? 16.0 : 8.0;
    final mainAxisSpacing = isDesktop ? 16.0 : 12.0;

    // 使用 LayoutBuilder 获取中间游戏列表区域的实际可用宽度
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double actualAvailableWidthForGames = constraints.maxWidth;

        // 如果可用宽度无效，则不渲染 GridView
        if (actualAvailableWidthForGames <= 0) {
          return const SizedBox.shrink();
        }

        // 使用获取到的实际宽度来计算每行卡片数
        // 当 directAvailableWidth 提供时，DeviceUtils 内部 targetCardWidth 的选择已修改为主要基于此宽度
        final int crossAxisCount =
            DeviceUtils.calculateGameCardsInGameListPerRow(
          context,
          directAvailableWidth: actualAvailableWidthForGames,
          withPanels: isDesktop && selectedGameForReview != null,
          isCompact: true,
          leftPanelVisible: isDesktop,
          rightPanelVisible: isDesktop && selectedGameForReview != null,
        );

        // 使用获取到的实际宽度和计算出的每行卡片数来计算卡片宽高比
        // 当 direct* 参数提供时，DeviceUtils 内部 min/max ratio 的选择逻辑已更新
        final double cardRatio = DeviceUtils.calculateGameCardRatio(
          context,
          directAvailableWidth: actualAvailableWidthForGames,
          directCardsPerRow: crossAxisCount,
          showTags: true, // 卡片是否显示标签
          // 同上，下面参数主要用于兼容 DeviceUtils 方法签名
          withPanels: isDesktop && selectedGameForReview != null,
          leftPanelVisible: false,
          rightPanelVisible: isDesktop && selectedGameForReview != null,
        );

        // Badge 样式参数定义
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

        // 构建 GridView
        return GridView.builder(
          key: const ValueKey('game_collection_final_grid'), // 使用唯一的 Key
          controller: scrollController,
          padding: gridPadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < collectedGames.length) {
              final gameWithCollection = collectedGames[index];
              final game = gameWithCollection.game;
              if (game == null) return const SizedBox.shrink(); // 防御性编程

              final String currentStatusString =
                  gameWithCollection.collection.status;
              final String statusText =
                  _statusTextMap[currentStatusString] ?? '未知';
              final Color statusColor =
                  GameConstants.getGameCollectionStatusColor(
                      currentStatusString);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CommonGameCard(
                    game: game,
                    isGridItem: crossAxisCount > 1,
                    onTapOverride: isDesktop
                        ? () => onGameTapForReview(gameWithCollection)
                        : () {
                            // 移动端点击跳转
                            NavigationUtils.pushNamed(
                              context,
                              AppRoutes.gameDetail,
                              arguments: game,
                            );
                          },
                  ),
                  Positioned(
                    top: crossAxisCount > 1 ? 0 : -1,
                    right: crossAxisCount > 1 ? 0 : -1,
                    child: Container(
                      padding: statusBadgePadding,
                      decoration: BoxDecoration(
                        color: statusColor,
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
                        statusText,
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
            } else {
              // 加载更多或无更多
              if (isLoadingMore) {
                return Center(child: LoadingWidget.inline(message: "加载更多..."));
              } else if (hasMore && collectedGames.isNotEmpty) {
                return Center(
                  child: FunctionalButton(
                    onPressed: onLoadMore,
                    label: '加载更多收藏',
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }
          },
        );
      },
    );
  }
}
