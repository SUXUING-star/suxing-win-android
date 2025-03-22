// lib/utils/navigation/navigation_util.dart
import 'package:flutter/material.dart';
import '../../app.dart';
import '../../layouts/main_layout.dart';

/// 统一的导航工具类，基于单一的MaterialApp结构
class NavigationUtil {
  /// 导航到指定路由，并可选择是否替换当前路由
  ///
  /// [routeName] 目标路由名称
  /// [arguments] 传递给路由的参数
  /// [replace] 是否替换当前路由
  static void navigateTo(BuildContext context, String routeName, {Object? arguments, bool replace = false}) {
    print("NavigationUtil: 导航到路由: $routeName, 替换当前: $replace");

    // 优先使用全局导航器
    final navigator = mainNavigatorKey.currentState ?? Navigator.of(context);

    if (replace) {
      navigator.pushReplacementNamed(routeName, arguments: arguments);
    } else {
      navigator.pushNamed(routeName, arguments: arguments);
    }
  }

  /// 返回到主页面并导航到特定标签
  ///
  /// [index] 要导航到的标签索引
  static void navigateToMainTab(BuildContext context, int index) {
    print("NavigationUtil: 导航到主页面标签: $index");

    // 设置标签索引
    MainLayout.navigateTo(index);

    // 使用全局导航器
    final navigator = mainNavigatorKey.currentState;

    if (navigator != null) {
      // 清除导航栈
      navigator.popUntil((route) => route.isFirst);
      print("NavigationUtil: 已返回到主页面");
    } else {
      print("NavigationUtil: 未找到导航器实例");

      // 后备方案：使用上下文导航器
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// 弹出指定数量的页面
  ///
  /// [context] 当前上下文
  /// [count] 要弹出的页面数量
  static void popPages(BuildContext context, int count) {
    print("NavigationUtil: 尝试弹出 $count 个页面");

    // 优先使用全局导航器
    final navigator = mainNavigatorKey.currentState ?? Navigator.of(context);

    // 弹出指定数量的页面
    for (int i = 0; i < count; i++) {
      if (navigator.canPop()) {
        navigator.pop();
        print("NavigationUtil: 已弹出第 ${i+1} 个页面");
      } else {
        print("NavigationUtil: 无法继续弹出页面，已弹出 $i 个页面");
        break;
      }
    }
  }
}