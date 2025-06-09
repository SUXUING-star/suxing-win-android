// lib/utils/navigation/sidebar_updater_observer.dart

/// 该文件定义了 SidebarUpdaterObserver，一个用于更新侧边栏状态的 NavigatorObserver。
/// SidebarUpdaterObserver 监听导航器路由变化，并更新侧边栏的子路由激活状态。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 侧边栏 Provider

/// `SidebarUpdaterObserver` 类：侧边栏更新观察者。
///
/// 该类监听导航器路由的变化，并根据导航栈状态更新侧边栏的子路由激活状态。
class SidebarUpdaterObserver extends NavigatorObserver {
  final SidebarProvider sidebarProvider; // 侧边栏 Provider 实例
  /// 构造函数。
  ///
  /// [sidebarProvider]：侧边栏 Provider 实例。
  SidebarUpdaterObserver({
    required this.sidebarProvider,
  });

  /// 更新侧边栏状态。
  ///
  /// [context]：Build 上下文。
  /// 在帧绘制完成后执行，避免在构建过程中修改状态。
  void _updateSidebarState(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 在当前帧绘制完成后回调
      final bool canPop = navigator?.canPop() ?? false; // 判断导航器是否可以弹出路由

      if (sidebarProvider.isSubRouteActive != canPop) {
        // 只有当状态真正改变时才更新
        sidebarProvider.setSubRouteActive(canPop); // 更新侧边栏的子路由激活状态
      }
    });
  }

  /// 路由被推入导航器时调用。
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute); // 调用父类方法
    if (navigator != null) {
      // 导航器存在时
      _updateSidebarState(navigator!.context); // 更新侧边栏状态
    }
  }

  /// 路由被弹出导航器时调用。
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute); // 调用父类方法
    if (navigator != null) {
      // 导航器存在时
      _updateSidebarState(navigator!.context); // 更新侧边栏状态
    }
  }

  /// 路由被移除导航器时调用。
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute); // 调用父类方法
    if (navigator != null) {
      // 导航器存在时
      _updateSidebarState(navigator!.context); // 更新侧边栏状态
    }
  }

  /// 路由被替换时调用。
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute); // 调用父类方法
    if (navigator != null) {
      // 导航器存在时
      _updateSidebarState(navigator!.context); // 更新侧边栏状态
    }
  }
}
