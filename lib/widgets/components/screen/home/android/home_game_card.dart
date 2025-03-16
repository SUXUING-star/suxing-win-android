import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../common/animated_card_container.dart';
import '../../../../common/image/safe_cached_image.dart';

class HomeGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  static const double cardWidth = 160.0;

  const HomeGameCard({
    Key? key,
    required this.game,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: AnimatedCardContainer(
        margin: EdgeInsets.symmetric(horizontal: 8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 8),
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
              Text(
                game.summary,
                maxLines: 1,
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