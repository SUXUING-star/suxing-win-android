// lib/routes/slide_fade_page_route.dart

/// 一个自定义的页面路由，结合了平移和淡入淡出效果
/// 让你的页面切换动画感觉更她妈的丝滑
library;

import 'package:flutter/material.dart';

/// 一个自定义的页面路由，结合了平移和淡入淡出效果
/// 让你的页面切换动画感觉更她妈的丝滑
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final RouteSettings? routeSettings;

  SlideFadePageRoute({
    required this.builder,
    this.routeSettings,
  }) : super(
          settings: routeSettings,
          // 页面构建器
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),

          // 动画时长
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),

          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 手动创建一个裁剪过的 animation
            final clampedAnimation =
                animation.drive(Tween<double>(begin: 0.0, end: 1.0));

            final curve = Curves.fastOutSlowIn;
            final curvedAnimation = CurvedAnimation(
              parent: clampedAnimation, // 使用裁剪过的 animation
              curve: curve,
              reverseCurve: curve.flipped,
            );

            final tween =
                Tween(begin: const Offset(0.3, 0.0), end: Offset.zero);
            final offsetAnimation = tween.animate(curvedAnimation);

            return FadeTransition(
              opacity: clampedAnimation, // 使用裁剪过的 animation
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        );
}
