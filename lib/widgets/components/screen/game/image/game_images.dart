import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/screens/game/detail/image_preview_screen.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class GameImages extends StatelessWidget {
  final Game game;

  const GameImages({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    if (game.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: 0.7,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '游戏截图',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: game.images.length,
                itemBuilder: (context, index) => _buildImageItem(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showImagePreview(context, index),
        child: Hero(
          tag: 'game_image_$index',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SafeCachedImage(
              imageUrl: game.images[index],
              width: 280,
              height: 180,
              fit: BoxFit.cover,
              memCacheWidth: 560, // 2倍于显示宽度
              onError: (url, error) {
                // print('游戏截图加载失败: $url, 错误: $error');
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, int initialIndex) {
    NavigationUtils.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(
          images: game.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}