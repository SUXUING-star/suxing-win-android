// lib/widgets/components/screen/mygames/my_games_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart'; // Ensure GameStatus enum is here
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/game_status_overlay.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

enum GameStatType {
  views,
  likes,
  ratings,
}

class MyGamesLayout extends StatelessWidget {
  final List<Game> myGames;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final VoidCallback onAddGame;
  final Function(Game) onResubmit;
  final Function(String) onShowReviewComment;
  final AuthProvider authProvider;

  const MyGamesLayout({
    super.key,
    required this.myGames,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onLoadMore,
    required this.onAddGame,
    required this.onResubmit,
    required this.onShowReviewComment,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktopScreen(context);

    if (myGames.isEmpty && !isLoadingMore && !hasMore) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '您还没有提交过游戏',
          action: FunctionalTextButton(
              onPressed: onAddGame,
              label: '创建新游戏',
              icon: Icons.videogame_asset_rounded),
        ),
      );
    }

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
            child: _buildMyGamesStatistics(context, isDesktop: true),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: 4,
          child: _buildGamesContent(context, isDesktop: true),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildMyGamesStatistics(context, isDesktop: false),
        ),
        Expanded(
          child: _buildGamesContent(context, isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildMyGamesStatistics(BuildContext context,
      {required bool isDesktop}) {
    final int totalGames = myGames.length;
    final int pendingGames = myGames
        .where((game) => game.approvalStatus == GameStatus.pending)
        .length;
    final int approvedGames = myGames
        .where((game) => game.approvalStatus == GameStatus.approved)
        .length;
    final int rejectedGames = myGames
        .where((game) => game.approvalStatus == GameStatus.rejected)
        .length;

    if (isDesktop) {
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
              Text('游戏统计', style: titleStyle),
              const SizedBox(height: 16),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.videogame_asset_outlined,
                  title: '总数',
                  value: totalGames.toString(),
                  color: Colors.blueAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.pending_actions,
                  title: '审核中',
                  value: pendingGames.toString(),
                  color: Colors.orangeAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.check_circle_outline,
                  title: '已通过',
                  value: approvedGames.toString(),
                  color: Colors.green),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.highlight_off,
                  title: '已拒绝',
                  value: rejectedGames.toString(),
                  color: Colors.redAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.visibility_outlined,
                  title: '总浏览量',
                  value: _calculateTotalGameStat(GameStatType.views).toString(),
                  color: Colors.indigoAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.thumb_up_alt_outlined,
                  title: '总点赞数',
                  value: _calculateTotalGameStat(GameStatType.likes).toString(),
                  color: Colors.pinkAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.star_outline,
                  title: '总评分人数',
                  value:
                      _calculateTotalGameStat(GameStatType.ratings).toString(),
                  color: Colors.teal),
            ],
          ),
        ),
      );
    } else {
      // Mobile layout using ExpansionTile
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
          key: const PageStorageKey<String>('my_games_stats_expansion_tile'),
          title: Text('游戏统计', style: titleStyle),
          trailing: Text(
            '总数: $totalGames',
            style: totalCountStyle,
          ),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          childrenPadding:
              const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          children: <Widget>[
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.videogame_asset_outlined,
                title: '总数',
                value: totalGames.toString(),
                color: Colors.blueAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.pending_actions,
                title: '审核中',
                value: pendingGames.toString(),
                color: Colors.orangeAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.check_circle_outline,
                title: '已通过',
                value: approvedGames.toString(),
                color: Colors.green),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.highlight_off,
                title: '已拒绝',
                value: rejectedGames.toString(),
                color: Colors.redAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.visibility_outlined,
                title: '总浏览量',
                value: _calculateTotalGameStat(GameStatType.views).toString(),
                color: Colors.indigoAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.thumb_up_alt_outlined,
                title: '总点赞数',
                value: _calculateTotalGameStat(GameStatType.likes).toString(),
                color: Colors.pinkAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.star_outline,
                title: '总评分人数',
                value: _calculateTotalGameStat(GameStatType.ratings).toString(),
                color: Colors.teal),
          ],
        ),
      );
    }
  }

  int _calculateTotalGameStat(GameStatType type) {
    double totalDouble = 0;

    for (var game in myGames) {
      if (type == GameStatType.views) {
        totalDouble += game.viewCount.toDouble();
      } else if (type == GameStatType.likes) {
        totalDouble += game.likeCount.toDouble();
      } else if (type == GameStatType.ratings) {
        totalDouble += game.ratingCount.toDouble();
      }
    }
    return totalDouble.toInt();
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
    final cardRatio = DeviceUtils.calculateSimpleGameCardRatio(context);
    final cardsPerRow = DeviceUtils.calculateGameCardsInGameListPerRow(context,
        withPanels: true, leftPanelVisible: true);

    return ListView(
      key: ValueKey<int>(myGames.length),
      controller: scrollController,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      children: [
        AnimatedContentGrid<Game>(
          items: myGames,
          crossAxisCount: cardsPerRow,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
          padding: EdgeInsets.zero, // 外部 ListView 已有 padding
          shrinkWrap: true, // 关键：使其在 ListView 内正常工作
          physics: const NeverScrollableScrollPhysics(), // 关键：禁用其内部滚动
          itemBuilder: (context, index, game) {
            return _buildGameCardItem(game);
          },
        ),

        // 加载更多
        if (isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: LoadingWidget.inline(message: "加载更多..."),
          ),
        if (!isLoadingMore && hasMore && myGames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: FunctionalTextButton(
                onPressed: onLoadMore,
                label: '加载更多游戏',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameCardItem(Game game) {
    return Stack(
      children: [
        CommonGameCard(
          game: game,
          isGridItem: true,
          showTags: true,
          maxTags: 1,
        ),
        GameApprovalStatusOverlay(
          game: game,
          onResubmit: () => onResubmit(game),
          onShowReviewComment: onShowReviewComment,
        ),
      ],
    );
  }
}
