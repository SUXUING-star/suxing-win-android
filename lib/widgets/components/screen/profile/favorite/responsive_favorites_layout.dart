// lib/widgets/components/screen/game/favorite/responsive_favorites_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'favorite_game_card.dart';
import 'favorite_game_grid_card.dart';

class ResponsiveFavoritesLayout extends StatelessWidget {
  final List<Game> games;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final Function(String) onToggleFavorite;

  const ResponsiveFavoritesLayout({
    super.key,
    required this.games,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingView();
    }

    if (error != null) {
      return _buildErrorView(error!);
    }

    if (games.isEmpty) {
      return _buildEmptyView();
    }

    // 根据设备类型选择不同的布局
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  Widget _buildLoadingView() {
    return LoadingWidget.inline(message: '正在加载收藏游戏...', size: 12);
  }

  Widget _buildErrorView(String error) {
    return InlineErrorWidget(onRetry: onRefresh, errorMessage: '重新加载');
  }

  Widget _buildEmptyView() {
    return const EmptyStateWidget(
      message: '暂无收藏的游戏',
      iconData: Icons.videogame_asset_off,
    );
  }

  // 列表布局 - 适用于移动设备
  Widget _buildListLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: FavoriteGameCard(
              game: game,
              onFavoritePressed: () => onToggleFavorite(game.id),
            ),
          );
        },
      ),
    );
  }

  // 网格布局 - 适用于桌面和平板
  Widget _buildGridLayout(BuildContext context) {
    // 计算一行显示的卡片数量
    final crossAxisCount = DeviceUtils.calculateCardsPerRow(context);
    // 计算卡片比例
    final cardRatio = DeviceUtils.calculateSimpleCardRatio(context);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return FavoriteGameGridCard(
            game: game,
            onFavoritePressed: () => onToggleFavorite(game.id),
          );
        },
      ),
    );
  }
}
