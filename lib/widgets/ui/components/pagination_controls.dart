// lib/widgets/ui/components/pagination_controls.dart

/// 该文件定义了 PaginationControls 组件，一个用于控制分页的 UI 控件。
/// PaginationControls 允许用户导航到上一页、下一页或选择特定页码。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/buttons/popup/custom_page_popup_item.dart'; // 导入自定义页码弹窗项
import 'package:suxingchahui/widgets/ui/buttons/popup/custom_popup_menu_button.dart'; // 导入自定义弹窗菜单按钮
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `PaginationControls` 类：分页控制组件。
///
/// 该组件提供上一页、下一页按钮和页码选择功能。
class PaginationControls extends StatelessWidget {
  final int currentPage; // 当前页码
  final int totalPages; // 总页数
  final bool isLoading; // 是否正在加载中
  final VoidCallback? onPreviousPage; // 点击上一页的回调
  final VoidCallback? onNextPage; // 点击下一页的回调
  final ValueChanged<int>? onPageSelected; // 选中页码的回调

  /// 构造函数。
  ///
  /// [currentPage]：当前页。
  /// [totalPages]：总页数。
  /// [isLoading]：是否加载中。
  /// [onPreviousPage]：上一页回调。
  /// [onNextPage]：下一页回调。
  /// [onPageSelected]：选中页回调。
  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
  });

  /// 构建分页控制组件。
  ///
  /// 当总页数小于等于 1 时，不显示分页控件。
  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      // 总页数小于等于 1 时返回空组件
      return const SizedBox.shrink();
    }

    final bool canGoPrevious = currentPage > 1 && !isLoading; // 是否可前往上一页
    final bool canGoNext = currentPage < totalPages && !isLoading; // 是否可前往下一页

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 行主轴居中
        children: [
          _buildNavigationButton(
            context,
            label: '上一页',
            icon: Icons.arrow_back_ios_new,
            isEnabled: canGoPrevious,
            onPressed: onPreviousPage,
            isPrevious: true,
          ),

          _buildPageInfo(context), // 构建中间的页码信息

          _buildNavigationButton(
            context,
            label: '下一页',
            icon: Icons.arrow_forward_ios,
            isEnabled: canGoNext,
            onPressed: onNextPage,
            isPrevious: false,
          ),
        ],
      ),
    );
  }

  /// 构建单个导航按钮。
  ///
  /// [context]：Build 上下文。
  /// [label]：按钮文本。
  /// [icon]：按钮图标。
  /// [isEnabled]：按钮是否启用。
  /// [onPressed]：按钮点击回调。
  /// [isPrevious]：是否为上一页按钮。
  Widget _buildNavigationButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required bool isPrevious,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme; // 颜色方案
    final TextTheme textTheme = Theme.of(context).textTheme; // 文本主题
    final Color disabledColor = Colors.grey.shade400; // 禁用颜色
    final Color enabledIconColor = colorScheme.primary; // 启用图标颜色
    final Color enabledTextColor =
        textTheme.bodyMedium?.color ?? Colors.black87; // 启用文本颜色

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
      children: [
        if (isPrevious) // 上一页图标
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Icon(
              icon,
              size: 14,
              color: isEnabled ? enabledIconColor : disabledColor,
            ),
          ),
        Text(
          label, // 按钮文本
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isEnabled ? enabledTextColor : disabledColor,
          ),
          maxLines: 1, // 最大行数
          overflow: TextOverflow.ellipsis, // 溢出显示省略号
        ),
        if (!isPrevious) // 下一页图标
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(
              icon,
              size: 14,
              color: isEnabled ? enabledIconColor : disabledColor,
            ),
          ),
      ],
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6, // 根据是否启用设置透明度
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6.0), // 外边距
        clipBehavior: Clip.antiAlias, // 裁剪行为
        elevation: isEnabled ? 0.5 : 0, // 阴影高度
        color: Theme.of(context).cardColor.withSafeOpacity(0.9), // 背景色
        shape: RoundedRectangleBorder(
          // 形状
          borderRadius: BorderRadius.circular(16), // 圆角
          side: isEnabled // 边框
              ? BorderSide.none
              : BorderSide(
                  color: Colors.grey.shade300.withSafeOpacity(0.5), width: 0.5),
        ),
        child: InkWell(
          onTap: isEnabled ? onPressed : null, // 点击回调
          borderRadius: BorderRadius.circular(16), // 圆角
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10.0, vertical: 6.0), // 内边距
            child: buttonContent, // 按钮内容
          ),
        ),
      ),
    );
  }

  /// 构建中间的页码信息区域。
  ///
  /// [context]：Build 上下文。
  /// 显示加载指示器、页码选择弹窗或纯文本页码信息。
  Widget _buildPageInfo(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme; // 颜色方案
    final TextTheme textTheme = Theme.of(context).textTheme; // 文本主题
    const double indicatorSize = 16.0; // 指示器大小
    final pageInfoStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: (textTheme.bodySmall?.color ?? Colors.grey.shade700)
          .withSafeOpacity(0.9),
    ); // 页码信息文本样式
    final disabledPageInfoColor =
        (textTheme.bodySmall?.color ?? Colors.grey.shade700)
            .withSafeOpacity(0.5); // 禁用页码信息颜色

    if (isLoading) {
      // 加载中状态
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // 水平内边距
        child: SizedBox(
          width: indicatorSize, // 宽度
          height: 30, // 高度
          child: Center(
            child: SizedBox(
              width: indicatorSize, // 宽度
              height: indicatorSize, // 高度
              child: LoadingWidget(
                color: colorScheme.primary.withSafeOpacity(0.8), // 颜色
              ),
            ),
          ),
        ),
      );
    }

    if (totalPages > 1 && onPageSelected != null) {
      // 多页且有页码选择回调
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // 水平内边距
        child: CustomPopupMenuButton<int>(
          itemBuilder: (context) {
            return List<PopupMenuEntry<int>>.generate(totalPages, (index) {
              final page = index + 1;
              return PopupMenuItem<int>(
                value: page, // 菜单项值
                padding: EdgeInsets.zero, // 内边距
                height: 40, // 高度
                child: CustomPagePopupItem(
                  pageNumber: page, // 页码
                  totalPages: totalPages, // 总页数
                  isCurrentPage: page == currentPage, // 是否当前页
                ),
              );
            });
          },
          onSelected: (int newPage) {
            if (newPage != currentPage) {
              onPageSelected!(newPage); // 选中页码回调
            }
          },
          tooltip: '跳转页面', // 提示
          isEnabled: !isLoading, // 是否启用
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // 圆角
          ),
          menuBackgroundColor: Colors.transparent, // 菜单背景透明
          elevation: 0, // 阴影
          padding: EdgeInsets.zero, // 内边距
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0), // 垂直内边距
            height: 30, // 高度
            alignment: Alignment.center, // 居中对齐
            child: Text(
              '$currentPage / $totalPages', // 页码信息文本
              style: pageInfoStyle, // 文本样式
            ),
          ),
        ),
      );
    } else {
      // 只有一页或无页码选择回调
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // 水平内边距
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0), // 垂直内边距
          height: 30, // 高度
          alignment: Alignment.center, // 居中对齐
          child: Text(
            '$currentPage / $totalPages', // 页码信息文本
            style: onPageSelected == null // 文本样式
                ? TextStyle(
                    color: disabledPageInfoColor,
                    fontSize: pageInfoStyle?.fontSize,
                    fontWeight: pageInfoStyle?.fontWeight)
                : pageInfoStyle,
          ),
        ),
      );
    }
  }
}
