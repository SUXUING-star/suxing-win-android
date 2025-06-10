// lib/widgets/ui/common/loading_widget.dart

/// 该文件定义了 LoadingWidget 组件，用于显示加载状态。
/// 该组件支持内联、全屏和覆盖层加载效果。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/animation/app_loading_animation.dart'; // 导入应用加载动画组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `LoadingWidget` 类：显示加载状态的组件。
///
/// 该组件提供内联、全屏和覆盖层加载效果，支持消息文本和自定义样式。
class LoadingWidget extends StatefulWidget {
  final String? message; // 加载消息文本
  final Color? color; // 加载指示器颜色
  final double size; // 加载指示器大小
  final bool isOverlay; // 是否为覆盖层加载模式
  final bool isDismissible; // 覆盖层是否可点击关闭
  final Widget? child; // 覆盖层模式下被覆盖的子组件
  final double overlayOpacity; // 覆盖层背景不透明度
  final Color? overlayCardColor; // 覆盖层卡片背景色
  final Color? overlayTextColor; // 覆盖层文本颜色
  final EdgeInsets overlayCardPadding; // 覆盖层卡片内边距
  final double overlayCardBorderRadius; // 覆盖层卡片圆角半径
  final double overlayCardWidth; // 覆盖层卡片宽度

  /// 构造函数。
  ///
  /// [message]：加载消息。
  /// [color]：加载指示器颜色。
  /// [size]：加载指示器大小。
  /// [isOverlay]：是否为覆盖层模式。
  /// [isDismissible]：覆盖层是否可关闭。
  /// [child]：覆盖层模式下的子组件。
  /// [overlayOpacity]：覆盖层不透明度。
  /// [overlayCardColor]：覆盖层卡片颜色。
  /// [overlayTextColor]：覆盖层文本颜色。
  /// [overlayCardPadding]：覆盖层卡片内边距。
  /// [overlayCardBorderRadius]：覆盖层卡片圆角。
  /// [overlayCardWidth]：覆盖层卡片宽度。
  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 16.0,
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

  /// 工厂构造函数：创建内联加载组件。
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

  /// 工厂构造函数：创建全屏加载组件。
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

  /// 工厂构造函数：创建覆盖层加载组件。
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

  /// 预设的简单内联加载指示器。
  static const Widget simpleInline = LoadingWidget();

  /// 预设的带默认消息的内联加载指示器。
  static const Widget inlineWithMessage = LoadingWidget(message: "努力加载中...");

  /// 预设的简单全屏加载指示器。
  static final Widget simpleFullScreen = LoadingWidget.fullScreen();

  /// 预设的带自定义消息的全屏加载指示器。
  ///
  /// [message]：自定义消息文本。
  static Widget fullScreenWithMessage(String message) =>
      LoadingWidget.fullScreen(message: message);

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

/// `_LoadingWidgetState` 类：`LoadingWidget` 的状态管理。
///
/// 管理加载组件的显示逻辑和动画。
class _LoadingWidgetState extends State<LoadingWidget> {
  @override
  Widget build(BuildContext context) {
    final Color loadingColor =
        widget.color ?? Theme.of(context).primaryColor; // 获取加载指示器颜色
    if (!widget.isOverlay) {
      // 根据模式选择构建方法
      return _buildInlineLoading(loadingColor);
    }
    return _buildOverlayLoading(loadingColor);
  }

  /// 构建内联加载组件。
  ///
  /// [loadingColor]：加载指示器颜色。
  Widget _buildInlineLoading(Color loadingColor) {
    final Color textColor = Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.grey[600]!; // 获取文本颜色
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化以适应内容
        children: [
          AppLoadingAnimation(
            // 加载动画组件
            size: widget.size,
            color: loadingColor,
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            // 存在消息时显示
            const SizedBox(height: 8), // 动画与文本间距
            Text(
              widget.message!, // 消息文本
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // 文本居中
            ),
          ],
        ],
      ),
    );
  }

  /// 构建覆盖层加载组件。
  ///
  /// [loadingColor]：加载指示器颜色。
  Widget _buildOverlayLoading(Color loadingColor) {
    Widget overlayContent = Material(
      type: MaterialType.transparency, // 材料类型为透明
      child: Container(
        color: Colors.black.withSafeOpacity(widget.overlayOpacity), // 覆盖层背景色
        child: Center(
          child: GestureDetector(
            // 可点击关闭手势检测
            onTap: widget.isDismissible
                ? () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // 关闭当前页面
                    }
                  }
                : null,
            behavior: HitTestBehavior.opaque, // 点击行为
            child: TweenAnimationBuilder<double>(
              // 渐变动画
              tween: Tween(begin: 0.0, end: 1.0), // 动画范围
              duration: const Duration(milliseconds: 250), // 动画时长
              curve: Curves.easeOutCubic, // 动画曲线
              builder: (context, value, child) {
                return Transform.scale(
                  // 缩放变换
                  scale: 0.9 + (0.1 * value), // 缩放比例
                  child: Opacity(
                    // 透明度
                    opacity: value, // 透明度值
                    child: _buildLoadingCard(loadingColor), // 加载卡片内容
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (widget.child != null) {
      // 存在子组件时使用 Stack 布局
      return Stack(
        children: [
          widget.child!, // 子组件
          Positioned.fill(child: overlayContent), // 覆盖层充满父组件
        ],
      );
    }
    return overlayContent; // 否则直接返回覆盖层内容
  }

  /// 构建加载卡片。
  ///
  /// [loadingColor]：加载指示器颜色。
  Widget _buildLoadingCard(Color loadingColor) {
    final Color cardBgColor =
        widget.overlayCardColor ?? Theme.of(context).cardColor; // 获取卡片背景色
    final Color textColor = widget.overlayTextColor ??
        (ThemeData.estimateBrightnessForColor(cardBgColor) == Brightness.dark
            ? Colors.white.withSafeOpacity(0.85)
            : Colors.black.withSafeOpacity(0.75)); // 获取文本颜色
    return Container(
      width: widget.overlayCardWidth, // 卡片宽度
      padding: widget.overlayCardPadding, // 卡片内边距
      decoration: BoxDecoration(
        // 卡片装饰
        color: cardBgColor.withSafeOpacity(0.95), // 卡片背景色
        borderRadius:
            BorderRadius.circular(widget.overlayCardBorderRadius), // 卡片圆角
        boxShadow: [
          // 卡片阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化以适应内容
        children: [
          AppLoadingAnimation(
            // 加载动画组件
            size: widget.size,
            color: loadingColor,
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            // 存在消息时显示
            const SizedBox(height: 12), // 动画与文本间距
            AppText(
              widget.message!, // 消息文本
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // 文本居中
              maxLines: 3, // 最大行数
              overflow: TextOverflow.ellipsis, // 超出部分显示省略号
            ),
          ],
        ],
      ),
    );
  }
}
