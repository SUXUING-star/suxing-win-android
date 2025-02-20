// lib/utils/loading_route_observer.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LoadingRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<bool> isFirstLoad;
  final Duration minLoadingDuration;
  DateTime? _loadingStartTime;

  LoadingRouteObserver({
    this.minLoadingDuration = const Duration(milliseconds: 300), // 减少最小加载时间
  }) : isLoading = ValueNotifier<bool>(false),
        isFirstLoad = ValueNotifier<bool>(true);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/home') {
      // 只在首次进入首页时显示加载
      if (isFirstLoad.value) {
        _startLoading();
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // 移除返回时的加载动画，因为数据已经缓存
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name == '/home' && isFirstLoad.value) {
      _startLoading();
    }
  }

  void _startLoading() {
    _loadingStartTime = DateTime.now();
    isLoading.value = true;
  }

  void showLoading() {
    _loadingStartTime = DateTime.now();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      isLoading.value = true;
    });
  }

  void hideLoading() {
    if (_loadingStartTime == null) {
      isLoading.value = false;
      return;
    }

    final elapsedDuration = DateTime.now().difference(_loadingStartTime!);
    final remainingDuration = minLoadingDuration - elapsedDuration;

    if (remainingDuration.isNegative) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
        if (isFirstLoad.value) {
          isFirstLoad.value = false;
        }
      });
    } else {
      Future.delayed(remainingDuration, () {
        if (isLoading.value) {  // 确保在延迟期间没有新的加载请求
          isLoading.value = false;
          if (isFirstLoad.value) {
            isFirstLoad.value = false;
          }
        }
      });
    }
    _loadingStartTime = null;
  }
}