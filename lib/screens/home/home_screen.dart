// lib/screens/home/home_screen.dart
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

// --- 引入动画组件 ---
import '../../widgets/ui/animation/fade_in_slide_up_item.dart';
import '../../widgets/ui/animation/fade_in_item.dart';
// --- 结束引入 ---

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  Stream<List<Game>>? _hotGamesStream;
  Stream<List<Game>>? _latestGamesStream;

  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(minutes: 5);

  bool _isInitialized = false;
  bool _isVisible = false;
  String? _errorMessage;
  bool _isLoading = false;

  // 新增：用于控制子组件动画只播放一次的标志
  bool _hasPlayedEntryAnimation = false;

  @override
  void initState() {
    super.initState();
    // 初始加载逻辑移到 _triggerInitialLoad
  }

  // 初始化游戏数据流
  void _loadData() {
    // 增加 mounted 检查
    if (!mounted) return;

    setState(() {
      _isLoading = true; // 开始加载，更新状态
      _errorMessage = null;
    });

    try {
      _hotGamesStream = _gameService.getHotGames();
      _latestGamesStream = _gameService.getLatestGames();
      _lastRefreshTime = DateTime.now();

      if (mounted) {
        setState(() {
          _isLoading = false; // 加载完成
          if (!_hasPlayedEntryAnimation) {
            _hasPlayedEntryAnimation = true; // 标记动画已播放（或即将播放）
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载数据失败：${e.toString()}';
          _isLoading = false;
          _hasPlayedEntryAnimation = false; // 加载失败，允许下次重试播放动画
        });
      }
    }
  }

  // 触发首次加载的方法
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && mounted) {
      // 增加 mounted 检查
      print("HomeScreen is now visible and not initialized. Loading data...");
      setState(() {
        _isInitialized = true;
        _isLoading = true;
        _errorMessage = null;
        _hasPlayedEntryAnimation = false; // 重置动画播放标志
      });
      _loadData();
    }
  }

  // 判断是否应该刷新数据 (保持不变)
  bool _shouldRefresh() {
    if (_lastRefreshTime == null) {
      return true;
    }
    final now = DateTime.now();
    return now.difference(_lastRefreshTime!) >= _minRefreshInterval;
  }

  // 刷新数据的方法
  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasPlayedEntryAnimation = false; // 刷新时重置动画标志
    });

    try {
      final shouldForceRefresh = _shouldRefresh();
      if (shouldForceRefresh) {
        print('主页：强制刷新数据');
        // 重新加载流，并在加载完成后更新状态
        _loadData(); // _loadData 内部会处理状态
      } else {
        print('主页：使用缓存数据，不强制刷新');
        if (mounted) {
          setState(() {
            _isLoading = false; // 仅结束加载状态
            if (!_hasPlayedEntryAnimation) {
              _hasPlayedEntryAnimation = true; // 标记动画已播放
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '刷新数据失败：${e.toString()}';
          _isLoading = false;
          _hasPlayedEntryAnimation = false; // 刷新失败，允许重试播放
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('home_screen_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        final wasVisible = _isVisible;
        // 使用 microtask 确保 setState 在 build 周期外或合适时机执行
        Future.microtask(() {
          final currentlyVisible = visibilityInfo.visibleFraction > 0;
          if (currentlyVisible != _isVisible) {
            if (mounted) {
              setState(() {
                _isVisible = currentlyVisible;
              });
            } else {
              _isVisible = currentlyVisible; // 如果 unmounted，只更新状态变量
            }
            // 如果从不可见到可见，尝试触发加载
            if (!wasVisible && _isVisible) {
              _triggerInitialLoad();
            }
          }
        });
      },
      child: _buildContent(),
    );
  }

  // 抽出实际的页面内容构建逻辑 (应用动画)
  Widget _buildContent() {
    // 1. 还未初始化
    if (!_isInitialized) {
      // --- 修改这里：初始等待状态加动画 ---
      return Scaffold(
        body: FadeInItem(
          // 使用 FadeInItem
          child: LoadingWidget.fullScreen(size: 40, message: '等待加载首页...'),
        ),
      );
      // --- 结束修改 ---
    }

    // 2. 正在加载（刷新或首次加载的短暂过程）
    // 这里可以考虑不显示全屏 Loading，让旧内容保持，仅在 AppBar 显示刷新指示器
    // 或者像现在这样显示 Loading
    if (_isLoading) {
      // --- 修改这里：加载中状态加动画 ---
      return Scaffold(
        body: LoadingWidget.fullScreen(size: 40, message: '正在加载首页...'),
      );
      // --- 结束修改 ---
    }

    // 3. 加载出错
    if (_errorMessage != null) {
      // --- 修改这里：错误状态加动画 ---
      return FadeInSlideUpItem(
        // 使用 FadeInSlideUpItem
        child: CustomErrorWidget(
          // CustomErrorWidget 可能需要 Scaffold 包裹或自行处理背景
          errorMessage: _errorMessage!,
          onRetry: _loadData,
          title: '加载失败',
        ),
      );
      // --- 结束修改 ---
    }

    // 4. 正常显示内容
    // 定义基础延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 150);
    const Duration stagger = Duration(milliseconds: 100);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          // 添加 Key，确保内容更新时能被识别
          key: ValueKey<bool>(_hasPlayedEntryAnimation), // 使用动画状态作为 Key 的一部分
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- 修改这里：为每个 Section 添加动画 ---
              // 只有在动画标志为 true 时才应用动画（首次加载/刷新成功后）
              // HomeBanner 动画
              FadeInSlideUpItem(
                // play: _hasPlayedEntryAnimation, // 可选：如果动画组件支持 play 参数
                delay: initialDelay,
                child: HomeBanner(),
              ),
              // HomeHot 动画
              if (_hotGamesStream != null)
                FadeInSlideUpItem(
                  // play: _hasPlayedEntryAnimation,
                  delay: initialDelay + stagger,
                  child: Padding(
                    // 给 Section 之间加点间距
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: HomeHot(gamesStream: _hotGamesStream),
                  ),
                ),
              // HomeLatest 动画
              if (_latestGamesStream != null)
                FadeInSlideUpItem(
                  // play: _hasPlayedEntryAnimation,
                  delay: initialDelay + stagger * 2,
                  child: HomeLatest(gamesStream: _latestGamesStream),
                ),
              // --- 结束修改 ---
            ],
          ),
        ),
      ),
    );
  }
}
