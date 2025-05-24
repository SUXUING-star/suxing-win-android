import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// 自定义分页弹出菜单项 UI
class CustomPagePopupItem extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final bool isCurrentPage;

  const CustomPagePopupItem({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    required this.isCurrentPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isCurrentPage
        ? colorScheme.onPrimary // 当前页用主色调上的文字颜色 (通常是白色)
        : colorScheme.onSurface.withSafeOpacity(0.8); // 其他页用表面颜色上的文字 (深灰/黑色)
    final backgroundColor = isCurrentPage
        ? colorScheme.primary // 当前页用主色调背景
        : Colors.white; // 其他页用白色背景
    final fontWeight = isCurrentPage ? FontWeight.bold : FontWeight.normal;

    // 使用 Container 来完全控制背景、内边距和样式
    return Container(
      // color: backgroundColor, // 直接设置 color 会覆盖 InkWell 的效果，下面用 decoration
      decoration: BoxDecoration(
        color: backgroundColor,
        // 可以给非当前页加个细微的边框？
        border: !isCurrentPage
            ? Border.all(color: Colors.grey.shade200, width: 0.5)
            : null,
        borderRadius: BorderRadius.circular(4), // 如果想要圆角效果
      ),
      // 控制内边距，让文字离边缘有距离
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        // 用 Row 来布局，可以加图标等
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 让页码和总数分开点
        children: [
          Text(
            '第 $pageNumber 页',
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: 13, // 稍微大一点的字号
            ),
          ),
          //如果需要，可以在右边显示总页数或其他信息
          Text(
            '/ $totalPages',
            style: TextStyle(
              color: textColor.withSafeOpacity(0.7),
              fontSize: 11,
            ),
          ),
          // 或者给当前页加个小对勾图标？
          if (isCurrentPage) Icon(Icons.check, size: 16, color: textColor)
        ],
      ),
    );
  }
}
