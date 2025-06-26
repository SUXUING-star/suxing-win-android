// lib/widgets/components/screen/home/section/home_latest_games.dart

/// 该文件定义了 HomeLatestGames 组件，用于显示主页的最新发布游戏板块。
/// HomeLatestGames 包含加载、错误、空状态和正常显示游戏卡片列表的逻辑。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart'; // 动画列表视图
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart'; // 通用游戏卡片组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由

/// `HomeLatestGames` 类：主页最新发布游戏板块组件。
///
/// 该组件负责展示最新发布的游戏，并处理加载、错误和空状态。
class HomeLatestGames extends StatelessWidget {
  final List<Game>? games; // 最新游戏列表
  final bool isLoading; // 是否正在加载
  final String? errorMessage; // 错误消息
  final Function(bool) onRetry; // 重试回调

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [games]：最新游戏列表。
  /// [isLoading]：是否正在加载。
  /// [errorMessage]：错误消息。
  /// [onRetry]：重试回调。
  const HomeLatestGames({
    super.key,
    required this.games,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  /// 构建 Widget。
  ///
  /// 渲染最新发布游戏板块，包含标题和游戏列表。
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // 内边距
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9), // 背景颜色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8), // 垂直内边距
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ), // 底部边框
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, // 主题色
                    borderRadius: BorderRadius.circular(3), // 圆角
                  ),
                ),
                const SizedBox(width: 12), // 间距
                Text(
                  '最新发布', // 标题文本
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const Spacer(), // 占据剩余空间
                InkWell(
                  borderRadius: BorderRadius.circular(8), // 圆角
                  onTap: () {
                    // 点击回调
                    NavigationUtils.pushNamed(
                      context,
                      AppRoutes.latestGames,
                    ); // 导航到最新游戏页面
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4), // 内边距
                    child: Row(
                      children: [
                        Text(
                          '更多', // 文本
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4), // 间距
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[700],
                        ) // 图标
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // 间距
          _buildGameListArea(context), // 构建游戏列表区域
        ],
      ),
    );
  }

  /// 构建游戏列表区域。
  ///
  /// [context]：Build 上下文。
  /// 根据加载、错误、空状态和正常状态渲染不同的内容。
  Widget _buildGameListArea(BuildContext context) {
    if (isLoading && games == null) {
      // 加载中且无数据时
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0), // 垂直内边距
        child: LoadingWidget(message: '加载最新游戏...', size: 24), // 加载指示器
      );
    }

    if (errorMessage != null && games == null) {
      // 错误状态且无数据时
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // 垂直内边距
        child: InlineErrorWidget(
          errorMessage: errorMessage!,
          onRetry: () => onRetry(true),
        ), // 错误组件
      );
    }
    final displayGames = games ?? []; // 待显示游戏列表
    if (!isLoading && displayGames.isEmpty) {
      // 空状态时
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // 垂直内边距
        child: InlineErrorWidget(
          errorMessage: '暂无最新游戏',
          icon: Icons.inbox_outlined,
          iconSize: 40,
          iconColor: Colors.grey,
          onRetry: () => onRetry(true),
        ), // 空状态组件
      );
    }

    return Stack(
      children: [
        _buildVerticalGameList(displayGames, context), // 构建垂直游戏列表
        if (isLoading && displayGames.isNotEmpty) // 加载中且有数据时显示加载指示器
          Positioned.fill(
              child: Container(
            color: Colors.white.withSafeOpacity(0.5), // 半透明背景
            child: const LoadingWidget(size: 30), // 加载指示器
          )),
      ],
    );
  }

  /// 构建垂直游戏列表。
  ///
  /// [gameList]：游戏列表。
  /// [context]：Build 上下文。
  /// 返回一个动画列表视图。
  Widget _buildVerticalGameList(List<Game> gameList, BuildContext context) {
    final itemsToShow = gameList.take(3).toList(); // 取前 3 个游戏显示
    if (itemsToShow.isEmpty) {
      // 列表为空时
      return const SizedBox(
        height: 100, // 固定高度
        child: Center(
          child: Text(
            "没有最新游戏可显示",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return AnimatedListView<Game>(
      // 动画列表视图
      listKey: const ValueKey('home_latest_games_list'), // 列表 Key
      items: itemsToShow, // 列表项
      shrinkWrap: true, // 在 Column 内正常工作
      physics: const NeverScrollableScrollPhysics(), // 禁用其内部滚动
      padding: EdgeInsets.zero, // 无内边距
      itemBuilder: (ctx, index, game) {
        return Column(
          children: [
            CommonGameCard(
              // 通用游戏卡片
              game: game,
              isGridItem: false, // 设置为非网格项
            ),
            if (index < itemsToShow.length - 1) // 非最后一项时显示分割线
              Divider(
                height: 16,
                indent: 88,
                endIndent: 16,
                color: Colors.grey.withSafeOpacity(0.1),
              ),
          ],
        );
      },
    );
  }
}
