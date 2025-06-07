// lib/widgets/ui/buttons/popup/custom_page_popup_item.dart

/// CustomPagePopupItem 组件，一个自定义的分页弹出菜单项。
/// CustomPagePopupItem 用于在分页控件中显示单个页码及其选中状态。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `CustomPagePopupItem` 类：自定义分页弹出菜单项 UI。
///
/// 该组件根据页码是否为当前选中页，显示不同的背景色、文本颜色和字体粗细。
class CustomPagePopupItem extends StatelessWidget {
  final int pageNumber; // 页码
  final int totalPages; // 总页数
  final bool isCurrentPage; // 是否为当前页

  /// 构造函数。
  ///
  /// [pageNumber]：页码。
  /// [totalPages]：总页数。
  /// [isCurrentPage]：是否当前页。
  const CustomPagePopupItem({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    required this.isCurrentPage,
  });

  /// 构建自定义分页弹出菜单项。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 获取当前主题
    final colorScheme = theme.colorScheme; // 获取颜色方案
    final textColor = isCurrentPage
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withSafeOpacity(0.8); // 文本颜色
    final backgroundColor =
        isCurrentPage ? colorScheme.primary : Colors.white; // 背景色
    final fontWeight =
        isCurrentPage ? FontWeight.bold : FontWeight.normal; // 字体粗细

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor, // 背景色
        border: !isCurrentPage // 边框
            ? Border.all(color: Colors.grey.shade200, width: 0.5)
            : null,
        borderRadius: BorderRadius.circular(4), // 圆角
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // 内边距
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 主轴两端对齐
        children: [
          Text(
            '第 $pageNumber 页', // 页码文本
            style: TextStyle(
              color: textColor, // 字体颜色
              fontWeight: fontWeight, // 字体粗细
              fontSize: 13, // 字体大小
            ),
          ),
          Text(
            '/ $totalPages', // 总页数文本
            style: TextStyle(
              color: textColor.withSafeOpacity(0.7), // 字体颜色
              fontSize: 11, // 字体大小
            ),
          ),
          if (isCurrentPage)
            Icon(Icons.check, size: 16, color: textColor) // 选中页显示对勾图标
        ],
      ),
    );
  }
}
