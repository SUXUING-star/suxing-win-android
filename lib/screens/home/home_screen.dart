// lib/screens/home/home_screen.dart
import 'dart:async'; // 需要导入 async 包
import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // 需要导入 hive 包
import 'package:rxdart/rxdart.dart'; // 引入 rxdart 用于 debounceTime
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_hot_posts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../widgets/components/screen/home/section/home_game_hot.dart';
import '../../widgets/components/screen/home/section/home_game_latest.dart';
import '../../widgets/components/screen/home/section/home_banner.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart';
import '../../widgets/ui/common/loading_widget.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/animation/fade_in_slide_up_item.dart';
import '../../widgets/ui/animation/fade_in_item.dart';
import '../../widgets/ui/common/error_widget.dart'; // 确保 CustomErrorWidget 路径正确

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// 定义枚举
enum HomeDataType { hotGames, latestGames, hotPosts }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GameService _gameService = GameService();
  final ForumService _forumService = ForumService();

  // --- Stream 成员变量保持不变 ---
  Stream<List<Game>>? _hotGamesStream;
  Stream<List<Game>>? _latestGamesStream;
  Stream<List<Post>>? _hotPostsStream;

  // --- 状态变量 ---
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(minutes: 5);
  bool _isInitialized = false;
  bool _isVisible = false;
  String? _errorMessage;
  bool _isLoading = false;
  bool _needsRefresh = false;
  bool _hasPlayedEntryAnimation = false;

  // --- 缓存监听订阅 ---
  StreamSubscription? _hotGamesWatchSub;
  StreamSubscription? _latestGamesWatchSub;
  StreamSubscription? _hotPostsWatchSub;
  static const Duration _cacheDebounceDuration = Duration(milliseconds: 500); // 增加防抖时间

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始加载由 VisibilityDetector 触发
    _subscribeToCacheChanges(); // *** 订阅缓存变化 ***
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeFromCacheChanges(); // *** 取消订阅 ***
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_needsRefresh && _isVisible) {
        print("HomeScreen Resumed with NeedsRefresh flag. Triggering refresh.");
        _refreshData(forceApi: true); // 回到前台强制刷新 API
        _needsRefresh = false;
      } else if (_isVisible) {
        print("HomeScreen Resumed and visible. Checking if data needs refresh.");
        _refreshIfNeeded();
      }
    } else if (state == AppLifecycleState.paused) {
      print("HomeScreen Paused. Setting NeedsRefresh flag.");
      _needsRefresh = true;
    }
  }

  // *** 订阅缓存变化 ***
  void _subscribeToCacheChanges() {
    print("HomeScreen: Subscribing to cache changes...");
    try {
      _hotGamesWatchSub = _gameService.hotGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.hotGames, event),
          onError: (e) => print("Error watching hot games: $e"));

      _latestGamesWatchSub = _gameService.latestGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.latestGames, event),
          onError: (e) => print("Error watching latest games: $e"));

      _hotPostsWatchSub = _forumService.hotPostsCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.hotPosts, event),
          onError: (e) => print("Error watching hot posts: $e"));
    } catch (e) {
      print("HomeScreen: Error subscribing to cache changes: $e");
      // 可以考虑在这里设置错误状态
    }
  }

  // *** 取消订阅缓存变化 ***
  void _unsubscribeFromCacheChanges() {
    print("HomeScreen: Unsubscribing from cache changes...");
    _hotGamesWatchSub?.cancel();
    _latestGamesWatchSub?.cancel();
    _hotPostsWatchSub?.cancel();
  }

  // *** 处理缓存变化事件 ***
  void _handleCacheChange(HomeDataType type, BoxEvent event) {
    print("HomeScreen received cache change for $type. Key: ${event.key}, Deleted: ${event.deleted}");
    if (mounted && _isVisible) {
      // 核心：收到缓存变化通知，重新获取对应的 Stream 并 setState
      print("Reloading Stream for $type due to change detection.");
      _reloadSpecificStream(type);
    } else if (mounted) {
      print("HomeScreen received cache change for $type but screen is not visible. Marking for refresh.");
      _needsRefresh = true;
    }
  }

  // *** 重新加载特定 Stream 的方法 ***
  void _reloadSpecificStream(HomeDataType type) {
    if (!mounted) return;
    setState(() {
      switch (type) {
        case HomeDataType.hotGames:
          print("Reloading _hotGamesStream");
          _hotGamesStream = _gameService.getHotGames();
          break;
        case HomeDataType.latestGames:
          print("Reloading _latestGamesStream");
          _latestGamesStream = _gameService.getLatestGames();
          break;
        case HomeDataType.hotPosts:
          print("Reloading _hotPostsStream");
          _hotPostsStream = _forumService.getHotPosts();
          break;
      }
      // 可选：可以加一个短暂的 visual cue 表示正在刷新这个 section
    });
  }

  // 初始化/加载所有数据流 (你的原始逻辑)
  void _loadData({bool forceApi = false}) { // 添加 forceApi 参数
    if (!mounted) return;
    print("HomeScreen: _loadData called (forceApi: $forceApi)");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 重新获取所有 Stream
      // 注意：如果 Service 层的 getXXX Stream 内部有缓存逻辑，
      // 这里重新获取不一定会立刻触发 API 调用，除非 forceApi 为 true
      // 或者 Service 层 Stream 实现就是简单的 API 调用
      _hotGamesStream = _gameService.getHotGames(); // 假设 getHotGames 内部会处理是否强制刷新
      _latestGamesStream = _gameService.getLatestGames();
      _hotPostsStream = _forumService.getHotPosts();

      _lastRefreshTime = DateTime.now();

      // 稍微延迟一点设置 isLoading = false，给 StreamBuilder 一点时间开始监听
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (!_hasPlayedEntryAnimation) {
              _hasPlayedEntryAnimation = true;
            }
          });
        }
      });

    } catch (e, s) {
      print("HomeScreen _loadData Error: $e\n$s");
      if (mounted) {
        setState(() {
          _errorMessage = '加载首页数据失败，请稍后重试。';
          _isLoading = false;
          _hasPlayedEntryAnimation = false;
          _hotGamesStream = null;
          _latestGamesStream = null;
          _hotPostsStream = null;
        });
      }
    }
  }

  // 触发首次加载的方法 (调用 _loadData)
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && mounted && !_isLoading) { // 加上 !_isLoading 防止重复加载
      print("HomeScreen is now visible and not initialized. Loading data...");
      setState(() {
        _isInitialized = true; // 标记已初始化
        // _isLoading = true; // _loadData 内部会设置
        _errorMessage = null;
        _hasPlayedEntryAnimation = false;
      });
      _loadData(); // 调用原始加载方法
    }
  }

  // 判断是否应该刷新数据 (保持不变)
  bool _shouldRefresh() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) >= _minRefreshInterval;
  }

  // 刷新数据的方法 (现在调用 _loadData)
  Future<void> _refreshData({bool forceApi = true}) async { // 默认强制刷新 API
    if (!mounted || _isLoading) return;
    print('HomeScreen: Refresh triggered (forceApi: $forceApi).');
    setState(() {
      _isLoading = true; // 显示加载指示
      _errorMessage = null;
      _hasPlayedEntryAnimation = false;
    });
    // 直接调用 _loadData 来重新获取所有 Stream
    _loadData(forceApi: forceApi);
    // _loadData 内部会在 Future.delayed 后设置 isLoading = false
  }

  // 检查是否需要刷新的方法
  void _refreshIfNeeded() {
    if (_shouldRefresh()) {
      print("HomeScreen: Refresh interval passed. Triggering refresh.");
      _refreshData(forceApi: true); // 时间到了，强制刷新 API
    } else {
      print("HomeScreen: No need to refresh based on interval.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // VisibilityDetector 逻辑保持不变，触发 _triggerInitialLoad
    return VisibilityDetector(
      key: Key('home_screen_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        final wasVisible = _isVisible;
        Future.microtask(() {
          if (!mounted) return;
          final currentlyVisible = visibilityInfo.visibleFraction > 0;
          if (currentlyVisible != _isVisible) {
            setState(() { _isVisible = currentlyVisible; }); // 更新可见状态
            if (!wasVisible && _isVisible) {
              // 从不可见到可见
              if (!_isInitialized) {
                _triggerInitialLoad(); // 触发首次加载
              } else if (_needsRefresh) {
                print("HomeScreen became visible with NeedsRefresh flag. Triggering refresh.");
                _refreshData(forceApi: true); // 如果标记了需要刷新，则强制刷新 API
                _needsRefresh = false;
              } else {
                print("HomeScreen became visible. No explicit refresh needed immediately.");
                // 可选：检查时间间隔决定是否刷新
                // _refreshIfNeeded();
              }
            } else if (wasVisible && !_isVisible) {
              // 从可见到不可见
              print("HomeScreen became invisible.");
            }
          }
        });
      },
      child: _buildContent(),
    );
  }

  // _buildContent 方法保持不变，它使用 Stream 成员变量和 StreamBuilder
  Widget _buildContent() {
    // 1. 还未初始化 (显示 Loading)
    if (!_isInitialized && !_isLoading) { // 确保在非加载状态下才显示等待初始化
      return Scaffold(
        body: FadeInItem(
          child: LoadingWidget.fullScreen(size: 40, message: '等待加载首页...'),
        ),
      );
    }

    // 2. 正在加载 (全屏 Loading)
    if (_isLoading && !_isInitialized) { // 仅在首次加载时全屏 Loading
      return Scaffold(
        body: LoadingWidget.fullScreen(size: 40, message: '正在加载首页...'),
      );
    }

    // 3. 加载出错 (全屏 Error)
    if (_errorMessage != null && _hotGamesStream == null && _latestGamesStream == null && _hotPostsStream == null) {
      return Scaffold( // 确保有 Scaffold
        body: FadeInSlideUpItem(
          child: CustomErrorWidget(
            errorMessage: _errorMessage!,
            onRetry: () => _loadData(forceApi: true), // 重试时强制 API
            title: '加载失败',
          ),
        ),
      );
    }

    // 4. 正常显示内容 (即使部分 Stream 为 null 或出错，也尝试构建)
    const Duration initialDelay = Duration(milliseconds: 150);
    const Duration stagger = Duration(milliseconds: 100);
    int sectionIndex = 0;

    // *** UI 结构保持不变，继续使用 StreamBuilder ***
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refreshData(forceApi: true), // 下拉刷新强制 API
        child: SingleChildScrollView(
          key: ValueKey<bool>(_hasPlayedEntryAnimation),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HomeBanner ---
              FadeInSlideUpItem(delay: initialDelay, child: HomeBanner()),
              SizedBox(height: 16),

              // --- HomeGameHot (使用 StreamBuilder) ---
              // 加载指示器现在由 _isLoading 控制，StreamBuilder 只处理流的数据/错误
              if (_hotGamesStream != null) // 确保 Stream 不为 null
                FadeInSlideUpItem(
                  delay: initialDelay + stagger * sectionIndex++,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    // *** 传递更新后的 Stream 给子 Widget ***
                    child: HomeGameHot(gamesStream: _hotGamesStream),
                  ),
                )
              else if (!_isLoading) // 如果 Stream 为 null 且不在加载中，可以显示错误或占位符
                Padding(padding: EdgeInsets.all(16), child: Text("无法加载热门游戏")),

              SizedBox(height: 16),

              // --- Latest Games 和 Hot Posts 并排 (使用 StreamBuilder) ---
              FadeInSlideUpItem(
                delay: initialDelay + stagger * sectionIndex++,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 左侧：热门帖子 ---
                      Expanded(
                          child: (_hotPostsStream != null)
                              ? HomeHotPosts(postsStream: _hotPostsStream)
                              : (!_isLoading ? Text("无法加载热门帖子") : SizedBox.shrink()) // 占位
                      ),

                      if (_latestGamesStream != null && _hotPostsStream != null)
                        SizedBox(width: 16.0),

                      // --- 右侧：最新游戏 ---
                      Expanded(
                          child: (_latestGamesStream != null)
                              ? HomeGameLatest(gamesStream: _latestGamesStream)
                              : (!_isLoading ? Text("无法加载最新游戏") : SizedBox.shrink()) // 占位
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} // End of _HomeScreenState