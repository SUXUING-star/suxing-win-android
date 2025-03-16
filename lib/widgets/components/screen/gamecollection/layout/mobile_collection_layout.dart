// lib/widgets/components/screen/game/collection/layout/mobile_collection_layout.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../models/game/game_collection.dart';
import '../../../../../utils/device/device_utils.dart';
import '../card/collection_game_card.dart';

/// 移动设备游戏收藏展示布局
///
/// 实现标签页式布局的内容区域，每个标签页使用网格显示游戏卡片
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
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          childAspectRatio: 0.7, // 更紧凑的卡片比例
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.games.length,
        itemBuilder: (context, index) {
          final gameWithCollection = widget.games[index];
          return CollectionGameCard(
            game: gameWithCollection.game,
            isMobile: true,
          );
        },
      ),
    );
  }

  // 根据屏幕宽度计算横向卡片数量
  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 400) {
      return 2; // 小屏幕手机显示2列
    } else if (screenWidth < 600) {
      return 3; // 大屏幕手机显示3列
    } else {
      return 4; // 平板显示4列
    }
  }

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
              Navigator.pushReplacementNamed(context, '/games');
            },
            child: Text('发现游戏'),
          ),
        ],
      ),
    );
  }
}