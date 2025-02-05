// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../routes/app_routes.dart';
import 'package:flutter/gestures.dart';

class HomeScreen extends StatelessWidget {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('宿星茶会'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 实现搜索功能
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 实现下拉刷新
          // Future.delayed(Duration(seconds: 1), () {
          //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //     content: Text('刷新完成'),
          //     duration: Duration(seconds: 1),
          //   ));
          // });
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBanner(),
              _buildSection(
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
              ),
              _buildSection(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                'https://galshare.oss-cn-beijing.aliyuncs.com/home/kaev_02l_9.jpg',
                fit: BoxFit.cover,
              ),
            ),
          );
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
          );
        },
      ),
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