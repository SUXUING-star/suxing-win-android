import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../widgets/components/screen/home/section/home_hot.dart';
import '../../widgets/components/screen/home/section/home_latest.dart';
import '../../widgets/components/screen/home/section/home_banner.dart';
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

  // --- 懒加载状态 ---
  bool _isInitialized = false; // 是否已初始化（首次加载）
  bool _isVisible = false; // 当前是否可见

  String? _errorMessage;
  bool _isLoading = false; // 这个仍然用于刷新和加载过程中的状态

  @override
  void initState() {
    super.initState();
  }

  // 初始化游戏数据流
  void _loadData() {
    try {
      // 使用缓存优先的流
      _hotGamesStream = _gameService.getHotGames();
      _latestGamesStream = _gameService.getLatestGames();

      // 设置刷新时间
      _lastRefreshTime = DateTime.now();

      // 确保 setState 在 mounted 状态下调用
      if (mounted) {
        setState(() {
          _isLoading = false; // 加载完成
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载数据失败：${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // --- 新增：触发首次加载的方法 ---
  void _triggerInitialLoad() {
    // 保证只加载一次，并且是在可见时加载
    if (_isVisible && !_isInitialized) {
      print("HomeScreen is now visible and not initialized. Loading data...");
      setState(() {
        _isInitialized = true; // 标记为已初始化
        _isLoading = true; // 开始加载，显示 Loading
        _errorMessage = null;
      });
      _loadData(); // 调用实际加载数据的方法
    }
  }

  // 判断是否应该刷新数据
  bool _shouldRefresh() {
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
    if (!mounted) return; // 检查 mounted

    setState(() {
      _isLoading = true; // 开始刷新，显示 Loading
      _errorMessage = null;
    });

    try {
      final shouldForceRefresh = _shouldRefresh();

      if (shouldForceRefresh) {
        print('主页：强制刷新数据');
        // 强制刷新时，直接调用 _loadData 获取新数据流
        _loadData(); // _loadData 内部会处理 stream 的重新获取和状态更新
        _lastRefreshTime = DateTime.now();
      } else {
        print('主页：使用缓存数据，不强制刷新');
        // 如果不强制刷新，只需结束 loading 状态
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '刷新数据失败：${e.toString()}';
          _isLoading = false; // 刷新失败也要结束 loading
        });
      }
    }
    // finally 块不再需要设置 _isLoading = false，因为成功和失败路径都处理了
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('home_screen_visibility'), // 给个 Key
      onVisibilityChanged: (visibilityInfo) {
        final wasVisible = _isVisible;
        _isVisible = visibilityInfo.visibleFraction > 0;
        // 如果从不可见到可见，尝试触发加载
        if (!wasVisible && _isVisible) {
          _triggerInitialLoad();
        }
      },
      child: _buildContent(), // 把实际内容抽出来
    );
  }

  // --- 抽出实际的页面内容构建逻辑 ---
  Widget _buildContent() {
    // 1. 如果还未初始化（即从未加载过），显示占位符或初始 Loading
    if (!_isInitialized) {
      return Scaffold(
        // 可以只显示一个简单的 Loading，或者根据你的 UI 设计来
        body: LoadingWidget.fullScreen(size: 40, message: '等待加载首页...'),
      );
    }

    // 2. 如果正在加载（包括首次加载或刷新）
    if (_isLoading) {
      // 如果已有内容，可以在内容上层叠 Loading，否则显示全屏 Loading
      // 这里简单处理，直接显示 Loading
      return Scaffold(
        body: LoadingWidget.fullScreen(size: 40, message: '正在加载首页...'),
      );
    }

    // 3. 如果加载出错
    if (_errorMessage != null) {
      return CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadData, // 出错重试时直接调用 _loadData
        title: '加载失败',
      );
    }

    // 4. 正常显示内容
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HomeBanner(),
              // 确保 Stream 不为 null 再传递
              if (_hotGamesStream != null)
                HomeHot(gamesStream: _hotGamesStream),
              if (_latestGamesStream != null)
                HomeLatest(gamesStream: _latestGamesStream),
            ],
          ),
        ),
      ),
    );
  }
}
