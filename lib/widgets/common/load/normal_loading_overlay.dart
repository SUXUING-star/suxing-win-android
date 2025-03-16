// lib/widgets/loading/normal_loading_overlay.dart
import 'package:flutter/material.dart';

class NormalLoadingOverlay extends StatefulWidget {
  final String? message;
  final bool isDismissible;

  const NormalLoadingOverlay({
    Key? key,
    this.message,
    this.isDismissible = false,
  }) : super(key: key);

  @override
  State<NormalLoadingOverlay> createState() => _NormalLoadingOverlayState();
}

class _NormalLoadingOverlayState extends State<NormalLoadingOverlay>
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
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: widget.isDismissible ? () => Navigator.pop(context) : null,
        child: Container(
          color: Colors.black.withOpacity(0.2),
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
                    child: _buildLoadingCard(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
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
          // 自定义进度指示器
          SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: _LoadingPainter(
                animation: _controller,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            // 加载文本
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

// 自定义加载动画绘制
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