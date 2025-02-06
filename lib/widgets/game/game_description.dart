import 'package:flutter/material.dart';
import '../../models/game.dart';
import './game_download_links.dart';

class GameDescription extends StatelessWidget {
  final Game game;

  const GameDescription({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '详细描述',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            game.description,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          if (game.downloadLinks.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              '下载链接',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            GameDownloadLinks(downloadLinks: game.downloadLinks),
          ],
        ],
      ),
    );
  }
}