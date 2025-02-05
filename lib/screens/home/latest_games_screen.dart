// lib/screens/latest_games_screen.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../widgets/game/latest_game_card.dart';

class LatestGamesScreen extends StatelessWidget {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('最新发布'),
      ),
      body: StreamBuilder<List<Game>>(
        stream: _gameService.getLatestGames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('暂无最新游戏'));
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return LatestGameCard(game: snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}