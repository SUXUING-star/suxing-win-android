import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class EmptyStateWidget extends StatelessWidget {
  /// 要显示的提示信息 (必需)。
  final String message;
  /// 在消息上方显示的可选图标数据。
  final IconData? iconData;
  /// 在消息下方显示的可选操作小部件 (例如按钮)。
  final Widget? action;
  /// 可选的图标颜色。默认为主题的提示颜色 (`Theme.of(context).hintColor`) 并带有透明度。
  final Color? iconColor;
  /// 可选的文本样式。默认为主题的 `titleMedium` 样式，颜色为灰色。
  final TextStyle? textStyle;
  /// 可选的图标大小。默认为 60.0。
  final double? iconSize;

  /// 创建一个 EmptyStateWidget。
  ///
  /// [message] 是必须的。
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.iconData,
    this.action,
    this.iconColor,
    this.textStyle,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color defaultIconColor = theme.hintColor.withSafeOpacity(0.7);
    final TextStyle defaultTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.grey[600], // 使用稍深的灰色以提高对比度
      height: 1.5, // 增加行高，改善可读性
    ) ??
        TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5); // 后备样式

    return Center( // 将内容垂直和水平居中
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 在内容周围添加一些边距
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 垂直居中 Column 内容
          crossAxisAlignment: CrossAxisAlignment.center, // 水平居中 Column 内容
          children: <Widget>[
            // 1. 显示图标 (如果提供了 iconData)
            if (iconData != null)
              Icon(
                iconData,
                size: iconSize ?? 60.0, // 使用提供的图标大小或默认值
                color: iconColor ?? defaultIconColor, // 使用提供的颜色或默认颜色
              ),

            // 2. 图标和文字之间的间距 (仅当图标存在时添加)
            if (iconData != null)
              const SizedBox(height: 16.0),

            // 3. 显示消息文本
            Text(
              message,
              textAlign: TextAlign.center, // 文本居中对齐
              style: textStyle ?? defaultTextStyle, // 使用提供的样式或默认样式
            ),

            // 4. 文字和操作按钮之间的间距 (仅当操作存在时添加)
            if (action != null)
              const SizedBox(height: 24.0),

            // 5. 显示操作按钮 (如果提供了 action)
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}