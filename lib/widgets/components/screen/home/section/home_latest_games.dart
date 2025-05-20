// lib/widgets/components/screen/home/section/home_latest_games.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 保留以防其他用途
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../../../models/game/game.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../ui/image/safe_cached_image.dart';

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
    return Opacity(
      opacity: 0.9, // 这个可以保留，或者由 HomeScreen 控制
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withSafeOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                      BorderSide(color: Colors.grey.shade200, width: 1))),
              child: Row(
                children: [
                  Container(
                      width: 6,
                      height: 22,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(3))),
                  SizedBox(width: 12),
                  Text('最新发布',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900])),
                  Spacer(),
                  InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        NavigationUtils.pushNamed(
                            context, AppRoutes.latestGames);
                      },
                      child: Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(children: [
                            Text('更多',
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 14)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey[700])
                          ]))),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildGameListArea(context), // context 作为参数传入
          ],
        ),
      ),
    );
  }

  Widget _buildGameListArea(BuildContext context) { // context 作为参数
    if (isLoading && games == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget.inline(message: '加载最新游戏...', size: 24),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                child: Center(child: LoadingWidget.inline(size: 30)),
              )),
      ],
    );
  }

  Widget _buildVerticalGameList(List<Game> gameList, BuildContext context) { // context 传入
    final itemsToShow = gameList.take(3).toList();
    if (itemsToShow.isEmpty) {
      // 即使 !isLoading && displayGames.isEmpty 已经在 _buildGameListArea 处理了
      // 这里再加一个防御，以防逻辑变动
      return SizedBox(
          height: 100,
          child: Center(
              child: Text("没有最新游戏可显示", style: TextStyle(color: Colors.grey))));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: itemsToShow.length,
      separatorBuilder: (_, __) => Divider(
          height: 16,
          indent: 88,
          endIndent: 16,
          color: Colors.grey.withSafeOpacity(0.1)),
      itemBuilder: (ctx, index) { // 使用 ctx 避免和外部 context 混淆
        final game = itemsToShow[index];
        return _buildGameListItem(game, ctx); // 使用 ctx
      },
    );
  }

  Widget _buildGameListItem(Game game, BuildContext context) { // context 传入
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        NavigationUtils.pushNamed(
          context, // 使用这里的 context
          AppRoutes.gameDetail,
          arguments: game,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Hero(
              tag: 'game_image_${game.id}_latest_section', // 确保tag唯一
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeCachedImage(
                  imageUrl: game.coverImage,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  memCacheWidth: 140,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Colors.grey[300],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    game.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            _buildStatsColumn(game),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsColumn(Game game) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStatItem(Icons.remove_red_eye_outlined, game.viewCount,
            Colors.blueGrey[300]),
        SizedBox(height: 6),
        _buildStatItem(Icons.star_border_purple500_outlined, game.ratingCount, // 假设是 ratingCount
            Colors.orange[400]),
        SizedBox(height: 6),
        _buildStatItem(Icons.thumb_up_off_alt_outlined, game.likeCount, // 假设是 likeCount
            Colors.redAccent[100]),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, int count, Color? iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.grey[500],
          size: 18,
        ),
        SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}