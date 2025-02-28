// lib/widgets/logo/custom_star_logo.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class StarLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final int numberOfStars;
  final bool withGlow;

  const StarLogo({
    Key? key,
    this.size = 80,
    this.primaryColor = const Color(0xFFFFD700), // 金黄色
    this.secondaryColor = const Color(0xFFFFA500), // 橙色
    this.numberOfStars = 7,
    this.withGlow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: StarClusterPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          numberOfStars: numberOfStars,
          withGlow: withGlow,
        ),
      ),
    );
  }
}

class StarClusterPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final int numberOfStars;
  final bool withGlow;
  final Random random = Random(12); // 固定种子以获得一致的随机分布

  StarClusterPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.numberOfStars,
    required this.withGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 定义星星可以出现的区域为中心区域
    final areaSize = size.width * 0.7;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 生成一系列星星信息，随机摆放但集中在中心区域
    final stars = <StarInfo>[];

    // 第一颗星星总是在中心
    stars.add(StarInfo(
      x: centerX,
      y: centerY,
      size: size.width * 0.4,
      color: primaryColor,
      points: 5,
      rotation: 0,
    ));

    // 生成剩余的星星，随机分布在中心区域
    for (int i = 1; i < numberOfStars; i++) {
      // 确保星星分布在中心附近，使用高斯分布感觉
      final distance = random.nextDouble() * (areaSize * 0.4);
      final angle = random.nextDouble() * 2 * math.pi;

      // 位置添加轻微随机偏移
      final x = centerX + math.cos(angle) * distance;
      final y = centerY + math.sin(angle) * distance;

      // 随机大小，但比中心星小
      final starSize = size.width * (0.15 + random.nextDouble() * 0.25);

      // 随机决定星星的点数 (5-7)
      final points = 5 + random.nextInt(3);

      // 随机颜色 - 在主色和次色之间插值
      final colorValue = random.nextDouble();
      final color = Color.lerp(primaryColor, secondaryColor, colorValue)!;

      // 随机旋转
      final rotation = random.nextDouble() * math.pi;

      stars.add(StarInfo(
        x: x,
        y: y,
        size: starSize,
        color: color,
        points: points,
        rotation: rotation,
      ));
    }

    // 按照大小排序，先绘制小星星，再绘制大星星，确保正确的重叠效果
    stars.sort((a, b) => a.size.compareTo(b.size));

    // 绘制所有星星
    for (var star in stars) {
      _drawStar(
        canvas: canvas,
        center: Offset(star.x, star.y),
        size: star.size,
        color: star.color,
        points: star.points,
        rotation: star.rotation,
        withGlow: withGlow,
      );
    }
  }

  void _drawStar({
    required Canvas canvas,
    required Offset center,
    required double size,
    required Color color,
    required int points,
    required double rotation,
    required bool withGlow,
  }) {
    // 如果启用光晕效果，先绘制光晕
    if (withGlow) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.2);

      _drawStarPath(canvas, center, size * 1.2, points, rotation, glowPaint);
    }

    // 绘制星星主体
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _drawStarPath(canvas, center, size, points, rotation, paint);

    // 添加高光效果
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 绘制小圆点作为星星的高光
    final highlightOffset = Offset(
      center.dx - size * 0.15 * math.cos(rotation),
      center.dy - size * 0.15 * math.sin(rotation),
    );

    canvas.drawCircle(
      highlightOffset,
      size * 0.1,
      highlightPaint,
    );
  }

  void _drawStarPath(
      Canvas canvas,
      Offset center,
      double size,
      int points,
      double rotation,
      Paint paint,
      ) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = rotation + (math.pi / points) * i;

      final x = center.dx + radius * math.cos(angle - math.pi / 2);
      final y = center.dy + radius * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! StarClusterPainter ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.numberOfStars != numberOfStars ||
        oldDelegate.withGlow != withGlow;
  }
}

// 用于存储星星信息的类
class StarInfo {
  final double x;
  final double y;
  final double size;
  final Color color;
  final int points;
  final double rotation;

  StarInfo({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.points,
    required this.rotation,
  });
}

// 对随机数生成器的简单包装
class Random {
  final math.Random _random;

  Random(int seed) : _random = math.Random(seed);

  double nextDouble() => _random.nextDouble();

  int nextInt(int max) => _random.nextInt(max);

  bool nextBool() => _random.nextBool();
}