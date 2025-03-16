// lib/widgets/components/screen/game/collection/layout/mobile_collection_layout.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../models/game/game_collection.dart';
import '../../../../../../routes/app_routes.dart';
import '../card/collection_game_card.dart';

/// 移动设备游戏收藏展示布局 - 瀑布流版本
///
/// 实现标签页式布局的内容区域，使用瀑布流显示游戏卡片
class MobileCollectionLayout extends StatefulWidget {
  final List<GameWithCollection> games;
  final Function onRefresh;
  final String collectionType;

  const MobileCollectionLayout({
    Key? key,
    required this.games,
    required this.onRefresh,
    required this.collectionType,
  }) : super(key: key);

  @override
  _MobileCollectionLayoutState createState() => _MobileCollectionLayoutState();
}

class _MobileCollectionLayoutState extends State<MobileCollectionLayout> {
  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
      },
      // 使用MasonryGridView实现瀑布流布局
      child: Padding(
        padding: EdgeInsets.all(8),
        // 对于横向布局的卡片，使用普通的ListView而不是瀑布流
        child: ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: widget.games.length,
          itemBuilder: (context, index) {
            final gameWithCollection = widget.games[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CollectionGameCard(
                game: gameWithCollection.game,
                collectionStatus: gameWithCollection.collection.status,
              ),
            );
          },
        ),
      ),
    );
  }

  // 对于横向卡片，我们不再需要计算列数

  // 构建空状态视图
  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (widget.collectionType) {
      case 'wantToPlay':
        message = '还没有想玩的游戏';
        icon = Icons.star_border;
        break;
      case 'playing':
        message = '还没有在玩的游戏';
        icon = Icons.videogame_asset;
        break;
      case 'played':
        message = '还没有玩过的游戏';
        icon = Icons.check_circle;
        break;
      default:
        message = '还没有收藏任何游戏';
        icon = Icons.collections_bookmark;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.gamesList);
            },
            child: Text('发现游戏'),
          ),
        ],
      ),
    );
  }
}