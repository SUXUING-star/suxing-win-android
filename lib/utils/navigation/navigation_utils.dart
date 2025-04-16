// lib/utils/navigation/navigation_utils.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import '../../app.dart'; // For mainNavigatorKey
import '../../routes/app_routes.dart'; // For route constants

/// 全局安全导航器
class NavigationUtils {
  NavigationUtils._();

  // 定义主 Tab 路由及其对应的索引
  // *** 确保这里的路由和索引与你的 MainLayout / BottomNavigationBar 完全对应 ***
  static const Map<String, int> _mainTabRoutes = {
    AppRoutes.home: 0, // 首页
    AppRoutes.gamesList: 1, // 游戏列表
    AppRoutes.forum: 2, // 论坛
    AppRoutes.activityFeed: 3, // 动态
    AppRoutes.externalLinks: 4, // 工具链接
    AppRoutes.profile: 5, // 个人中心 (假设索引为5)
  };

  static NavigatorState _getRootNavigator() {
    final navigator = mainNavigatorKey.currentState;
    if (navigator == null) {
      throw FlutterError(
          'NavigationUtils: mainNavigatorKey.currentState is null. Ensure it is attached to MaterialApp.');
    }
    return navigator;
  }

  static NavigatorState of(BuildContext context, {bool rootNavigator = false}) {
    if (rootNavigator) {
      try {
        return _getRootNavigator();
      } catch (e) {
        // Fallback if root navigator fails, though ideally it shouldn't
        try {
          return Navigator.of(context);
        } catch (fallbackError) {
          throw FlutterError(
              'NavigationUtils.of(rootNavigator: true) failed: ${e.toString()}. Fallback Navigator.of(context) also failed: ${fallbackError.toString()}');
        }
      }
    } else {
      try {
        return Navigator.of(context);
      } catch (e) {
        // Fallback to root navigator if local navigator is not found
        return _getRootNavigator();
      }
    }
  }

  static Future<T?> push<T>(BuildContext context, Route<T> route) {
    return _safeCall(() => _getRootNavigator().push(route));
  }

  static Future<T?> pushNamed<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    // 1. 检查是否是登录页
    if (routeName == AppRoutes.login) {
      bool redirectAfterLogin = false;
      int? redirectIndex;
      if (arguments is Map<String, dynamic>) {
        redirectAfterLogin = arguments['redirect_after_login'] ?? false;
        redirectIndex = arguments['redirect_index'] as int?;
      }
      return navigateToLogin<T>(
        context,
        redirectAfterLogin: redirectAfterLogin,
        redirectIndex: redirectIndex,
      );
    }
    // 2. 检查是否是主 Tab 页
    else if (_mainTabRoutes.containsKey(routeName)) {
      final int tabIndex = _mainTabRoutes[routeName]!;
      // 直接调用 navigateToHome 切换 Tab，不推送新路由
      navigateToHome(context, tabIndex: tabIndex);
      // 返回 null Future 以匹配签名
      return Future.value(null as T?);
    }
    // 3. 其他路由正常推送
    else {
      return _safeCall(() =>
          _getRootNavigator().pushNamed<T>(routeName, arguments: arguments));
    }
  }

  static Future<T?> pushReplacement<T, TO>(BuildContext context, Route<T> route,
      {TO? result}) {
    return _safeCall(
        () => _getRootNavigator().pushReplacement(route, result: result));
  }

  static Future<T?> pushReplacementNamed<T, TO>(
      BuildContext context, String routeName,
      {TO? result, Object? arguments}) {
    // 1. 检查是否是登录页 (替换为登录通常意味着清栈后跳转)
    if (routeName == AppRoutes.login) {
      bool redirectAfterLogin = false;
      int? redirectIndex;
      if (arguments is Map<String, dynamic>) {
        redirectAfterLogin = arguments['redirect_after_login'] ?? false;
        redirectIndex = arguments['redirect_index'] as int?;
      }
      // 使用 navigateToLogin 清栈并跳转
      return navigateToLogin<T>(
        context,
        redirectAfterLogin: redirectAfterLogin,
        redirectIndex: redirectIndex,
      );
    }
    // 2. 检查是否是主 Tab 页
    else if (_mainTabRoutes.containsKey(routeName)) {
      final int tabIndex = _mainTabRoutes[routeName]!;
      // 替换为主 Tab 页，本质上也是切换 Tab
      navigateToHome(context, tabIndex: tabIndex);
      // 返回 null Future
      return Future.value(null as T?);
    }
    // 3. 其他路由正常替换
    else {
      return _safeCall(() => _getRootNavigator().pushReplacementNamed(routeName,
          result: result, arguments: arguments));
    }
  }

  static Future<T?> pushAndRemoveUntil<T>(
      BuildContext context, Route<T> route, RoutePredicate predicate) {
    return _safeCall(
        () => _getRootNavigator().pushAndRemoveUntil(route, predicate));
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
      BuildContext context, String routeName, RoutePredicate predicate,
      {Object? arguments}) {
    // 此方法通常用于特殊流程，如登录后跳转、清空栈等，不拦截主 Tab 路由
    return _safeCall(() => _getRootNavigator()
        .pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments));
  }

  static bool pop<T>(BuildContext context, [T? result]) {
    final navigator = _getRootNavigator();
    if (!navigator.canPop()) return false;
    _safeCallSync(() => navigator.pop(result));
    return true;
  }

  static void popUntil(BuildContext context, RoutePredicate predicate) {
    _safeCallSync(() => _getRootNavigator().popUntil(predicate));
  }

  static bool canPop(BuildContext context) {
    try {
      return _getRootNavigator().canPop();
    } catch (e) {
      return false;
    }
  }

  static void popToRoot(BuildContext context) {
    _safeCallSync(() => _getRootNavigator().popUntil((route) => route.isFirst));
  }

  static void navigateToHome(BuildContext context, {int tabIndex = 0}) {
    // 简单的范围检查 (基于 _mainTabRoutes 的大小)
    if (tabIndex < 0 || tabIndex >= _mainTabRoutes.length) {
      tabIndex = 0; // 索引无效则重置为 0
    }

    _safeCallSync(() {
      final navigator = mainNavigatorKey.currentState;
      if (navigator == null) return; // _getRootNavigator() 已处理，但再次检查无妨

      // 清除当前路由栈直到根路由 (MainLayout)
      if (navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }

      // 更新 SidebarProvider 状态
      final providerContext = mainNavigatorKey.currentContext;
      if (providerContext != null) {
        try {
          Provider.of<SidebarProvider>(providerContext, listen: false)
              .setCurrentIndex(tabIndex);
        } catch (e) {
          print(
              "NavigationUtils Error: Failed to update SidebarProvider in navigateToHome: $e");
        }
      } else {
        print(
            "NavigationUtils Error: mainNavigatorKey.currentContext is null in navigateToHome.");
      }
    });
  }

  static Future<T?> navigateToLogin<T>(BuildContext context,
      {bool redirectAfterLogin = false, int? redirectIndex}) {
    // 使用 pushNamedAndRemoveUntil 清除到根路由再 push 登录页
    return _getRootNavigator().pushNamedAndRemoveUntil<T>(
      AppRoutes.login,
      (route) => route.isFirst,
      arguments: {
        if (redirectAfterLogin) 'redirect_after_login': true,
        if (redirectIndex != null) 'redirect_index': redirectIndex,
      },
    );
    // 注意：这里没有使用 _safeCall 包装，因为 pushNamedAndRemoveUntil 内部会处理
    // 如果需要 _safeCall 的 postFrameCallback 行为，可以像下面这样包装：
    // return _safeCall(() => _getRootNavigator().pushNamedAndRemoveUntil<T>(...));
  }

  static Future<T?> clearStackAndPush<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    // 此方法明确要清空整个栈，不应拦截主 Tab 页
    // 如果 routeName 是主 Tab 路由，行为可能会不符合预期（会清空包括 MainLayout 的所有路由）
    // 开发者使用此方法时应明确目标不是主 Tab 页
    return _safeCall(() => _getRootNavigator()
        .pushNamedAndRemoveUntil<T>(routeName, (route) => false, // 清除所有路由
            arguments: arguments));
  }

  static Future<bool> maybePop<T>(BuildContext context, [T? result]) {
    try {
      return _getRootNavigator().maybePop(result);
    } catch (e) {
      return Future.value(false);
    }
  }

  static Future<bool> showLoginDialog(BuildContext context,
      {String message = '请登录后继续操作', int? redirectIndex}) {
    // 使用 rootNavigator 的 context 显示对话框
    final rootContext = mainNavigatorKey.currentContext;
    if (rootContext == null) {
      print(
          "NavigationUtils Error: Cannot show login dialog, root context is null.");
      return Future.value(false); // 无法显示对话框
    }
    return showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('需要登录'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
              // 使用原始 context 或 rootContext 调用导航均可，navigateToLogin 内部会找到根 navigator
              navigateToLogin(
                context, // 使用调用处的 context
                redirectAfterLogin: true,
                redirectIndex: redirectIndex,
              );
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  // --- 安全调用包装器 ---

  static Future<T> _safeCall<T>(Future<T> Function() navigateFunction) async {
    final completer = Completer<T>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 确保 Navigator 存在
        _getRootNavigator();
        final result = await navigateFunction();
        if (!completer.isCompleted) completer.complete(result);
      } catch (e, s) {
        if (!completer.isCompleted) completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  static void _safeCallSync(Function() navigateFunction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // 确保 Navigator 存在
        _getRootNavigator();
        navigateFunction();
      } catch (e, s) {
        print("NavigationUtils _safeCallSync Error: $e\n$s");
      }
    });
  }
}
