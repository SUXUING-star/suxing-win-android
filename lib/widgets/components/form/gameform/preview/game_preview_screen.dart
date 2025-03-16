// lib/widgets/form/gameform/preview/game_preview_screen.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../widgets/components/screen/game/game_detail_content.dart';
import '../../../../../../utils/font/font_config.dart';

class GamePreviewScreen extends StatelessWidget {
  final Game game;

  const GamePreviewScreen({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('预览: ${game.title}'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.arrow_back),
            label: Text('返回编辑'),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview banner
          Container(
            width: double.infinity,
            color: Colors.amber.withOpacity(0.2),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                '预览模式 - 这是您保存后的游戏详情页效果预览',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Use the actual game detail content widget with Expanded to fill available space
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: GameDetailContent(game: game),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        label: Text('返回继续编辑'),
        icon: Icon(Icons.edit),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                game.title,
                style: const TextStyle(
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
                  if (game.coverImage.isNotEmpty)
                    Image.network(
                      game.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const DecoratedBox(
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
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.amber.withOpacity(0.2),
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '预览模式 - 实时预览效果',
                  style: TextStyle(
                    fontFamily: FontConfig.defaultFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: SliverToBoxAdapter(
              child: GameDetailContent(game: game),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        label: Text('返回编辑'),
        icon: Icon(Icons.edit),
      ),
    );
  }
}