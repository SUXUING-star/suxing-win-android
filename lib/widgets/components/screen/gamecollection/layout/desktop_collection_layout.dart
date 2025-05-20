// lib/widgets/components/screen/gamecollection/layout/desktop_collection_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../models/game/game_collection.dart'; // 确保路径正确
import '../../../../../utils/navigation/navigation_utils.dart'; // 确保路径正确
import '../../../../../routes/app_routes.dart'; // 确保路径正确
import '../card/collection_game_card.dart'; // 确保路径正确

/// 桌面设备游戏收藏展示布局 - 只负责展示列表
/// 刷新、加载、错误处理由父组件 (GameCollectionScreen) 完成
class DesktopCollectionLayout extends StatelessWidget {
  // 改为 StatelessWidget
  final List<GameWithCollection> games;
  final String collectionType;
  final String title; // 标题现在可以包含数量，由父组件传入
  final IconData icon;

  const DesktopCollectionLayout({
    super.key,
    required this.games,
    required this.collectionType,
    required this.title, // 直接接收完整标题
    required this.icon,
    // *** 移除 onRefresh 参数 ***
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 列标题 (保持不变，但标题内容由外部传入)
        _buildColumnHeader(),
        const SizedBox(height: 12),
        // 游戏列表内容
        Expanded(
          child: _buildGamesList(context),
        ),
      ],
    );
  }

  // 构建列标题 (保持不变)
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
              icon,
              color: _getStatusColor(),
              size: 20,
            ),
            const SizedBox(width: 8),
            // *** 直接使用传入的 title ***
            Flexible(
              // 使用 Flexible 防止标题过长溢出
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
                overflow: TextOverflow.ellipsis, // 溢出时显示省略号
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建游戏列表
  Widget _buildGamesList(BuildContext context) {
    if (games.isEmpty) {
      // *** 空状态 UI 保持不变 ***
      return _buildEmptyState(context);
    }

    // *** 移除 RefreshIndicator ***
    // 直接返回 ListView
    return ListView.builder(
      padding: const EdgeInsets.all(8), // 内边距
      itemCount: games.length,
      itemBuilder: (context, index) {
        final gameWithCollection = games[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0), // 卡片间距
          // *** 调用 CollectionGameCard 显示卡片 (不变) ***
          child: CollectionGameCard(
            game: gameWithCollection.game,
            collectionStatus: gameWithCollection.collection.status,
          ),
        );
      },
    );
  }

  // 根据收藏类型获取对应颜色 (保持不变)
  Color _getStatusColor() {
    switch (collectionType) {
      case GameCollectionStatus.wantToPlay:
        return Colors.blue;
      case GameCollectionStatus.playing:
        return Colors.green;
      case GameCollectionStatus.played:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 构建空状态视图 (保持不变)
  Widget _buildEmptyState(BuildContext context) {
    String message;
    switch (collectionType) {
      case GameCollectionStatus.wantToPlay:
        message = '还没有想玩的游戏';
        break;
      case GameCollectionStatus.playing:
        message = '还没有在玩的游戏';
        break;
      case GameCollectionStatus.played:
        message = '还没有玩过的游戏';
        break;
      default:
        message = '还没有收藏任何游戏';
    }

    return EmptyStateWidget(
      message: message,
      action: FunctionalButton(
        label: '发现游戏',
        onPressed: () => NavigationUtils.navigateToHome(context, tabIndex: 1),
        icon: Icons.search_rounded,
      ),
    );
  }
}
