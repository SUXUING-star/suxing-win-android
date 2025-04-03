// lib/utils/navigation/navigation_utils.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import '../../app.dart';
import '../../layouts/main_layout.dart';
import 'dart:async';

/// 全局安全导航器
/// 使用方式与Navigator完全一致，但确保不会出现GlobalKey冲突
class NavigationUtils {
  NavigationUtils._();

  /// 获取导航器状态
  static NavigatorState of(BuildContext context, {bool rootNavigator = false}) {
    if (rootNavigator) {
      // 如果需要根导航器，返回全局导航器
      return mainNavigatorKey.currentState!;
    } else {
      // 否则尝试获取最近的导航器（与Navigator.of行为一致）
      try {
        return Navigator.of(context);
      } catch (e) {
        // 如果无法获取最近的导航器，回退到全局导航器
        return mainNavigatorKey.currentState!;
      }
    }
  }

  /// 导航到指定路由
  static Future<T?> push<T>(BuildContext context, Route<T> route) {
    return _safeCall(() => of(context, rootNavigator: true).push(route));
  }

  /// 导航到命名路由
  static Future<T?> pushNamed<T>(BuildContext context, String routeName, {Object? arguments}) {
    return _safeCall(() => of(context, rootNavigator: true).pushNamed(routeName, arguments: arguments));
  }

  /// 替换当前路由
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Route<T> route, {TO? result}) {
    return _safeCall(() => of(context, rootNavigator: true).pushReplacement(route, result: result));
  }

  /// 替换当前命名路由
  static Future<T?> pushReplacementNamed<T, TO>(BuildContext context, String routeName, {TO? result, Object? arguments}) {
    return _safeCall(() => of(context, rootNavigator: true).pushReplacementNamed(routeName, result: result, arguments: arguments));
  }

  /// 删除所有路由直到某个条件，然后添加新路由
  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, Route<T> route, RoutePredicate predicate) {
    return _safeCall(() => of(context, rootNavigator: true).pushAndRemoveUntil(route, predicate));
  }

  /// 删除所有路由直到某个条件，然后添加新命名路由
  static Future<T?> pushNamedAndRemoveUntil<T>(BuildContext context, String routeName, RoutePredicate predicate, {Object? arguments}) {
    return _safeCall(() => of(context, rootNavigator: true).pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments));
  }

  /// 弹出当前路由，返回结果
  static bool pop<T>(BuildContext context, [T? result]) {
    final navigator = of(context, rootNavigator: true);
    if (!navigator.canPop()) return false;
    _safeCallSync(() => navigator.pop(result));
    return true;
  }

  /// 弹出多个路由直到满足条件
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    _safeCallSync(() => of(context, rootNavigator: true).popUntil(predicate));
  }

  /// 判断是否可以弹出路由
  static bool canPop(BuildContext context) {
    return of(context, rootNavigator: true).canPop();
  }

  /// 弹出到第一个路由(通常是首页)
  static void popToRoot(BuildContext context) {
    _safeCallSync(() => of(context, rootNavigator: true).popUntil((route) => route.isFirst));
  }

  /// 清除所有路由并导航到首页(指定标签页)
  static void navigateToHome(BuildContext context, {int tabIndex = 0}) {
    _safeCallSync(() {
      final navigator = mainNavigatorKey.currentState;
      if (navigator == null) {
        print("NavigationUtils Error: mainNavigatorKey.currentState is null in navigateToHome.");
        return;
      }

      // 1. 清除所有路由直到第一个路由
      navigator.popUntil((route) => route.isFirst);

      // 2. *** 更新 SidebarProvider 的状态 ***
      //    使用 mainNavigatorKey.currentContext! 来获取一个有效的、在 Provider 之下的 context
      final providerContext = mainNavigatorKey.currentContext;
      if (providerContext != null) {
        try {
          Provider.of<SidebarProvider>(providerContext, listen: false)
              .setCurrentIndex(tabIndex);
        } catch (e) {
          print("NavigationUtils Error: Failed to update SidebarProvider in navigateToHome: $e");
          // 可能 providerContext 不在 MultiProvider 之下，检查你的 Widget 树结构
        }
      } else {
        print("NavigationUtils Error: mainNavigatorKey.currentContext is null in navigateToHome, cannot update SidebarProvider.");
      }

    });
  }

  /// 登录页面导航(保留首页)
  static Future<T?> navigateToLogin<T>(BuildContext context, {bool redirectAfterLogin = false, int? redirectIndex}) {
    return pushNamedAndRemoveUntil<T>(
      context,
      '/login',
          (route) => route.isFirst,
      arguments: {
        if (redirectAfterLogin) 'redirect_after_login': true,
        if (redirectIndex != null) 'redirect_index': redirectIndex,
      },
    );
  }

  /// 强制清空栈并导航到指定路由
  static Future<T?> clearStackAndPush<T>(BuildContext context, String routeName, {Object? arguments}) {
    return pushNamedAndRemoveUntil<T>(
        context,
        routeName,
            (route) => false,
        arguments: arguments
    );
  }

  /// 直接使用maybePop，尝试关闭当前页面
  static Future<bool> maybePop<T>(BuildContext context, [T? result]) {
    return of(context, rootNavigator: true).maybePop(result);
  }

  /// 显示登录提示对话框
  static Future<bool> showLoginDialog(BuildContext context, {String message = '请登录后继续操作', int? redirectIndex}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('需要登录'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
              navigateToLogin(
                context,
                redirectAfterLogin: true,
                redirectIndex: redirectIndex,
              );
            },
            child: Text('去登录'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  /// 安全执行导航操作，确保不会出现GlobalKey冲突
  static Future<T> _safeCall<T>(Future<T> Function() navigateFunction) async {
    final completer = Completer<T>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final result = await navigateFunction();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// 安全执行同步导航操作，确保不会出现GlobalKey冲突
  static void _safeCallSync(Function() navigateFunction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateFunction();
    });
  }
}