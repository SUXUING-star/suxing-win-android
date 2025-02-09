// lib/widgets/common/animated_card_container.dart
import 'package:flutter/material.dart';

class AnimatedCardContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enableHover;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const AnimatedCardContainer({
    Key? key,
    required this.child,
    this.onTap,
    this.enableHover = true,
    this.margin,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<AnimatedCardContainer> createState() => _AnimatedCardContainerState();
}

class _AnimatedCardContainerState extends State<AnimatedCardContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _brightnessAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _brightnessAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverChanged(bool isHovered) {
    if (!widget.enableHover) return;
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _handleHoverChanged(true),
      onExit: (_) => _handleHoverChanged(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _handleHoverChanged(true),
        onTapUp: (_) => _handleHoverChanged(false),
        onTapCancel: () => _handleHoverChanged(false),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95 + _brightnessAnimation.value),
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1 + _elevationAnimation.value * 0.1),
                      blurRadius: 8 + _elevationAnimation.value * 8,
                      offset: Offset(0, 2 + _elevationAnimation.value * 2),
                      spreadRadius: _elevationAnimation.value * 2,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}