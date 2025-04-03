// lib/widgets/components/loading/loading_route_observer.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LoadingRouteObserver extends NavigatorObserver {
  static final LoadingRouteObserver _instance = LoadingRouteObserver._internal();
  factory LoadingRouteObserver() => _instance;

  final ValueNotifier<bool> isLoading;
  final Duration minLoadingDuration;
  DateTime? _loadingStartTime;

  LoadingRouteObserver._internal({
    this.minLoadingDuration = const Duration(milliseconds: 100),
  }) : isLoading = ValueNotifier<bool>(false);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 移除首次加载的特殊处理
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
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
      });
    } else {
      Future.delayed(remainingDuration, () {
        if (isLoading.value) {  // 确保在延迟期间没有新的加载请求
          isLoading.value = false;
        }
      });
    }
    _loadingStartTime = null;
  }
}