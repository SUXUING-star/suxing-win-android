import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/custom_page_popup_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/custom_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  // 回调不变：当用户通过菜单选择了新页码时调用
  final ValueChanged<int>? onPageSelected;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final bool canGoPrevious = currentPage > 1 && !isLoading;
    final bool canGoNext = currentPage < totalPages && !isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavigationButton(
            context,
            label: '上一页',
            icon: Icons.arrow_back_ios_new,
            isEnabled: canGoPrevious,
            onPressed: onPreviousPage,
            isPrevious: true,
          ),

          // --- 中间的页码信息 (使用 PopupMenuButton) ---
          _buildPageInfo(context), // 现在用 PopupMenuButton 实现

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

  // 构建单个导航按钮 (不变)
  Widget _buildNavigationButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required bool isPrevious,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color disabledColor = Colors.grey.shade400;
    final Color enabledIconColor = colorScheme.primary;
    final Color enabledTextColor =
        textTheme.bodyMedium?.color ?? Colors.black87;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPrevious)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Icon(icon,
                size: 14, color: isEnabled ? enabledIconColor : disabledColor),
          ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isEnabled ? enabledTextColor : disabledColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!isPrevious)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(icon,
                size: 14, color: isEnabled ? enabledIconColor : disabledColor),
          ),
      ],
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        clipBehavior: Clip.antiAlias,
        elevation: isEnabled ? 0.5 : 0,
        color: Theme.of(context).cardColor.withSafeOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isEnabled
              ? BorderSide.none
              : BorderSide(
                  color: Colors.grey.shade300.withSafeOpacity(0.5), width: 0.5),
        ),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: buttonContent,
          ),
        ),
      ),
    );
  }

  // *** 构建中间的页码信息 (使用 PopupMenuButton 实现) ***
  // *** 构建中间的页码信息 (尝试移除 ConstrainedBox/Center) ***
  Widget _buildPageInfo(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double indicatorSize = 16.0;
    final pageInfoStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: (textTheme.bodySmall?.color ?? Colors.grey.shade700)
          .withSafeOpacity(0.9),
    );
    final disabledPageInfoColor =
        (textTheme.bodySmall?.color ?? Colors.grey.shade700)
            .withSafeOpacity(0.5);

    // 1. 加载圈 (不变)
    if (isLoading) {
      // *** 为了保险，也给加载圈一个明确的大小，避免依赖 ConstrainedBox ***
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          // 直接用 SizedBox 指定大小
          width: indicatorSize,
          height: 30, // 给一个大概的高度，跟按钮差不多
          child: Center(
            // Center 保证加载圈在 SizedBox 中间
            child: SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colorScheme.primary.withSafeOpacity(0.8),
              ),
            ),
          ),
        ),
      );
    }

    // 2. 使用 CustomPopupMenuButton，并用自定义 Item
    if (totalPages > 1 && onPageSelected != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CustomPopupMenuButton<int>(
          // 继续使用支持 child 的版本
          itemBuilder: (context) {
            return List<PopupMenuEntry<int>>.generate(totalPages, (index) {
              final page = index + 1;
              return PopupMenuItem<int>(
                value: page,
                // *** 重要：移除内边距，让 child 完全填充 ***
                padding: EdgeInsets.zero,
                // *** 设置 enabled 为 false 可以禁用默认的 Material 点击效果 (可选) ***
                // enabled: false, // 如果完全不想要 Material 的反馈，可以试试这个
                height: 40, // 根据 CustomPagePopupItem 的内边距调整，确保高度足够
                // *** 把自定义的 Item 作为 child ***
                child: CustomPagePopupItem(
                  pageNumber: page,
                  totalPages: totalPages,
                  isCurrentPage: page == currentPage,
                ),
              );
            });
          },
          onSelected: (int newPage) {
            if (newPage != currentPage) {
              onPageSelected!(newPage);
            }
          },
          tooltip: '跳转页面',
          isEnabled: !isLoading,
          shape: RoundedRectangleBorder(
            // 保持菜单的圆角
            borderRadius: BorderRadius.circular(8.0),
          ),
          // *** 设置菜单背景为透明或白色，让 Item 的背景生效 ***
          // 如果 CustomPagePopupItem 本身有背景色，这里可以设为透明
          menuBackgroundColor: Colors.transparent, // 例如，让菜单背景透明
          // 或者如果 CustomPagePopupItem 没有设置背景，这里统一设置白色
          // color: Colors.white,
          elevation: 0, // 保持阴影
          padding: EdgeInsets.zero, // 继续使用支持 child 的版本
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            height: 30,
            alignment: Alignment.center,
            child: Text(
              '$currentPage / $totalPages',
              style: pageInfoStyle,
            ),
          ),
        ),
      );
    }
    // 3. 只显示文本 (移除 ConstrainedBox 和 Center)
    else {
      // *** 也给纯文本一个明确的高度或容器，保持一致性 ***
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          // 用 Container 包裹
          padding: const EdgeInsets.symmetric(vertical: 6.0), // 同上，给点垂直空间
          height: 30, // 保持和其他情况高度一致
          alignment: Alignment.center, // 确保文本在容器中居中
          child: Text(
            '$currentPage / $totalPages',
            style: onPageSelected == null
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
} // --- PaginationControls 组件结束 ---
