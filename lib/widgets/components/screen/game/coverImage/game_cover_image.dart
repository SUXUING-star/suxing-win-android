// lib/widgets/game/coverImage/game_cover_image.dart
import 'package:flutter/material.dart';

class GameCoverImage extends StatelessWidget {
  final String imageUrl;

  const GameCoverImage({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                if (loadingProgress.expectedTotalBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${((loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!) *
                          100)
                          .toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 48,
              ),
              const SizedBox(height: 8),
              const Text(
                '图片加载失败',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}