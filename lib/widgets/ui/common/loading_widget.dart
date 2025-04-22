// lib/widgets/ui/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/modern_loading_animation.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 确保这个导入路径正确

class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color; // 动画颜色 (优先使用)
  final double size;  // 动画大小 (内联和覆盖卡片模式现在用同一个控制)
  final bool isOverlay; // 决定是内联显示还是覆盖显示
  // --- Overlay specific params ---
  final bool isDismissible;
  final Widget? child; // For overlay mode on top of specific content
  final double overlayOpacity; // Renamed from opacity for clarity
  final Color? overlayCardColor; // Specific color for the overlay card background
  final Color? overlayTextColor; // Specific color for text inside the overlay card
  final EdgeInsets overlayCardPadding;
  final double overlayCardBorderRadius;
  final double overlayCardWidth;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 32.0, // Default size for animation
    this.isOverlay = false,
    // --- Overlay defaults ---
    this.isDismissible = false,
    this.child,
    this.overlayOpacity = 0.4, // Slightly increased default opacity for better visibility
    this.overlayCardColor, // Default will be Theme.of(context).cardColor
    this.overlayTextColor, // Default will be calculated based on card color
    this.overlayCardPadding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24), // Adjusted padding
    this.overlayCardBorderRadius = 12.0,
    this.overlayCardWidth = 130.0, // Adjusted width
  });

  /// 创建一个内联加载指示器 (动画 + 可选文字，无背景容器)
  factory LoadingWidget.inline({
    String? message,
    Color? color,
    double size = 24.0, // 内联默认小一点
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size,
      isOverlay: false, // 明确是内联
    );
  }

  /// 创建一个覆盖整个页面的加载指示器 (带背景卡片)
  factory LoadingWidget.fullScreen({
    String? message = "加载中...", // Add default message
    Color? color,
    bool isDismissible = false,
    double opacity = 0.4,
    double size = 36.0, // Full screen animation slightly larger
    Color? cardColor,
    Color? textColor,
    EdgeInsets cardPadding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    double cardBorderRadius = 12.0,
    double cardWidth = 130.0,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size,
      isOverlay: true, // 明确是覆盖
      isDismissible: isDismissible,
      overlayOpacity: opacity,
      overlayCardColor: cardColor,
      overlayTextColor: textColor,
      overlayCardPadding: cardPadding,
      overlayCardBorderRadius: cardBorderRadius,
      overlayCardWidth: cardWidth,
      // child is null for full screen
    );
  }

  /// 创建一个覆盖在特定内容上的加载指示器 (带背景卡片)
  factory LoadingWidget.overlay({
    required Widget child,
    String? message = "加载中...", // Add default message
    Color? color,
    bool isDismissible = false,
    double opacity = 0.4,
    double size = 32.0, // Overlay on content default size
    Color? cardColor,
    Color? textColor,
    EdgeInsets cardPadding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    double cardBorderRadius = 12.0,
    double cardWidth = 130.0,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size,
      isOverlay: true, // 明确是覆盖
      isDismissible: isDismissible, // Pass the child to overlay
      overlayOpacity: opacity,
      overlayCardColor: cardColor,
      overlayTextColor: textColor,
      overlayCardPadding: cardPadding,
      overlayCardBorderRadius: cardBorderRadius,
      overlayCardWidth: cardWidth,
      child: child,
    );
  }

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {

  @override
  Widget build(BuildContext context) {
    // 决定动画颜色：优先 widget.color，否则主题色
    final Color loadingColor = widget.color ?? Theme.of(context).primaryColor;

    if (!widget.isOverlay) {
      // **【改动点】调用修改后的内联构建，现在不带背景容器**
      return _buildInlineLoading(loadingColor);
    }
    // **调用覆盖构建，内部使用带背景的卡片**
    return _buildOverlayLoading(loadingColor);
  }

  // **【改动点】内联加载构建方法 - 改回简单版本 (无背景容器)**
  Widget _buildInlineLoading(Color loadingColor) {
    // 内联文字颜色：可以简单使用次要文字颜色
    final Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600]!;

    return Center( // 使用 Center 确保在可用空间内居中
      child: Column(
        mainAxisSize: MainAxisSize.min, // 让 Column 包裹内容
        children: [
          // --- 直接使用外部统一动画组件 ---
          ModernLoadingAnimation(
            size: widget.size, // 使用 widget 的 size 控制
            color: loadingColor, // 使用计算好的颜色
          ),
          // --- 如果有消息，显示文字 ---
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 8), // 动画和文字之间的间距
            Text(
              widget.message!,
              style: TextStyle(
                color: textColor, // 使用计算的文字颜色
                fontSize: 13, // 内联文字可以小一点
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // 覆盖加载构建方法 (基本不变，使用 _buildLoadingCard)
  Widget _buildOverlayLoading(Color loadingColor) {
    Widget overlayContent = Material( // Use Material for transparency and ink effects if needed later
      type: MaterialType.transparency,
      child: Container(
        // Background dimming effect
        color: Colors.black.withOpacity(widget.overlayOpacity),
        child: Center(
          child: GestureDetector( // Wrap card with GestureDetector for dismissible
            onTap: widget.isDismissible ? () {
              // Safely attempt to pop the route
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } : null,
            // Prevent taps falling through to underlying content when not dismissible
            behavior: HitTestBehavior.opaque,
            child: TweenAnimationBuilder<double>( // Fade-in and scale animation
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250), // Slightly longer duration
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    // **构建包含背景、动画和文字的卡片**
                    child: _buildLoadingCard(loadingColor),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // If child is provided, stack the overlay on top
    if (widget.child != null) {
      return Stack(
        children: [
          widget.child!,
          Positioned.fill(child: overlayContent),
        ],
      );
    }
    // Otherwise, return the overlay content directly (for full screen)
    return overlayContent;
  }

  // 加载卡片构建方法 (用于 Overlay 模式，保持带背景容器的样式)
  Widget _buildLoadingCard(Color loadingColor) {
    // 卡片背景色：优先 widget 参数，否则用主题卡片色
    final Color cardBgColor = widget.overlayCardColor ?? Theme.of(context).cardColor;
    // 卡片内文字颜色：优先 widget 参数，否则根据背景亮度计算
    final Color textColor = widget.overlayTextColor ??
        (ThemeData.estimateBrightnessForColor(cardBgColor) == Brightness.dark
            ? Colors.white.withOpacity(0.85)
            : Colors.black.withOpacity(0.75));

    return Container(
      width: widget.overlayCardWidth, // Use parameter for width
      padding: widget.overlayCardPadding, // Use parameter for padding
      decoration: BoxDecoration(
        color: cardBgColor.withOpacity(0.95), // Apply slight transparency to card background
        borderRadius: BorderRadius.circular(widget.overlayCardBorderRadius), // Use parameter for radius
        boxShadow: [ // Subtle shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 动画 ---
          ModernLoadingAnimation(
            size: widget.size, // Use widget's size for animation inside card
            color: loadingColor,
          ),
          // --- 文字 (如果提供) ---
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 12), // Spacing between animation and text
            AppText(
              widget.message!,
              style: TextStyle(
                color: textColor,
                fontSize: 14, // Standard text size for card
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 3, // Allow slightly more lines for messages
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
