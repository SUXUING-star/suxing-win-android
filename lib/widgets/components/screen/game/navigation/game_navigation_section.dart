import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class GameNavigationSection extends StatelessWidget { // <--- 改为 StatelessWidget
  final String currentGameId; // 仍然需要知道当前 ID 以避免导航到自身（虽然不太可能）
  final Map<String, dynamic>? navigationInfo; // <--- 新增：接收导航信息
  final Function(String gameId)? onNavigate;

  const GameNavigationSection({
    Key? key,
    required this.currentGameId,
    this.navigationInfo, // <--- 接收导航信息
    this.onNavigate,
  }) : super(key: key);

  // 导航方法保持不变
  void _navigateToGame(BuildContext context, String gameId) {
    if (onNavigate != null) {
      onNavigate!(gameId);
    } else {
      NavigationUtils.pushReplacementNamed(
        context,
        '/games/detail',
        arguments: gameId,
      );
    }
  }

  // 修改: 构建导航按钮，直接使用 navigationInfo
  Widget _buildNavigationButton(BuildContext context, {
    required bool isPrevious,
  }) {
    // 从 navigationInfo 中安全地获取 ID 和 Title
    final gameId = navigationInfo?[isPrevious ? 'previousId' : 'nextId'] as String?;
    final gameTitle = navigationInfo?[isPrevious ? 'previousTitle' : 'nextTitle'] as String?;

    // 如果没有对应的导航游戏 ID，则返回占位
    if (gameId == null || gameId.isEmpty) {
      return Expanded(child: SizedBox.shrink());
    }

    final icon = isPrevious ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios; // 使用更现代的图标
    final label = isPrevious ? '上一篇' : '下一篇';
    final alignment = isPrevious ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final mainAxisAlignmentRow = isPrevious ? MainAxisAlignment.start : MainAxisAlignment.end;
    final textAlign = isPrevious ? TextAlign.left : TextAlign.right;

    return Expanded(
      child: Card(
        margin: EdgeInsets.zero, // 去掉 Card 的默认外边距
        clipBehavior: Clip.antiAlias,
        elevation: 1, // 稍微降低阴影
        shape: RoundedRectangleBorder( // 添加圆角
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _navigateToGame(context, gameId),
          child: Padding( // 在 InkWell 内部添加 Padding
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: mainAxisAlignmentRow,
              children: [
                // 图标在左（上一篇）
                if (isPrevious)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0), // 图标和文字间距
                    child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), // 调整大小和颜色
                  ),

                // 文字部分
                Expanded(
                  child: Column(
                    crossAxisAlignment: alignment,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11, // 稍小
                          color: Colors.grey[600], // 柔和的颜色
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gameTitle?.isNotEmpty == true ? gameTitle! : label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600, // 调整粗细
                          fontSize: 14, // 稍大
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: textAlign,
                      ),
                    ],
                  ),
                ),

                // 图标在右（下一篇）
                if (!isPrevious)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0), // 图标和文字间距
                    child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), // 调整大小和颜色
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 修改: 检查 navigationInfo 是否有效
    final bool hasPrevious = navigationInfo?['previousId'] != null && (navigationInfo!['previousId'] as String? ?? '').isNotEmpty;
    final bool hasNext = navigationInfo?['nextId'] != null && (navigationInfo!['nextId'] as String? ?? '').isNotEmpty;

    // 如果没有导航信息，则不显示
    if (navigationInfo == null || (!hasPrevious && !hasNext)) {
      return const SizedBox.shrink();
    }

    // 构建导航按钮区域
    return Padding( // 添加外层 Padding 控制与其他 Section 的间距
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _buildNavigationButton(context, isPrevious: true),
          if (hasPrevious && hasNext)
            const SizedBox(width: 16), // 增加按钮间距
          _buildNavigationButton(context, isPrevious: false),
        ],
      ),
    );
  }
}