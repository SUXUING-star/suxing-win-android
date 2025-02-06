import 'package:flutter/material.dart';

class LoadingRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<bool> isFirstLoad;

  LoadingRouteObserver()
      : isLoading = ValueNotifier<bool>(false),
        isFirstLoad = ValueNotifier<bool>(true);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _startLoading();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _startLoading();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _startLoading();
  }

  void _startLoading() {
    isLoading.value = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      isLoading.value = false;
      if (isFirstLoad.value) {
        isFirstLoad.value = false;
      }
    });
  }

  void showLoading() {
    isLoading.value = true;
  }

  void hideLoading() {
    isLoading.value = false;
  }
}