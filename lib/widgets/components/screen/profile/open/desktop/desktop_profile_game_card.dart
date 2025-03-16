// lib/widgets/components/screen/profile/open/desktop_profile_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../common/image/safe_cached_image.dart';

class DesktopProfileGameCard extends StatelessWidget {
  final Game game;

  const DesktopProfileGameCard({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/game/detail', arguments: game),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 游戏封面
            AspectRatio(
              aspectRatio: 16 / 9,
              child: SafeCachedImage(
                imageUrl: game.coverImage,
                fit: BoxFit.cover,
                backgroundColor: Colors.grey[200],
                onError: (url, error) {
                  print('游戏封面加载失败: $url, 错误: $error');
                },
              ),
            ),

            // 游戏信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 游戏标题
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // 游戏简介
                  Text(
                    game.summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // 统计信息
                  Row(
                    children: [
                      Icon(Icons.thumb_up, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        game.likeCount.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.lightBlueAccent),
                      const SizedBox(width: 4),
                      Text(
                        game.viewCount.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}