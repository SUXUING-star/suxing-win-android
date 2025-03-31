import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game.dart';
import '../../../../ui/image/safe_cached_image.dart';

/// A specialized card widget for displaying random games with simplified interface
class RandomGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  const RandomGameCard({
    Key? key,
    required this.game,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {
          NavigationUtils.pushReplacementNamed(
            context,
            '/game/detail',
            arguments: game.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片和统计信息（叠加在一起）
            _buildGameCoverWithStats(context),

            // 标题
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: _buildGameTitle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCoverWithStats(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4/3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 游戏封面图片
              SafeCachedImage(
                imageUrl: game.coverImage,
                fit: BoxFit.cover,
                memCacheWidth: 320,
                onError: (url, error) {
                  print('随机游戏图片加载失败: $url, 错误: $error');
                },
              ),

              // 底部渐变遮罩（让统计数据更清晰）
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 左下角放点赞数
              Positioned(
                bottom: 8,
                left: 8,
                child: _buildLikesIndicator(),
              ),

              // 右下角放浏览数
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildViewsIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikesIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.thumb_up,
            color: Colors.pink,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            game.likeCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_red_eye,
            color: Colors.lightBlue,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            game.viewCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTitle() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 40),
      child: Text(
        game.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          height: 1.2,
        ),
      ),
    );
  }
}