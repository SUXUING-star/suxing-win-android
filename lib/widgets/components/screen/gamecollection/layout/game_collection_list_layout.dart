// lib/widgets/components/screen/gamecollection/layout/game_collection_list_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/widgets/components/screen/gamecollection/card/game_collection_game_card.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/utils/device/device_utils.dart'; // 需要引入 DeviceUtils

class GameCollectionListLayout extends StatelessWidget {
  final List<GameWithCollection> games;
  final SidebarProvider sidebarProvider;
  final String collectionType;
  final String? desktopTitle; // 桌面版列标题
  final IconData? desktopIcon; // 桌面版列图标

  const GameCollectionListLayout({
    super.key,
    required this.games,
    required this.sidebarProvider,
    required this.collectionType,
    this.desktopTitle, // 可选，仅桌面用
    this.desktopIcon, // 可选，仅桌面用
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面

    if (isDesktop) {
      // --- 桌面布局 ---
      // 必须提供桌面标题和图标
      assert(desktopTitle != null && desktopIcon != null,
          'Desktop layout requires desktopTitle and desktopIcon.');
      return Column(
        children: [
          _buildDesktopColumnHeader(desktopTitle!, desktopIcon!), // 使用断言后的非空值
          const SizedBox(height: 12),
          Expanded(
            child: _buildGamesListOrEmptyState(context),
          ),
        ],
      );
    } else {
      // --- 移动布局 ---
      // 移动版直接是列表或者空状态
      return _buildGamesListOrEmptyState(context);
    }
  }

  // 构建桌面版的列标题 (原 DesktopCollectionLayout._buildColumnHeader)
  Widget _buildDesktopColumnHeader(String title, IconData icon) {
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
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建游戏列表或空状态 (这是共享逻辑)
  Widget _buildGamesListOrEmptyState(BuildContext context) {
    if (games.isEmpty) {
      return _buildEmptyState(context); // 空状态是共享的
    }

    // 列表的 padding 根据是否桌面调整，移动版通常有自己的外层 padding
    final bool isDesktop = DeviceUtils.isDesktop;
    EdgeInsets listPadding = isDesktop
        ? const EdgeInsets.all(8) // 桌面列表的内边距
        : const EdgeInsets.only(top: 8.0, bottom: 8.0); // 移动列表的内边距

    return ListView.builder(
      padding: listPadding,
      itemCount: games.length,
      itemBuilder: (context, index) {
        final gameWithCollection = games[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0), // 卡片间距
          child: GameCollectionGameCard(
            game: gameWithCollection.game,
            collectionStatus: gameWithCollection.collection.status,
          ),
        );
      },
    );
  }

  // 获取状态颜色 (共享逻辑)
  Color _getStatusColor() {
    return GameConstants.getGameCollectionStatusColor(collectionType);
  }

  // 构建空状态视图 (共享逻辑)
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
        onPressed: () => NavigationUtils.navigateToHome(
            sidebarProvider, context,
            tabIndex: 1),
        icon: Icons.search_rounded,
      ),
    );
  }
}
