// lib/widgets/components/screen/game/title/game_title_toolbar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';
import '../button/edit_button.dart';
import '../button/like_button.dart';

class GameTitleToolbar extends StatelessWidget {
  final Game game;
  final GameService gameService;
  final VoidCallback onEditComplete;

  const GameTitleToolbar({
    Key? key,
    required this.game,
    required this.gameService,
    required this.onEditComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => NavigationUtils.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              game.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // 分享功能
            },
          ),
          // 使用现有的LikeButton组件
          LikeButton(
            game: game,
            gameService: gameService,
          ),
          // 使用现有的EditButton组件
          EditButton(
            game: game,
            onEditComplete: onEditComplete,
          ),
        ],
      ),
    );
  }
}