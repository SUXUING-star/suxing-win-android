import 'package:flutter/material.dart';
import '../../models/game.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../common/animated_card_container.dart';

class GameCard extends StatelessWidget {
  final Game game;

  GameCard({required this.game});

  Future<ui.Image> _getImage(String url) async {
    final completer = Completer<ui.Image>();
    final image = CachedNetworkImageProvider(url);
    final listener = ImageStreamListener(
          (info, call) {
        completer.complete(info.image);
      },
    );
    image.resolve(ImageConfiguration()).addListener(listener);
    return completer.future;
  }

  Future<double> _getImageAspectRatio(String imageUrl) async {
    try {
      final ui.Image image = await _getImage(imageUrl);
      return image.width / image.height;
    } catch (e) {
      print('Error getting image aspect ratio: $e');
      return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return FutureBuilder<double>(
                  future: _getImageAspectRatio(game.coverImage),
                  builder: (context, snapshot) {
                    double aspectRatio = snapshot.data ?? 16 / 9;
                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: CachedNetworkImage(
                        imageUrl: game.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported,
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    game.summary,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.thumb_up, size: 14),
                      SizedBox(width: 4),
                      Text(
                        game.likeCount.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        game.rating.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      Spacer(),
                      Icon(Icons.remove_red_eye_outlined, size: 14),
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
          ],
        ),
      ),
    );
  }
}