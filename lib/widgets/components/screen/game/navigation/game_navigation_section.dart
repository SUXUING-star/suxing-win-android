// lib/widgets/components/screen/game/navigation/game_navigation_section.dart

/// 该文件定义了 [GameNavigationSection] 组件，用于显示游戏的上一篇/下一篇导航。
/// [GameNavigationSection] 负责渲染导航按钮，并处理导航逻辑。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/models/game/game_navigation_info.dart'; // 游戏导航信息模型
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类

/// [GameNavigationSection] 类：游戏导航板块组件。
///
/// 该组件显示用于在游戏详情页之间切换的“上一篇”和“下一篇”按钮。
class GameNavigationSection extends StatelessWidget {
  final String currentGameId; // 当前游戏 ID
  final GameNavigationInfo? navigationInfo; // 游戏导航信息
  final Function(String gameId)? onNavigate; // 导航回调

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [currentGameId]：当前游戏 ID。
  /// [navigationInfo]：游戏导航信息。
  /// [onNavigate]：导航回调。
  const GameNavigationSection({
    super.key,
    required this.currentGameId,
    this.navigationInfo,
    this.onNavigate,
  });

  /// 导航到指定游戏。
  ///
  /// [context]：Build 上下文。
  /// [gameId]：目标游戏 ID。
  /// 如果提供了 `onNavigate` 回调，则调用该回调；否则，执行页面替换。
  void _navigateToGame(BuildContext context, String gameId) {
    if (onNavigate != null) {
      // 检查回调是否存在
      onNavigate!(gameId); // 调用导航回调
    } else {
      NavigationUtils.pushReplacementNamed(
        // 执行页面替换
        context,
        AppRoutes.gameDetail,
        arguments: gameId,
      );
    }
  }

  /// 构建导航按钮。
  ///
  /// [context]：Build 上下文。
  /// [isPrevious]：是否为“上一篇”按钮。
  /// 返回一个包含导航信息的 Card Widget。
  Widget _buildNavigationButton(
    BuildContext context, {
    required bool isPrevious,
  }) {
    String? gameId; // 游戏 ID
    String? gameTitle; // 游戏标题
    if (isPrevious) {
      // 如果是“上一篇”按钮
      gameId = navigationInfo?.previousId;
      gameTitle = navigationInfo?.previousTitle;
    } else {
      // 如果是“下一篇”按钮
      gameId = navigationInfo?.nextId;
      gameTitle = navigationInfo?.nextTitle;
    }
    String finalGameId;
    if (gameId == null || gameId.isEmpty) {
      // 游戏 ID 无效时
      return const Expanded(child: SizedBox.shrink()); // 返回空 Widget
    } else {
      finalGameId = gameId;
    }

    final icon = isPrevious // 根据按钮类型选择图标
        ? Icons.arrow_back_ios_new
        : Icons.arrow_forward_ios;
    final label = isPrevious ? '上一篇' : '下一篇'; // 根据按钮类型选择标签
    final alignment = isPrevious
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end; // 根据按钮类型选择对齐方式
    final mainAxisAlignmentRow = isPrevious
        ? MainAxisAlignment.start
        : MainAxisAlignment.end; // 根据按钮类型选择主轴对齐方式
    final textAlign =
        isPrevious ? TextAlign.left : TextAlign.right; // 根据按钮类型选择文本对齐方式

    return Expanded(
      child: Card(
        margin: EdgeInsets.zero, // 无外边距
        clipBehavior: Clip.antiAlias, // 裁剪行为
        elevation: 1, // 阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 圆角
        ),
        child: InkWell(
          onTap: () => _navigateToGame(context, finalGameId), // 点击时导航到游戏
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 10.0), // 内边距
            child: Row(
              mainAxisAlignment: mainAxisAlignmentRow, // 主轴对齐
              children: [
                if (isPrevious) // “上一篇”按钮时，图标在左
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0), // 右侧内边距
                    child: Icon(icon, // 图标
                        size: 18,
                        color: Theme.of(context).colorScheme.primary), // 图标颜色
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: alignment, // 交叉轴对齐
                    mainAxisSize: MainAxisSize.min, // 最小尺寸
                    children: [
                      Text(
                        label, // 标签
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2), // 间距
                      Text(
                        gameTitle?.isNotEmpty == true
                            ? gameTitle!
                            : label, // 游戏标题或标签
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1, // 最大行数
                        overflow: TextOverflow.ellipsis, // 溢出时显示省略号
                        textAlign: textAlign, // 文本对齐
                      ),
                    ],
                  ),
                ),
                if (!isPrevious) // “下一篇”按钮时，图标在右
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0), // 左侧内边距
                    child: Icon(icon, // 图标
                        size: 18,
                        color: Theme.of(context).colorScheme.primary), // 图标颜色
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建 Widget。
  ///
  /// 根据导航信息构建“上一篇”和“下一篇”按钮。
  @override
  Widget build(BuildContext context) {
    final bool hasPrevious = navigationInfo?.previousId != null &&
        (navigationInfo?.previousId ?? '').isNotEmpty; // 是否有上一篇
    final bool hasNext = navigationInfo?.nextId != null &&
        (navigationInfo?.nextId ?? '').isNotEmpty; // 是否有下一篇

    if (navigationInfo == null || (!hasPrevious && !hasNext)) {
      // 无导航信息时
      return const SizedBox.shrink(); // 返回空 Widget
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 垂直内边距
      child: Row(
        children: [
          _buildNavigationButton(context, isPrevious: true), // 上一篇按钮
          if (hasPrevious && hasNext) const SizedBox(width: 16), // 按钮间距
          _buildNavigationButton(context, isPrevious: false), // 下一篇按钮
        ],
      ),
    );
  }
}
