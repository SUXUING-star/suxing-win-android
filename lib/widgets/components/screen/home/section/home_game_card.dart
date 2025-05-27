// lib/widgets/components/screen/home/section/home_game_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/game_stats_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_category_tag_view.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class HomeGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  static const double cardWidth = 160.0;
  static const double cardHeight = 210;

  const HomeGameCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (game.approvalStatus == GameStatus.pending) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 1.5, // 你可以根据喜好调整或设为 0
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SafeCachedImage(
                        imageUrl: game.coverImage,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        memCacheWidth: 320,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    Positioned(
                        top: 8,
                        left: 8,
                        child: GameCategoryTagView(
                          category: game.category,
                        )),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GameStatsWidget(
                        game: game,
                        showCollectionStats: true,
                        isGrid: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
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
      ),
    );
  }
}
