import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    this.onPreviousPage,
    this.onNextPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final bool canGoPrevious = currentPage > 1 && !isLoading;
    final bool canGoNext = currentPage < totalPages && !isLoading;

    // 使用 Row 并让其内容居中
    return Padding(
      // 外层 Padding 控制整个控件组的边距
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ***核心改动：让子元素在 Row 中居中对齐***
        children: [
          // --- 上一页按钮 (不再使用 Expanded) ---
          _buildNavigationButton(
            context,
            label: '上一页',
            icon: Icons.arrow_back_ios_new,
            isEnabled: canGoPrevious,
            onPressed: onPreviousPage,
            isPrevious: true,
          ),

          // --- 中间的页码信息或加载指示器 ---
          _buildPageInfo(context), // 页码/加载指示器

          // --- 下一页按钮 (不再使用 Expanded) ---
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

  // 构建单个导航按钮，样式微调，使其更“轻”
  Widget _buildNavigationButton(BuildContext context, {
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required bool isPrevious,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    // 稍微柔和的禁用颜色
    final Color disabledColor = Colors.grey.shade400;
    // 启用时的颜色可以从主题获取或保持原样
    final Color enabledIconColor = colorScheme.primary;
    final Color enabledTextColor = textTheme.bodyMedium?.color ?? Colors.black87;

    // 使用原始 Card 结构，但调整内部样式
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min, // 让 Row 包裹内容，不主动伸展
      children: [
        if (isPrevious)
          Padding(
            padding: const EdgeInsets.only(right: 4.0), // 减小间距
            child: Icon(icon, size: 14, color: isEnabled ? enabledIconColor : disabledColor), // 减小图标
          ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500, // 正常字重或稍细
            fontSize: 12, // 减小字号
            color: isEnabled ? enabledTextColor : disabledColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!isPrevious)
          Padding(
            padding: const EdgeInsets.only(left: 4.0), // 减小间距
            child: Icon(icon, size: 14, color: isEnabled ? enabledIconColor : disabledColor), // 减小图标
          ),
      ],
    );

    // Card 外层控制形状和点击效果，不再需要 Expanded
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6, // 禁用时稍微透明即可
      child: Card(
        // 添加左右边距，防止按钮紧挨着页码
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        clipBehavior: Clip.antiAlias,
        elevation: isEnabled ? 0.5 : 0, // 降低阴影，更“无感”
        // 可以考虑用 surfaceVariant 或带透明度的 cardColor
        // color: colorScheme.surfaceVariant.withOpacity(0.7),
        color: Theme.of(context).cardColor.withOpacity(0.9), // 卡片背景可以带点透明
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 圆角可以大一点，显得更柔和
          side: isEnabled
              ? BorderSide.none // 启用时无边框
              : BorderSide(color: Colors.grey.shade300.withOpacity(0.5), width: 0.5), // 禁用时可以加个非常淡的边框
        ),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16), // InkWell 的圆角要匹配 Card
          child: Padding(
            // 减小内边距，让按钮更紧凑
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: buttonContent,
          ),
        ),
      ),
    );
  }

  // 构建中间的页码/加载指示器，也调小一点
  Widget _buildPageInfo(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double indicatorSize = 16.0; // 减小加载圈尺寸

    return Padding(
      // 控制页码与按钮的间距
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ConstrainedBox( // 限制最小高度防止跳动
        constraints: const BoxConstraints(minHeight: indicatorSize + 4),
        child: isLoading
            ? SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: 1.5, // 更细的加载圈
            color: colorScheme.primary.withOpacity(0.8),
          ),
        )
            : Text(
          '$currentPage / $totalPages',
          style: textTheme.bodySmall?.copyWith( // 使用更小的字号样式
            fontWeight: FontWeight.w600,
            color: (textTheme.bodySmall?.color ?? Colors.grey.shade700).withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}