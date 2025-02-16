import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../common/animated_card_container.dart';

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
                child: Image.network(
                  game.coverImage,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // 添加缓存策略
                  cacheWidth: 320, // 2倍于显示尺寸以支持高清屏
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 120.0,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120.0,
                      color: Colors.grey[200],
                      child: Icon(Icons.error_outline),
                    );
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