// lib/widgets/components/screen/gamecollection/layout/mobile_collection_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/components/screen/gamecollection/card/collection_game_card.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/models/game/game_collection.dart'; // 确保路径正确
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 确保路径正确


/// 移动设备游戏收藏展示布局 - 只负责展示列表
/// 刷新、加载、错误处理由父组件 (GameCollectionScreen) 完成
class MobileCollectionLayout extends StatelessWidget {
  // 改为 StatelessWidget
  final List<GameWithCollection> games;
  final String collectionType;

  const MobileCollectionLayout({
    super.key,
    required this.games,
    required this.collectionType,
    // *** 移除 onRefresh 参数 ***
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      // *** 空状态 UI 保持不变 ***
      return _buildEmptyState(context);
    }

    // *** 移除 RefreshIndicator ***
    // 直接返回 Padding 和 ListView
    return Padding(
      // 可以根据需要调整内边距
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListView.builder(
        // physics: const AlwaysScrollableScrollPhysics(), // 如果需要即使内容不足也允许滚动触发父级刷新
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), // 列表本身的内边距
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
      ),
    );
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
