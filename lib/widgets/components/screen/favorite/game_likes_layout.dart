// lib/widgets/components/screen/favorite/game_likes_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameLikesLayout extends StatefulWidget {
  final List<Game> favoriteGames;
  final PaginationData? paginationData; // 收藏列表如果有分页信息
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetryInitialLoad;
  final VoidCallback onLoadMore;
  final Function(String gameId) onToggleLike;
  final ScrollController scrollController;

  const GameLikesLayout({
    super.key,
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
      return Center(child: LoadingWidget.fullScreen(message: "正在加载收藏游戏"));
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

    final isDesktop = DeviceUtils.isDesktopScreen(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildGameFavoritesStatistics(context, isDesktop: true),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: 4,
          child: _buildFavoritesContent(context, isDesktop: true),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildGameFavoritesStatistics(context, isDesktop: false),
        ),
        Expanded(
          child: _buildFavoritesContent(context, isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildGameFavoritesStatistics(BuildContext context,
      {required bool isDesktop}) {
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
      {required bool isDesktop}) {
    final crossAxisCount = DeviceUtils.calculateGameCardsInGameListPerRow(
      context,
      withPanels: true,
      leftPanelVisible: true,
    );
    final cardRatio = DeviceUtils.calculateSimpleGameCardRatio(context);

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: isDesktop ? 16 : 8,
          ),
          itemCount: widget.favoriteGames.length,
          itemBuilder: (context, index) {
            final gameItem = widget.favoriteGames[index];
            return FadeInSlideUpItem(
              delay: Duration(milliseconds: 50 * index),
              duration: const Duration(milliseconds: 350),
              child: _buildGameCard(gameItem, isDesktop),
            );
          },
        ),
        if (widget.isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: FadeInItem(child: LoadingWidget.inline(message: "正在加载更多")),
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
