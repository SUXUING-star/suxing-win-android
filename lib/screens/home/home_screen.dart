// lib/screens/home/home_screen.dart
// *** 严格基于缓存变化刷新版本 ***
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_hot_posts.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_game_hot.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_latest_games.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_banner.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// 定义枚举 (保持不变)
enum HomeDataType { hotGames, latestGames, hotPosts }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {


  // --- 状态变量 ---
  DateTime? _lastPullToRefreshTime; // 记录上次下拉刷新的时间 (可选)
  bool _isInitialized = false; // 标记整体页面是否已初始化加载过
  bool _isVisible = false;
  String? _errorMessage; // 保留用于可能的整体错误
  bool _isLoadingOnPullToRefresh = false; // *只* 控制下拉刷新的 Loading 状态
  bool _hasPlayedEntryAnimation = false;

  // --- 用于强制重建子组件的 Key 状态 (由缓存监听器和下拉刷新驱动) ---
  int _hotGamesKeyCounter = 0;
  int _latestGamesKeyCounter = 0;
  int _hotPostsKeyCounter = 0;

  // --- 缓存监听订阅 (保持不变) ---
  StreamSubscription? _hotGamesWatchSub;
  StreamSubscription? _latestGamesWatchSub;
  StreamSubscription? _hotPostsWatchSub;
  static const Duration _cacheDebounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToCacheChanges();
    // 初始加载由 VisibilityDetector 触发
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeFromCacheChanges();
    super.dispose();
  }

  // --- 修改：didChangeAppLifecycleState ---
  // --- 完全移除自动刷新逻辑，只管理 _isVisible 状态 ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      // App 恢复到前台
    } else if (state == AppLifecycleState.paused) {}
  }

  // *** 订阅缓存变化 (保持不变) ***
  void _subscribeToCacheChanges() {
    final gameService = context.read<GameService>();
    final forumService = context.read<ForumService>(); // 安全获取
    try {
      _hotGamesWatchSub = gameService.hotGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.hotGames, event),
              onError: (e) => print("Error watching hot games: $e"));

      _latestGamesWatchSub = gameService.latestGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen(
              (event) => _handleCacheChange(HomeDataType.latestGames, event),
              onError: (e) => print("Error watching latest games: $e"));

      _hotPostsWatchSub = forumService.hotPostsCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.hotPosts, event),
              onError: (e) => print("Error watching hot posts: $e"));
    } catch (e) {}
  }

  // *** 取消订阅缓存变化 (保持不变) ***
  void _unsubscribeFromCacheChanges() {
    _hotGamesWatchSub?.cancel();
    _latestGamesWatchSub?.cancel();
    _hotPostsWatchSub?.cancel();
  }

  // *** 修改：_handleCacheChange - 这是触发对应组件刷新的核心！ ***
  void _handleCacheChange(HomeDataType type, BoxEvent event) {
    if (!mounted) {
      return;
    }
    if (kDebugMode) {}

    // 只增加对应类型的计数器并 setState
    // 只有当对应缓存真的变了，才会走到这里，触发对应组件的刷新
    setState(() {
      switch (type) {
        case HomeDataType.hotGames:
          _hotGamesKeyCounter++;
          break;
        case HomeDataType.latestGames:
          _latestGamesKeyCounter++;
          break;
        case HomeDataType.hotPosts:
          _hotPostsKeyCounter++;
          break;
      }
    });
  }

  // *** 修改：_loadInitialData - 用于首次加载 ***
  void _loadInitialData() {
    if (!mounted) return;
    setState(() {
      _isInitialized = true; // 标记已初始化
      _errorMessage = null;
      // 触发所有子组件的首次加载 (通过增加 Key Counter)
      _forceRefreshAllChildrenCounters();
      if (!_hasPlayedEntryAnimation) {
        _hasPlayedEntryAnimation = true;
      }
    });
  }

  // *** 修改：_refreshData - 用于下拉刷新 ***
  Future<void> _refreshData() async {
    // 注意：这个方法现在只由 RefreshIndicator 调用
    if (!mounted || _isLoadingOnPullToRefresh) return; // 防止重复下拉刷新
    print('HomeScreen: Pull-to-refresh triggered.');
    setState(() {
      _isLoadingOnPullToRefresh = true; // 设置下拉刷新的 Loading 状态
    });
    _lastPullToRefreshTime = DateTime.now();

    // 强制刷新所有子组件
    // 这里我们明确希望下拉刷新能获取所有部分的最新数据
    setState(() {
      _forceRefreshAllChildrenCounters();
    });

    // 给子组件一些时间去开始 fetch，然后解除下拉刷新的 loading 状态
    // 这个时间需要调整，取决于子组件 fetch 的大概时间
    // 或者更好的方式是让子组件 fetch 完成后通知 HomeScreen？（会更复杂）
    // 暂时用固定延迟
    await Future.delayed(Duration(seconds: 1)); // 模拟网络延迟 + 子组件处理

    if (mounted) {
      setState(() {
        _isLoadingOnPullToRefresh = false; // 解除下拉刷新的 Loading 状态
      });
    }
  }

  // 辅助方法：增加所有 Key Counter (不变，但调用时机改变了)
  void _forceRefreshAllChildrenCounters() {
    // 这个方法现在只在首次加载和下拉刷新时被调用
    _hotGamesKeyCounter++;
    _latestGamesKeyCounter++;
    _hotPostsKeyCounter++;
  }

  // *** 修改：_triggerInitialLoad - 触发首次加载 ***
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && mounted) {
      _loadInitialData();
    }
  }

  // --- build 方法和 VisibilityDetector ---
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('home_screen_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        if (!mounted) return; // 先检查 mounted
        final wasVisible = _isVisible;
        final currentlyVisible = visibilityInfo.visibleFraction > 0.1;

        if (currentlyVisible != wasVisible) {
          if (mounted) {
            // 再次检查
            setState(() {
              _isVisible = currentlyVisible;
            }); // 更新状态
          } else {
            return;
          }

          // 只有在首次变为可见时触发初始加载
          if (_isVisible && !_isInitialized) {
            _triggerInitialLoad();
          }
        }
      },
      child: _buildContent(),
    );
  }

  // *** 修改：_buildContent 方法 ***
  Widget _buildContent() {
    if (!_isInitialized) {
      // 可以显示一个空的 Scaffold 或者骨架屏
      return Scaffold(
        //appBar: CustomAppBar(title: '主页'),
        body: LoadingWidget.fullScreen(message: "首次加载中..."), // 或者骨架屏
      );
    }
    if (_errorMessage != null) {
      return CustomErrorWidget(
        errorMessage: "发生错误 $_errorMessage",
        onRetry: ()=> _refreshData(),
      );
    }

    // 正常显示内容框架
    const Duration initialDelay = Duration(milliseconds: 150);
    const Duration stagger = Duration(milliseconds: 100);
    int sectionIndex = 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // 下拉刷新调用 _refreshData
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HomeBanner (保持不变) ---
              FadeInSlideUpItem(delay: initialDelay, child: HomeBanner()),
              SizedBox(height: 16),

              // --- HomeGameHot (使用 ValueKey) ---
              FadeInSlideUpItem(
                delay: initialDelay + stagger * sectionIndex++,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: HomeHotGames(
                    // Key 会根据 counter 变化，触发重建
                    key: ValueKey('hot_games_$_hotGamesKeyCounter'),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // --- Latest Games 和 Hot Posts (响应式布局) ---
              FadeInSlideUpItem(
                delay: initialDelay + stagger * sectionIndex++,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildPostsAndGamesSection(context),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // *** _buildPostsAndGamesSection 方法 (保持不变) ***
  Widget _buildPostsAndGamesSection(BuildContext context) {
    final bool isLarge = DeviceUtils.isLargeScreen(context);

    final Widget hotPostsWidget = HomeHotPosts(
      key: ValueKey('hot_posts_$_hotPostsKeyCounter'),
    );

    final Widget latestGamesWidget = HomeLatestGames(
      key: ValueKey('latest_games_$_latestGamesKeyCounter'),
    );

    if (isLarge) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: hotPostsWidget),
          SizedBox(width: 16.0),
          Expanded(child: latestGamesWidget),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hotPostsWidget,
          SizedBox(height: 16.0),
          latestGamesWidget,
        ],
      );
    }
  }
} // End of _HomeScreenState
