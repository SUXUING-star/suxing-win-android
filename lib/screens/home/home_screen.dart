import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../widgets/components/loading/loading_route_observer.dart';
import '../../widgets/components/screen/home/android/home_hot.dart';
import '../../widgets/components/screen/home/android/home_latest.dart';
import '../../widgets/components/screen/home/android/home_banner.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart';
import '../../widgets/ui/common/loading_widget.dart';
import '../../widgets/ui/common/error_widget.dart';

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

  // 错误处理
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 初始化游戏数据流 - 懒加载方式
    _initGameStreams();
  }

  // 初始化游戏数据流
  void _initGameStreams() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 使用缓存优先的流
      _hotGamesStream = _gameService.getHotGames();
      _latestGamesStream = _gameService.getLatestGames();

      // 设置刷新时间
      _lastRefreshTime = DateTime.now();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载数据失败：${e.toString()}';
        _isLoading = false;
      });
    }
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
    final loadingObserver = NavigationUtils.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 检查是否应该强制刷新
      final shouldForceRefresh = _shouldRefresh();

      if (shouldForceRefresh) {
        print('主页：强制刷新数据');

        // 重新初始化数据流
        setState(() {
          _hotGamesStream = null;
          _latestGamesStream = null;
        });

        // 等待一小段时间确保缓存清除完成
        await Future.delayed(Duration(milliseconds: 200));

        // 重新获取数据
        _hotGamesStream = _gameService.getHotGames();
        _latestGamesStream = _gameService.getLatestGames();
        _lastRefreshTime = DateTime.now();
      } else {
        print('主页：使用缓存数据，不强制刷新');
        // 如果不强制刷新，只需轻微刷新UI
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '刷新数据失败：${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 加载状态处理
    if (_isLoading) {
      return Scaffold(
        body: LoadingWidget.fullScreen(message: '正在加载首页...'),
      );
    }

    // 错误状态处理
    if (_errorMessage != null) {
      return Scaffold(
        body: CustomErrorWidget(
          errorMessage: _errorMessage!,
          onRetry: _initGameStreams,
          title: '加载失败',
        ),
      );
    }

    // 正常显示内容
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