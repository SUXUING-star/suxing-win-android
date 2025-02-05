// lib/screens/home/widgets/home_latest.dart
import 'package:flutter/material.dart';
import '../../../models/game.dart';
import '../../../services/game_service.dart';
import '../../../routes/app_routes.dart';

class HomeLatest extends StatelessWidget {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      title: '最新发布',
      onMorePressed: () {
        Navigator.pushNamed(context, AppRoutes.latestGames);
      },
      child: StreamBuilder<List<Game>>(
        stream: _gameService.getLatestGames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError('加载失败：${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState('暂无最新游戏');
          }
          return _buildVerticalGameList(snapshot.data!, context);
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required VoidCallback onMorePressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onMorePressed,
                child: Text('更多 >'),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildVerticalGameList(List<Game> games, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
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
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.error_outline, color: Colors.red),
                    ),
                  );
                },
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
      },
    );
  }

  Widget _buildError(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}