// lib/utils/navigation/navigation_utils.dart

/// 该文件定义了 NavigationUtils 工具类，提供全局安全导航功能。
/// NavigationUtils 封装了 Flutter 导航操作，确保在任何时候都能安全地进行页面跳转、返回和栈管理。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 框架和导航器
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 侧边栏 Provider
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 基础输入对话框
import 'package:suxingchahui/app.dart'; // 应用主入口，包含全局导航键
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由常量

/// `NavigationUtils` 类：全局安全导航工具。
///
/// 该类提供了一系列静态方法，用于在整个应用中进行导航操作。
/// 所有导航操作都通过根导航器执行，并包含安全检查。
class NavigationUtils {
  /// 私有构造函数，阻止实例化此类。
  NavigationUtils._();

  /// 定义主 Tab 路由及其对应的索引。
  static const Map<String, int> _mainTabRoutes = {
    AppRoutes.home: 0, // 首页路由索引
    AppRoutes.gamesList: 1, // 游戏列表路由索引
    AppRoutes.forum: 2, // 论坛路由索引
    AppRoutes.activityFeed: 3, // 动态路由索引
    AppRoutes.externalLinks: 4, // 工具链接路由索引
    AppRoutes.profile: 5, // 个人中心路由索引
  };

  /// 获取根导航器状态。
  ///
  /// 该方法通过全局导航键 `mainNavigatorKey` 获取 `NavigatorState`。
  /// 如果 `NavigatorState` 为空，则抛出 `FlutterError`。
  static NavigatorState _getRootNavigator() {
    final navigator = mainNavigatorKey.currentState; // 获取根导航器状态
    if (navigator == null) {
      throw FlutterError(
          'NavigationUtils: mainNavigatorKey.currentState 为空。请确保已附加到 MaterialApp。');
    }
    return navigator; // 返回根导航器状态
  }

  /// 获取指定 BuildContext 的导航器状态。
  ///
  /// [context]：Build 上下文。
  /// [rootNavigator]：指定是否获取根导航器。
  /// 返回对应的 `NavigatorState`。
  static NavigatorState of(BuildContext context, {bool rootNavigator = false}) {
    if (rootNavigator) {
      // 获取根导航器
      try {
        return _getRootNavigator();
      } catch (e) {
        try {
          return Navigator.of(context); // 根导航器获取失败时回退到局部导航器
        } catch (fallbackError) {
          throw FlutterError(
              'NavigationUtils.of(rootNavigator: true) 失败: ${e.toString()}. 回退 Navigator.of(context) 也失败: ${fallbackError.toString()}');
        }
      }
    } else {
      // 获取局部导航器
      try {
        return Navigator.of(context);
      } catch (e) {
        return _getRootNavigator(); // 局部导航器获取失败时回退到根导航器
      }
    }
  }

  /// 推送一个新路由到导航栈。
  ///
  /// [context]：Build 上下文。
  /// [route]：要推送的新路由。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> push<T>(BuildContext context, Route<T> route) {
    return _safeCall(
        () => _getRootNavigator().push(route)); // 安全调用根导航器的 push 方法
  }

  /// 通过路由名称推送一个新路由到导航栈。
  ///
  /// [context]：Build 上下文。
  /// [routeName]：要推送的路由名称。
  /// [arguments]：可选的路由参数。
  /// 如果是登录页，则调用 `navigateToLogin`。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> pushNamed<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    if (routeName == AppRoutes.login) {
      // 如果是登录页路由
      bool redirectAfterLogin = false; // 登录后是否重定向标记
      int? redirectIndex; // 重定向目标索引
      if (arguments is Map<String, dynamic>) {
        // 从参数中解析重定向信息
        redirectAfterLogin = arguments['redirect_after_login'] ?? false;
        redirectIndex = arguments['redirect_index'] as int?;
      }
      return navigateToLogin<T>(
        // 跳转到登录页
        context,
        redirectAfterLogin: redirectAfterLogin,
        redirectIndex: redirectIndex,
      );
    }
    return _safeCall(() => // 安全调用根导航器的 pushNamed 方法
        _getRootNavigator().pushNamed<T>(routeName, arguments: arguments));
  }

  /// 替换当前路由为一个新路由。
  ///
  /// [context]：Build 上下文。
  /// [route]：要替换的新路由。
  /// [result]：可选的返回结果。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Route<T> route,
      {TO? result}) {
    return _safeCall(() => _getRootNavigator().pushReplacement(route,
        result: result)); // 安全调用根导航器的 pushReplacement 方法
  }

  /// 通过路由名称替换当前路由为一个新路由。
  ///
  /// [context]：Build 上下文。
  /// [routeName]：要替换的路由名称。
  /// [result]：可选的返回结果。
  /// [arguments]：可选的路由参数。
  /// 如果是登录页，则调用 `navigateToLogin`。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> pushReplacementNamed<T, TO>(
      BuildContext context, String routeName,
      {TO? result, Object? arguments}) {
    if (routeName == AppRoutes.login) {
      // 如果是登录页路由
      bool redirectAfterLogin = false; // 登录后是否重定向标记
      int? redirectIndex; // 重定向目标索引
      if (arguments is Map<String, dynamic>) {
        // 从参数中解析重定向信息
        redirectAfterLogin = arguments['redirect_after_login'] ?? false;
        redirectIndex = arguments['redirect_index'] as int?;
      }
      return navigateToLogin<T>(
        // 跳转到登录页
        context,
        redirectAfterLogin: redirectAfterLogin,
        redirectIndex: redirectIndex,
      );
    }
    return _safeCall(() => _getRootNavigator()
        .pushReplacementNamed(routeName, // 安全调用根导航器的 pushReplacementNamed 方法
            result: result,
            arguments: arguments));
  }

  /// 推送一个新路由并移除直到满足指定条件的路由。
  ///
  /// [context]：Build 上下文。
  /// [route]：要推送的新路由。
  /// [predicate]：一个函数，用于判断哪些路由应该被移除。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> pushAndRemoveUntil<T>(
      BuildContext context, Route<T> route, RoutePredicate predicate) {
    return _safeCall(() => _getRootNavigator().pushAndRemoveUntil(
        route, predicate)); // 安全调用根导航器的 pushAndRemoveUntil 方法
  }

  /// 通过路由名称推送一个新路由并移除直到满足指定条件的路由。
  ///
  /// [context]：Build 上下文。
  /// [routeName]：要推送的路由名称。
  /// [predicate]：一个函数，用于判断哪些路由应该被移除。
  /// [arguments]：可选的路由参数。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> pushNamedAndRemoveUntil<T>(
      BuildContext context, String routeName, RoutePredicate predicate,
      {Object? arguments}) {
    return _safeCall(() =>
        _getRootNavigator() // 安全调用根导航器的 pushNamedAndRemoveUntil 方法
            .pushNamedAndRemoveUntil(routeName, predicate,
                arguments: arguments));
  }

  /// 弹出当前路由。
  ///
  /// [context]：Build 上下文。
  /// [result]：可选的返回结果。
  /// 返回 true 表示成功弹出，false 表示无法弹出。
  static bool pop<T>(BuildContext context, [T? result]) {
    final navigator = _getRootNavigator(); // 获取根导航器
    if (!navigator.canPop()) return false; // 无法弹出时返回 false
    _safeCallSync(() => navigator.pop(result)); // 安全同步调用导航器的 pop 方法
    return true; // 成功弹出
  }

  /// 弹出直到满足指定条件的路由。
  ///
  /// [context]：Build 上下文。
  /// [predicate]：一个函数，用于判断哪些路由应该被弹出。
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    _safeCallSync(() =>
        _getRootNavigator().popUntil(predicate)); // 安全同步调用导航器的 popUntil 方法
  }

  /// 检查导航栈是否可以弹出。
  ///
  /// [context]：Build 上下文。
  /// 返回 true 表示可以弹出，false 表示不能弹出。
  static bool canPop(BuildContext context) {
    try {
      return _getRootNavigator().canPop(); // 检查根导航器是否可以弹出
    } catch (e) {
      return false; // 捕获错误时返回 false
    }
  }

  /// 弹出所有路由直到根路由。
  ///
  /// [context]：Build 上下文。
  static void popToRoot(BuildContext context) {
    _safeCallSync(() => _getRootNavigator()
        .popUntil((route) => route.isFirst)); // 安全同步调用导航器的 popUntil 方法，直到根路由
  }

  /// 导航到主页的指定 Tab。
  ///
  /// [sidebarProvider]：侧边栏 Provider 实例。
  /// [context]：Build 上下文。
  /// [tabIndex]：要切换到的 Tab 索引，默认为 0。
  /// 清除当前路由栈直到根路由，并更新侧边栏的选中索引。
  static void navigateToHome(
      SidebarProvider sidebarProvider, BuildContext context,
      {int tabIndex = 0}) {
    if (tabIndex < 0 || tabIndex >= _mainTabRoutes.length) {
      // 简单的范围检查
      tabIndex = 0; // 索引无效时重置为 0
    }

    _safeCallSync(() {
      // 安全同步调用
      final navigator = mainNavigatorKey.currentState;
      if (navigator == null) return; // 再次检查导航器是否存在

      if (navigator.canPop()) {
        // 如果导航栈中有其他路由
        navigator.popUntil((route) => route.isFirst); // 清除当前路由栈直到根路由
      }

      final providerContext =
          mainNavigatorKey.currentContext; // 获取侧边栏 Provider 的上下文
      if (providerContext != null) {
        try {
          sidebarProvider.setCurrentIndex(tabIndex); // 更新侧边栏选中索引
        } catch (e) {
          // 捕获更新 SidebarProvider 错误
        }
      }
    });
  }

  /// 导航到登录页。
  ///
  /// [context]：Build 上下文。
  /// [redirectAfterLogin]：登录成功后是否重定向。
  /// [redirectIndex]：重定向目标 Tab 索引。
  /// 清空导航栈并推送登录页。
  /// 返回一个 Future，表示登录页的返回结果。
  static Future<T?> navigateToLogin<T>(BuildContext context,
      {bool redirectAfterLogin = false, int? redirectIndex}) {
    return _getRootNavigator().pushNamedAndRemoveUntil<T>(
      // 调用根导航器的 pushNamedAndRemoveUntil 方法
      AppRoutes.login, // 登录路由名称
      (route) => route.isFirst, // 移除直到根路由
      arguments: {
        // 传递参数
        if (redirectAfterLogin) 'redirect_after_login': true,
        if (redirectIndex != null) 'redirect_index': redirectIndex,
      },
    );
  }

  /// 清空整个导航栈并推送一个新路由。
  ///
  /// [context]：Build 上下文。
  /// [routeName]：要推送的路由名称。
  /// [arguments]：可选的路由参数。
  /// 返回一个 Future，表示新路由的返回结果。
  static Future<T?> clearStackAndPush<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    return _safeCall(
        () => _getRootNavigator() // 安全调用根导航器的 pushNamedAndRemoveUntil 方法
            .pushNamedAndRemoveUntil<T>(routeName, (route) => false, // 移除所有路由
                arguments: arguments));
  }

  /// 尝试弹出当前路由。
  ///
  /// [context]：Build 上下文。
  /// [result]：可选的返回结果。
  /// 返回一个 Future，表示是否成功弹出。
  static Future<bool> maybePop<T>(BuildContext context, [T? result]) {
    try {
      return _getRootNavigator().maybePop(result); // 调用根导航器的 maybePop 方法
    } catch (e) {
      return Future.value(false); // 捕获错误时返回 false
    }
  }

  /// 显示提示登录的对话框。
  ///
  /// [invokerContext]：调用处的 Build 上下文。
  /// [message]：提示消息，默认为“请登录后继续操作”。
  /// [redirectIndex]：登录后重定向目标 Tab 索引。
  /// 返回一个 Future：用户选择“去登录”返回 true，否则返回 false。
  static Future<bool> showLoginDialog(BuildContext invokerContext,
      {String message = '请登录后继续操作', int? redirectIndex}) async {
    final rootContext = mainNavigatorKey.currentContext; // 获取根上下文
    if (rootContext == null) {
      return false; // 无法显示对话框时返回 false
    }

    final bool? shouldLogin = await BaseInputDialog.show<bool?>(
      // 显示基础输入对话框
      context: rootContext, // 使用根上下文
      title: '需要登录', // 对话框标题
      contentBuilder: (BuildContext dialogContext) {
        // 内容构建器
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
        );
      },
      confirmButtonText: '去登录', // 确认按钮文本
      onConfirm: () async {
        return Future.value(true); // 用户选择“去登录”时返回 true
      },
      cancelButtonText: '取消', // 取消按钮文本
      showCancelButton: true, // 显示取消按钮
      onCancel: () {}, // 取消回调
      isDraggable: false, // 不可拖拽
      isScalable: false, // 不可缩放
      barrierDismissible: true, // 允许点击外部区域关闭
      allowDismissWhenNotProcessing: true, // 允许在非处理状态下关闭
    );

    if (shouldLogin == true) {
      // 用户选择“去登录”
      navigateToLogin(
        // 导航到登录页
        mainNavigatorKey.currentContext ?? invokerContext,
        redirectAfterLogin: true,
        redirectIndex: redirectIndex,
      );
      return true; // 返回 true
    }
    return false; // 用户不想登录时返回 false
  }

  // --- 安全调用包装器 ---

  /// 安全异步调用导航函数。
  ///
  /// [navigateFunction]：要执行的异步导航函数。
  /// 该方法在 `WidgetsBinding.instance.addPostFrameCallback` 中执行导航操作，
  /// 确保在导航器可用时执行。
  static Future<T> _safeCall<T>(Future<T> Function() navigateFunction) async {
    final completer = Completer<T>(); // 创建 Completer
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 在下一帧回调中执行
      try {
        _getRootNavigator(); // 确保导航器存在
        final result = await navigateFunction(); // 执行导航函数
        if (!completer.isCompleted) completer.complete(result); // 完成 Completer
      } catch (e, s) {
        if (!completer.isCompleted)
          completer.completeError(e, s); // 错误时完成 Completer
      }
    });
    return completer.future; // 返回 Completer 的 Future
  }

  /// 安全同步调用导航函数。
  ///
  /// [navigateFunction]：要执行的同步导航函数。
  /// 该方法在 `WidgetsBinding.instance.addPostFrameCallback` 中执行导航操作，
  /// 确保在导航器可用时执行。
  static void _safeCallSync(Function() navigateFunction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 在下一帧回调中执行
      try {
        _getRootNavigator(); // 确保导航器存在
        navigateFunction(); // 执行导航函数
      } catch (e) {
        // 捕获错误
      }
    });
  }
}
