// lib/widgets/ui/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/app_loading_animation.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isOverlay;
  final bool isDismissible;
  final Widget? child;
  final double overlayOpacity;
  final Color? overlayCardColor;
  final Color? overlayTextColor;
  final EdgeInsets overlayCardPadding;
  final double overlayCardBorderRadius;
  final double overlayCardWidth;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 32.0,
    this.isOverlay = false,
    this.isDismissible = false,
    this.child,
    this.overlayOpacity = 0.4,
    this.overlayCardColor,
    this.overlayTextColor,
    this.overlayCardPadding =
        const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    this.overlayCardBorderRadius = 12.0,
    this.overlayCardWidth = 130.0,
  });

  factory LoadingWidget.inline({
    String? message,
    Color? color,
    double size = 24.0,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size,
      isOverlay: false,
    );
  }

  factory LoadingWidget.fullScreen({
    String? message = "加载中...",
    Color? color,
    bool isDismissible = false,
    double opacity = 0.4,
    double size = 36.0,
    Color? cardColor,
    Color? textColor,
    EdgeInsets cardPadding =
        const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    double cardBorderRadius = 12.0,
    double cardWidth = 130.0,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size,
      isOverlay: true,
      isDismissible: isDismissible,
      overlayOpacity: opacity,
      overlayCardColor: cardColor,
      overlayTextColor: textColor,
      overlayCardPadding: cardPadding,
      overlayCardBorderRadius: cardBorderRadius,
      overlayCardWidth: cardWidth,
    );
  }

  factory LoadingWidget.overlay({
    required Widget child,
    String? message = "加载中...",
    Color? color,
    bool isDismissible = false,
    double opacity = 0.4,
    double size = 32.0,
    Color? cardColor,
    Color? textColor,
    EdgeInsets cardPadding =
        const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    double cardBorderRadius = 12.0,
    double cardWidth = 130.0,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size,
      isOverlay: true,
      isDismissible: isDismissible,
      overlayOpacity: opacity,
      overlayCardColor: cardColor,
      overlayTextColor: textColor,
      overlayCardPadding: cardPadding,
      overlayCardBorderRadius: cardBorderRadius,
      overlayCardWidth: cardWidth,
      child: child,
    );
  }

  /// 一个预设的、简单的内联加载指示器 (无消息)
  static final Widget simpleInline = LoadingWidget.inline();

  /// 一个预设的、带默认消息的内联加载指示器
  static final Widget inlineWithMessage =
      LoadingWidget.inline(message: "努力加载中...");

  /// 一个预设的、简单的全屏加载指示器
  static final Widget simpleFullScreen = LoadingWidget.fullScreen();

  /// 一个预设的、带自定义消息的全屏加载指示器
  static Widget fullScreenWithMessage(String message) =>
      LoadingWidget.fullScreen(message: message);
  // --- 👆👆👆 修改结束 👆👆👆 ---

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

// ... (State 类代码保持不变) ...
class _LoadingWidgetState extends State<LoadingWidget> {
  @override
  Widget build(BuildContext context) {
    final Color loadingColor = widget.color ?? Theme.of(context).primaryColor;
    if (!widget.isOverlay) {
      return _buildInlineLoading(loadingColor);
    }
    return _buildOverlayLoading(loadingColor);
  }

  Widget _buildInlineLoading(Color loadingColor) {
    final Color textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600]!;
    print("LoadingWidget._buildLoadingCard: widget.size = ${widget.size}");
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoadingAnimation(
            size: widget.size,
            color: loadingColor,
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.message!,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlayLoading(Color loadingColor) {
    Widget overlayContent = Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withSafeOpacity(widget.overlayOpacity),
        child: Center(
          child: GestureDetector(
            onTap: widget.isDismissible
                ? () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildLoadingCard(loadingColor),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (widget.child != null) {
      return Stack(
        children: [
          widget.child!,
          Positioned.fill(child: overlayContent),
        ],
      );
    }
    return overlayContent;
  }

  Widget _buildLoadingCard(Color loadingColor) {
    final Color cardBgColor =
        widget.overlayCardColor ?? Theme.of(context).cardColor;
    final Color textColor = widget.overlayTextColor ??
        (ThemeData.estimateBrightnessForColor(cardBgColor) == Brightness.dark
            ? Colors.white.withSafeOpacity(0.85)
            : Colors.black.withSafeOpacity(0.75));
    return Container(
      width: widget.overlayCardWidth,
      padding: widget.overlayCardPadding,
      decoration: BoxDecoration(
        color: cardBgColor.withSafeOpacity(0.95),
        borderRadius: BorderRadius.circular(widget.overlayCardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoadingAnimation(
            size: widget.size,
            color: loadingColor,
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppText(
              // 确保 AppText 导入正确且可用
              widget.message!,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
