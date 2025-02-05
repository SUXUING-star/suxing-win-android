// lib/widgets/latest_game_card.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../routes/app_routes.dart';

class LatestGameCard extends StatelessWidget {
  final Game game;

  const LatestGameCard({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.gameDetail,
            arguments: game,
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            game.coverImage,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(game.title),
        subtitle: Text(
          game.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye_outlined),
            Text('${game.viewCount}'),
          ],
        ),
      ),
    );
  }
}