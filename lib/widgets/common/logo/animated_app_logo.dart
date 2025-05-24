// // lib/widgets/logo/animated_app_logo.dart
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
//
// class AnimatedAppLogo extends StatefulWidget {
//   final double size;
//
//   const AnimatedAppLogo({
//     super.key,
//     this.size = 180,
//   });
//
//   @override
//   State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
// }
//
// class _AnimatedAppLogoState extends State<AnimatedAppLogo> with TickerProviderStateMixin {
//   late AnimationController _orbitController;
//   late List<StarParticle> _particles;
//
//   // Colors similar to the Kotlin implementation
//   final List<Color> particleColors = [
//     const Color(0xFF90CAF9), // Light Blue
//     const Color(0xFFA5D6A7), // Light Green
//     const Color(0xFFFFCC80), // Light Orange
//     const Color(0xFFEF9A9A), // Light Red
//     const Color(0xFFCE93D8), // Light Purple
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Create orbit animation controller
//     _orbitController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 8),
//     )..repeat();
//
//     // Create particles
//     _createParticles();
//   }
//
//   void _createParticles() {
//     final random = Random();
//     _particles = List.generate(10, (index) {
//       // Calculate a fixed orbit radius at the edge of the circle
//       // with small variations for visual interest
//       final orbitRadius = widget.size * 0.43 - random.nextDouble() * 5;
//
//       return StarParticle(
//         radius: random.nextDouble() * 3 + 1.5,
//         orbitRadius: orbitRadius,
//         angle: random.nextDouble() * 2 * pi,
//         // Vary speeds slightly for more natural movement
//         speed: random.nextDouble() * 0.03 + 0.01,
//         color: particleColors[random.nextInt(particleColors.length)],
//         opacity: random.nextDouble() * 0.5 + 0.5,
//         glowFactor: random.nextDouble() * 0.5 + 0.5,
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     _orbitController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: widget.size,
//       height: widget.size,
//       child: AnimatedBuilder(
//         animation: _orbitController,
//         builder: (context, child) {
//           // Update particle positions based on animation value
//           for (var particle in _particles) {
//             particle.angle += particle.speed;
//           }
//
//           return CustomPaint(
//             painter: LogoPainter(
//               particles: _particles,
//               animationValue: _orbitController.value,
//               size: widget.size,
//             ),
//             size: Size(widget.size, widget.size),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class StarParticle {
//   final double radius;
//   final double orbitRadius;
//   double angle;
//   final double speed;
//   final Color color;
//   final double opacity;
//   final double glowFactor;
//
//   StarParticle({
//     required this.radius,
//     required this.orbitRadius,
//     required this.angle,
//     required this.speed,
//     required this.color,
//     required this.opacity,
//     required this.glowFactor,
//   });
// }
//
// class LogoPainter extends CustomPainter {
//   final List<StarParticle> particles;
//   final double animationValue;
//   final double size;
//
//   LogoPainter({
//     required this.particles,
//     required this.animationValue,
//     required this.size,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width * 0.45;
//
//     // Background gradient - make it match the image (more solid blue)
//     final bgPaint = Paint()
//       ..shader = RadialGradient(
//         colors: const [
//           Color(0xFF2196F3), // Lighter center
//           Color(0xFF1976D2), // Darker edge
//         ],
//         stops: const [0.7, 1.0],
//       ).createShader(Rect.fromCircle(center: center, radius: radius));
//
//     // Draw main circle
//     canvas.drawCircle(center, radius, bgPaint);
//
//     // Draw nebula cloud in upper half - make it more like the image
//     final Path nebulaPath = Path();
//     nebulaPath.moveTo(center.dx - radius * 0.6, center.dy - radius * 0.05);
//     nebulaPath.cubicTo(
//         center.dx - radius * 0.3, center.dy - radius * 0.3,
//         center.dx, center.dy - radius * 0.2,
//         center.dx + radius * 0.6, center.dy - radius * 0.05
//     );
//     nebulaPath.cubicTo(
//         center.dx + radius * 0.5, center.dy + radius * 0.1,
//         center.dx, center.dy + radius * 0.1,
//         center.dx - radius * 0.5, center.dy + radius * 0.05
//     );
//     nebulaPath.close();
//
//     final nebulaGradient = Paint()
//       ..shader = LinearGradient(
//         colors: const [
//           Color(0xAAD0A7FF), // Lighter purple with alpha
//           Color(0x9989CFF0), // Light blue with alpha
//         ],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ).createShader(Rect.fromCircle(center: center, radius: radius))
//       ..style = PaintingStyle.fill;
//
//     canvas.drawPath(nebulaPath, nebulaGradient);
//
//     // Remove the line visualization as it's not in the reference image
//
//     // Draw fixed stars matching the image
//     _drawStar(canvas, Offset(center.dx - radius * 0.2, center.dy - radius * 0.2), radius * 0.02, Colors.white);
//     _drawStar(canvas, Offset(center.dx, center.dy - radius * 0.25), radius * 0.02, Colors.white);
//     _drawStar(canvas, Offset(center.dx + radius * 0.2, center.dy - radius * 0.2), radius * 0.02, Colors.white);
//     _drawStar(canvas, Offset(center.dx - radius * 0.1, center.dy - radius * 0.1), radius * 0.02, Colors.white);
//     _drawStar(canvas, Offset(center.dx + radius * 0.35, center.dy - radius * 0.1), radius * 0.02, Colors.white);
//
//     // Draw simplified "宿" character (like in the reference image)
//     final simplePath = Path();
//
//     // Base on the reference image - simple white lines
//     // Vertical line (main stem)
//     simplePath.moveTo(center.dx - radius * 0.05, center.dy - radius * 0.1);
//     simplePath.lineTo(center.dx - radius * 0.05, center.dy + radius * 0.15);
//
//     // Top arch (like a gate/门)
//     simplePath.moveTo(center.dx - radius * 0.15, center.dy - radius * 0.1);
//     simplePath.lineTo(center.dx - radius * 0.15, center.dy - radius * 0.2);
//     simplePath.lineTo(center.dx + radius * 0.05, center.dy - radius * 0.2);
//     simplePath.lineTo(center.dx + radius * 0.05, center.dy - radius * 0.1);
//
//     // Connect top to vertical stem
//     simplePath.moveTo(center.dx - radius * 0.15, center.dy - radius * 0.1);
//     simplePath.lineTo(center.dx + radius * 0.05, center.dy - radius * 0.1);
//
//     final textPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = size.width * 0.018
//       ..strokeCap = StrokeCap.round;
//
//     canvas.drawPath(simplePath, textPaint);
//
//     // Draw enhanced glossy star - LARGER as requested
//     final starX = center.dx + size.width * 0.13;
//     final starY = center.dy - size.width * 0.05;
//     final starOuterRadius = size.width * 0.13; // Increased size
//     final starInnerRadius = starOuterRadius * 0.4;
//
//     // Main star path
//     final starPath = Path();
//     for (int i = 0; i < 5; i++) {
//       final outerAngle = -pi / 2 + 2 * pi * i / 5;
//       final innerAngle = -pi / 2 + 2 * pi * (i + 0.5) / 5;
//
//       final outerX = starX + cos(outerAngle) * starOuterRadius;
//       final outerY = starY + sin(outerAngle) * starOuterRadius;
//       final innerX = starX + cos(innerAngle) * starInnerRadius;
//       final innerY = starY + sin(innerAngle) * starInnerRadius;
//
//       if (i == 0) {
//         starPath.moveTo(outerX, outerY);
//       } else {
//         starPath.lineTo(outerX, outerY);
//       }
//
//       starPath.lineTo(innerX, innerY);
//     }
//     starPath.close();
//
//     // Golden gradient for star
//     final starPaint = Paint()
//       ..shader = RadialGradient(
//         colors: const [
//           Color(0xFFFFEE58), // Light yellow center
//           Color(0xFFFFD600), // Golden edge
//         ],
//         stops: const [0.3, 1.0],
//         center: Alignment(0.3, -0.3), // Offset highlight for 3D effect
//       ).createShader(Rect.fromCircle(
//           center: Offset(starX, starY),
//           radius: starOuterRadius
//       ));
//
//     canvas.drawPath(starPath, starPaint);
//
//     // Add highlight for glossy effect
//     final highlightPath = Path();
//     highlightPath.moveTo(starX - starOuterRadius * 0.3, starY - starOuterRadius * 0.3);
//     highlightPath.lineTo(starX - starOuterRadius * 0.1, starY - starOuterRadius * 0.5);
//     highlightPath.lineTo(starX + starOuterRadius * 0.1, starY - starOuterRadius * 0.2);
//     highlightPath.close();
//
//     final highlightPaint = Paint()
//       ..color = Colors.white.withSafeOpacity(0.7);
//
//     canvas.drawPath(highlightPath, highlightPaint);
//
//     canvas.drawPath(starPath, starPaint);
//
//     // Draw mountain "A" symbol (without the horizontal line)
//     final trianglePath = Path();
//     final triangleHeight = size.width * 0.15;
//     final triangleBase = size.width * 0.15;
//     final triangleX = center.dx + size.width * 0.05;
//     final triangleY = center.dy + radius * 0.13;
//
//     trianglePath.moveTo(triangleX - triangleBase/2, triangleY + triangleHeight/2); // Bottom left
//     trianglePath.lineTo(triangleX, triangleY - triangleHeight/2); // Top center
//     trianglePath.lineTo(triangleX + triangleBase/2, triangleY + triangleHeight/2); // Bottom right
//     trianglePath.close();
//
//     // // Red color as shown in the image
//     // final trianglePaint = Paint()
//     //   ..color = Color(0xFFFF5252)
//     //   ..style = PaintingStyle.fill;
//
//     // Draw orbiting particles
//     for (var particle in particles) {
//       final x = center.dx + cos(particle.angle) * particle.orbitRadius;
//       final y = center.dy + sin(particle.angle) * particle.orbitRadius;
//
//       // Create a scale effect based on the y-position
//       final scaleEffect = (sin(particle.angle) + 1) / 2;
//       final currentRadius = particle.radius * (0.5 + scaleEffect * 0.5);
//
//       final particlePaint = Paint()
//         ..color = particle.color.withSafeOpacity(particle.opacity * scaleEffect)
//         ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentRadius * particle.glowFactor);
//
//       canvas.drawCircle(Offset(x, y), currentRadius, particlePaint);
//     }
//   }
//
//   void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;
//
//     canvas.drawCircle(center, radius, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant LogoPainter oldDelegate) {
//     return oldDelegate.animationValue != animationValue;
//   }
// }