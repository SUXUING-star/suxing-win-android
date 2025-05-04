import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_category_tag.dart';
import '../../../../../models/game/game.dart';
import 'animated_card_container.dart';
import '../../../../ui/image/safe_cached_image.dart';
import '../../game/card/game_stats_widget.dart';

class HomeGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  static const double cardWidth = 160.0;
  static const double cardHeight = 210; // 稍微增加高度，为统计信息留出空间

  const HomeGameCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- 新增加的保险判断 ---
    // 如果游戏状态是 'pending' (待审核)，则不显示此卡片
    if (game.approvalStatus == 'pending') {
      // 返回一个空的、不占空间的Widget
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: AnimatedCardContainer(
        margin: EdgeInsets.symmetric(horizontal: 8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 游戏封面图片
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SafeCachedImage(
                      imageUrl: game.coverImage,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      memCacheWidth: 320, // 2倍于显示尺寸以支持高清屏
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.grey[200],
                      onError: (url, error) {
                        print('首页游戏卡片图片加载失败: $url, 错误: $error');
                      },
                    ),
                  ),
                  Positioned(
                      top: 8,
                      left: 8,
                      child: GameCategoryTag(category: game.category)),

                  // 右下角添加统计信息
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GameStatsWidget(
                      game: game,
                      showCollectionStats: true,
                      isGrid: true, // 使用网格样式的统计信息
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // 游戏标题
              Text(
                game.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              SizedBox(height: 4),

              // 游戏简介
              Text(
                game.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
