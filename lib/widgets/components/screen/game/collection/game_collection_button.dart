// lib/widgets/components/screen/game/collection/game_collection_button.dart

/// 该文件定义了 GameCollectionButton 组件，用于显示和触发游戏的收藏操作。
/// 该组件根据收藏状态、加载状态和紧凑模式渲染不同的按钮样式。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/constants/game/game_constants.dart'; // 游戏常量所需
import 'package:suxingchahui/models/game/game_collection_item.dart'; // 游戏收藏项模型所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// `GameCollectionButton` 类：显示和触发游戏收藏操作的 StatelessWidget。
///
/// 该组件根据收藏状态、加载状态和紧凑模式渲染不同的按钮样式。
class GameCollectionButton extends StatelessWidget {
  final GameCollectionItem? collectionStatus; // 当前游戏的收藏状态
  final bool isLoading; // 按钮是否处于加载状态
  final VoidCallback onPressed; // 按钮点击回调
  final bool compact; // 是否为紧凑模式
  final bool isPreview; // 是否为预览模式

  /// 构造函数。
  ///
  /// [collectionStatus]：当前游戏的收藏状态。
  /// [isLoading]：按钮是否处于加载状态。
  /// [onPressed]：按钮点击回调。
  /// [compact]：是否为紧凑模式。
  /// [isPreview]：是否为预览模式。
  const GameCollectionButton({
    super.key,
    required this.collectionStatus,
    required this.isLoading,
    required this.onPressed,
    this.compact = false,
    this.isPreview = false,
  });

  /// 构建组件的 UI。
  ///
  /// [context]：Build 上下文。
  /// 根据收藏状态和预览模式渲染不同的按钮。
  @override
  Widget build(BuildContext context) {
    final bool hasStatus = collectionStatus != null; // 判断是否存在收藏状态
    final ThemeData theme = Theme.of(context); // 获取当前主题数据

    if (isPreview) {
      // 预览模式下不显示任何内容
      return const SizedBox.shrink();
    }

    if (hasStatus) {
      // 存在收藏状态时显示收藏状态按钮
      return _buildCollectionStatusButton(collectionStatus!.status, theme);
    } else {
      // 否则显示添加收藏按钮
      return _buildAddCollectionButton(theme);
    }
  }

  /// 构建“添加收藏”按钮的 Widget。
  ///
  /// [theme]：当前主题数据。
  /// 返回一个添加收藏的按钮。
  Widget _buildAddCollectionButton(ThemeData theme) {
    if (compact) {
      // 紧凑模式下显示图标按钮
      return IconButton(
        icon: isLoading
            ? const LoadingWidget(size: 18) // 加载中显示加载指示器
            : Icon(Icons.add_circle_outline,
                color: theme.primaryColor), // 否则显示添加图标
        tooltip: isLoading ? '处理中' : '添加收藏', // 工具提示
        onPressed: isLoading ? null : onPressed, // 加载中时禁用按钮
      );
    } else {
      // 非紧凑模式下显示 ElevatedButton
      return ElevatedButton.icon(
        icon: isLoading
            ? const LoadingWidget(size: 18) // 加载中显示加载指示器
            : const Icon(Icons.add_circle_outline,
                color: Colors.white, size: 18), // 否则显示添加图标
        label: Text(isLoading ? '处理中' : '添加收藏'), // 按钮文本
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: theme.primaryColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: isLoading ? null : onPressed, // 加载中时禁用按钮
      );
    }
  }

  /// 构建显示当前收藏状态的按钮 Widget。
  ///
  /// [status]：收藏状态字符串。
  /// [theme]：当前主题数据。
  /// 返回一个显示收藏状态的按钮。
  Widget _buildCollectionStatusButton(String status, ThemeData theme) {
    final statusTheme = GameCollectionStatusUtils.getTheme(status); // 获取对应状态的主题

    if (compact) {
      // 紧凑模式下显示图标按钮
      return IconButton(
        icon: isLoading
            ? const LoadingWidget(size: 18) // 加载中显示加载指示器
            : Icon(statusTheme.icon, color: statusTheme.textColor), // 否则显示状态图标
        tooltip: isLoading ? '处理中' : statusTheme.text, // 工具提示
        onPressed: isLoading ? null : onPressed, // 加载中时禁用按钮
      );
    } else {
      // 非紧凑模式下显示 OutlinedButton
      return OutlinedButton.icon(
        icon: isLoading
            ? const LoadingWidget(size: 18) // 加载中显示加载指示器
            : Icon(statusTheme.icon, size: 18), // 否则显示状态图标
        label: Text(isLoading ? '处理中' : statusTheme.text), // 按钮文本
        style: OutlinedButton.styleFrom(
          foregroundColor: statusTheme.textColor,
          backgroundColor: statusTheme.backgroundColor,
          side: BorderSide(
              color: statusTheme.textColor.withSafeOpacity(0.5),
              width: 1), // 边框样式
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: isLoading ? null : onPressed, // 加载中时禁用按钮
      );
    }
  }
}
