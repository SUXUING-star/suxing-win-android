// lib/widgets/components/screen/game/card/optimized_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../common/animated_card_container.dart';
import '../../../../../utils/device/device_utils.dart';
import '../tag/game_tags.dart';
import '../../../../ui/image/safe_cached_image.dart';

/// 优化版GameCard
///
/// 使用SafeCachedImage组件加载图片
class GameCard extends StatelessWidget {
  final Game game;
  final double imageHeight = 160.0;

  GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final isAndroidPortrait = DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);

    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片部分 - 使用SafeCachedImage
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                child: SafeCachedImage(
                  imageUrl: game.coverImage,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 480, // 适合大多数设备宽度的2倍
                  backgroundColor: Colors.grey[200],
                  onError: (url, error) {
                    // 记录错误，可以用于后续分析或报告
                    print('游戏卡片图片加载失败: $url, 错误: $error');
                  },
                ),
              ),

              // 在图片上方显示类别标签
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 内容部分保持不变
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 0,
              maxHeight: isAndroidPortrait ? 120 : 140,
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isAndroidPortrait ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  // 摘要
                  Text(
                    game.summary,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isAndroidPortrait ? 12 : 14,
                      height: 1.2,
                    ),
                    maxLines: isAndroidPortrait ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 标签部分
                  if (game.tags.isNotEmpty && !isAndroidPortrait) ...[
                    SizedBox(height: 4),
                    GameTags(
                      game: game,
                      wrap: false,
                      maxTags: isAndroidPortrait ? 1 : 2,
                      fontSize: isAndroidPortrait ? 10 : 11,
                    ),
                  ],

                  // 底部统计信息
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: isAndroidPortrait ? 14 : 16,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        game.likeCount.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 12),
                      Spacer(),
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 14,
                        color: Colors.lightBlueAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        game.viewCount.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}