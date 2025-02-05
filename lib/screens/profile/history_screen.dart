// lib/screens/profile/history_screen.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../services/history_service.dart';
import '../../routes/app_routes.dart';
import '../../models/history.dart';  // 添加这行

class HistoryScreen extends StatelessWidget {
  final GameService _gameService = GameService();
  final HistoryService _historyService = HistoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('浏览历史')),
      body: StreamBuilder<List<History>>(
        stream: _historyService.getUserHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data!;
          if (history.isEmpty) {
            return Center(child: Text('暂无浏览记录'));
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final historyItem = history[index];
              return FutureBuilder<Game?>(
                future: _gameService.getGameById(historyItem.gameId),
                builder: (context, gameSnapshot) {
                  if (!gameSnapshot.hasData || gameSnapshot.data == null) {
                    return SizedBox.shrink();
                  }

                  final game = gameSnapshot.data!;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(game.coverImage),
                      ),
                      title: Text(game.title),
                      subtitle: Text(
                          '上次浏览: ${_formatDate(historyItem.lastViewTime)}'
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.gameDetail,
                          arguments: game,
                        );
                      },
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}