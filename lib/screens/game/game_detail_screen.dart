// lib/screens/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../services/game_service.dart'; // 引入 GameService
import '../../providers/auth_provider.dart';
import 'image_preview_screen.dart';
import '../../widgets/game/comments_section.dart';
import '../../widgets/common/toaster.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;
  final GameService _gameService = GameService(); // 使用 GameService

  GameDetailScreen({required this.game});

  @override
  Widget build(BuildContext context) {
    // 每次进入详情页增加浏览量
    _incrementViewCount();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildDescription(),
                _buildImages(),
                const Divider(height: 32),
                CommentsSection(gameId: game.id), // 添加评论区组件
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFavoriteButton(context),
    );
  }

  void _incrementViewCount() {
    _gameService.incrementGameView(game.id);
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          game.title,
          style: TextStyle(
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              game.coverImage,
              fit: BoxFit.cover,
            ),
            // 添加渐变效果使标题更清晰
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () {
            // 实现分享功能
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  game.category,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Spacer(),
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                game.rating.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            game.summary,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16),
              SizedBox(width: 4),
              Text(
                '${game.viewCount} 次浏览',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time, size: 16),
              SizedBox(width: 4),
              Text(
                '发布于 ${_formatDate(game.createTime)}',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '详细描述',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            game.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (game.downloadLinks.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              '下载链接',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...game.downloadLinks.map((link) => Card(
              child: ListTile(
                title: Text(link['title'] ?? ''),
                subtitle: Text(link['description'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    // 处理下载链接点击
                    // 可以使用 url_launcher 包来打开链接
                    // launchUrl(Uri.parse(link['url']));
                  },
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '游戏截图',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: game.images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _showImagePreview(context, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      game.images[index],
                      width: 250,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildFavoriteButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return FloatingActionButton(
            onPressed: () {
              Toaster.show(
                context,
                message: '请先登录后再操作',
                isError: true,
              );
              Navigator.pushNamed(context, '/login');
            },
            child: Icon(Icons.favorite_border),
            backgroundColor: Theme.of(context).primaryColor,
          );
        }

        return StreamBuilder<List<String>>(
          stream: _gameService.getUserFavorites(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return FloatingActionButton(
                onPressed: null,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              );
            }

            final isFavorite = snapshot.data!.contains(game.id);
            return FloatingActionButton(
              onPressed: () => _toggleLike(context, isFavorite),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              backgroundColor: isFavorite ? Colors.red : Theme.of(context).primaryColor,
            );
          },
        );
      },
    );
  }

  void _toggleLike(BuildContext context, bool isLiked) async {
    try {
      await _gameService.toggleLike(game.id);
      Toaster.show(
        context,
        message: isLiked ? '已取消点赞' : '点赞成功',
      );
    } catch (e) {
      Toaster.show(
        context,
        message: '操作失败，请稍后重试',
        isError: true,
      );
    }
  }

  void _showImagePreview(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(
          images: game.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}