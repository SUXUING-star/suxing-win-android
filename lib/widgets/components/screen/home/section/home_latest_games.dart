// lib/widgets/components/screen/home/section/home_latest_games.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/routes/app_routes.dart';

class HomeLatestGames extends StatelessWidget {
  final List<Game>? games;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const HomeLatestGames({
    super.key,
    required this.games,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '最新发布',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    NavigationUtils.pushNamed(
                      context,
                      AppRoutes.latestGames,
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '更多',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[700],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildGameListArea(context), // context 作为参数传入
        ],
      ),
    );
  }

  Widget _buildGameListArea(BuildContext context) {
    // context 作为参数
    if (isLoading && games == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget(message: '加载最新游戏...', size: 24),
      );
    }

    if (errorMessage != null && games == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: InlineErrorWidget(
          errorMessage: errorMessage!,
          onRetry: onRetry,
        ),
      );
    }
    final displayGames = games ?? [];
    if (!isLoading && displayGames.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: EmptyStateWidget(
          message: '暂无最新游戏',
          iconData: Icons.inbox_outlined,
          iconSize: 40,
          iconColor: Colors.grey,
        ),
      );
    }

    return Stack(
      children: [
        _buildVerticalGameList(displayGames, context), // context 传入
        if (isLoading && displayGames.isNotEmpty)
          Positioned.fill(
              child: Container(
            color: Colors.white.withSafeOpacity(0.5),
            child: const LoadingWidget(size: 30),
          )),
      ],
    );
  }

  Widget _buildVerticalGameList(List<Game> gameList, BuildContext context) {
    final itemsToShow = gameList.take(3).toList();
    if (itemsToShow.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "没有最新游戏可显示",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 使用封装好的 AnimatedListView
    return AnimatedListView<Game>(
      listKey: const ValueKey('home_latest_games_list'),
      items: itemsToShow,
      shrinkWrap: true, // 关键：使其在 Column 内正常工作
      physics: const NeverScrollableScrollPhysics(), // 关键：禁用其内部滚动
      padding: EdgeInsets.zero, // 外部已有 padding
      itemBuilder: (ctx, index, game) {
        // 为了在 item 之间显示分割线，我们可以在这里做个小处理
        return Column(
          children: [
            CommonGameCard(
              game: game,
              isGridItem: false,
            ),
            if (index < itemsToShow.length - 1) // 不是最后一个 item 才显示分割线
              Divider(
                height: 16,
                indent: 88,
                endIndent: 16,
                color: Colors.grey.withSafeOpacity(0.1),
              ),
          ],
        );
      },
    );
  }
}
