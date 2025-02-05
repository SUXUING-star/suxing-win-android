// lib/screens/profile/favorites_screen.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../routes/app_routes.dart';


class FavoritesScreen extends StatelessWidget {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的收藏')),
      body: StreamBuilder<List<String>>(
        stream: _gameService.getUserFavorites(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final favoriteIds = snapshot.data!;
          if (favoriteIds.isEmpty) {
            return Center(child: Text('暂无收藏的游戏'));
          }

          return StreamBuilder<List<Game>>(
            stream: _gameService.getGames(),
            builder: (context, gamesSnapshot) {
              if (!gamesSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final favoriteGames = gamesSnapshot.data!
                  .where((game) => favoriteIds.contains(game.id))
                  .toList();

              return ListView.builder(
                itemCount: favoriteGames.length,
                itemBuilder: (context, index) {
                  final game = favoriteGames[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(game.coverImage),
                    ),
                    title: Text(game.title),
                    subtitle: Text(game.summary),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _gameService.toggleLike(game.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.gameDetail,
                              arguments: game,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}