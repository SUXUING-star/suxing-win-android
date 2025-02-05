
import 'package:flutter/material.dart';
import '../../../models/game.dart';
import '../../../services/game_service.dart';
import '../../../routes/app_routes.dart';
import 'package:flutter/gestures.dart';

class HomeHot extends StatelessWidget {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      title: '热门游戏',
      onMorePressed: () {
        Navigator.pushNamed(context, AppRoutes.hotGames);
      },
      child: StreamBuilder<List<Game>>(
        stream: _gameService.getHotGames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError('加载失败：${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState('暂无热门游戏');
          }
          return _buildHorizontalGameList(snapshot.data!, context);
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

  Widget _buildHorizontalGameList(List<Game> games, BuildContext context) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.gameDetail,
                  arguments: game,
                );
              },
              child: Container(
                width: 160,
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: DecoratedBox( // 使用 DecoratedBox 添加背景
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7), // 白色背景，透明度 0.7
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding( // 添加 Padding，使内容不紧贴背景边缘
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            game.coverImage,
                            height: 120,
                            width: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context, Object exception,
                                StackTrace? stackTrace) {
                              return Container(
                                height: 120,
                                width: 160,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(Icons.error_outline, color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          game.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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