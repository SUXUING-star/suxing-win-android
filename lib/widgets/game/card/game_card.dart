import 'package:flutter/material.dart';
import '../../../models/game.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common/animated_card_container.dart';
import 'dart:io';

class GameCard extends StatelessWidget {
  final Game game;
  final double imageHeight = 160.0; // 固定图片高度

  GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            child: Container(
              height: imageHeight,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: game.coverImage,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 36,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isAndroid? 14 :16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    game.summary,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isAndroid? 12:14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: isAndroid? 14 :16,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        game.likeCount.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 12),
                      Spacer(),
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 14,
                        color: Colors.lightBlueAccent,
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
    );
  }
}