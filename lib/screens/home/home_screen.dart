import 'package:flutter/material.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../widgets/components/screen/home/android/home_hot.dart';
import '../../widgets/components/screen/home/android/home_latest.dart';
import '../../widgets/components/screen/home/android/home_banner.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  Stream<List<Game>>? _hotGamesStream;
  Stream<List<Game>>? _latestGamesStream;

  // 添加缓存刷新控制
  DateTime? _lastRefreshTime;
  // 最小刷新间隔 - 5分钟
  static const Duration _minRefreshInterval = Duration(minutes: 5);

  // 追踪是否第一次初始化
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();

    // 初始化游戏数据流 - 懒加载方式
    _initGameStreams();
  }

  // 初始化游戏数据流
  void _initGameStreams() {
    // 使用缓存优先的流
    _hotGamesStream = _gameService.getHotGames();
    _latestGamesStream = _gameService.getLatestGames();

    // 设置刷新时间
    _lastRefreshTime = DateTime.now();
  }

  // 判断是否应该刷新数据
  bool _shouldRefresh() {
    if (_isFirstLoad) {
      _isFirstLoad = false;
      return false; // 首次加载不需要强制刷新
    }

    // 如果从未刷新过，则应该刷新
    if (_lastRefreshTime == null) {
      return true;
    }

    // 检查刷新间隔
    final now = DateTime.now();
    return now.difference(_lastRefreshTime!) >= _minRefreshInterval;
  }

  // 刷新数据的方法
  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      // 检查是否应该强制刷新
      final shouldForceRefresh = _shouldRefresh();

      if (shouldForceRefresh) {
        print('主页：强制刷新数据');

        // 清除相关缓存（可选，取决于是否需要强制从服务器获取新数据）
        // 在GameCacheService中添加一个特定方法来清除首页相关缓存

        // 重新初始化数据流
        setState(() {
          _hotGamesStream = null;
          _latestGamesStream = null;
        });

        // 等待一小段时间确保缓存清除完成
        await Future.delayed(Duration(milliseconds: 200));

        // 重新获取数据
        setState(() {
          _hotGamesStream = _gameService.getHotGames();
          _latestGamesStream = _gameService.getLatestGames();
          _lastRefreshTime = DateTime.now();
        });
      } else {
        print('主页：使用缓存数据，不强制刷新');
        // 如果不强制刷新，只需轻微刷新UI
        if (mounted) {
          setState(() {});
        }
      }
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HomeBanner(),
              // 传入已初始化的流，避免重复创建
              HomeHot(gamesStream: _hotGamesStream),
              HomeLatest(gamesStream: _latestGamesStream),
            ],
          ),
        ),
      ),
    );
  }
}