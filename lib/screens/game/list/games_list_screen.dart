// lib/screens/game/list/games_list_screen.dart

/// 该文件定义了 GamesListScreen 组件，一个用于显示游戏列表的屏幕。
/// GamesListScreen 负责加载和展示游戏数据，支持筛选、排序、分页和游戏操作。
library;

import 'dart:async'; // 导入异步操作所需
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:hive/hive.dart'; // 导入 Hive 数据库，用于监听缓存事件
import 'package:suxingchahui/constants/common/app_bar_actions.dart'; // 导入 AppBar 动作常量
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_category.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/models/game/game/game.dart'; // 导入游戏模型
import 'package:suxingchahui/models/game/game/game_list_pagination.dart'; // 导入游戏列表分页模型
import 'package:suxingchahui/models/game/game/game_tag_count.dart'; // 导入游戏标签模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart'; // 导入游戏列表筛选 Provider
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/services/main/game/game_service.dart'; // 导入游戏服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart'; // 导入动画内容网格组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart'; // 导入左右滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart'; // 导入悬浮动作按钮组
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart'; // 导入功能图标按钮
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart'; // 导入分页控件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 导入基础输入对话框
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 导入确认对话框
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart'; // 导入通用悬浮动作按钮
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 导入空状态组件
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart'; // 导入基础游戏卡片
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/widgets/components/screen/game/section/tag/mobile_tag_bar.dart'; // 导入标签栏
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 导入应用 SnackBar 工具
import 'package:visibility_detector/visibility_detector.dart'; // 导入可见性检测器
import 'package:suxingchahui/widgets/components/screen/game/panel/game_left_panel.dart'; // 导入游戏左侧面板
import 'package:suxingchahui/widgets/components/screen/game/panel/game_right_panel.dart'; // 导入游戏右侧面板

/// `GamesListScreen` 类：游戏列表屏幕。
///
/// 该屏幕负责加载、展示游戏数据，支持筛选、排序、分页和游戏操作。
class GamesListScreen extends StatefulWidget {
  final String? selectedTag; // 初始选中的标签
  final AuthProvider authProvider; // 认证 Provider
  final GameService gameService; // 游戏服务
  final GameListFilterProvider gameListFilterProvider; // 游戏列表筛选 Provider
  final WindowStateProvider windowStateProvider;

  /// 构造函数。
  ///
  /// [selectedTag]：初始选中标签。
  /// [authProvider]：认证 Provider。
  /// [gameService]：游戏服务。
  /// [gameListFilterProvider]：游戏列表筛选 Provider。
  /// [windowStateProvider] : 窗口管理 Provider
  const GamesListScreen({
    super.key,
    this.selectedTag,
    required this.authProvider,
    required this.gameService,
    required this.gameListFilterProvider,
    required this.windowStateProvider,
  });

  /// 创建状态。
  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

/// `_NavigationTilePlaceholder` 类：导航瓦片占位符。
///
/// 用于在网格中表示上一页或下一页的导航项。
class _NavigationTilePlaceholder {
  final bool isPrevious; // 是否为上一页导航
  /// 构造函数。
  ///
  /// [isPrevious]：是否上一页。
  const _NavigationTilePlaceholder({
    required this.isPrevious,
  });
}

/// `_GamesListScreenState` 类：`GamesListScreen` 的状态管理。
///
/// 管理数据加载、筛选、排序、分页、缓存监听和 UI 状态。
class _GamesListScreenState extends State<GamesListScreen>
    with WidgetsBindingObserver {
  bool _isLoadingGameData = false; // 数据是否正在加载中
  DateTime? _lastLoadingGameTime;
  bool _isTagsLoading = false;
  DateTime? _lastTagsLoadingTime;
  bool _isInitialized = false; // 屏幕是否已初始化
  bool _isVisible = false; // 屏幕是否可见
  bool _needsRefresh = false; // 是否需要刷新
  bool _hasInitializedDependencies = false; // 依赖是否已初始化
  String? _errorMessage; // 错误消息
  String? _tagsErrMsg;
  bool _showMobileTagBar = false; // 是否显示移动端标签栏
  bool _showLeftPanel = true; // 是否显示左侧面板
  bool _showRightPanel = true; // 是否显示右侧面板
  List<Game> _gamesList = []; // 游戏列表数据
  int _currentPage = 1; // 当前页码
  int _cacheUpdateCount = 0;
  int _totalPages = 1; // 总页数
  String _currentSortBy = Game.sortByCreateTime; // 当前排序字段
  bool _isDescending = true; // 是否降序
  String? _currentTag; // 当前选中的标签
  String? _currentUserId; // 当前用户ID
  String? _currentCategory; // 当前选中的分类

  List<GameTagCount> _availableTags = []; // 可用的游戏标签列表

  int _pageSize = GameService.gamesLimit;

  static const List<EnrichGameCategory> _availableCategories =
      EnrichGameCategory.defaultEnrichGameCategory; // 可用的游戏分类列表
  StreamSubscription<BoxEvent>? _cacheSubscription; // 缓存订阅器
  String _currentWatchIdentifier = ''; // 当前缓存监听标识符
  Timer? _refreshDebounceTimer; // 刷新防抖计时器
  Timer? _checkProviderDebounceTimer; // Provider 检查防抖计时器
  static const Duration _cacheDebounceDuration = Duration(seconds: 2); // 缓存防抖时长
  static const Duration _checkProviderDebounceDuration =
      Duration(milliseconds: 500); // Provider 检查防抖时长
  static const Map<String, String> _sortOptions = Game.defaultFilter; // 排序选项

  bool _isPerformingRefreshGame = false; // 是否正在执行下拉刷新操作
  DateTime? _lastRefreshGameAttemptTime; // 上次尝试下拉刷新的时间戳

  bool _isPerformingRefreshTags = false; // 是否正在执行下拉刷新操作
  DateTime? _lastRefreshTagsAttemptTime; // 上次尝试下拉刷新的时间戳

  static const Duration _minRefreshInterval = Duration(seconds: 20); // 最小刷新间隔
  static const Duration _maxLoadingDuration = Duration(seconds: 10);
  // 状态缓存
  Timer? _resizeDebounceTimer; // 防抖计时器

  late bool _isDesktop;
  late double _screenWidth;

  static const double _hideRightPanelThreshold = 1000.0; // 隐藏右侧面板的屏幕宽度阈值
  static const double _hideLeftPanelThreshold = 800.0; // 隐藏左侧面板的屏幕宽度阈值

  // 面板动画时长
  static const Duration panelAnimationDuration = Duration(milliseconds: 300);
  static const Duration leftPanelDelay = Duration(milliseconds: 50); // 左侧面板延迟
  static const Duration rightPanelDelay = Duration(milliseconds: 100); // 右侧面板延迟

  static const String _ctxScreen = 'game_list';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加应用生命周期观察者
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
      _isDesktop = DeviceUtils.isDesktopInThisWidth(_screenWidth);
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户ID
    }
  }

  @override
  void didUpdateWidget(covariant GamesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAuthStateChange();
    if (widget.selectedTag != oldWidget.selectedTag) {
      // 选中标签变化时
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除应用生命周期观察者
    _stopWatchingCache(); // 停止监听缓存
    _refreshDebounceTimer?.cancel(); // 取消刷新防抖计时器
    _checkProviderDebounceTimer?.cancel(); // 取消 Provider 检查防抖计时器
    _resizeDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _checkAuthStateChange();
    _checkLoadingTimeout();
    if (state == AppLifecycleState.resumed) {
      if (_isVisible) {
        if (_needsRefresh) {
          // 页面当前可见
          _checkProviderAndApplyFilterIfNeeded(
              reason: "应用恢复"); // 检查 Provider 并应用筛选
          _refreshDataIfNeeded(reason: "应用恢复"); // 刷新当前页数据
        }
      } else {
        _needsRefresh = true; // 标记，等可见时刷新
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时
      _needsRefresh = true; // 标记需要刷新
    }
  }

  /// 检查登录状态是否变动
  ///
  void _checkAuthStateChange() {
    if (!mounted) return;
    if (_currentUserId != widget.authProvider.currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
  }

  /// 检查加载是否超时
  ///
  void _checkLoadingTimeout() {
    if (!mounted) return;
    final now = DateTime.now();
    // 超过最大时长直接关闭
    if (_isLoadingGameData &&
        _lastLoadingGameTime != null &&
        now.difference(_lastLoadingGameTime!) > _maxLoadingDuration) {
      setState(() {
        _lastLoadingGameTime = null;
        _isLoadingGameData = false;
      });
    }
    // 超过最大时长直接关闭
    if (_isTagsLoading &&
        _lastTagsLoadingTime != null &&
        now.difference(_lastTagsLoadingTime!) > _maxLoadingDuration) {
      setState(() {
        _lastTagsLoadingTime = null;
        _isTagsLoading = false;
      });
    }
  }

  /// 初始化当前选中的标签。
  ///
  void _initializeCurrentTag() {
    final initialProviderTag =
        widget.gameListFilterProvider.selectedTag; // 获取 Provider 中的标签
    final tagWasSet =
        widget.gameListFilterProvider.tagHasBeenSet; // 获取标签是否已设置标记
    _currentTag =
        tagWasSet ? initialProviderTag : widget.selectedTag; // 根据标记设置当前标签
  }

  /// 处理可见性变化。
  ///
  /// [visibilityInfo]：可见性信息。
  void _handleVisibilityChange(VisibilityInfo visibilityInfo) {
    final bool nowVisible = visibilityInfo.visibleFraction > 0; // 判断当前是否可见

    _checkAuthStateChange();
    _checkLoadingTimeout();
    if (!mounted) return; // 组件已卸载时返回
    if (nowVisible && !_isVisible) {
      // 变为可见时
      _isVisible = true; // 更新可见性状态
      _checkProviderAndApplyFilterIfNeeded(reason: "变为可见"); // 检查 Provider 并应用筛选
      if (!_isInitialized) {
        // 未初始化时
        _initializeCurrentTag(); // 初始化当前标签
        _loadTags(); // 加载可用标签列表
        _loadGames(pageToFetch: 1, isInitialLoad: true); // 初始加载游戏
        _lastRefreshGameAttemptTime = DateTime.now();
      } else if (_needsRefresh) {
        // 需要刷新时
        _refreshDataIfNeeded(reason: "变为可见且需要刷新"); // 刷新数据
        _needsRefresh = false; // 重置刷新标记
      } else {
        _startOrUpdateWatchingCache(); // 启动或更新缓存监听
      }
    } else if (!nowVisible && _isVisible) {
      // 变为不可见时
      _isVisible = false; // 更新可见性状态
      _stopWatchingCache(); // 停止监听缓存
      _refreshDebounceTimer?.cancel(); // 取消刷新定时器
    }
  }

  /// 检查 Provider 是否需要更新内部状态并应用筛选。
  ///
  /// [reason]：检查原因。
  void _checkProviderAndApplyFilterIfNeeded({required String reason}) {
    _checkProviderDebounceTimer?.cancel(); // 取消上一个计时器
    _checkProviderDebounceTimer = Timer(_checkProviderDebounceDuration, () {
      if (!mounted) return; // 确保 Widget 仍然挂载

      final providerTag =
          widget.gameListFilterProvider.selectedTag; // 获取 Provider 中的标签
      final providerCategory =
          widget.gameListFilterProvider.selectedCategory; // 获取 Provider 中的分类
      final tagWasSet = widget.gameListFilterProvider.tagHasBeenSet; // 标签是否已设置
      final categoryWasSet =
          widget.gameListFilterProvider.categoryHasBeenSet; // 分类是否已设置

      if (tagWasSet && !categoryWasSet && providerTag != _currentTag) {
        // 标签已设置且分类未设置，且标签不同时
        _applyFilterAndSort(
            tag: providerTag,
            category: null,
            sortBy: _currentSortBy,
            descending: _isDescending); // 应用筛选
        widget.gameListFilterProvider.resetTagFlag(); // 重置标签标记
      } else if (tagWasSet && providerTag == _currentTag) {
        // 标签相同但 Provider 标记已设置
        widget.gameListFilterProvider.resetTagFlag(); // 重置标签标记
      }

      if (categoryWasSet &&
          !tagWasSet &&
          providerCategory != _currentCategory) {
        // 分类已设置且标签未设置，且分类不同时
        _applyFilterAndSort(
            tag: null,
            category: providerCategory,
            sortBy: _currentSortBy,
            descending: _isDescending); // 应用筛选
        widget.gameListFilterProvider.resetCategoryFlag(); // 重置分类标记
      } else if (categoryWasSet && providerCategory == _currentCategory) {
        // 分类相同但 Provider 标记已设置
        widget.gameListFilterProvider.resetCategoryFlag(); // 重置分类标记
      }
    });
  }

  /// 加载标签。
  ///
  Future<void> _loadTags({bool forceRefresh = false}) async {
    if (_lastTagsLoadingTime != null) {
      _lastLoadingGameTime = null;
    }
    if (_isTagsLoading) {
      return;
    }
    setState(() {
      _isTagsLoading = true;
      _tagsErrMsg = null;
      _lastTagsLoadingTime = DateTime.now();
    });
    try {
      final tags = await widget.gameService
          .getAllGameTags(forceRefresh: forceRefresh); // 获取所有标签
      if (mounted) setState(() => _availableTags = tags); // 更新可用标签列表
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableTags = []; // 错误时清空标签列表
          _tagsErrMsg = e.toString();
        });
      }
    } finally {
      setState(() {
        _isTagsLoading = false;
        _lastTagsLoadingTime = null;
      });
    }
  }

  /// 刷新标签
  Future<void> _refreshTags({bool needCheck = true}) async {
    if (_isPerformingRefreshTags) return;
    final now = DateTime.now();
    if (needCheck) {
      // 需要进行时间间隔检查时
      if (_lastRefreshTagsAttemptTime != null &&
          now.difference(_lastRefreshTagsAttemptTime!) < _minRefreshInterval) {
        // 时间间隔不足时
        if (mounted) {
          AppSnackBar.showWarning(
              '刷新太频繁啦，请 ${(_minRefreshInterval.inSeconds - now.difference(_lastRefreshGameAttemptTime!).inSeconds)} 秒后再试'); // 提示刷新频繁
        }
        return; // 返回
      }
    }
    setState(() {
      _lastRefreshTagsAttemptTime = now;
      _isPerformingRefreshTags = true;
    });

    try {
      await _loadTags(forceRefresh: true);
      if (mounted) {
        setState(() {
          _isPerformingRefreshTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPerformingRefreshTags = false;
        });
      }
    }
  }

  /// 加载游戏数据。
  ///
  /// [pageToFetch]：目标页码。
  /// [isInitialLoad]：是否为初始加载。
  /// [isRefresh]：是否为刷新。
  /// [forceRefresh]：是否强制刷新。
  Future<void> _loadGames({
    int? pageToFetch,
    bool isInitialLoad = false,
    bool isRefresh = false,
    bool forceRefresh = false,
  }) async {
    if (_lastLoadingGameTime != null) _lastLoadingGameTime = null;
    if (!mounted || _isLoadingGameData) return; // 组件未挂载或正在加载时返回

    final int targetPage = pageToFetch ?? 1; // 目标页码

    if (targetPage < 1 ||
        (!isInitialLoad &&
            !isRefresh &&
            _totalPages > 1 &&
            targetPage > _totalPages)) {
      // 目标页码无效时返回
      return;
    }

    _isInitialized = true; // 标记为已初始化

    setState(() {
      _isLoadingGameData = true; // 设置加载状态
      _lastLoadingGameTime = DateTime.now();
      _errorMessage = null; // 清空错误消息
      if (isRefresh || isInitialLoad) {
        // 刷新或初始加载时清空游戏列表
        _gamesList = [];
      }
    });

    try {
      GameListPagination result;
      if (_currentCategory != null) {
        // 按分类加载
        result = await widget.gameService.getGamesByCategoryWithInfo(
          categoryName: _currentCategory!,
          page: targetPage,
          sortBy: _currentSortBy,
          sortDesc: _isDescending,
          forceRefresh: forceRefresh,
        );
      } else if (_currentTag != null) {
        // 按标签加载
        result = await widget.gameService.getGamesByTagWithInfo(
          tag: _currentTag!,
          page: targetPage,
          sortBy: _currentSortBy,
          sortDesc: _isDescending,
          forceRefresh: forceRefresh,
        );
      } else {
        // 加载所有游戏
        result = await widget.gameService.getGamesPaginatedWithInfo(
          page: targetPage,
          sortBy: _currentSortBy,
          sortDesc: _isDescending,
          forceRefresh: forceRefresh,
        );
      }

      if (!mounted) return; // 组件未挂载时返回

      final games = result.games; // 获取游戏列表
      final pagination = result.pagination; // 获取分页信息
      final int serverPage = pagination.page; // 服务器返回的页码
      final int serverPageSize = pagination.limit;
      final int serverTotalPages = pagination.pages; // 服务器返回的总页数

      setState(() {
        _gamesList = games; // 更新游戏列表
        _currentPage = serverPage; // 更新当前页码
        _pageSize = serverPageSize;
        _totalPages = serverTotalPages; // 更新总页数
        _errorMessage = null; // 清空错误消息
        if (!_isInitialized) _isInitialized = true; // 标记为已初始化
      });

      _startOrUpdateWatchingCache(); // 监听当前页缓存
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败，请稍后重试。'; // 设置错误消息
          if (isRefresh || isInitialLoad) {
            // 刷新或初始加载时清空列表和重置分页
            _gamesList = [];
            _currentPage = 1;
            _totalPages = 1;
          }
        });
      }
      _stopWatchingCache(); // 停止监听缓存
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGameData = false; // 重置加载状态
          _lastLoadingGameTime = null;
          _cacheUpdateCount = 0;
        });
      }
    }
  }

  /// 开始监听缓存变化。
  ///
  /// 该方法根据当前的筛选条件和页码生成监听标识符，并监听游戏列表页的缓存变化。
  void _startOrUpdateWatchingCache() {
    final WatchGameListScope filterType; // 筛选类型
    final String? filterValue; // 筛选值
    if (_currentCategory != null) {
      // 按分类筛选
      filterType = WatchGameListScope.category;
      filterValue = _currentCategory;
    } else if (_currentTag != null) {
      // 按标签筛选
      filterType = WatchGameListScope.tag;
      filterValue = _currentTag;
    } else {
      // 无筛选
      filterType = WatchGameListScope.all;
      filterValue = null;
    }
    final String newWatchIdentifier =
        "${filterType}_${filterValue ?? 'none'}_${_currentPage}_${_currentSortBy}_$_isDescending"; // 新的监听标识符

    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      // 已经在监听相同状态时返回
      return;
    }
    _stopWatchingCache(); // 停止之前的监听
    _currentWatchIdentifier = newWatchIdentifier; // 更新监听标识符
    try {
      _cacheSubscription = widget.gameService
          .watchGameListPageChanges(
        tag: _currentTag,
        categoryName: _currentCategory,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
        scope: _currentTag != null
            ? WatchGameListScope.tag
            : WatchGameListScope.all,
      )
          .listen((BoxEvent event) {
        if (_isVisible) {
          // 屏幕可见时触发刷新
          _refreshDataIfNeeded(
              reason: "缓存变化：第 $_currentPage 页，事件: $event",
              isCacheUpdated: true);
          _needsRefresh = false;
        } else {
          // 屏幕不可见时标记需要刷新
          _needsRefresh = true;
        }
      }, onError: (e, s) {
        // 监听错误时
        _stopWatchingCache(); // 停止监听
      }, onDone: () {
        // 监听完成时
        _stopWatchingCache(); // 停止监听
      }, cancelOnError: true); // 发生错误时自动取消监听
    } catch (e) {
      _currentWatchIdentifier = ''; // 启动监听失败时重置标识符
    }
  }

  /// 停止监听缓存变化。
  ///
  void _stopWatchingCache() {
    if (_cacheSubscription != null) {
      _cacheSubscription?.cancel(); // 取消订阅
      _cacheSubscription = null; // 清空订阅器
      _currentWatchIdentifier = ''; // 清空监听标识符
    }
  }

  /// 刷新数据，带防抖控制。
  ///
  /// [reason]：刷新原因。
  /// [isCacheUpdated]：是否因缓存更新触发。
  void _refreshDataIfNeeded(
      {required String reason, bool isCacheUpdated = false}) {
    _refreshDebounceTimer?.cancel(); // 取消旧的防抖计时器
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      // 启动新的防抖计时器
      if (!mounted) return; // 组件已卸载时返回

      if (!_isVisible) {
        // 屏幕不可见时标记需要刷新
        _needsRefresh = true;
        return;
      }

      if (_isLoadingGameData) {
        // 正在加载数据时
        if (isCacheUpdated) {
          // 如果是缓存更新触发
          if (_cacheUpdateCount < 2) {
            _needsRefresh = true; // 标记需要刷新
            _cacheUpdateCount++;
            return;
          } else {
            _cacheUpdateCount++;
            return;
          }
        } else {
          _needsRefresh = true; // 标记需要刷新
          return;
        }
      }

      _loadGames(pageToFetch: _currentPage, isRefresh: true); // 加载游戏数据
    });
  }

  /// 刷新主逻辑。
  ///
  /// [needCheck]：是否需要进行时间间隔检查。
  Future<void> _forceRefreshGameData({bool needCheck = true}) async {
    if (_isPerformingRefreshGame) {
      // 如果正在执行下拉刷新，则返回
      return;
    }
    final now = DateTime.now();
    if (needCheck) {
      // 需要进行时间间隔检查时
      if (_lastRefreshGameAttemptTime != null &&
          now.difference(_lastRefreshGameAttemptTime!) < _minRefreshInterval) {
        // 时间间隔不足时
        if (mounted) {
          AppSnackBar.showWarning(
              '刷新太频繁啦，请 ${(_minRefreshInterval.inSeconds - now.difference(_lastRefreshGameAttemptTime!).inSeconds)} 秒后再试'); // 提示刷新频繁
        }
        return; // 返回
      }
    }

    if (mounted) {
      setState(() {
        _isPerformingRefreshGame = true; // 设置正在执行下拉刷新标记
      });
    }
    _lastRefreshGameAttemptTime = now; // 记录本次尝试刷新时间

    try {
      if (_isLoadingGameData) {
        // 如果其他数据加载正在进行，则返回
        return;
      }
      _stopWatchingCache(); // 停止监听缓存
      await _loadGames(
          pageToFetch: 1, isRefresh: true, forceRefresh: true); // 加载第一页并标记为刷新
    } catch (e) {
      // 错误处理
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingRefreshGame = false; // 清除刷新状态标记
        });
      }
    }
  }

  /// 前往上一页。
  ///
  Future<void> _goToPreviousPageInternal() async {
    if (_currentPage > 1 && !_isLoadingGameData) {
      // 当前页大于 1 且未加载数据时
      _stopWatchingCache(); // 停止监听缓存
      await _loadGames(pageToFetch: _currentPage - 1); // 加载上一页
    } else {
      AppSnackBar.showWarning("已经是第一页了"); // 提示已是第一页
    }
  }

  /// 前往下一页。
  ///
  Future<void> _goToNextPageInternal() async {
    if (_currentPage < _totalPages && !_isLoadingGameData) {
      // 当前页小于总页数且未加载数据时
      _stopWatchingCache(); // 停止监听缓存
      await _loadGames(pageToFetch: _currentPage + 1); // 加载下一页
    } else {
      AppSnackBar.showWarning("已经是最后一页了了"); // 提示已是最后一页
    }
  }

  /// 前往指定页码。
  ///
  /// [pageNumber]：目标页码。
  Future<void> _goToPage(int pageNumber) async {
    if (pageNumber >= 1 &&
        pageNumber <= _totalPages &&
        pageNumber != _currentPage &&
        !_isLoadingGameData) {
      // 目标页码有效且非当前页且未加载数据时
      _stopWatchingCache(); // 停止监听缓存
      await _loadGames(pageToFetch: pageNumber); // 加载指定页
    } else if (pageNumber == _currentPage && mounted) {
      // 目标页为当前页时无操作
    } else if (!_isLoadingGameData && mounted) {
      // 未加载数据时无操作
    } else if (_isLoadingGameData) {
      // 正在加载数据时无操作
    }
  }

  /// 显示筛选对话框。
  ///
  /// [context]：Build 上下文。
  Future<void> _showFilterDialog(BuildContext context) async {
    String? tempSelectedTag = _currentTag; // 临时选中的标签
    String? tempSelectedCategory = _currentCategory; // 临时选中的分类
    String tempSortBy = _currentSortBy; // 临时排序字段
    bool tempDescending = _isDescending; // 临时降序标记

    final confirmed = await BaseInputDialog.show<bool>(
      context: context,
      title: '筛选与排序',
      confirmButtonText: '应用',
      contentBuilder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('按分类筛选:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: tempSelectedCategory,
                    hint: const Text('所有分类'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('所有分类')),
                      ..._availableCategories.map(
                        (enrichCategory) => DropdownMenuItem<String?>(
                          value: enrichCategory.category,
                          child: Text(enrichCategory.textLabel),
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        tempSelectedCategory = newValue;
                        if (newValue != null) {
                          tempSelectedTag = null; // 选择分类时清除临时标签
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('按标签筛选:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: tempSelectedTag,
                    hint: const Text('所有标签'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('所有标签')),
                      ..._availableTags.map((tag) => DropdownMenuItem<String?>(
                          value: tag.tagLabel,
                          child: Text('${tag.tagLabel} (${tag.count})'))),
                    ],
                    onChanged: (String? newValue) =>
                        setDialogState(() => tempSelectedTag = newValue),
                  ),
                  const SizedBox(height: 16),
                  Text('排序方式:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._sortOptions.entries.map((entry) => _buildSortOptionTile(
                        title: entry.value,
                        sortField: entry.key,
                        currentSortBy: tempSortBy,
                        isDescending: tempDescending,
                        onChanged: (field, desc) {
                          setDialogState(() {
                            tempSortBy = field;
                            tempDescending = desc;
                          });
                        },
                      )),
                ],
              ),
            );
          },
        );
      },
      onConfirm: () async {
        return true; // 返回非 null 值表示确认成功，对话框将关闭
      },
      iconData: Icons.filter_list_alt, // 筛选图标
    );

    if (confirmed == true && mounted) {
      // 对话框确认关闭后
      _handleFilterDialogConfirm(tempSelectedCategory, tempSelectedTag,
          tempSortBy, tempDescending); // 处理筛选确认
    }
  }

  /// 构建排序选项瓦片。
  ///
  /// [title]：标题。
  /// [sortField]：排序字段。
  /// [currentSortBy]：当前排序字段。
  /// [isDescending]：是否降序。
  /// [onChanged]：改变回调。
  Widget _buildSortOptionTile({
    required String title,
    required String sortField,
    required String currentSortBy,
    required bool isDescending,
    required Function(String, bool) onChanged,
  }) {
    final bool isSelected = currentSortBy == sortField; // 是否选中
    final colorScheme = Theme.of(context).colorScheme; // 颜色方案
    return ListTile(
      title: Text(title,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : null)), // 标题样式
      selected: isSelected, // 是否选中
      selectedTileColor: Colors.grey.withSafeOpacity(0.1), // 选中瓦片背景色
      dense: true, // 紧凑模式
      contentPadding: const EdgeInsets.symmetric(horizontal: 0), // 内容内边距
      onTap: () {
        // 点击回调
        if (!isSelected) onChanged(sortField, true); // 未选中时更新排序字段和降序
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward), // 升序图标
            iconSize: 20,
            color: isSelected && !isDescending
                ? colorScheme.secondary
                : Colors.grey,
            tooltip: '升序', // 提示
            onPressed: () => onChanged(sortField, false), // 升序点击回调
            splashRadius: 20, // 水波纹半径
            constraints: const BoxConstraints(), // 约束
            padding: EdgeInsets.zero,
          ), // 内边距
          IconButton(
            icon: const Icon(Icons.arrow_downward), // 降序图标
            iconSize: 20,
            color: isSelected && isDescending
                ? colorScheme.secondary
                : Colors.grey,
            tooltip: '降序', // 提示
            onPressed: () => onChanged(sortField, true), // 降序点击回调
            splashRadius: 20, // 水波纹半径
            constraints: const BoxConstraints(), // 约束
            padding: EdgeInsets.zero,
          ), // 内边距
        ],
      ),
    );
  }

  /// 应用筛选（标签或分类）和排序，并触发刷新。
  ///
  /// [tag]：要应用的标签。
  /// [category]：要应用的分类。
  /// [sortBy]：排序字段。
  /// [descending]：是否降序。
  void _applyFilterAndSort(
      {String? tag,
      String? category,
      required String sortBy,
      required bool descending}) {
    String? finalTag = tag; // 最终标签
    String? finalCategory = category; // 最终分类

    if (finalCategory != null && finalTag != null) {
      // 如果同时选择了分类和标签，优先分类，清除标签
      finalTag = null;
    }

    bool categoryChanged = _currentCategory != finalCategory; // 分类是否改变
    bool tagChanged = _currentTag != finalTag; // 标签是否改变
    bool sortChanged =
        _currentSortBy != sortBy || _isDescending != descending; // 排序是否改变

    if (categoryChanged || tagChanged || sortChanged) {
      // 如果状态发生变化
      _stopWatchingCache(); // 停止旧监听
      setState(() {
        _currentCategory = finalCategory; // 更新分类
        _currentTag = finalTag; // 更新标签
        _currentSortBy = sortBy; // 更新排序字段
        _isDescending = descending; // 更新降序标记
        _currentPage = 1; // 重置分页
        _totalPages = 1;
        _errorMessage = null; // 清空错误消息
        _gamesList = []; // 清空游戏列表
      });
      _loadGames(pageToFetch: 1, isRefresh: true); // 触发第一页加载
    }
  }

  /// 清除标签筛选。
  void _clearTagFilter() {
    _applyFilterAndSort(
        tag: null,
        category: _currentCategory,
        sortBy: _currentSortBy,
        descending: _isDescending); // 清除标签，保持当前分类和排序
    widget.gameListFilterProvider.clearTag(); // 更新 Provider 状态为 null
    widget.gameListFilterProvider.resetTagFlag(); // 重置标签标记
  }

  /// 清除分类筛选。
  void _clearCategoryFilter() {
    _applyFilterAndSort(
        tag: _currentTag,
        category: null,
        sortBy: _currentSortBy,
        descending: _isDescending); // 清除分类，保持当前标签和排序
  }

  /// 处理筛选对话框确认。
  ///
  /// [newCategory]：新的分类。
  /// [newTag]：新的标签。
  /// [newSortBy]：新的排序字段。
  /// [newDescending]：新的降序标记。
  void _handleFilterDialogConfirm(String? newCategory, String? newTag,
      String newSortBy, bool newDescending) {
    _applyFilterAndSort(
      category: newCategory,
      tag: newTag,
      sortBy: newSortBy,
      descending: newDescending,
    ); // 应用筛选和排序
    if (widget.gameListFilterProvider.selectedTag != newTag) {
      // 更新 Provider 标签状态
      widget.gameListFilterProvider.setTag(newTag);
    }
    if (widget.gameListFilterProvider.selectedCategory != newCategory) {
      // 更新 Provider 分类状态
      widget.gameListFilterProvider.setCategory(newCategory);
    }
    widget.gameListFilterProvider.resetTagFlag(); // 重置标签标记
  }

  /// 处理分类选择。
  ///
  /// [category]：选中的分类。
  void _handleCategorySelected(EnrichGameCategory? enrichCategory) {
    final category = enrichCategory?.category;
    final newCategory =
        (_currentCategory == category) ? null : category; // 切换分类
    _applyFilterAndSort(
        tag: null,
        category: newCategory,
        sortBy: _currentSortBy,
        descending: _isDescending); // 应用新分类并清除标签
    if (_currentTag != null) {
      // 如果有标签，清除标签并重置标记
      widget.gameListFilterProvider.clearTag();
      widget.gameListFilterProvider.resetTagFlag();
    }
  }

  /// 处理标签栏选择。
  ///
  /// [enrichTag]：选中的标签。
  void _handleTagBarSelected(EnrichGameTag? enrichTag) {
    final tag = enrichTag?.tag;
    final newTag = (_currentTag == tag) ? null : tag; // 切换标签
    _applyFilterAndSort(
        tag: tag,
        category: null,
        sortBy: _currentSortBy,
        descending: _isDescending); // 应用新标签并清除分类
    if (widget.gameListFilterProvider.selectedTag != newTag) {
      // 更新 Provider 标签状态
      widget.gameListFilterProvider.setTag(newTag);
    }
    widget.gameListFilterProvider.resetTagFlag(); // 重置标签标记
  }

  /// 处理删除游戏。
  ///
  /// [game]：要删除的游戏。
  Future<void> _handleDeleteGame(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeleteGame(game)) {
      // 无权限时提示错误
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    await CustomConfirmDialog.show(
      // 显示确认对话框
      context: context,
      title: '确认删除',
      message: '确定要删除这个游戏吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever,
      iconColor: Colors.red,
      onConfirm: () async {
        // 确认删除回调
        try {
          await widget.gameService.deleteGame(game); // 调用删除游戏服务
          if (!mounted) return; // 组件未挂载时返回
          AppSnackBar.showSuccess("成功删除游戏"); // 提示删除成功
          await _loadGames(isRefresh: true);
        } catch (e) {
          AppSnackBar.showError("删除游戏失败,${e.toString()}"); // 提示删除失败
        }
      },
    );
  }

  /// 检查是否可编辑或删除游戏。
  ///
  /// [game]：要检查的游戏。
  /// 返回 true 表示可编辑或删除，否则返回 false。
  bool _checkCanEditOrDeleteGame(Game game) {
    return widget.authProvider.isAdmin
        ? true
        : widget.authProvider.currentUserId == game.authorId; // 管理员或作者可编辑删除
  }

  /// 处理编辑游戏。
  ///
  /// [game]：要编辑的游戏。
  Future<void> _handleEditGame(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeleteGame(game)) {
      // 无权限时提示错误
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }

    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game.id); // 导航到编辑游戏页面
    if (result == true && mounted) {
      await _loadGames(pageToFetch: _currentPage);
    }
  }

  /// 处理添加游戏。
  void _handleAddGame() {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((result) async {
      // 导航到添加游戏页面
      if (result == true && mounted) {
        // 添加成功且组件挂载时
        await _loadGames(isRefresh: true, forceRefresh: true);
        // 要加载第一页，因为新游戏在第一页，虽然普通用户看不到刚创建的游戏
      }
    });
  }

  /// 切换左侧面板的可见性。
  void _toggleLeftPanel() =>
      setState(() => _showLeftPanel = !_showLeftPanel); // 切换左侧面板可见性

  /// 切换右侧面板的可见性。
  void _toggleRightPanel() =>
      setState(() => _showRightPanel = !_showRightPanel); // 切换右侧面板可见性

  /// 构建屏幕 UI。
  @override
  Widget build(BuildContext context) {
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // 注这个screenWidth就是指整个屏幕的宽度
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
        // 要用这个值去判断这个实际宽度
        _screenWidth = screenWidth;
        _isDesktop = isDesktop;
        return Scaffold(
          appBar: _buildAppBar(), // AppBar
          body: VisibilityDetector(
            key: const ValueKey('games_list_visibility_detector'), // 可见性检测器 Key
            onVisibilityChanged: _handleVisibilityChange, // 可见性变化回调
            child: _buildBodyContent(), // 主体内容
          ),
          floatingActionButton: _buildFabGroup(), // 悬浮动作按钮组
          bottomNavigationBar:
              _buildFloatingPaginationControlsIfNeeded(), // 悬浮分页控件
        );
      },
    );
  }

  /// 构建 AppBar。
  PreferredSizeWidget _buildAppBar() {
    String title = '游戏列表'; // 默认标题

    if (_currentCategory != null) {
      // 有分类时显示分类标题
      title = '分类: $_currentCategory';
    } else if (_currentTag != null) {
      // 有标签时显示标签标题
      title = '标签: $_currentTag';
    }
    final canShowLeftPanelBasedOnWidth =
        _screenWidth >= _hideLeftPanelThreshold; // 是否可显示左侧面板
    final canShowRightPanelBasedOnWidth =
        _screenWidth >= _hideRightPanelThreshold; // 是否可显示右侧面板

    return CustomAppBar(
      title: title, // 标题
      actions: [
        if (_isDesktop) const SizedBox(width: 8), // 间距
        if (_isDesktop)
          FunctionalIconButton(
            buttonBackgroundColor: Colors.white,
            onPressed: () => _forceRefreshGameData(needCheck: true),
            icon: Icons.refresh_outlined,
          ),
        // 动作按钮
        if (_isDesktop) const SizedBox(width: 8), // 桌面平台间距
        if (_isDesktop) // 桌面平台左侧面板切换按钮
          FunctionalIconButton(
            buttonBackgroundColor: AppBarAction.toggleLeftPanel.defaultBgColor,
            icon: AppBarAction.toggleLeftPanel.icon,
            iconColor: _showLeftPanel && canShowLeftPanelBasedOnWidth
                ? Colors.black38
                : Colors.amber,
            tooltip: _showLeftPanel ? '隐藏左侧面板' : '显示左侧面板',
            onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
          ),
        if (_isDesktop) const SizedBox(width: 8), // 桌面平台间距
        if (_isDesktop) // 桌面平台右侧面板切换按钮
          FunctionalIconButton(
            buttonBackgroundColor: AppBarAction.toggleRightPanel.defaultBgColor,
            icon: AppBarAction.toggleRightPanel.icon,
            iconColor: _showRightPanel && canShowRightPanelBasedOnWidth
                ? Colors.black38
                : Colors.amber,
            tooltip: _showRightPanel ? '隐藏右侧面板' : '显示右侧面板',
            onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
          ),
        const SizedBox(width: 8), // 间距
        FunctionalIconButton(
          // 添加游戏按钮
          icon: AppBarAction.addGame.icon,
          tooltip: AppBarAction.addGame.defaultTooltip!,
          iconColor: AppBarAction.addGame.defaultIconColor,
          buttonBackgroundColor: AppBarAction.addGame.defaultBgColor,
          onPressed: _isLoadingGameData ? null : _handleAddGame,
        ),
        const SizedBox(width: 8), // 间距
        FunctionalIconButton(
          // 我的游戏按钮
          icon: AppBarAction.myGames.icon,
          tooltip: AppBarAction.myGames.defaultTooltip!,
          iconColor: AppBarAction.myGames.defaultIconColor,
          buttonBackgroundColor: AppBarAction.myGames.defaultBgColor,
          onPressed: _isLoadingGameData
              ? null
              : () => NavigationUtils.pushNamed(context, AppRoutes.myGames),
        ),
        const SizedBox(width: 8), // 间距
        FunctionalIconButton(
          // 搜索游戏按钮
          icon: AppBarAction.searchGame.icon,
          tooltip: AppBarAction.searchGame.defaultTooltip!,
          iconColor: AppBarAction.searchGame.defaultIconColor,
          buttonBackgroundColor: AppBarAction.searchGame.defaultBgColor,
          onPressed: _isLoadingGameData
              ? null
              : () => NavigationUtils.pushNamed(context, AppRoutes.searchGame),
        ),
        const SizedBox(width: 8), // 间距
        FunctionalIconButton(
          // 筛选排序按钮
          icon: AppBarAction.filterSort.icon,
          tooltip: AppBarAction.filterSort.defaultTooltip!,
          iconColor: AppBarAction.filterSort.defaultIconColor,
          buttonBackgroundColor: AppBarAction.filterSort.defaultBgColor,
          onPressed:
              _isLoadingGameData ? null : () => _showFilterDialog(context),
        ),
        if (_currentCategory != null) const SizedBox(width: 8), // 清除分类按钮间距
        if (_currentCategory != null) // 清除分类按钮
          FunctionalIconButton(
            icon: AppBarAction.clearCategoryFilter.icon,
            iconColor: AppBarAction.clearCategoryFilter.defaultIconColor,
            iconBackgroundColor: Colors.white,
            onPressed: _isLoadingGameData ? null : _clearCategoryFilter,
            tooltip: '清除分类筛选 ($_currentCategory)',
          ),
        if (_currentTag != null) const SizedBox(width: 8), // 清除标签按钮间距
        if (_currentTag != null) // 清除标签按钮
          FunctionalIconButton(
            icon: AppBarAction.clearTagFilter.icon,
            iconColor: AppBarAction.clearTagFilter.defaultIconColor,
            iconBackgroundColor: Colors.white,
            onPressed: _isLoadingGameData ? null : _clearTagFilter,
            tooltip: '清除标签筛选 ($_currentTag)',
          ),
        if (!_isDesktop) const SizedBox(width: 8), // 移动端间距
        if (!_isDesktop) // 移动端标签栏切换按钮
          FunctionalIconButton(
            icon: AppBarAction.toggleMobileTagBar.icon,
            tooltip: _showMobileTagBar ? '隐藏标签栏' : '显示标签栏',
            iconColor: _showMobileTagBar ? Colors.grey : Colors.amber,
            iconBackgroundColor: Colors.white,
            onPressed: () =>
                setState(() => _showMobileTagBar = !_showMobileTagBar),
          ),
      ],
      bottom: (!_isDesktop &&
              _showMobileTagBar &&
              _availableTags.isNotEmpty) // 底部标签栏
          ? MobileTagBar(
              tags: _availableTags,
              selectedTag: _currentTag,
              onTagSelected: _handleTagBarSelected,
            )
          : null,
    );
  }

  /// 构建页面主体内容。
  Widget _buildBodyContent() {
    final bool shouldShowLeftPanel = _isDesktop &&
        _showLeftPanel &&
        (_screenWidth >= _hideLeftPanelThreshold); // 是否显示左侧面板
    final bool shouldShowRightPanel = _isDesktop &&
        _showRightPanel &&
        (_screenWidth >= _hideRightPanelThreshold); // 是否显示右侧面板

    final panelWidth = DeviceUtils.getSidePanelWidthInScreenWidth(_screenWidth);

    return RefreshIndicator(
      onRefresh: () => _forceRefreshGameData(needCheck: true), // 下拉刷新回调
      child: Stack(
        children: [
          _isDesktop // 桌面布局
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
                  children: [
                    if (shouldShowLeftPanel) // 显示左侧面板
                      FadeInSlideLRItem(
                        key: const ValueKey('game_list_left_panel'), // 唯一键
                        slideDirection: SlideDirection.left, // 滑动方向
                        duration: panelAnimationDuration, // 动画时长
                        delay: leftPanelDelay, // 延迟
                        child: GameLeftPanel(
                          panelWidth: panelWidth,
                          tags: _availableTags, // 标签列表
                          selectedTag: _currentTag, // 选中标签
                          onTagSelected: _isTagsLoading // 点击标签回调
                              ? (EnrichGameTag? tag) {}
                              : _handleTagBarSelected,
                          isTagLoading: _isTagsLoading,
                          errorMessage: _tagsErrMsg,
                          refreshTags: (c) => _refreshTags(needCheck: c),
                        ),
                      ),
                    Expanded(
                      child: _buildMainContentArea(
                          // 主要内容区域
                          _isDesktop,
                          shouldShowLeftPanel,
                          shouldShowRightPanel),
                    ),
                    if (shouldShowRightPanel && // 显示右侧面板
                        (_isInitialized || _gamesList.isNotEmpty))
                      FadeInSlideLRItem(
                        key: const ValueKey('game_list_right_panel'), // 唯一键
                        slideDirection: SlideDirection.right, // 滑动方向
                        duration: panelAnimationDuration, // 动画时长
                        delay: rightPanelDelay, // 延迟
                        child: GameRightPanel(
                          panelWidth: panelWidth,
                          currentPageGames: _gamesList, // 当前页游戏列表
                          totalGamesCount: _totalPages * _pageSize, // 总游戏数量
                          selectedTag: _currentTag, // 选中标签
                          onTagSelected: _isLoadingGameData // 标签选择回调
                              ? null
                              : _handleTagBarSelected,
                          selectedCategory: _currentCategory, // 选中分类
                          availableCategories: _availableCategories, // 可用分类
                          onCategorySelected: _isLoadingGameData // 分类选择回调
                              ? null
                              : _handleCategorySelected,
                        ),
                      ),
                  ],
                )
              : Column(
                  // 移动端布局
                  children: [
                    Expanded(
                      child: _buildMainContentArea(
                        _isDesktop,
                        false,
                        false,
                      ), // 主要内容区域
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// 构建中心内容区域（加载、错误、空或网格）。
  Widget _buildMainContentArea(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    if (!_isInitialized) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (_errorMessage != null && _gamesList.isEmpty && !_isLoadingGameData) {
      // 错误且列表为空时显示错误组件
      return CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: () {
          _loadGames(pageToFetch: 1, isRefresh: true); // 点击重试加载
        },
      );
    }

    if (!_isLoadingGameData && _errorMessage == null && _gamesList.isEmpty) {
      // 无数据且无错误时显示空状态
      return _buildEmptyState();
    }

    return Stack(
      children: [
        _buildGameGridWithNavigation(showLeftPanel, showRightPanel), // 游戏网格和导航
        if (_isLoadingGameData && _gamesList.isNotEmpty) // 加载中且列表不为空时显示半透明加载层
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(240), // 半透明黑色背景
              child: const FadeInItem(
                // 全屏加载组件
                child: LoadingWidget(
                  message: "正在等待加载...",
                  overlayOpacity: 0.4,
                  size: 36,
                ),
              ), // 内联加载指示器
            ),
          ),
        if (_isLoadingGameData &&
            _gamesList.isEmpty &&
            _errorMessage == null) // 加载中且列表为空时显示加载组件
          const LoadingWidget(
            message: '正在加载游戏...',
            size: 36,
          ),
      ],
    );
  }

  /// 构建游戏网格和导航。
  Widget _buildGameGridWithNavigation(bool showLeftPanel, bool showRightPanel) {
    final List<Object> displayItems = []; // 要显示在网格中的所有项目列表
    final bool showPrevTile = _currentPage > 1 && _totalPages > 1; // 是否显示上一页瓦片
    final bool showNextTile = _currentPage < _totalPages; // 是否显示下一页瓦片

    if (showPrevTile) {
      displayItems
          .add(const _NavigationTilePlaceholder(isPrevious: true)); // 添加上一页占位符
    }
    displayItems.addAll(_gamesList); // 添加游戏列表
    if (showNextTile) {
      displayItems
          .add(const _NavigationTilePlaceholder(isPrevious: false)); // 添加下一页占位符
    }

    double availableWidth = _screenWidth;
    final panelWidth = DeviceUtils.getSidePanelWidthInScreenWidth(_screenWidth);
    if (showLeftPanel) availableWidth -= panelWidth;
    if (showRightPanel) availableWidth -= panelWidth;

    final bool withPanels =
        _isDesktop && (showLeftPanel || showRightPanel); // 是否显示面板
    int cardsPerRow = DeviceUtils.calculateGameCardsInGameListPerRow(
      context,
      directAvailableWidth: availableWidth,
    ); // 计算每行卡片数量
    if (cardsPerRow <= 0) cardsPerRow = 1; // 确保至少为 1

    final useCompactMode =
        cardsPerRow > 3 || (cardsPerRow == 3 && withPanels); // 是否使用紧凑模式

    final cardRatio = withPanels // 卡片宽高比
        ? DeviceUtils.calculateGameListCardRatio(
            context,
            directAvailableWidth: availableWidth,
          )
        : DeviceUtils.calculateSimpleGameCardRatio(context, showTags: true);
    if (cardRatio <= 0) {
      // 宽高比无效时显示错误
      return const CustomErrorWidget(errorMessage: "发生异常错误");
    }

    return AnimatedContentGrid<Object>(
      gridKey: ValueKey('${_ctxScreen}_$_currentPage'),
      // 网格的 Key
      items: displayItems,
      // 显示的项目列表
      crossAxisCount: cardsPerRow,
      // 交叉轴项数
      childAspectRatio: cardRatio,
      // 子项宽高比
      crossAxisSpacing: 8,
      // 交叉轴间距
      mainAxisSpacing: _isDesktop ? 16 : 8,
      // 主轴间距
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
      // 内边距
      itemBuilder: (context, index, item) {
        if (item is _NavigationTilePlaceholder) {
          // 如果是导航占位符
          return _buildNavigationTile(
            isPrevious: item.isPrevious,
            cardRatio: cardRatio,
          ); // 构建导航瓦片
        }

        if (item is Game) {
          // 如果是游戏
          final game = item;

          return BaseGameCard(
            key: ValueKey('${_ctxScreen}_${game.id}'),
            // 唯一键
            currentUser: widget.authProvider.currentUser,
            // 参数
            // 当前用户
            game: game,
            // 游戏数据
            isGridItem: true,
            // 是否为网格项
            showNewBadge: true,
            // 显示新徽章
            showUpdatedBadge: true,
            // 显示更新徽章
            adaptForPanels: withPanels,
            // 是否适应面板
            showTags: true,
            // 显示标签
            showCollectionStats: true,
            // 显示收藏统计
            forceCompact: useCompactMode,
            // 强制紧凑模式
            maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2),
            // 最大标签数
            onDeleteAction:
                _isLoadingGameData && !_checkCanEditOrDeleteGame(game) // 删除回调
                    ? null
                    : () {
                        _handleDeleteGame(game);
                      },
            onEditAction:
                _isLoadingGameData && !_checkCanEditOrDeleteGame(game) // 编辑回调
                    ? null
                    : () => _handleEditGame(game),
          );
        }

        return const SizedBox.shrink(); // 否则返回空组件
      },
    );
  }

  /// 构建导航瓦片（上一页或下一页）。
  Widget _buildNavigationTile(
      {required bool isPrevious, required double cardRatio}) {
    final bool canNavigate =
        isPrevious ? (_currentPage > 1) : (_currentPage < _totalPages); // 是否可导航
    final IconData icon =
        isPrevious ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios; // 图标
    final String label = isPrevious ? '上一页' : '下一页'; // 标签
    final String pageInfo = isPrevious // 页码信息
        ? '(${_currentPage - 1}/$_totalPages)'
        : '(${_currentPage + 1}/$_totalPages)';
    final VoidCallback? action = (_isLoadingGameData || !canNavigate) // 动作回调
        ? null
        : (isPrevious
            ? () {
                _goToPreviousPageInternal();
              }
            : () {
                _goToNextPageInternal();
              });

    return AspectRatio(
      aspectRatio: cardRatio, // 宽高比
      child: Opacity(
        opacity: action != null ? 1.0 : 0.5, // 透明度
        child: Card(
          clipBehavior: Clip.antiAlias, // 裁剪行为
          margin: const EdgeInsets.all(4), // 外边距
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)), // 形状
          child: InkWell(
            onTap: action, // 点击回调
            borderRadius: BorderRadius.circular(12), // 圆角
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
              children: [
                Icon(icon,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary), // 图标
                const SizedBox(height: 4), // 间距
                Text(
                  label, // 标签文本
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary), // 样式
                  maxLines: 1, // 最大行数
                  overflow: TextOverflow.ellipsis, // 溢出显示省略号
                ),
                const SizedBox(height: 2), // 间距
                Text(
                  pageInfo, // 页码信息文本
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withSafeOpacity(0.7)), // 样式
                  maxLines: 1, // 最大行数
                  overflow: TextOverflow.ellipsis, // 溢出显示省略号
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建空状态组件。
  Widget _buildEmptyState() {
    String message; // 消息
    Widget? actionButton; // 动作按钮

    if (_currentCategory != null) {
      // 当前有分类筛选时
      message = '没有找到分类为 “$_currentCategory” 的游戏';
      actionButton = FunctionalButton(
          onPressed: _isLoadingGameData ? null : _clearCategoryFilter, // 点击清除分类
          label: '查看全部游戏',
          icon: Icons.list_alt);
    } else if (_currentTag != null) {
      // 当前有标签筛选时
      message = '没有找到标签为 “$_currentTag” 的游戏';
      actionButton = FunctionalButton(
          onPressed: _isLoadingGameData ? null : _clearTagFilter, // 点击清除标签
          label: '查看全部游戏',
          icon: Icons.list_alt);
    } else {
      // 无筛选时
      message = '这里还没有游戏呢';
      actionButton = FunctionalButton(
          onPressed: _isLoadingGameData ? null : _handleAddGame, // 点击添加游戏
          label: '添加一个游戏',
          icon: Icons.add);
    }

    return EmptyStateWidget(
      iconData: Icons.videogame_asset_off_outlined, // 图标
      message: message, // 消息
      action: actionButton, // 动作按钮
    );
  }

  /// 构建悬浮动作按钮组。
  Widget? _buildFabGroup() {
    if (_isLoadingGameData) return null; // 加载时不显示

    return FloatingActionButtonGroup(
      toggleButtonHeroTag: '${_ctxScreen}_heroTags',
      children: widget.authProvider.isLoggedIn
          ? _addGameFab()
          : _toLoginFab(), // 根据登录状态显示不同按钮组
    );
  }

  String _makeHeroTag(String mainCtx) => '${_ctxScreen}_${_isDesktop}_$mainCtx';

  /// 构建添加游戏悬浮动作按钮组。
  List<Widget> _addGameFab() {
    return [
      GenericFloatingActionButton(
        onPressed: _handleAddGame, // 点击添加游戏
        icon: AppBarAction.addGame.icon,
        tooltip: '添加游戏',
        heroTag: _makeHeroTag('add'),
      ),
      GenericFloatingActionButton(
        onPressed: () =>
            NavigationUtils.pushNamed(context, AppRoutes.myGames), // 点击导航到我的游戏
        icon: AppBarAction.myGames.icon,
        tooltip: '我的游戏',
        heroTag: _makeHeroTag('my'),
      ),
    ];
  }

  /// 构建登录提示悬浮动作按钮组。
  List<Widget> _toLoginFab() {
    return [
      GenericFloatingActionButton(
        onPressed: () => NavigationUtils.navigateToLogin(context), // 点击导航到登录页
        icon: Icons.login,
        tooltip: '登录后可以添加游戏',
        heroTag: _makeHeroTag('login'),
      )
    ];
  }

  /// 构建悬浮分页控件（如果需要）。
  Widget? _buildFloatingPaginationControlsIfNeeded() {
    if (!_isInitialized) {
      return null; // 未初始化时不显示
    }
    if (_isLoadingGameData) {
      return const LoadingWidget();
    }
    return PaginationControls(
      currentPage: _currentPage, // 当前页码
      totalPages: _totalPages, // 总页数
      isLoading: _isLoadingGameData, // 是否加载中
      onPreviousPage: _goToPreviousPageInternal, // 上一页回调
      onNextPage: _goToNextPageInternal, // 下一页回调
      onPageSelected: _goToPage, // 页码选择回调
    );
  }
}
