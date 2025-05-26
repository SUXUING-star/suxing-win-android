import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/components/screen/game/download/game_download_links.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';

class GameDescription extends StatelessWidget {
  final Game game;
  final User? currentUser;

  const GameDescription({
    super.key,
    required this.game,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
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
                  '详细描述',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              game.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
            if (game.downloadLinks.isNotEmpty) ...[
              SizedBox(height: 24),
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
                    '下载链接',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              GameDownloadLinks(
                downloadLinks: game.downloadLinks,
                currentUser: currentUser,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
