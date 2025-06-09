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

          // 核心：过渡动画构建器
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 定义一个从右侧滑入的动画
            // begin: const Offset(1.0, 0.0) -> 从右边屏幕外开始
            // end: Offset.zero -> 到屏幕正常位置结束
            const begin = Offset(0.3, 0.0); // 从右侧 30% 的位置开始，动画幅度小一点更精致
            const end = Offset.zero;

            // 动画曲线，这个是精髓，决定了动画的“节奏”
            // fastOutSlowIn 是 Material Design 推荐的，效果非常赞，丝滑感的主要来源
            final curve = Curves.fastOutSlowIn;
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
              reverseCurve: curve.flipped,
            );

            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = tween.animate(curvedAnimation);

            // 用 FadeTransition 包裹，实现淡入淡出效果
            return FadeTransition(
              opacity: animation, // 直接用主动画控制器驱动透明度
              // 用 SlideTransition 包裹，实现平移动画
              child: SlideTransition(
                position: offsetAnimation,
                child: child, // child 就是我们要切换的那个新页面
              ),
            );
          },
        );
}
