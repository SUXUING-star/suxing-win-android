// lib/screens/home/home_screen.dart

/// 该文件定义了 HomeScreen 组件，作为应用的主页显示各类热门和最新内容。
/// HomeScreen 负责加载和展示热门游戏、最新游戏和热门帖子，并支持刷新和自动轮播。
library;

import 'dart:async'; // 导入异步操作所需，如 Timer
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:hive/hive.dart'; // 导入 Hive 数据库，用于监听缓存事件
import 'package:rxdart/rxdart.dart'; // 导入 RxDart，用于流的 debounceTime
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/models/game/game.dart'; // 导入游戏模型
import 'package:suxingchahui/models/post/post.dart'; // 导入帖子模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart'; // 导入帖子服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/widgets/components/screen/home/section/home_hot_posts.dart'; // 导入热门帖子组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_can_play.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 导入应用 SnackBar 工具
import 'package:visibility_detector/visibility_detector.dart'; // 导入可见性检测器
import 'package:suxingchahui/widgets/components/screen/home/section/home_hot_games.dart'; // 导入热门游戏组件
import 'package:suxingchahui/widgets/components/screen/home/section/home_latest_games.dart'; // 导入最新游戏组件
import 'package:suxingchahui/widgets/components/screen/home/section/home_banner.dart'; // 导入首页 Banner 组件
import 'package:suxingchahui/services/main/game/game_service.dart'; // 导入游戏服务
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件

/// `HomeScreen` 类：应用主页屏幕组件。
///
/// 该屏幕负责加载、展示热门游戏、最新游戏和热门帖子数据，
/// 支持刷新和热门游戏的自动轮播。
class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final GameService gameService; // 游戏服务
  final PostService postService; // 帖子服务
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息 Provider

  final WindowStateProvider windowStateProvider;

  /// 构造函数。
  ///
  /// [authProvider]：认证 Provider。
  /// [gameService]：游戏服务。
  /// [postService]：帖子服务。
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  const HomeScreen({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.postService,
    required this.followService,
    required this.infoService,
    required this.windowStateProvider,
  });

  /// 创建状态。
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

/// `HomeDataType` 枚举：表示主页不同数据类型。
enum HomeDataType {
  hotGames, // 热门游戏
  latestGames, // 最新游戏
  hotPosts, // 热门帖子
}

/// `_HomeScreenState` 类：`HomeScreen` 的状态管理。
///
/// 管理数据加载、刷新、可见性、缓存监听、自动轮播和 UI 状态。
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isOverallInitialized = false; // 整体页面是否已首次加载标记
  bool _isVisible = false; // 页面是否可见标记
  String? _overallErrorMessage; // 整体页面框架的错误消息

  bool _hasPlayedEntryAnimation = false; // 用于首次进入动画的控制标记

  bool _isPerformingHomeScreenRefresh = false; // 正在执行主页刷新操作标记
  DateTime? _lastHomeScreenRefreshAttemptTime; // 上次尝试主页刷新的时间
  static const Duration _minHomeScreenRefreshInterval =
      Duration(seconds: 60); // 最小刷新间隔

  int _hotGamesKeyCounter = 0; // 热门游戏 Key 计数器
  int _latestGamesKeyCounter = 0; // 最新游戏 Key 计数器
  int _hotPostsKeyCounter = 0; // 热门帖子 Key 计数器

  List<Game>? _hotGamesData; // 热门游戏数据列表
  bool _isHotGamesLoading = false; // 热门游戏是否正在加载中
  String? _hotGamesError; // 热门游戏错误消息
  DateTime? _lastHotGamesLoadingSetTime;
  static const Duration _maxSectionLoadingDuration = Duration(seconds: 10);

  List<Game>? _latestGamesData; // 最新游戏数据列表
  bool _isLatestGamesLoading = false; // 最新游戏是否正在加载中
  String? _latestGamesError; // 最新游戏错误消息
  DateTime? _lastLatestGamesLoadingSetTime;

  List<Post>? _hotPostsData; // 热门帖子数据列表
  bool _isHotPostsLoading = false; // 热门帖子是否正在加载中
  String? _hotPostsError; // 热门帖子错误消息
  DateTime? _lastHotPostsLoadingSetTime;

  PageController _hotGamesPageController = PageController(); // 热门游戏轮播控制器
  Timer? _hotGamesScrollTimer; // 热门游戏自动滚动计时器
  int _currentHotGamesPage = 0; // 当前热门游戏轮播页码
  static const Duration _hotGamesAutoscrollDuration =
      Duration(seconds: 5); // 热门游戏自动滚动间隔
  bool _isHotGamesTimerActive = false; // 热门游戏计时器是否活跃

  StreamSubscription? _hotGamesWatchSub; // 热门游戏缓存监听订阅
  StreamSubscription? _latestGamesWatchSub; // 最新游戏缓存监听订阅
  StreamSubscription? _hotPostsWatchSub; // 热门帖子缓存监听订阅
  static const Duration _cacheDebounceDuration = Duration(seconds: 2); // 缓存防抖时长

  bool _hasInitializedDependencies = false; // 依赖是否已初始化标记
  String? _currentUserId; // 当前用户ID

  late double _screenWidth;

  late String _bannerImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加应用生命周期观察者
    _hotGamesPageController = PageController(); // 初始化 PageController
    _bannerImage = GlobalConstants.bannerImageFirst;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      // 依赖未初始化时
      _hasInitializedDependencies = true; // 标记为已初始化
    }
    if (_hasInitializedDependencies) {
      _screenWidth = DeviceUtils.getScreenWidth(context);
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户ID
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != widget.authProvider.currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除应用生命周期观察者
    _unsubscribeFromCacheChanges(); // 取消缓存监听
    _hotGamesPageController.dispose(); // 销毁 PageController
    _stopHotGamesAutoScrollTimer(); // 停止自动轮播计时器
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return; // 组件未挂载时返回

    _checkLoadingTimeout();

    if (state == AppLifecycleState.resumed) {
      setState(() {
        _screenWidth = DeviceUtils.getScreenWidth(context);
      });
      // 应用从后台恢复时
      _checkAuthStateChange();
      _subscribeToCacheChanges(); // 订阅缓存变化
      if (_isVisible) {
        // 页面当前可见时
        _startHotGamesAutoScrollTimer(); // 启动轮播
        if (!_isOverallInitialized) {
          // 未初始化时触发初始加载
          _triggerInitialLoad();
        } else {
          // 已初始化时尝试有条件刷新所有数据
          _attemptRefreshAllDataConditionally(checkInterval: true);
        }
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时
      _unsubscribeFromCacheChanges(); // 取消缓存监听
      _stopHotGamesAutoScrollTimer(); // 停止轮播
    }
  }

  ///
  ///
  void _checkAuthStateChange() {
    if (!mounted) return;
    if (widget.authProvider.currentUserId != _currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
  }

  ///
  ///
  void _checkLoadingTimeout() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastHotGamesLoadingSetTime != null &&
        _isHotGamesLoading &&
        now.difference(_lastHotGamesLoadingSetTime!) >
            _maxSectionLoadingDuration) {
      if (mounted) {
        setState(() {
          _isHotGamesLoading = false;
          _lastHotGamesLoadingSetTime = null;
        });
      }
    }
    // 检查 _isLatestGamesLoading 超时
    if (_lastLatestGamesLoadingSetTime != null &&
        _isLatestGamesLoading &&
        now.difference(_lastLatestGamesLoadingSetTime!) >
            _maxSectionLoadingDuration) {
      if (mounted) {
        setState(() {
          _isLatestGamesLoading = false;
          _lastLatestGamesLoadingSetTime = null;
        });
      }
    }
    // 检查 _isHotPostsLoading 超时
    if (_lastHotPostsLoadingSetTime != null &&
        _isHotPostsLoading &&
        now.difference(_lastHotPostsLoadingSetTime!) >
            _maxSectionLoadingDuration) {
      if (mounted) {
        setState(() {
          _isHotPostsLoading = false;
          _lastHotPostsLoadingSetTime = null;
        });
      }
    }
  }

  /// 处理可见性变化。
  ///
  /// [visibilityInfo]：可见性信息。
  void _handleVisibilityChange(VisibilityInfo visibilityInfo) {
    if (!mounted) return; // 组件未挂载时返回
    final bool wasVisible = _isVisible; // 记录旧的可见性状态
    final bool currentlyVisible =
        visibilityInfo.visibleFraction > 0.1; // 判断当前可见性

    _checkLoadingTimeout();
    _checkAuthStateChange();

    if (currentlyVisible != wasVisible) {
      // 可见性状态变化时
      setState(() {
        _isVisible = currentlyVisible; // 更新可见性状态
      });

      if (_isVisible) {
        // 页面变为可见时
        _subscribeToCacheChanges(); // 订阅缓存变化
        _startHotGamesAutoScrollTimer(); // 启动轮播

        if (!_isOverallInitialized) {
          // 未初始化时触发初始加载
          _triggerInitialLoad();
        } else {
          // 已初始化时尝试有条件刷新所有数据
          _attemptRefreshAllDataConditionally(checkInterval: true);
        }
      } else {
        // 页面变为不可见时
        _unsubscribeFromCacheChanges(); // 取消缓存监听
        _stopHotGamesAutoScrollTimer(); // 停止轮播
      }
    }
  }

  /// 触发初始加载。
  ///
  /// 仅在整体未初始化时加载所有必要数据。
  void _triggerInitialLoad() {
    if (!_isOverallInitialized && mounted) {
      // 整体未初始化且组件挂载时
      _loadAllData(isInitialLoad: true); // 加载所有数据
    }
  }

  /// 获取所有数据。
  ///
  /// [isInitialLoad]：是否为初始加载。
  /// [isRefresh]：是否为刷新。
  Future<void> _loadAllData(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    if (!mounted) return; // 组件未挂载时返回

    if (isRefresh && _isPerformingHomeScreenRefresh) return; // 刷新中时返回

    if (isRefresh) {
      // 如果是刷新操作
      final now = DateTime.now();
      if (_lastHomeScreenRefreshAttemptTime != null &&
          now.difference(_lastHomeScreenRefreshAttemptTime!) <
              _minHomeScreenRefreshInterval) {
        // 刷新间隔不足时
        final remainingSeconds = (_minHomeScreenRefreshInterval.inSeconds -
            now.difference(_lastHomeScreenRefreshAttemptTime!).inSeconds);
        if (mounted) {
          AppSnackBar.showWarning(
            '刷新太频繁啦，请 $remainingSeconds 秒后再试',
            duration: const Duration(seconds: 2),
          );
        }
        return; // 返回
      }
      _isPerformingHomeScreenRefresh = true; // 标记正在刷新
      _lastHomeScreenRefreshAttemptTime = now; // 记录刷新时间
    }

    setState(() {
      // 设置加载状态
      if (isInitialLoad) {
        _isHotGamesLoading = true;
        _isLatestGamesLoading = true;
        _isHotPostsLoading = true;
        _overallErrorMessage = null;
      } else if (isRefresh) {
        _isHotGamesLoading = true;
        _isLatestGamesLoading = true;
        _isHotPostsLoading = true;
      }
    });

    try {
      await Future.wait([
        // 并行获取所有数据
        _fetchSpecificData(HomeDataType.hotGames,
            isTriggeredByRefresh: isRefresh || isInitialLoad),
        _fetchSpecificData(HomeDataType.latestGames,
            isTriggeredByRefresh: isRefresh || isInitialLoad),
        _fetchSpecificData(HomeDataType.hotPosts,
            isTriggeredByRefresh: isRefresh || isInitialLoad),
      ]);

      if (mounted) {
        // 组件挂载时
        setState(() {
          if (isInitialLoad) {
            _isOverallInitialized = true; // 标记整体初始化完成
          }
          if (_hotGamesError == null &&
              _latestGamesError == null &&
              _hotPostsError == null) {
            _overallErrorMessage = null; // 清除整体错误
          }
        });
        if (isInitialLoad || isRefresh) {
          // 初始加载或刷新成功后重置并启动轮播
          _resetAndStartHotGamesAutoScroll();
        }
      }
    } catch (e) {
      if (mounted) {
        // 捕获错误时
        setState(() {
          if (isInitialLoad) {
            _overallErrorMessage = "页面数据加载失败，请稍后重试。"; // 设置整体错误消息
          }
        });
      }
    } finally {
      if (mounted && isRefresh) {
        // 刷新结束后重置刷新标记
        setState(() {
          _isPerformingHomeScreenRefresh = false;
        });
      }
    }
  }

  /// 获取特定类型的数据。
  ///
  /// [type]：数据类型。
  /// [isTriggeredByCache]：是否因缓存触发。
  /// [isTriggeredByRefresh]：是否因刷新触发。
  Future<void> _fetchSpecificData(
    HomeDataType type, {
    bool isTriggeredByCache = false,
    bool isTriggeredByRefresh = false,
    bool forceRefresh = false,
  }) async {
    if (!mounted) return; // 组件未挂载时返回

    setState(() {
      // 设置对应板块的加载状态
      switch (type) {
        case HomeDataType.hotGames:
          if (_lastHotGamesLoadingSetTime != null) {
            _lastHotGamesLoadingSetTime = null;
          }
          if (_isHotGamesLoading) return;
          break;
        case HomeDataType.latestGames:
          if (_lastLatestGamesLoadingSetTime != null) {
            _lastLatestGamesLoadingSetTime = null;
          }
          if (_isLatestGamesLoading) return;
          break;
        case HomeDataType.hotPosts:
          if (_lastHotPostsLoadingSetTime != null) {
            _lastHotPostsLoadingSetTime = null;
          }
          if (_isHotPostsLoading) return;
          break;
      }
    });

    final now = DateTime.now();
    setState(() {
      // 设置对应板块的加载状态
      switch (type) {
        case HomeDataType.hotGames:
          _isHotGamesLoading = true;
          _lastHotGamesLoadingSetTime = now;
          _hotGamesError = null;
          break;
        case HomeDataType.latestGames:
          _isLatestGamesLoading = true;
          _lastLatestGamesLoadingSetTime = now;
          _latestGamesError = null;
          break;
        case HomeDataType.hotPosts:
          _isHotPostsLoading = true;
          _hotPostsError = null;
          _lastHotGamesLoadingSetTime = now;
          break;
      }
    });

    try {
      dynamic data;
      switch (type) {
        case HomeDataType.hotGames:
          data = await widget.gameService
              .getHotGames(forceRefresh: forceRefresh); // 获取热门游戏
          if (mounted) {
            setState(() {
              _hotGamesData = data; // 更新热门游戏数据
              if (isTriggeredByRefresh || isTriggeredByCache) {
                _resetAndStartHotGamesAutoScroll(); // 重置并启动轮播
              }
            });
          }
          break;
        case HomeDataType.latestGames:
          data = await widget.gameService
              .getLatestGames(forceRefresh: forceRefresh); // 获取最新游戏
          if (mounted) setState(() => _latestGamesData = data); // 更新最新游戏数据
          break;
        case HomeDataType.hotPosts:
          data = await widget.postService
              .getHotPosts(forceRefresh: forceRefresh); // 获取热门帖子
          if (mounted) setState(() => _hotPostsData = data); // 更新热门帖子数据
          break;
      }
    } catch (e) {
      if (mounted) {
        // 捕获错误时
        setState(() {
          final errorMsg = '加载失败: $e'; // 错误消息
          switch (type) {
            case HomeDataType.hotGames:
              _hotGamesError = errorMsg; // 设置错误消息
              _hotGamesData = null; // 清空旧数据
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
    } finally {
      if (mounted) {
        // 组件挂载时重置加载状态
        setState(() {
          switch (type) {
            case HomeDataType.hotGames:
              _isHotGamesLoading = false;
              _lastHotGamesLoadingSetTime = null;
              break;
            case HomeDataType.latestGames:
              _isLatestGamesLoading = false;
              _lastLatestGamesLoadingSetTime = null;
              break;
            case HomeDataType.hotPosts:
              _isHotPostsLoading = false;
              _lastHotPostsLoadingSetTime = null;
              break;
          }
        });
      }
    }
  }

  /// 处理下拉刷新。
  Future<void> _handlePullToRefresh() async {
    await _loadAllData(isRefresh: true); // 加载所有数据并标记为刷新
  }

  /// 尝试有条件地刷新所有数据。
  ///
  /// [checkInterval]：是否检查刷新时间间隔。
  void _attemptRefreshAllDataConditionally({bool checkInterval = false}) {
    if (checkInterval) {
      // 检查刷新时间间隔时
      final now = DateTime.now();
      if (_lastHomeScreenRefreshAttemptTime != null &&
          now.difference(_lastHomeScreenRefreshAttemptTime!) <
              _minHomeScreenRefreshInterval) {
        // 时间间隔不足时返回
        return;
      }
    }
    if (_isPerformingHomeScreenRefresh) return;

    if (!_isPerformingHomeScreenRefresh) {
      // 未在刷新中时
      setState(() {
        _isPerformingHomeScreenRefresh = true; // 标记开始刷新
        _lastHomeScreenRefreshAttemptTime = DateTime.now(); // 更新时间戳
      });

      _fetchSpecificData(HomeDataType.hotGames,
          isTriggeredByRefresh: true); // 获取热门游戏
      _fetchSpecificData(HomeDataType.latestGames,
          isTriggeredByRefresh: true); // 获取最新游戏
      _fetchSpecificData(HomeDataType.hotPosts,
              isTriggeredByRefresh: true) // 获取热门帖子
          .whenComplete(() {
        if (mounted) {
          // 组件挂载时
          setState(() {
            _isPerformingHomeScreenRefresh = false; // 标记刷新结束
          });
        } else {
          _isPerformingHomeScreenRefresh = false;
        }
      });
    }
  }

  /// 订阅缓存变化。
  void _subscribeToCacheChanges() {
    _unsubscribeFromCacheChanges(); // 先取消旧订阅
    try {
      _hotGamesWatchSub = widget.gameService.hotGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(
                HomeDataType.hotGames,
                event,
              )); // 监听热门游戏缓存变化
      _latestGamesWatchSub = widget.gameService.latestGamesCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(
                HomeDataType.latestGames,
                event,
              )); // 监听最新游戏缓存变化
      _hotPostsWatchSub = widget.postService.hotPostsCacheChangeNotifier
          .debounceTime(_cacheDebounceDuration)
          .listen((event) => _handleCacheChange(
                HomeDataType.hotPosts,
                event,
              )); // 监听热门帖子缓存变化
    } catch (e) {
      // 订阅缓存变化发生错误
    }
  }

  /// 取消缓存变化订阅。
  void _unsubscribeFromCacheChanges() {
    _hotGamesWatchSub?.cancel(); // 取消热门游戏订阅
    _hotGamesWatchSub = null;
    _latestGamesWatchSub?.cancel(); // 取消最新游戏订阅
    _latestGamesWatchSub = null;
    _hotPostsWatchSub?.cancel(); // 取消热门帖子订阅
    _hotPostsWatchSub = null;
  }

  /// 处理缓存变化。
  ///
  /// [type]：数据类型。
  /// [event]：缓存事件。
  void _handleCacheChange(HomeDataType type, BoxEvent event) {
    if (!mounted || !_isVisible) return; // 组件未挂载或不可见时返回

    setState(() {
      // 更新 Key 计数器
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
    _fetchSpecificData(type, isTriggeredByCache: true); // 获取对应板块数据
  }

  /// 启动热门游戏自动滚动计时器。
  void _startHotGamesAutoScrollTimer() {
    if (!mounted ||
        !_isVisible ||
        _isHotGamesTimerActive ||
        _hotGamesData == null ||
        _hotGamesData!.isEmpty) {
      // 不满足启动条件时返回
      return;
    }

    final int totalPages = HomeHotGames.getTotalPages(
        HomeHotGames.getCardsPerPage(
          context,
          _screenWidth,
        ),
        _hotGamesData); // 获取总页数

    if (totalPages <= 1) {
      // 总页数小于等于 1 时停止计时器
      _stopHotGamesAutoScrollTimer();
      return;
    }

    _isHotGamesTimerActive = true; // 标记计时器活跃
    _hotGamesScrollTimer?.cancel(); // 取消现有计时器

    _hotGamesScrollTimer = Timer.periodic(_hotGamesAutoscrollDuration, (timer) {
      // 启动周期计时器
      if (!mounted ||
          !_isHotGamesTimerActive ||
          !_hotGamesPageController.hasClients) {
        // 核心条件不满足时返回
        return;
      }

      final int currentCardsPerPage = HomeHotGames.getCardsPerPage(
        context,
        _screenWidth,
      ); // 当前每页卡片数
      final int currentActualTotalPages = HomeHotGames.getTotalPages(
          currentCardsPerPage, _hotGamesData); // 当前实际总页数

      if (currentActualTotalPages <= 1) {
        // 实际总页数小于等于 1 时停止计时器
        _stopHotGamesAutoScrollTimer();
        return;
      }

      int currentPageFromController =
          (_hotGamesPageController.page ?? 0.0).round(); // 获取当前页码
      int nextPage = currentPageFromController + 1; // 下一页页码

      if (nextPage >= currentActualTotalPages) {
        nextPage = 0; // 回到第一页
      }

      _hotGamesPageController.animateToPage(
        // 动画滚动到下一页
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  /// 停止热门游戏自动滚动计时器。
  void _stopHotGamesAutoScrollTimer() {
    if (_hotGamesScrollTimer != null && _hotGamesScrollTimer!.isActive) {
      _hotGamesScrollTimer!.cancel(); // 取消计时器
    }
    _hotGamesScrollTimer = null; // 清空计时器引用
    if (_isHotGamesTimerActive) {
      _isHotGamesTimerActive = false; // 标记计时器不活跃
    }
  }

  bool _isUserInteractingWithHotGamesPager = false; // 用户是否正在与热门游戏分页器交互

  /// 处理热门游戏页码变化。
  ///
  /// [page]：新页码。
  void _onHotGamesPageChanged(int page) {
    if (!mounted) return; // 组件未挂载时返回

    setState(() {
      _currentHotGamesPage = page; // 更新当前页码
    });

    if (_isUserInteractingWithHotGamesPager) {
      // 如果是用户手动滑动
      _resetAndStartHotGamesAutoScroll(); // 重置并启动计时器
    }
  }

  /// 重置并启动热门游戏自动滚动计时器。
  void _resetAndStartHotGamesAutoScroll() {
    if (!mounted) return; // 组件未挂载时返回
    _stopHotGamesAutoScrollTimer(); // 总是先停止当前的计时器

    if (_isVisible && _hotGamesData != null && _hotGamesData!.isNotEmpty) {
      // 页面可见且有数据时
      final int totalPages = HomeHotGames.getTotalPages(
          HomeHotGames.getCardsPerPage(
            context,
            _screenWidth,
          ),
          _hotGamesData); // 获取总页数
      if (totalPages > 1) {
        // 总页数大于 1 时启动计时器
        _startHotGamesAutoScrollTimer();
      }
    }
  }

  /// 构建 UI。
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('home_screen_visibility'), // 可见性检测器 Key
      onVisibilityChanged: _handleVisibilityChange, // 可见性变化回调
      child: _buildScaffoldContent(), // 构建 Scaffold 内容
    );
  }

  /// 构建 Scaffold 内容。
  Widget _buildScaffoldContent() {
    if (!_isOverallInitialized &&
        (_isHotGamesLoading ||
            _isLatestGamesLoading ||
            _isHotPostsLoading ||
            !_hasInitializedDependencies)) {
      // 首次加载时显示骨架屏或加载动画
      return const Scaffold(
        body: FadeInItem(
          // 全屏加载组件
          child: LoadingWidget(
            isOverlay: true,
            message: "少女祈祷中...",
            overlayOpacity: 0.4,
            size: 36,
          ),
        ),
      );
    }

    if (_overallErrorMessage != null && !_isOverallInitialized) {
      // 整体加载错误时显示错误组件
      return Scaffold(
        body: CustomErrorWidget(
          errorMessage: _overallErrorMessage!, // 错误消息
          onRetry: () => _loadAllData(isInitialLoad: true), // 重试初始加载
        ),
      );
    }

    const Duration initialDelay = Duration(milliseconds: 150); // 初始延迟
    const Duration stagger = Duration(milliseconds: 100); // 交错延迟
    int sectionIndex = 0; // 区域索引

    bool playAnimationsThisBuildCycle = false; // 当前构建周期是否播放入口动画
    if (_isOverallInitialized && !_hasPlayedEntryAnimation) {
      playAnimationsThisBuildCycle = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hasPlayedEntryAnimation = true; // 标记已播放动画
        }
      });
    }
    final bool currentPlaySectionEntryAnimation =
        playAnimationsThisBuildCycle; // 当前播放区域入口动画标记

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handlePullToRefresh, // 下拉刷新回调
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 始终可滚动物理
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 水平拉伸
            children: [
              FadeInSlideUpItemCanPlay(
                play: currentPlaySectionEntryAnimation, // 播放动画
                delay: initialDelay, // 延迟
                child: HomeBanner(
                  bannerImagePath: _bannerImage,
                ),
              ), // 首页 Banner
              const SizedBox(height: 16), // 间距

              FadeInSlideUpItemCanPlay(
                play: currentPlaySectionEntryAnimation, // 播放动画
                delay: initialDelay + stagger * sectionIndex++, // 延迟
                child: LazyLayoutBuilder(
                  windowStateProvider: widget.windowStateProvider,
                  builder: (context, constraints) {
                    _screenWidth = constraints.maxWidth;
                    if (!context.mounted) return const SizedBox.shrink();
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16.0), // 水平内边距
                      child: _buildHotGamesSection(
                          currentPlaySectionEntryAnimation),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16), // 间距

              FadeInSlideUpItemCanPlay(
                play: currentPlaySectionEntryAnimation, // 播放动画
                delay: initialDelay + stagger * sectionIndex++, // 延迟
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0), // 水平内边距
                  child: _buildPostsAndGamesSection(
                      currentPlaySectionEntryAnimation), // 帖子和游戏区域
                ),
              ),
              const SizedBox(height: 16), // 间距
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotGamesSection(
    bool currentPlaySectionEntryAnimation,
  ) {
    return HomeHotGames(
      key: ValueKey('hot_games_$_hotGamesKeyCounter'), // 唯一键
      games: _hotGamesData, // 游戏数据
      isLoading: _isHotGamesLoading, // 是否加载中
      screenWidth: _screenWidth,
      errorMessage: _hotGamesError, // 错误消息
      onRetry: (f) => _fetchSpecificData(
        HomeDataType.hotGames,
        isTriggeredByRefresh: true,
        forceRefresh: f,
      ), // 重试回调
      pageController: _hotGamesPageController, // 页面控制器
      currentPage: _currentHotGamesPage, // 当前页码
      onPageChanged: _onHotGamesPageChanged, // 页面改变回调
      playInitialAnimation: currentPlaySectionEntryAnimation && // 播放初始动画
          _hotGamesData != null &&
          _hotGamesData!.isNotEmpty,
      onUserInteraction: (isInteracting) {
        // 用户交互回调
        if (!mounted) return;
        _isUserInteractingWithHotGamesPager = isInteracting; // 更新用户交互状态
        if (isInteracting) {
          _stopHotGamesAutoScrollTimer(); // 停止自动滚动计时器
        }
      },
    );
  }

  /// 构建帖子和游戏区域。
  ///
  /// [context]：Build 上下文。
  /// [playAnimations]：是否播放动画。
  Widget _buildPostsAndGamesSection(bool playAnimations) {
    final Widget hotPostsWidget = HomeHotPosts(
      key: ValueKey('hot_posts_$_hotPostsKeyCounter'), // 唯一键
      currentUser: widget.authProvider.currentUser, // 当前用户
      followService: widget.followService, // 关注服务
      screenWidth: _screenWidth,
      infoService: widget.infoService, // 用户信息 Provider
      posts: _hotPostsData, // 帖子数据
      isLoading: _isHotPostsLoading, // 是否加载中
      errorMessage: _hotPostsError, // 错误消息
      onRetry: (f) => _fetchSpecificData(
        HomeDataType.hotPosts,
        isTriggeredByRefresh: true,
        forceRefresh: f,
      ), // 重试回调
    );

    final Widget latestGamesWidget = HomeLatestGames(
      key: ValueKey('latest_games_$_latestGamesKeyCounter'), // 唯一键
      games: _latestGamesData, // 游戏数据
      isLoading: _isLatestGamesLoading, // 是否加载中
      errorMessage: _latestGamesError, // 错误消息
      onRetry: (f) => _fetchSpecificData(
        HomeDataType.latestGames,
        isTriggeredByRefresh: true,
        forceRefresh: f,
      ), // 重试回调
    );

    if (DeviceUtils.isDesktopInThisWidth(_screenWidth)) {
      // 大屏幕时使用 Row 布局
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
        children: [
          Expanded(child: hotPostsWidget), // 热门帖子
          const SizedBox(width: 16.0), // 间距
          Expanded(child: latestGamesWidget), // 最新游戏
        ],
      );
    } else {
      // 否则使用 Column 布局
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 水平拉伸
        children: [
          hotPostsWidget, // 热门帖子
          const SizedBox(height: 16.0), // 间距
          latestGamesWidget, // 最新游戏
        ],
      );
    }
  }
}
