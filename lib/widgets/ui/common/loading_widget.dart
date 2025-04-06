// lib/widgets/ui/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
// --- 导入【外部】统一的动画组件 ---
import 'package:suxingchahui/widgets/ui/animation/modern_loading_animation.dart';
// --- 导入骨架屏和其他相关组件 ---
class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color; // 动画颜色 (优先使用)
  final double size;  // 内联模式动画大小 & 覆盖卡片模式动画大小 (现在用同一个控制)
  final bool isOverlay;
  final bool isDismissible;
  final Widget? child;
  final double opacity;
  // 可以考虑为 overlay 单独添加 size 参数，但按“不大改”原则，暂时共用 size

  const LoadingWidget({
    Key? key,
    this.message,
    this.color,
    this.size = 32.0, // 默认大小调整为通用大小
    this.isOverlay = false,
    this.isDismissible = false,
    this.child,
    this.opacity = 0.3, // 覆盖背景透明度提高一点点
  }) : super(key: key);

  /// 创建一个内联加载指示器
  factory LoadingWidget.inline({
    String? message,
    Color? color,
    double size = 24.0, // 内联可以小一点
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      size: size, // 传递内联特定大小
      isOverlay: false,
    );
  }

  /// 创建一个覆盖整个页面的加载指示器
  factory LoadingWidget.fullScreen({
    String? message,
    Color? color,
    bool isDismissible = false,
    double opacity = 0.3,
    double size = 40.0, // 全屏覆盖可以大一点
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      isOverlay: true,
      isDismissible: isDismissible,
      opacity: opacity,
      size: size, // 传递全屏特定大小
    );
  }

  /// 创建一个覆盖在特定内容上的加载指示器
  factory LoadingWidget.overlay({
    required Widget child,
    String? message,
    Color? color,
    bool isDismissible = false,
    double opacity = 0.3,
    double size = 32.0, // 内容覆盖用默认大小或中等大小
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      isOverlay: true,
      isDismissible: isDismissible,
      child: child,
      opacity: opacity,
      size: size, // 传递内容覆盖特定大小
    );
  }

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

// ** 这个 State 现在不再需要 AnimationController 了 **
class _LoadingWidgetState extends State<LoadingWidget> {
  // late AnimationController _controller; // <--- 不再需要！

  // @override void initState() { ... _controller = ... } // <--- 不再需要！
  // @override void dispose() { _controller.dispose(); ... } // <--- 不再需要！

  @override
  Widget build(BuildContext context) {
    // **颜色处理：优先 widget.color，否则主题色**
    final Color loadingColor = widget.color ?? Theme.of(context).primaryColor;

    // 内部结构和逻辑保持不变
    if (!widget.isOverlay) {
      // **调用内联构建，使用【外部】动画**
      return _buildInlineLoading(loadingColor);
    }
    // **调用覆盖构建，使用【外部】动画**
    return _buildOverlayLoading(loadingColor);
  }

  // 内联加载构建方法，【使用 ModernLoadingAnimation】
  Widget _buildInlineLoading(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 直接使用外部统一动画组件 ---
          ModernLoadingAnimation(
            size: widget.size, // 使用 widget 的 size 控制
            color: color,      // 使用计算好的颜色
            // strokeWidth: ..., // 可以按需传递，或使用动画组件的默认值
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.message!,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // 覆盖加载构建方法，【内部卡片使用 ModernLoadingAnimation】
  Widget _buildOverlayLoading(Color color) {
    Widget overlay = Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: widget.isDismissible ? () {
          try { if (Navigator.canPop(context)) { Navigator.pop(context); } } catch (e) { print("Error dismissing overlay: $e"); }
        } : null,
        child: Container(
          color: Colors.black.withOpacity(widget.opacity),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    // **构建卡片，传入最终颜色，内部将使用 ModernLoadingAnimation**
                    child: _buildLoadingCard(color),
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
          Positioned.fill(child: overlay),
        ],
      );
    }
    return overlay;
  }

  // 加载卡片构建方法，【使用 ModernLoadingAnimation】
  Widget _buildLoadingCard(Color color) {
    // 卡片内文字颜色，可以简单处理，比如根据主题亮度
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.8)
        : Colors.black.withOpacity(0.7);

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4),),],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 直接使用外部统一动画组件 ---
          ModernLoadingAnimation(
            size: widget.size, // 卡片内动画大小也由 widget.size 控制 (按“不大改”原则)
            color: color,      // 使用传入的颜色
            // strokeWidth: ..., // 可以按需传递，或使用动画组件的默认值
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.message!,
              style: TextStyle(
                color: textColor, // 使用计算的文字颜色
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

