// lib/widgets/home/home_game_card.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';

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
    return Container(
      width: cardWidth,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
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
                      errorBuilder: (context, exception, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
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
        ),
      ),
    );
  }
}