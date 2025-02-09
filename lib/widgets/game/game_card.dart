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

  // 获取图片宽高比
  Future<double> _getImageAspectRatio(String imageUrl) async {
    try {
      final ui.Image image = await _getImage(imageUrl);
      return image.width / image.height;
    } catch (e) {
      print('Error getting image aspect ratio: $e');
      return 1.0; // 加载失败时返回默认比例
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 自适应高度的封面图
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return FutureBuilder<double>(
                  future: _getImageAspectRatio(game.coverImage),
                  builder: (context, snapshot) {
                    double aspectRatio = snapshot.data ?? 16 / 9; // 默认比例
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
            // 使用 Padding 代替 Expanded
            Padding(
              padding: EdgeInsets.all(8),
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
                  SizedBox(height: 4),
                  Text(
                    game.summary,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  // 点赞和浏览等信息
                  Row(
                    children: [
                      Icon(Icons.thumb_up, size: 14),
                      SizedBox(width: 4),
                      Text(
                        game.likeCount.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
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

    );
  }
}