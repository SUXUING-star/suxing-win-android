// lib/widgets/components/screen/game/collection/layout/desktop_collection_layout.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../models/game/game_collection.dart';
import '../../../../../../routes/app_routes.dart';
import '../card/collection_game_card.dart';

/// 桌面设备游戏收藏展示布局 - 瀑布流版本
///
/// 实现并排式列布局，每列独立显示一种收藏类型的游戏
class DesktopCollectionLayout extends StatefulWidget {
  final List<GameWithCollection> games;
  final Function onRefresh;
  final String collectionType;
  final String title;
  final IconData icon;

  const DesktopCollectionLayout({
    Key? key,
    required this.games,
    required this.onRefresh,
    required this.collectionType,
    required this.title,
    required this.icon,
  }) : super(key: key);

  @override
  _DesktopCollectionLayoutState createState() => _DesktopCollectionLayoutState();
}

class _DesktopCollectionLayoutState extends State<DesktopCollectionLayout> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 列标题
        _buildColumnHeader(),

        SizedBox(height: 12),

        // 游戏列表内容
        Expanded(
          child: _buildGamesList(),
        ),
      ],
    );
  }

  // 构建列标题
  Widget _buildColumnHeader() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: _getStatusColor(),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
            if (widget.games.isNotEmpty) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.games.length.toString(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 构建游戏列表 - 使用瀑布流
  Widget _buildGamesList() {
    if (widget.games.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
      },
      // 对于横向布局的卡片，使用普通的ListView
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
    );
  }

  // 根据收藏类型获取对应颜色
  Color _getStatusColor() {
    switch (widget.collectionType) {
      case 'wantToPlay':
        return Colors.blue;
      case 'playing':
        return Colors.green;
      case 'played':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 构建空状态视图
  Widget _buildEmptyState() {
    String message;

    switch (widget.collectionType) {
      case 'wantToPlay':
        message = '还没有想玩的游戏';
        break;
      case 'playing':
        message = '还没有在玩的游戏';
        break;
      case 'played':
        message = '还没有玩过的游戏';
        break;
      default:
        message = '还没有收藏任何游戏';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 40, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.gamesList);
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: TextStyle(fontSize: 14),
            ),
            child: Text('发现游戏'),
          ),
        ],
      ),
    );
  }
}