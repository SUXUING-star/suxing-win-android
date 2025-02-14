// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/home/home_hot.dart';
import '../../widgets/home/home_latest.dart';
import '../../utils/loading_route_observer.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取 LoadingRouteObserver 实例
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      // 显示加载动画
      loadingObserver.showLoading();

      // 模拟数据加载
      _initializeData().then((_) {
        // 隐藏加载动画
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _initializeData() async {
    // 模拟异步数据加载
    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await Future.delayed(Duration(seconds: 2));
      // 在这里添加实际的数据刷新逻辑
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 不需要加上appbar太丑了
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBanner(),
              HomeHot(),
              HomeLatest(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    double bannerHeight = 140.0; // 默认移动端高度

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      bannerHeight = 200.0; // 桌面端高度
    }

    return Container(
      height: bannerHeight,
      width: double.infinity,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  //home顶部图片
                  'images/kaev.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}