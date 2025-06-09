// lib/providers/navigation/sidebar_provider.dart

/// 该文件定义了 SidebarProvider，管理侧边栏导航状态。
/// SidebarProvider 控制侧边栏当前选中项和子路由的激活状态。
library;

import 'dart:async';

/// `SidebarProvider` 类：管理侧边栏导航状态的 Provider。
///
/// 该类提供侧边栏选中索引和子路由激活状态的更新。
class SidebarProvider {
  int _currentIndex = 0; // 当前选中的侧边栏索引
  bool _isSubRouteActive = false; // 子路由是否处于激活状态

  final _indexController = StreamController<int>.broadcast(); // 广播侧边栏索引变化的控制器
  final _subRouteActiveController =
      StreamController<bool>.broadcast(); // 广播子路由激活状态变化的控制器

  /// 获取侧边栏索引的 Stream。
  Stream<int> get indexStream => _indexController.stream;

  /// 获取子路由激活状态的 Stream。
  Stream<bool> get subRouteActiveStream => _subRouteActiveController.stream;

  /// 获取当前选中的侧边栏索引。
  int get currentIndex => _currentIndex;

  /// 获取子路由的激活状态。
  bool get isSubRouteActive => _isSubRouteActive;

  /// 设置当前选中的侧边栏索引。
  ///
  /// [index]：新的侧边栏索引。
  /// 如果索引发生变化，则更新状态并通知监听者。
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      // 检查索引是否发生变化
      _currentIndex = index; // 更新当前索引
      _indexController.add(index); // 向索引 Stream 广播新值
    }
  }

  /// 设置子路由的激活状态。
  ///
  /// [isActive]：子路由是否激活。
  /// 如果状态发生变化，则更新状态并通知监听者。
  void setSubRouteActive(bool isActive) {
    if (_isSubRouteActive != isActive) {
      // 检查状态是否发生变化
      _isSubRouteActive = isActive; // 更新子路由激活状态
      _subRouteActiveController.add(isActive); // 向子路由激活状态 Stream 广播新值
    }
  }

  /// 清理资源。
  ///
  /// 关闭所有 StreamController。
  void dispose() {
    _indexController.close(); // 关闭索引 StreamController
    _subRouteActiveController.close(); // 关闭子路由激活状态 StreamController
  }
}
