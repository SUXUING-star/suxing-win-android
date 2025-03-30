// lib/widgets/components/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isOverlay;
  final bool isDismissible;
  final Widget? child;
  final double opacity;

  const LoadingWidget({
    Key? key,
    this.message,
    this.color,
    this.size = 32.0,
    this.isOverlay = false,
    this.isDismissible = false,
    this.child,
    this.opacity = 0.2,
  }) : super(key: key);

  /// 创建一个内联加载指示器，适用于页面中的小区域
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

  /// 创建一个覆盖整个页面的加载指示器
  factory LoadingWidget.fullScreen({
    String? message,
    Color? color,
    bool isDismissible = false,
    double opacity = 0.2,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      isOverlay: true,
      isDismissible: isDismissible,
      opacity: opacity,
    );
  }

  /// 创建一个覆盖在特定内容上的加载指示器
  factory LoadingWidget.overlay({
    required Widget child,
    String? message,
    Color? color,
    bool isDismissible = false,
    double opacity = 0.2,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      isOverlay: true,
      isDismissible: isDismissible,
      child: child,
      opacity: opacity,
    );
  }

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color loadingColor = widget.color ?? Theme.of(context).primaryColor;

    // 内联加载指示器
    if (!widget.isOverlay) {
      return _buildInlineLoading(loadingColor);
    }

    // 覆盖加载指示器
    return _buildOverlayLoading(loadingColor);
  }

  Widget _buildInlineLoading(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _LoadingPainter(
                animation: _controller,
                color: color,
              ),
            ),
          ),
          if (widget.message != null) ...[
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

  Widget _buildOverlayLoading(Color color) {
    Widget overlay = Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: widget.isDismissible ? () => NavigationUtils.pop(context) : null,
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
                    child: _buildLoadingCard(color),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // 如果有子Widget，则覆盖在其上方
    if (widget.child != null) {
      return Stack(
        children: [
          widget.child!,
          overlay,
        ],
      );
    }

    return overlay;
  }

  Widget _buildLoadingCard(Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _LoadingPainter(
                animation: _controller,
                color: color,
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.message!,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
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

// 骨架屏加载组件
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoading({
    Key? key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.baseColor ??
        (Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade300
            : Colors.grey.shade700);

    final Color highlightColor = widget.highlightColor ??
        (Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade100
            : Colors.grey.shade600);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(-_animation.value, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

// 列表占位加载组件
class ListPlaceholderLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final bool hasImage;
  final bool hasTitle;
  final bool hasSubtitle;
  final double spacing;

  const ListPlaceholderLoading({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.hasImage = true,
    this.hasTitle = true,
    this.hasSubtitle = true,
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : spacing),
        child: _buildListItem(context),
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    return Container(
      height: itemHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          if (hasImage) ...[
            SkeletonLoading(
              width: itemHeight - 16,
              height: itemHeight - 16,
              borderRadius: 8,
            ),
            SizedBox(width: spacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasTitle) ...[
                  SkeletonLoading(
                    width: 200,
                    height: 16,
                    borderRadius: 4,
                  ),
                  SizedBox(height: spacing),
                ],
                if (hasSubtitle) ...[
                  SkeletonLoading(
                    width: 150,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: spacing / 2),
                  SkeletonLoading(
                    width: 100,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 自定义加载动画绘制器
class _LoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _LoadingPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制背景圆环
    canvas.drawCircle(size.center(Offset.zero), size.width / 2.2, paint);

    // 绘制动态圆弧
    paint.color = color;
    final double startAngle = animation.value * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2.2),
      startAngle,
      3.14159,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}