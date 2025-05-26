// lib/screens/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_hot_posts.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_extension.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_hot_games.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_latest_games.dart';
import 'package:suxingchahui/widgets/components/screen/home/section/home_banner.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final GameService gameService;
  final PostService postService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  const HomeScreen({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.postService,
    required this.followService,
    required this.infoProvider,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum HomeDataType {
  hotGames,
  latestGames,
  hotPosts,
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isOverallInitialized = false; // 标记整体页面是否已“首次加载”过所有必要数据
  bool _isVisible = false;
  String? _overallErrorMessage; // 整体页面框架的错误

  bool _hasPlayedEntryAnimation = false; // 用于首次进入的动画控制

  // --- 下拉刷新节流 ---
  bool _isPerformingHomeScreenRefresh = false;
  DateTime? _lastHomeScreenRefreshAttemptTime;
  static const Duration _minHomeScreenRefreshInterval =
      Duration(seconds: 60); // 改回60秒

  // --- 子组件 Key Counters (用于强制重建子组件的UI结构，但不直接驱动数据获取) ---
  // 现在主要用于缓存变化时，如果子组件内部有一些依赖Key的UI逻辑，可以保留
  // 但数据刷新主要靠 HomeScreen 的 setState 更新 props
  int _hotGamesKeyCounter = 0;
  int _latestGamesKeyCounter = 0;
  int _hotPostsKeyCounter = 0;

  // --- HomeScreen 管理的数据和加载状态 ---
  List<Game>? _hotGamesData;
  bool _isHotGamesLoading = false;
  String? _hotGamesError;

  List<Game>? _latestGamesData;
  bool _isLatestGamesLoading = false;
  String? _latestGamesError;

  List<Post>? _hotPostsData;
  bool _isHotPostsLoading = false;
  String? _hotPostsError;

  // --- HomeHotGames 轮播控制 ---
  PageController _hotGamesPageController = PageController();
  Timer? _hotGamesScrollTimer;
  int _currentHotGamesPage = 0;
  static const Duration _hotGamesAutoscrollDuration = Duration(seconds: 5);
  bool _isHotGamesTimerActive = false; // 标记计时器是否应该运行

  // --- 缓存监听 ---
  StreamSubscription? _hotGamesWatchSub;
  StreamSubscription? _latestGamesWatchSub;
  StreamSubscription? _hotPostsWatchSub;
  static const Duration _cacheDebounceDuration = Duration(milliseconds: 1000);

  bool _hasInitializedDependencies = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hotGamesPageController = PageController(); // 初始化 PageController
    // 初始加载由 VisibilityDetector 触发
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != widget.authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeFromCacheChanges();
    _hotGamesPageController.dispose();
    _stopHotGamesAutoScrollTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      if (widget.authProvider.currentUserId != _currentUserId) {
        if (mounted) {
          setState(() {
            _currentUserId = widget.authProvider.currentUserId;
          });
        }
      }
      // App 恢复到前台
      _subscribeToCacheChanges();
      if (_isVisible) {
        // 确保页面当前也可见
        _startHotGamesAutoScrollTimer(); // 尝试启动轮播
        if (!_isOverallInitialized) {
          _triggerInitialLoad(); // 如果还未初始化，则加载
        } else {
          // 如果已经初始化过，检查是否需要刷新（例如从后台回来超过一定时间）
          _attemptRefreshAllDataConditionally(checkInterval: true);
        }
      }
    } else if (state == AppLifecycleState.paused) {
      // App 进入后台
      _unsubscribeFromCacheChanges();
      _stopHotGamesAutoScrollTimer(); // 暂停轮播
    }
  }

  void _handleVisibilityChange(VisibilityInfo visibilityInfo) {
    if (!mounted) return;
    final bool wasVisible = _isVisible;
    final bool currentlyVisible = visibilityInfo.visibleFraction > 0.1;

    if (widget.authProvider.currentUserId != _currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }

    if (currentlyVisible != wasVisible) {
      setState(() {
        _isVisible = currentlyVisible;
      });

      if (_isVisible) {
        // ---- 页面变为可见 ----
        _subscribeToCacheChanges();
        _startHotGamesAutoScrollTimer(); // 启动轮播

        if (!_isOverallInitialized) {
          _triggerInitialLoad();
        } else {
          // 页面从不可见到可见，可以考虑刷新，特别是如果上次刷新很久了
          _attemptRefreshAllDataConditionally(checkInterval: true);
        }
      } else {
        // ---- 页面变为不可见 ----
        _unsubscribeFromCacheChanges();
        _stopHotGamesAutoScrollTimer(); // 停止轮播
      }
    }
  }

  void _triggerInitialLoad() {
    if (!_isOverallInitialized && mounted) {
      _loadAllData(isInitialLoad: true);
    }
  }

  // --- 数据获取核心逻辑 ---
  Future<void> _loadAllData(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    if (!mounted) return;

    // 如果是刷新，且正在刷新中，则返回
    if (isRefresh && _isPerformingHomeScreenRefresh) return;
    // 如果是刷新，检查时间间隔
    if (isRefresh) {
      final now = DateTime.now();
      if (_lastHomeScreenRefreshAttemptTime != null &&
          now.difference(_lastHomeScreenRefreshAttemptTime!) <
              _minHomeScreenRefreshInterval) {
        final remainingSeconds = (_minHomeScreenRefreshInterval.inSeconds -
            now.difference(_lastHomeScreenRefreshAttemptTime!).inSeconds);
        if (mounted) {
          AppSnackBar.showInfo(
            context,
            '刷新太频繁啦，请 $remainingSeconds 秒后再试',
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }
      _isPerformingHomeScreenRefresh = true;
      _lastHomeScreenRefreshAttemptTime = now;
    }

    // 标记开始加载
    setState(() {
      if (isInitialLoad) {
        _isHotGamesLoading = true;
        _isLatestGamesLoading = true;
        _isHotPostsLoading = true;
        _overallErrorMessage = null; // 清除整体错误
      } else if (isRefresh) {
        // 下拉刷新时，也显示加载状态
        _isHotGamesLoading = true;
        _isLatestGamesLoading = true;
        _isHotPostsLoading = true;
      }
      // 对于缓存驱动的单个板块刷新，其 loading 状态在 _fetchSpecificData 中处理
    });

    try {
      // 并行获取所有数据
      await Future.wait([
        _fetchSpecificData(HomeDataType.hotGames,
            isTriggeredByRefresh: isRefresh || isInitialLoad),
        _fetchSpecificData(HomeDataType.latestGames,
            isTriggeredByRefresh: isRefresh || isInitialLoad),
        _fetchSpecificData(HomeDataType.hotPosts,
            isTriggeredByRefresh: isRefresh || isInitialLoad),
      ]);

      if (mounted) {
        setState(() {
          if (isInitialLoad) {
            _isOverallInitialized = true; // 标记整体初始化完成
          }
          // 如果所有数据加载都成功（没有error），可以清除整体错误
          if (_hotGamesError == null &&
              _latestGamesError == null &&
              _hotPostsError == null) {
            _overallErrorMessage = null;
          }
        });
        // 初始加载或刷新成功后，重置并启动轮播
        if (isInitialLoad || isRefresh) {
          _resetAndStartHotGamesAutoScroll();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isInitialLoad) {
            _overallErrorMessage = "页面数据加载失败，请稍后重试。";
          }
          // 具体的子模块错误在 _fetchSpecificData 中设置
        });
      }
    } finally {
      if (mounted && isRefresh) {
        setState(() {
          _isPerformingHomeScreenRefresh = false;
        });
      }
      // loading状态在 _fetchSpecificData 的 finally 中处理
    }
  }

  Future<void> _fetchSpecificData(HomeDataType type,
      {bool isTriggeredByCache = false,
      bool isTriggeredByRefresh = false}) async {
    if (!mounted) return;

    // 设置对应板块的加载状态
    setState(() {
      switch (type) {
        case HomeDataType.hotGames:
          _isHotGamesLoading = true;
          _hotGamesError = null;
          break;
        case HomeDataType.latestGames:
          _isLatestGamesLoading = true;
          _latestGamesError = null;
          break;
        case HomeDataType.hotPosts:
          _isHotPostsLoading = true;
          _hotPostsError = null;
          break;
      }
    });

    try {
      dynamic data;
      switch (type) {
        case HomeDataType.hotGames:
          data = await widget.gameService.getHotGames();
          if (mounted) {
            setState(() {
              _hotGamesData = data;
              if (isTriggeredByRefresh || isTriggeredByCache) {
                // 如果是刷新或缓存更新，重置轮播
                _resetAndStartHotGamesAutoScroll();
              }
            });
          }
          break;
        case HomeDataType.latestGames:
          data = await widget.gameService.getLatestGames();
          if (mounted) setState(() => _latestGamesData = data);
          break;
        case HomeDataType.hotPosts:
          data = await widget.postService.getHotPosts();
          if (mounted) setState(() => _hotPostsData = data);
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorMsg = '加载失败: $e';
          switch (type) {
            case HomeDataType.hotGames:
              _hotGamesError = errorMsg;
              _hotGamesData = null; // 出错时清空旧数据
              break;
            case HomeDataType.latestGames:
              _latestGamesError = errorMsg;
              _latestGamesData = null;
              break;
            case HomeDataType.hotPosts:
              _hotPostsError = errorMsg;
              _hotPostsData = null;
              break;
          }
        });
      }
      // if (kDebugMode) print("Error fetching ${type.name} data: $e");
    } finally {
      if (mounted) {
        setState(() {
          switch (type) {
            case HomeDataType.hotGames:
              _isHotGamesLoading = false;
              break;
            case HomeDataType.latestGames:
              _isLatestGamesLoading = false;
              break;
            case HomeDataType.hotPosts:
              _isHotPostsLoading = false;
              break;
          }
        });
      }
    }
  }

  // 下拉刷新调用
  Future<void> _handlePullToRefresh() async {
    await _loadAllData(isRefresh: true);
  }

  // 尝试有条件地刷新所有数据（例如，从后台返回时）
  void _attemptRefreshAllDataConditionally({bool checkInterval = false}) {
    if (checkInterval) {
      final now = DateTime.now();
      // 如果距离上次刷新成功的时间在最小间隔内，则不主动刷新
      if (_lastHomeScreenRefreshAttemptTime != null &&
          now.difference(_lastHomeScreenRefreshAttemptTime!) <
              _minHomeScreenRefreshInterval) {
        // 可选：如果需要，这里可以只刷新缓存认为“脏”的数据，而不是全部
        // debugPrint("HomeScreen: Conditional refresh skipped due to interval.");
        return;
      }
    }
    // 否则，执行一次类似下拉刷新的全量数据获取，但不显示“刷新太频繁”的提示
    // _loadAllData(isRefresh: true) 会自己处理节流，但这里我们希望绕过那个节流提示，直接尝试刷新
    if (!_isPerformingHomeScreenRefresh) {
      // 避免和用户触发的下拉刷新冲突
      _isPerformingHomeScreenRefresh = true; // 标记开始
      _lastHomeScreenRefreshAttemptTime = DateTime.now(); // 更新时间戳

      _fetchSpecificData(HomeDataType.hotGames, isTriggeredByRefresh: true);
      _fetchSpecificData(HomeDataType.latestGames, isTriggeredByRefresh: true);
      _fetchSpecificData(HomeDataType.hotPosts, isTriggeredByRefresh: true)
          .whenComplete(() {
        if (mounted) {
          setState(() {
            _isPerformingHomeScreenRefresh = false; // 标记结束
          });
        } else {
          _isPerformingHomeScreenRefresh = false;
        }
      });
    }
  }

  // --- 缓存变化处理 ---
  void _subscribeToCacheChanges() {
    _unsubscribeFromCacheChanges();
    try {
      _hotGamesWatchSub = widget.gameService.hotGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.hotGames, event));
      _latestGamesWatchSub = widget.gameService.latestGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen(
              (event) => _handleCacheChange(HomeDataType.latestGames, event));
      _hotPostsWatchSub = widget.postService.hotPostsCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(HomeDataType.hotPosts, event));
    } catch (e) {
      //if (kDebugMode) print("Error subscribing to cache changes: $e");
    }
  }

  void _unsubscribeFromCacheChanges() {
    _hotGamesWatchSub?.cancel();
    _hotGamesWatchSub = null;
    _latestGamesWatchSub?.cancel();
    _latestGamesWatchSub = null;
    _hotPostsWatchSub?.cancel();
    _hotPostsWatchSub = null;
  }

  void _handleCacheChange(HomeDataType type, BoxEvent event) {
    if (!mounted || !_isVisible) return; // 如果页面不可见，不处理缓存变化导致的数据刷新

    // 缓存变化时，重新获取对应板块的数据，并更新Key以防子组件有依赖Key的内部状态
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
    _fetchSpecificData(type, isTriggeredByCache: true);
  }

  void _startHotGamesAutoScrollTimer() {
    // 检查核心条件：页面可见、有数据、超过1页、且计时器当前未激活
    if (!mounted ||
        !_isVisible ||
        _isHotGamesTimerActive ||
        _hotGamesData == null ||
        _hotGamesData!.isEmpty) {
      return;
    }

    final int totalPages = HomeHotGames.getTotalPages(
        HomeHotGames.getCardsPerPage(context), // 确保 context 可用
        _hotGamesData);

    if (totalPages <= 1) {
      _stopHotGamesAutoScrollTimer(); // 如果只有一页或没有数据，确保计时器是停止的
      return;
    }

    // 如果条件都满足，才真正启动计时器
    _isHotGamesTimerActive = true; // 先标记为 active
    _hotGamesScrollTimer?.cancel(); // 先取消已有的，以防万一

    //if (kDebugMode) print("HotGames auto-scroll timer: Attempting to start...");

    _hotGamesScrollTimer = Timer.periodic(_hotGamesAutoscrollDuration, (timer) {
      // Timer 回调内部的核心检查：
      // 1. 组件是否还 mounted
      // 2. 页面是否仍然应该滚动 (_isHotGamesTimerActive 这个标志位很重要)
      // 3. PageController 是否可用 (hasClients)
      if (!mounted ||
          !_isHotGamesTimerActive ||
          !_hotGamesPageController.hasClients) {
        // 如果这些核心条件之一不满足，通常意味着应该停止（可能是 dispose, 或外部指令）
        // 但要小心这里的 _stopHotGamesAutoScrollTimer 调用，避免无限循环停止
        // _stopHotGamesAutoScrollTimer(); // 这行暂时注释掉，因为外部会有更宏观的控制
        return;
      }

      // 重新获取当前实际的 cards per page 和 total pages，因为屏幕尺寸可能变化（虽然不常见）
      final int currentCardsPerPage = HomeHotGames.getCardsPerPage(context);
      final int currentActualTotalPages =
          HomeHotGames.getTotalPages(currentCardsPerPage, _hotGamesData);

      if (currentActualTotalPages <= 1) {
        // 如果在滚动过程中数据变少到只有一页，则停止
        _stopHotGamesAutoScrollTimer();
        return;
      }

      // 获取当前 PageController 报告的页面，并四舍五入
      // 注意：controller.page 在动画过程中是 double
      int currentPageFromController =
          (_hotGamesPageController.page ?? 0.0).round();
      int nextPage = currentPageFromController + 1;

      if (nextPage >= currentActualTotalPages) {
        nextPage = 0; // 回到第一页
      }

      // 执行动画，这里不需要再检查 hasClients，因为前面已经检查过了
      _hotGamesPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800), // 动画时间
        curve: Curves.easeInOut,
      );
      // 注意：animateToPage 会触发 onPageChanged，但我们下面会处理这个
    });
    //if (kDebugMode) print("HotGames auto-scroll timer: STARTED with duration ${_hotGamesAutoscrollDuration.inSeconds}s.");
  }

  void _stopHotGamesAutoScrollTimer() {
    if (_hotGamesScrollTimer != null && _hotGamesScrollTimer!.isActive) {
      _hotGamesScrollTimer!.cancel();
      //if (kDebugMode) print("HotGames auto-scroll timer: CANCELLED.");
    }
    _hotGamesScrollTimer = null; // 置空
    // 只有当计时器确实被停止时，才更新 _isHotGamesTimerActive 状态
    // 防止在不应该停止的时候错误地将 _isHotGamesTimerActive 置为 false
    if (_isHotGamesTimerActive) {
      _isHotGamesTimerActive = false;
      //if (kDebugMode) print("HotGames auto-scroll timer: Marked as INACTIVE.");
    }
  }

  // 标记用户是否正在拖拽，用于区分 onPageChanged 的触发源
  bool _isUserInteractingWithHotGamesPager = false;

  void _onHotGamesPageChanged(int page) {
    if (!mounted) return;

    // 更新内部追踪的当前页码
    // 这个 setState 是必要的，因为 HomeHotGames 组件的 currentPage prop 依赖它
    setState(() {
      _currentHotGamesPage = page;
    });

    // 如果是用户手动滑动导致的页面变化，则重置并重启计时器
    // 如果是自动滚动，则不应在这里重置，否则会打断下一次自动滚动计划
    if (_isUserInteractingWithHotGamesPager) {
      _resetAndStartHotGamesAutoScroll(); // 用户交互后重置计时器
    } else {
      // 自动滚动时，不需要在这里重置计时器，Timer 会继续工作
      // 也不需要在这里手动启动，因为Timer的下一个tick会自动处理
    }
  }

  // _resetAndStartHotGamesAutoScroll 应该更纯粹地负责重置和启动逻辑
  // 它被用户交互、数据变化、可见性变化等多种情况调用
  void _resetAndStartHotGamesAutoScroll() {
    if (!mounted) return;
    _stopHotGamesAutoScrollTimer(); // 总是先停止当前的，无论是什么原因调用

    // 只有在页面可见、有数据、且数据多于一页时才尝试启动
    if (_isVisible && _hotGamesData != null && _hotGamesData!.isNotEmpty) {
      final int totalPages = HomeHotGames.getTotalPages(
          HomeHotGames.getCardsPerPage(context), _hotGamesData);
      if (totalPages > 1) {
        _startHotGamesAutoScrollTimer(); // 重新启动
      } else {
        //if (kDebugMode) print("HotGames reset: Not starting timer, total pages <= 1.");
      }
    } else {
      //if (kDebugMode) print("HotGames reset: Not starting timer, conditions not met (visible: $_isVisible, data: ${(_hotGamesData != null && _hotGamesData!.isNotEmpty)}).");
    }
  }

  // --- 构建UI ---
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('home_screen_visibility'),
      onVisibilityChanged: _handleVisibilityChange,
      child: _buildScaffoldContent(),
    );
  }

  Widget _buildScaffoldContent() {
    // 首次加载时的整体骨架屏或loading
    if (!_isOverallInitialized &&
        (_isHotGamesLoading || _isLatestGamesLoading || _isHotPostsLoading)) {
      return Scaffold(
        body: LoadingWidget.fullScreen(message: "少女祈祷中..."),
      );
    }

    // 整体加载错误
    if (_overallErrorMessage != null && !_isOverallInitialized) {
      return Scaffold(
        body: CustomErrorWidget(
          errorMessage: _overallErrorMessage!,
          onRetry: () => _loadAllData(isInitialLoad: true), // 重试整个页面的初始加载
        ),
      );
    }

    // 正常UI
    const Duration initialDelay = Duration(milliseconds: 150);
    const Duration stagger = Duration(milliseconds: 100);
    int sectionIndex = 0;

    // 这个 flag 决定当前 build 周期是否应该播放入口动画
    bool playAnimationsThisBuildCycle = false;
    if (_isOverallInitialized && !_hasPlayedEntryAnimation) {
      playAnimationsThisBuildCycle = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 此处不需要 setState，因为这个状态的改变是为了影响 *未来* 的 build 行为。
          _hasPlayedEntryAnimation = true;
        }
      });
    }
    // 使用这个一次性的动画触发标志
    final bool currentPlaySectionEntryAnimation = playAnimationsThisBuildCycle;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handlePullToRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 确保内容不足一屏也能下拉
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HomeBanner (保持不变，假设它自己管理或无复杂状态) ---
              FadeInSlideUpItemCanPlay(
                  play: currentPlaySectionEntryAnimation, // 确保动画只在首次加载后播放
                  delay: initialDelay,
                  child: const HomeBanner()),
              const SizedBox(height: 16),

              // --- HomeHotGames ---
              FadeInSlideUpItemCanPlay(
                play: currentPlaySectionEntryAnimation,
                delay: initialDelay + stagger * sectionIndex++,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: HomeHotGames(
                    key: ValueKey(
                        'hot_games_$_hotGamesKeyCounter'), // Key用于缓存变化时重建UI
                    games: _hotGamesData,
                    isLoading: _isHotGamesLoading,
                    errorMessage: _hotGamesError,
                    onRetry: () => _fetchSpecificData(HomeDataType.hotGames,
                        isTriggeredByRefresh: true),
                    pageController: _hotGamesPageController,
                    currentPage: _currentHotGamesPage,
                    onPageChanged: _onHotGamesPageChanged,
                    playInitialAnimation:
                        currentPlaySectionEntryAnimation && // 确保是首次动画
                            _hotGamesData != null &&
                            _hotGamesData!.isNotEmpty, // 且有数据
                    onUserInteraction: (isInteracting) {
                      // 实现回调
                      if (!mounted) return;
                      // 这里直接修改 _isUserInteractingWithHotGamesPager 状态
                      // 不需要 setState 因为这个状态主要用于 _onHotGamesPageChanged 的逻辑判断
                      // 而 _onHotGamesPageChanged 内部会 setState 更新 _currentHotGamesPage
                      // 从而触发UI重建（如果需要）
                      _isUserInteractingWithHotGamesPager = isInteracting;
                      if (isInteracting) {
                        // 用户开始交互时，可以主动停止一下计时器，确保平滑
                        _stopHotGamesAutoScrollTimer();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Latest Games 和 Hot Posts (响应式布局) ---
              FadeInSlideUpItemCanPlay(
                play: currentPlaySectionEntryAnimation, // 使用修正后的标志
                delay: initialDelay + stagger * sectionIndex++,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildPostsAndGamesSection(context,
                      currentPlaySectionEntryAnimation), // playAnimations 参数也使用修正后的标志
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsAndGamesSection(BuildContext context, bool playAnimations) {
    final bool isLarge = DeviceUtils.isLargeScreen(context);

    final Widget hotPostsWidget = HomeHotPosts(
      key: ValueKey('hot_posts_$_hotPostsKeyCounter'),
      currentUser: widget.authProvider.currentUser,
      followService: widget.followService,
      infoProvider: widget.infoProvider,
      posts: _hotPostsData,
      isLoading: _isHotPostsLoading,
      errorMessage: _hotPostsError,
      onRetry: () =>
          _fetchSpecificData(HomeDataType.hotPosts, isTriggeredByRefresh: true),
    );

    final Widget latestGamesWidget = HomeLatestGames(
      key: ValueKey('latest_games_$_latestGamesKeyCounter'),
      games: _latestGamesData,
      isLoading: _isLatestGamesLoading,
      errorMessage: _latestGamesError,
      onRetry: () => _fetchSpecificData(HomeDataType.latestGames,
          isTriggeredByRefresh: true),
    );

    if (isLarge) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: hotPostsWidget),
          const SizedBox(width: 16.0),
          Expanded(child: latestGamesWidget),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hotPostsWidget,
          const SizedBox(height: 16.0),
          latestGamesWidget,
        ],
      );
    }
  }
}
