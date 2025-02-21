// profile_game_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../models/game/game.dart';

class ProfileGameCard extends StatelessWidget {
  final Game game;

  const ProfileGameCard({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/game/detail', arguments: game),
        child: Row(
          children: [
            // 游戏封面
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: SizedBox(
                width: 120,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: game.coverImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
            // 游戏信息
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      game.summary,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    // 统计信息
                    Row(
                      children: [
                        Icon(Icons.thumb_up, size: 14, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text(
                          game.likeCount.toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 14,
                            color: Colors.lightBlueAccent
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
      ),
    );
  }
}
