import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:suxingchahui/constants/common/app_bar_actions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/tag/tag.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/game/game_service.dart'; // Correct path
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart';
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/tag/tag_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/panel/game_left_panel.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/panel/game_right_panel.dart';

class GamesListScreen extends StatefulWidget {
  final String? selectedTag;
  final AuthProvider authProvider;
  final GameService gameService;
  final GameListFilterProvider gameListFilterProvider;

  const GamesListScreen({
    super.key,
    this.selectedTag,
    required this.authProvider,
    required this.gameService,
    required this.gameListFilterProvider,
  });

  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen>
    with WidgetsBindingObserver {
  bool _isLoadingData = false;
  bool _isInitialized = false;
  bool _isVisible = false;
  bool _needsRefresh = false;
  bool _hasInitializedDependencies = false;
  String? _errorMessage;
  bool _showMobileTagBar = false;
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  List<Game> _gamesList = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _currentSortBy = 'createTime';
  bool _isDescending = true;
  String? _currentTag;
  String? _currentUserId;
  String? _currentCategory;
  // 直接上升为生命周期管控内部状态变量，不要写为可空的变量！！！！！！！！

  List<Tag> _availableTags = [];
  final List<String> _availableCategories = GameConstants.defaultGameCategory;
  StreamSubscription<BoxEvent>? _cacheSubscription;
  String _currentWatchIdentifier = '';
  Timer? _refreshDebounceTimer;
  Timer? _checkProviderDebounceTimer;
  static const int _pageSize = GameService.gamesLimit;
  static const Duration _cacheDebounceDuration = Duration(milliseconds: 1000);
  static const Duration _checkProviderDebounceDuration =
      Duration(milliseconds: 500);
  final Map<String, String> _sortOptions = GameConstants.defaultFilter;
  static const double _hideRightPanelThreshold = 1000.0;
  static const double _hideLeftPanelThreshold = 800.0;

  bool _isPerformingRefresh = false; // 标记是否正在执行下拉刷新操作
  DateTime? _lastRefreshAttemptTime; // 上次尝试下拉刷新的时间戳
  // 定义最小刷新间隔 (1 分钟)
  static const Duration _minRefreshInterval = Duration(minutes: 1);

  // === Lifecycle ===
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 不需要在这里赋值服务和provider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      // 初始化 _currentTag
      _currentUserId = widget.authProvider.currentUserId;
    }
  }

  @override
  void didUpdateWidget(covariant GamesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != widget.authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
    if (widget.selectedTag != oldWidget.selectedTag) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchingCache();
    _refreshDebounceTimer?.cancel();
    _checkProviderDebounceTimer?.cancel();
    super.dispose();
    // 不需要dispose内部监听的provider和服务状态变量自己会被gc掉
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_currentUserId != widget.authProvider.currentUserId) {
        if (mounted) {
          setState(() {
            _currentUserId = widget.authProvider.currentUserId;
          });
        }
      }
      if (_isVisible) {
        // 页面当前可见
        _checkProviderAndApplyFilterIfNeeded(
            reason: "App Resumed"); // 检查 Provider

        _refreshDataIfNeeded(reason: "App Resumed"); // 刷新当前页数据
      } else {
        _needsRefresh = true; // 标记，等可见时刷新
      }
    } else if (state == AppLifecycleState.paused) {
      _needsRefresh = true; // 可选：离开时标记需要刷新
    }
  }

  void _initializeCurrentTag() {
    final initialProviderTag = widget.gameListFilterProvider.selectedTag;
    final tagWasSet = widget.gameListFilterProvider.tagHasBeenSet;
    _currentTag = tagWasSet ? initialProviderTag : widget.selectedTag;
  }

  // === 可视处理 ===
  void _handleVisibilityChange(VisibilityInfo visibilityInfo) {
    // 使用一个稍微宽松的阈值，避免快速切换时误判
    final bool nowVisible = visibilityInfo.visibleFraction > 0;

    if (widget.authProvider.currentUserId != _currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
    if (!mounted) return; // 组件已卸载，不处理
    if (nowVisible && !_isVisible) {
      _isVisible = true;
      // 1. 检查 Provider 是否有新的 tag 指令
      _checkProviderAndApplyFilterIfNeeded(reason: "Became Visible");

      // 2. 处理加载逻辑
      if (!_isInitialized) {
        _initializeCurrentTag();
        _loadTags(); // 异步加载可用标签列表
        // 初始加载使用当前的 _currentTag (可能已被 _checkProvider 更新)
        _loadGames(pageToFetch: 1, isInitialLoad: true);
      } else if (_needsRefresh) {
        _refreshDataIfNeeded(reason: "Became Visible with NeedsRefresh");

        _needsRefresh = false;
      } else {
        // 确保缓存监听器在监听当前状态
        _startOrUpdateWatchingCache();
      }
    } else if (!nowVisible && _isVisible) {
      _isVisible = false;
      _stopWatchingCache(); // 页面隐藏时停止监听缓存
      _refreshDebounceTimer?.cancel(); // 取消可能存在的刷新定时器
    }
  }

// === 检查provider是否需要更新内部状态 ===
  void _checkProviderAndApplyFilterIfNeeded({required String reason}) {
    _checkProviderDebounceTimer?.cancel(); // 取消上一个计时器（如果存在）
    _checkProviderDebounceTimer = Timer(_checkProviderDebounceDuration, () {
      if (!mounted) return; // 确保 Widget 仍然挂载

      final providerTag = widget.gameListFilterProvider.selectedTag;
      final providerCategory = widget.gameListFilterProvider.selectedCategory;
      final tagWasSet = widget.gameListFilterProvider.tagHasBeenSet;
      final categoryWasSet = widget.gameListFilterProvider.categoryHasBeenSet;

      if (tagWasSet && !categoryWasSet && providerTag != _currentTag) {
        _applyFilterAndSort(
            tag: providerTag,
            category: null,
            sortBy: _currentSortBy,
            descending: _isDescending);
        widget.gameListFilterProvider.resetTagFlag();
      } else if (tagWasSet && providerTag == _currentTag) {
        // 即使 tag 相同，如果 provider 标记被设置过，也应该重置
        widget.gameListFilterProvider.resetTagFlag();
      }

      if (categoryWasSet &&
          !tagWasSet &&
          providerCategory != _currentCategory) {
        _applyFilterAndSort(
            tag: null,
            category: providerCategory,
            sortBy: _currentSortBy,
            descending: _isDescending);
        widget.gameListFilterProvider.resetCategoryFlag();
      } else if (categoryWasSet && providerCategory == _currentCategory) {
        // 即使 category 相同，如果 provider 标记被设置过，也应该重置
        widget.gameListFilterProvider.resetCategoryFlag();
      }
    });
  }

  // === 加载标签 ===
  Future<void> _loadTags() async {
    try {
      final tags = await widget.gameService.getAllTags();
      if (mounted) setState(() => _availableTags = tags);
    } catch (e) {
      if (mounted) {
        setState(() => _availableTags = []);
      }
    }
  }

  /// === 加载游戏数据 ===
  Future<void> _loadGames({
    int? pageToFetch, // 目标页码
    bool isInitialLoad = false,
    bool isRefresh = false,
    bool forceRefresh = false,
  }) async {
    if (!mounted || _isLoadingData) return;

    final int targetPage = pageToFetch ?? 1;

    if (targetPage < 1 ||
        (!isInitialLoad &&
            !isRefresh &&
            _totalPages > 1 &&
            targetPage > _totalPages)) {
      return;
    }

    _isInitialized = true;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      if (isRefresh || isInitialLoad) {
        _gamesList = [];
      }
    });

    try {
      Map<String, dynamic> result;
      if (_currentCategory != null) {
        // *** 优先检查分类 ***
        result = await widget.gameService.getGamesByCategoryWithInfo(
          categoryName: _currentCategory!, // 使用分类 API
          page: targetPage,
          pageSize: _pageSize,
          sortBy: _currentSortBy,
          descending: _isDescending,
          forceRefresh: forceRefresh,
        );
      } else if (_currentTag != null) {
        result = await widget.gameService.getGamesByTagWithInfo(
          tag: _currentTag!,
          page: targetPage,
          pageSize: _pageSize,
          sortBy: _currentSortBy,
          descending: _isDescending,
          forceRefresh: forceRefresh,
        );
      } else {
        // *** 最后是默认分页 ***
        result = await widget.gameService.getGamesPaginatedWithInfo(
          page: targetPage,
          pageSize: _pageSize,
          sortBy: _currentSortBy,
          descending: _isDescending,
          forceRefresh: forceRefresh,
        );
      }

      if (!mounted) return;

      final games = result['games'] as List<Game>? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      final int serverPage = pagination['page'] ?? targetPage;
      final int serverTotalPages = pagination['totalPages'] ?? 1;

      setState(() {
        _gamesList = games;
        _currentPage = serverPage;
        _totalPages = serverTotalPages;
        _errorMessage = null;
        if (!_isInitialized) _isInitialized = true;
      });

      _startOrUpdateWatchingCache(); // 监听当前页
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败，请稍后重试。';
          if (isRefresh || isInitialLoad) {
            _gamesList = [];
            _currentPage = 1;
            _totalPages = 1;
          }
        });
      }
      _stopWatchingCache();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// 开始监听缓存
  void _startOrUpdateWatchingCache() {
    // 确定当前的筛选类型和值
    final String filterType;
    final String? filterValue;
    if (_currentCategory != null) {
      filterType = 'category';
      filterValue = _currentCategory;
    } else if (_currentTag != null) {
      filterType = 'tag';
      filterValue = _currentTag;
    } else {
      filterType = 'all';
      filterValue = null; // 或者 'none'
    }
    final String newWatchIdentifier =
        "${filterType}_${filterValue ?? 'none'}_${_currentPage}_${_currentSortBy}_$_isDescending";

    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      return; // 已经在监听同一个状态
    }
    _stopWatchingCache();
    _currentWatchIdentifier = newWatchIdentifier;
    try {
      _cacheSubscription = widget.gameService
          .watchGameListPageChanges(
        tag: _currentTag,
        categoryName: _currentCategory,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
        scope: _currentTag != null ? 'tag' : 'all',
      )
          .listen((BoxEvent event) {
        if (_isVisible) {
          _refreshDataIfNeeded(reason: "Cache Change on page $_currentPage");
        } else {
          _needsRefresh = true;
        }
      }, onError: (e, s) {
        _stopWatchingCache();
      }, onDone: () {
        _stopWatchingCache();
      }, cancelOnError: true);
    } catch (e) {
      _currentWatchIdentifier = '';
    }
  }

  /// 停止监听
  void _stopWatchingCache() {
    if (_cacheSubscription != null) {
      _cacheSubscription?.cancel();
      _cacheSubscription = null;
      _currentWatchIdentifier = '';
    }
  }

  /// 防抖刷新
  void _refreshDataIfNeeded({required String reason}) {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      if (mounted && _isVisible && !_isLoadingData) {
        _loadGames(pageToFetch: 1, isRefresh: true);
      } else if (mounted && !_isVisible) {
        _needsRefresh = true;
      }
    });
  }

  // === User Interactions ===

  /// 刷新主逻辑
  Future<void> _refreshData({bool needCheck = true}) async {
    // 1. 防止重复触发：如果已经在执行下拉刷新，直接返回
    if (_isPerformingRefresh) {
      return;
    }
    // 2. 检查时间间隔
    final now = DateTime.now();
    if (needCheck) {
      if (_lastRefreshAttemptTime != null &&
          now.difference(_lastRefreshAttemptTime!) < _minRefreshInterval) {
        // 可以给用户一个提示
        if (mounted) {
          AppSnackBar.showWarning(context,
              '刷新太频繁啦，请 ${(_minRefreshInterval.inSeconds - now.difference(_lastRefreshAttemptTime!).inSeconds)} 秒后再试');
        }
        return; // 时间不够，直接返回
      }
    }

    // 3. 时间足够 或 首次刷新 -> 执行刷新逻辑

    if (mounted) {
      setState(() {
        _isPerformingRefresh = true; // 开始下拉刷新
      });
    }
    _lastRefreshAttemptTime = now; // 记录本次尝试刷新的时间

    try {
      // --- 原有的刷新逻辑 ---
      if (_isLoadingData) {
        return; // 如果其他数据加载正在进行，也阻止（虽然 _isPerformingRefresh 应该已经挡住了）
      }
      _stopWatchingCache();
      await _loadGames(
          pageToFetch: 1, isRefresh: true, forceRefresh: true); // 加载第一页并标记为刷新
      // --- 刷新逻辑结束 ---
    } catch (e) {
      // print("下拉刷新执行过程中发生错误: $e");
      // 可以在这里处理 specific refresh 错误
    } finally {
      // 4. 清除刷新状态标记 (无论成功失败)
      if (mounted) {
        setState(() {
          _isPerformingRefresh = false; // 结束下拉刷新
        });
        // print("节流 (GameList): 下拉刷新操作完成 (finally)");
      }
    }
  }

  /// 前一页
  Future<void> _goToPreviousPageInternal() async {
    if (_currentPage > 1 && !_isLoadingData) {
      // print("导航到上一页 (目标: ${_currentPage - 1})");
      _stopWatchingCache();
      await _loadGames(pageToFetch: _currentPage - 1); // 加载上一页
    } else {
      //
      AppSnackBar.showWarning(context, "已经是第一页了");
    }
  }

  /// 下一页
  Future<void> _goToNextPageInternal() async {
    if (_currentPage < _totalPages && !_isLoadingData) {
      _stopWatchingCache();
      await _loadGames(pageToFetch: _currentPage + 1); // 加载下一页
    } else {
      //
      AppSnackBar.showWarning(context, "已经是最后一页了了");
    }
  }

  /// 指定页数
  Future<void> _goToPage(int pageNumber) async {
    if (pageNumber >= 1 &&
        pageNumber <= _totalPages &&
        pageNumber != _currentPage &&
        !_isLoadingData) {
      _stopWatchingCache();
      await _loadGames(pageToFetch: pageNumber);
    } else if (pageNumber == _currentPage && mounted) {
    } else if (!_isLoadingData && mounted) {
    } else if (_isLoadingData) {}
  }

  /// 显示筛选
  void _showFilterDialog(BuildContext context) async {
    // 改为 async
    // 1. 在调用 show 之前定义临时状态变量
    String? tempSelectedTag = _currentTag;
    String? tempSelectedCategory = _currentCategory;
    String tempSortBy = _currentSortBy;
    bool tempDescending = _isDescending;

    // 2. 调用 BaseInputDialog.show<bool> (返回 bool 表示是否确认)
    final confirmed = await BaseInputDialog.show<bool>(
      context: context,
      title: '筛选与排序',
      confirmButtonText: '应用',
      // 3. contentBuilder 包含 StatefulBuilder 来管理临时状态
      contentBuilder: (dialogContext) {
        // 使用 StatefulBuilder 使得对话框内部的内容可以局部刷新
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              // 确保内容可滚动
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('按分类筛选:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: tempSelectedCategory, // 使用临时变量
                    hint: const Text('所有分类'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('所有分类')),
                      ..._availableCategories
                          .map((category) => DropdownMenuItem<String?>(
                              // 使用常量
                              value: category,
                              child: Text(category))),
                    ],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        tempSelectedCategory = newValue;
                        if (newValue != null) {
                          tempSelectedTag = null; // *** 选择分类时，清除临时标签 ***
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('按标签筛选:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: tempSelectedTag, // 使用临时变量
                    hint: const Text('所有标签'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('所有标签')),
                      ..._availableTags.map((tag) => DropdownMenuItem<String?>(
                          value: tag.name,
                          child: Text('${tag.name} (${tag.count})'))),
                    ],
                    onChanged: (String? newValue) => setDialogState(
                        () => tempSelectedTag = newValue), // 更新临时变量
                  ),
                  const SizedBox(height: 16),
                  Text('排序方式:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  // 注意: 这里传递的是临时变量和更新临时变量的回调
                  ..._sortOptions.entries.map((entry) => _buildSortOptionTile(
                        title: entry.value,
                        sortField: entry.key,
                        currentSortBy: tempSortBy, // 传临时变量
                        isDescending: tempDescending, // 传临时变量
                        onChanged: (field, desc) {
                          setDialogState(() {
                            // 更新临时变量
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
      // 4. onConfirm 确认时返回 true
      onConfirm: () async {
        // 确认按钮按下，表示用户希望应用更改
        // 不需要在这里做复杂的逻辑，直接返回 true 即可关闭对话框
        return true; // 返回非 null 值表示确认成功，对话框将关闭
      },
      // 可选: 添加图标等
      iconData: Icons.filter_list_alt,
    );

    // 5. 对话框关闭后，如果用户点击了 "应用" (confirmed == true)
    if (confirmed == true && mounted) {
      // 使用更新后的临时变量调用应用逻辑
      _handleFilterDialogConfirm(
          tempSelectedCategory, tempSelectedTag, tempSortBy, tempDescending);
    }
  }
  // UI 构建

  /// 筛选
  Widget _buildSortOptionTile({
    required String title,
    required String sortField,
    required String currentSortBy,
    required bool isDescending,
    required Function(String, bool) onChanged,
  }) {
    final bool isSelected = currentSortBy == sortField;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
      selected: isSelected,
      selectedTileColor: Colors.grey.withSafeOpacity(0.1),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: () {
        // onTap 是 VoidCallback
        if (!isSelected) onChanged(sortField, true);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_upward),
              iconSize: 20,
              color: isSelected && !isDescending
                  ? colorScheme.secondary
                  : Colors.grey,
              tooltip: '升序',
              onPressed: () =>
                  onChanged(sortField, false), // onPressed 是 VoidCallback
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero),
          IconButton(
              icon: const Icon(Icons.arrow_downward),
              iconSize: 20,
              color: isSelected && isDescending
                  ? colorScheme.secondary
                  : Colors.grey,
              tooltip: '降序',
              onPressed: () =>
                  onChanged(sortField, true), // onPressed 是 VoidCallback
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  /// 应用筛选（标签或分类）和排序，并触发刷新
  void _applyFilterAndSort(
      {String? tag, // 要应用的标签 (null 表示不按标签筛选)
      String? category, // <<< 新增：要应用的分类 (null 表示不按分类筛选)
      required String sortBy, // 排序字段
      required bool descending // 是否降序
      }) {
    // 确定新的筛选状态，并强制互斥
    String? finalTag = tag;
    String? finalCategory = category;

    if (finalCategory != null && finalTag != null) {
      finalTag = null; // *** 优先分类，清除标签 ***
    }

    // 检查状态是否真的改变了
    bool categoryChanged = _currentCategory != finalCategory;
    bool tagChanged = _currentTag != finalTag;
    bool sortChanged = _currentSortBy != sortBy || _isDescending != descending;

    if (categoryChanged || tagChanged || sortChanged) {
      _stopWatchingCache(); // 停止旧监听
      setState(() {
        // 更新内部状态
        _currentCategory = finalCategory; // <<< 更新分类状态
        _currentTag = finalTag; // <<< 更新标签状态 (可能是 null)
        _currentSortBy = sortBy;
        _isDescending = descending;
        // 重置分页和错误信息
        _currentPage = 1;
        _totalPages = 1;
        _errorMessage = null;
        _gamesList = []; // 清空列表
      });
      _loadGames(pageToFetch: 1, isRefresh: true); // 触发第一页加载
    } else {}
  }

  void _clearTagFilter() {
    // 清除标签，保持当前分类（如果选择了的话）
    _applyFilterAndSort(
        tag: null, // <<< 清除标签
        category: _currentCategory, // <<< 保持分类
        sortBy: _currentSortBy,
        descending: _isDescending);
    // *** Provider 只处理 Tag ***
    widget.gameListFilterProvider.clearTag(); // 更新 Provider 状态为 null
    widget.gameListFilterProvider.resetTagFlag(); // 标记处理完成
  }

  // 清除分类筛选的处理
  void _clearCategoryFilter() {
    // 清除分类，保持当前标签（如果选择了的话）
    _applyFilterAndSort(
        tag: _currentTag, // <<< 保持标签
        category: null, // <<< 清除分类
        sortBy: _currentSortBy,
        descending: _isDescending);
    // Category 状态只在本地，不需要更新 Provider
  }

  // 筛选对话框确认
  void _handleFilterDialogConfirm(String? newCategory, String? newTag,
      String newSortBy, bool newDescending) {
    // 1. 调用 apply 函数更新页面状态并触发加载
    _applyFilterAndSort(
      category: newCategory, // 传递分类
      tag: newTag, // 传递标签
      sortBy: newSortBy,
      descending: newDescending,
    );
    // 2. 同步更新 Provider 状态
    if (widget.gameListFilterProvider.selectedTag != newTag) {
      widget.gameListFilterProvider.setTag(newTag);
    }
    if (widget.gameListFilterProvider.selectedCategory != newCategory) {
      widget.gameListFilterProvider.setCategory(newCategory);
    }
    // 3. 因为是页面内部操作触发，立即重置标志位
    widget.gameListFilterProvider.resetTagFlag();
  }

  // <<< 新增：处理左右面板或未来可能的分类选择器点击 >>>
  void _handleCategorySelected(String? category) {
    final newCategory = (_currentCategory == category) ? null : category;
    // 选择分类时，清除当前标签筛选
    _applyFilterAndSort(
        tag: null, // <<< 清除标签
        category: newCategory, // <<< 应用新分类
        sortBy: _currentSortBy,
        descending: _isDescending);
    if (_currentTag != null) {
      widget.gameListFilterProvider.clearTag();
      widget.gameListFilterProvider.resetTagFlag();
    }
  }

  // 移动端 TagBar 选择
  void _handleTagBarSelected(String? tag) {
    final newTag = (_currentTag == tag) ? null : tag; // 点击相同 tag 则取消
    // 1. 调用 apply 函数更新页面状态并触发加载
    _applyFilterAndSort(
        tag: newTag,
        category: null,
        sortBy: _currentSortBy,
        descending: _isDescending);
    // 2. 同步更新 Provider 状态
    if (widget.gameListFilterProvider.selectedTag != newTag) {
      widget.gameListFilterProvider.setTag(newTag);
    }
    // 3. 因为是页面内部操作触发，立即重置标志位
    widget.gameListFilterProvider.resetTagFlag();
  }

  /// 删除游戏回调
  Future<void> _handleDeleteGame(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeleteGame(game)) {
      AppSnackBar.showPermissionDenySnackBar(context);
      return;
    }
    await CustomConfirmDialog.show(
      context: context,
      title: '确认删除',
      message: '确定要删除这个游戏吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever,
      iconColor: Colors.red,
      onConfirm: () async {
        // onConfirm 是 AsyncCallback?
        try {
          await widget.gameService.deleteGame(game);
          // 刷新由 cache watcher 触发
          if (!mounted) return;
          AppSnackBar.showSuccess(context, "成功删除游戏");
        } catch (e) {
          AppSnackBar.showError(context, "删除游戏失败");
          // print("删除游戏失败: $gameId, Error: $e");
        }
      },
    );
  }

  // 权限检查
  bool _checkCanEditOrDeleteGame(Game game) {
    return widget.authProvider.isAdmin
        ? true
        : widget.authProvider.currentUserId == game.authorId;
  }

  // 处理编辑按钮点击事件
  Future<void> _handleEditGame(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeleteGame(game)) {
      AppSnackBar.showPermissionDenySnackBar(context);
      return;
    }

    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game.id);
    if (result == true && mounted) {
      _refreshDataIfNeeded(reason: "Edited Game"); // 触发刷新
    }
  }

  /// 添加游戏
  void _handleAddGame() {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((result) {
      if (result == true && mounted) {
        _refreshDataIfNeeded(reason: "Add Game Completed"); // 触发刷新
      }
    });
  }

  void _toggleLeftPanel() => setState(() => _showLeftPanel = !_showLeftPanel);

  void _toggleRightPanel() =>
      setState(() => _showRightPanel = !_showRightPanel);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // AppBar 不包含跳页按钮
      body: VisibilityDetector(
        key: const ValueKey('games_list_visibility_detector'),
        onVisibilityChanged: _handleVisibilityChange,
        child: _buildBodyContent(),
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar:
          _buildFloatingPaginationControlsIfNeeded(), // <--- 构建悬浮分页控件
    );
  }

  /// Builds the AppBar. (移除了跳页按钮)
  PreferredSizeWidget _buildAppBar() {
    final isDesktop = DeviceUtils.isDesktop;
    String title = '游戏列表';

    if (_currentCategory != null) {
      title = '分类: $_currentCategory';
    } else if (_currentTag != null) {
      title = '标签: $_currentTag';
    }
    final theme = Theme.of(context);
    final appBarColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    final screenWidth = MediaQuery.of(context).size.width;
    final canShowLeftPanelBasedOnWidth = screenWidth >= _hideLeftPanelThreshold;
    final canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold;
    final defaultAppBarIconColor =
        ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return CustomAppBar(
      title: title,
      actions: [
        if (isDesktop) SizedBox(width: 8),
        if (isDesktop)
          FunctionalIconButton(
            buttonBackgroundColor: AppBarAction.toggleLeftPanel.defaultBgColor,
            icon: AppBarAction.toggleLeftPanel.icon,
            iconColor: _showLeftPanel && canShowLeftPanelBasedOnWidth
                ? Colors.black38
                : Colors.amber,
            tooltip: _showLeftPanel ? '隐藏左侧面板' : '显示左侧面板',
            onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
          ),
        if (isDesktop) SizedBox(width: 8),
        if (isDesktop)
          FunctionalIconButton(
            buttonBackgroundColor: AppBarAction.toggleRightPanel.defaultBgColor,
            icon: AppBarAction.toggleRightPanel.icon,
            iconColor: _showRightPanel && canShowRightPanelBasedOnWidth
                ? Colors.black38
                : Colors.amber,
            tooltip: _showRightPanel ? '隐藏右侧面板' : '显示右侧面板',
            onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
          ),
        SizedBox(width: 8),
        // 业务逻辑有审核机制
        // 不需要admincheck
        FunctionalIconButton(
          icon: AppBarAction.addGame.icon,
          tooltip: AppBarAction.addGame.defaultTooltip!,
          iconColor: AppBarAction.addGame.defaultIconColor,
          buttonBackgroundColor: AppBarAction.addGame.defaultBgColor,
          onPressed: _isLoadingData ? null : _handleAddGame,
        ),
        SizedBox(width: 8),
        FunctionalIconButton(
          icon: AppBarAction.myGames.icon,
          tooltip: AppBarAction.myGames.defaultTooltip!,
          iconColor: AppBarAction.myGames.defaultIconColor,
          buttonBackgroundColor: AppBarAction.myGames.defaultBgColor,
          onPressed: _isLoadingData
              ? null
              : () => NavigationUtils.pushNamed(context, AppRoutes.myGames),
        ),
        SizedBox(width: 8),
        FunctionalIconButton(
          icon: AppBarAction.searchGame.icon,
          tooltip: AppBarAction.searchGame.defaultTooltip!,
          iconColor: AppBarAction.searchGame.defaultIconColor,
          buttonBackgroundColor: AppBarAction.searchGame.defaultBgColor,
          onPressed: _isLoadingData
              ? null
              : () => NavigationUtils.pushNamed(context, AppRoutes.searchGame),
        ),
        SizedBox(width: 8),
        FunctionalIconButton(
          icon: AppBarAction.filterSort.icon,
          tooltip: AppBarAction.filterSort.defaultTooltip!,
          iconColor: AppBarAction.filterSort.defaultIconColor,
          buttonBackgroundColor: AppBarAction.filterSort.defaultBgColor,
          onPressed: _isLoadingData ? null : () => _showFilterDialog(context),
        ),
        // 清除分类按钮
        if (_currentCategory != null) SizedBox(width: 8),
        if (_currentCategory != null)
          IconButton(
            icon: Icon(AppBarAction.clearCategoryFilter.icon),
            color: AppBarAction.clearCategoryFilter.defaultIconColor,
            onPressed: _isLoadingData ? null : _clearCategoryFilter,
            tooltip: '清除分类筛选 ($_currentCategory)',
          ),
        if (_currentTag != null) SizedBox(width: 8),
        if (_currentTag != null)
          IconButton(
            icon: Icon(AppBarAction.clearTagFilter.icon),
            color: AppBarAction.clearTagFilter.defaultIconColor,
            onPressed: _isLoadingData ? null : _clearTagFilter,
            tooltip: '清除标签筛选 ($_currentTag)',
          ),
        if (!isDesktop) SizedBox(width: 8),
        if (!isDesktop)
          IconButton(
            icon: Icon(AppBarAction.toggleMobileTagBar.icon),
            tooltip: _showMobileTagBar ? '隐藏标签栏' : '显示标签栏',
            color: _showMobileTagBar ? secondaryColor : defaultAppBarIconColor,
            onPressed: () =>
                setState(() => _showMobileTagBar = !_showMobileTagBar),
          ),
      ],
      bottom: (!DeviceUtils.isDesktop &&
              _showMobileTagBar &&
              _availableTags.isNotEmpty)
          ? TagBar(
              tags: _availableTags,
              selectedTag: _currentTag, // 使用内部状态
              onTagSelected: _handleTagBarSelected, // 调用新的处理函数
            )
          : null,
    );
  }

  /// Builds the main body content.
  Widget _buildBodyContent() {
    final isDesktop = DeviceUtils.isDesktop;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool shouldShowLeftPanel =
        isDesktop && _showLeftPanel && (screenWidth >= _hideLeftPanelThreshold);
    final bool shouldShowRightPanel = isDesktop &&
        _showRightPanel &&
        (screenWidth >= _hideRightPanelThreshold);
    const Duration panelAnimationDuration = Duration(milliseconds: 300);
    const Duration leftPanelDelay = Duration(milliseconds: 50);
    const Duration rightPanelDelay = Duration(milliseconds: 100);

    return RefreshIndicator(
      onRefresh: () =>
          _refreshData(needCheck: true), // onRefresh 需要 Future<void> Function()
      child: Stack(
        children: [
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shouldShowLeftPanel)
                      FadeInSlideLRItem(
                        key: const ValueKey('game_list_left_panel'),
                        slideDirection: SlideDirection.left,
                        duration: panelAnimationDuration,
                        delay: leftPanelDelay,
                        child: GameLeftPanel(
                          tags: _availableTags,
                          selectedTag: _currentTag,
                          onTagSelected: _isLoadingData
                              ? (String? tag) {}
                              : _handleTagBarSelected, // onTagSelected 需要 Function(String?)?
                        ),
                      ),
                    Expanded(
                      child: _buildMainContentArea(
                          isDesktop, shouldShowLeftPanel, shouldShowRightPanel),
                    ),
                    if (shouldShowRightPanel &&
                        (_isInitialized || _gamesList.isNotEmpty))
                      FadeInSlideLRItem(
                        key: const ValueKey('game_list_right_panel'),
                        slideDirection: SlideDirection.right,
                        duration: panelAnimationDuration,
                        delay: rightPanelDelay,
                        child: GameRightPanel(
                          currentPageGames: _gamesList,
                          totalGamesCount: _totalPages * _pageSize,
                          selectedTag: _currentTag,
                          onTagSelected: _isLoadingData
                              ? null
                              : _handleTagBarSelected, // onTagSelected 需要 Function(String?)?
                          selectedCategory: _currentCategory,
                          availableCategories: _availableCategories,
                          onCategorySelected:
                              _isLoadingData ? null : _handleCategorySelected,
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: _buildMainContentArea(isDesktop, false, false),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// Builds the central content area (loading, error, empty, or grid).
  Widget _buildMainContentArea(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    if (!_isInitialized) {
      return FadeInItem(child: LoadingWidget.fullScreen(message: '正在加载游戏...'));
    }

    if (_errorMessage != null && _gamesList.isEmpty && !_isLoadingData) {
      return CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: () {
          _loadGames(pageToFetch: 1, isRefresh: true);
        }, // onRetry 是 VoidCallback?
      );
    }

    if (!_isLoadingData && _errorMessage == null && _gamesList.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        _buildGameGridWithNavigation(isDesktop, showLeftPanel, showRightPanel),
        if (_isLoadingData && _gamesList.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(240),
              child: LoadingWidget.inline(message: '加载中...'),
            ),
          ),
        if (_isLoadingData && _gamesList.isEmpty && _errorMessage == null)
          LoadingWidget.inline(message: '正在加载游戏...'),
      ],
    );
  }

  /// Builds the GridView with In-Grid Navigation Tiles.
  Widget _buildGameGridWithNavigation(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    final bool withPanels = isDesktop && (showLeftPanel || showRightPanel);
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(context,
        withPanels: withPanels,
        leftPanelVisible: showLeftPanel,
        rightPanelVisible: showRightPanel);
    if (cardsPerRow <= 0) {
      //print("错误：计算出的每行卡片数为 $cardsPerRow");
      return CustomErrorWidget(errorMessage: "无法计算布局 (cardsPerRow <= 0)");
    }
    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio(
            context, showLeftPanel, showRightPanel,
            showTags: true)
        : DeviceUtils.calculateSimpleCardRatio(context, showTags: true);
    if (cardRatio <= 0) {
      //print("错误：计算出的卡片宽高比为 $cardRatio");
      return const CustomErrorWidget(errorMessage: "发生异常错误");
    }

    int totalItemCount = _gamesList.length;
    final bool showPrevTile = _currentPage > 1 && _totalPages > 1;
    final bool showNextTile = _currentPage < _totalPages;

    if (_gamesList.isNotEmpty ||
        (_isLoadingData && (_isInitialized || _currentPage == 1))) {
      if (showPrevTile) totalItemCount++;
      if (showNextTile) totalItemCount++;
    }

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        key: ValueKey(
            'game_grid_page_${_currentPage}_count_${_gamesList.length}_total_$totalItemCount'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0), // 底部留白
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
        ),
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          int gameIndex = index;
          bool isPrevTileRender = false;
          bool isNextTileRender = false;

          if (showPrevTile && index == 0) {
            isPrevTileRender = true;
          } else if (showPrevTile) {
            gameIndex = index - 1;
          }
          if (showNextTile && index == totalItemCount - 1) {
            isNextTileRender = true;
          }

          if (isPrevTileRender) {
            return _buildNavigationTile(isPrevious: true, cardRatio: cardRatio);
          } else if (isNextTileRender) {
            return _buildNavigationTile(
                isPrevious: false, cardRatio: cardRatio);
          } else {
            if (gameIndex < 0 || gameIndex >= _gamesList.length) {
              return const SizedBox.shrink();
            }
            final game = _gamesList[gameIndex];
            final animationDelayIndex = gameIndex % _pageSize;

            return FadeInSlideUpItem(
              key: ValueKey(game.id),
              delay: Duration(milliseconds: animationDelayIndex * 50),
              child: BaseGameCard(
                currentUser: widget.authProvider.currentUser,
                game: game,
                isGridItem: true,
                adaptForPanels: withPanels,
                showTags: true,
                showCollectionStats: true,
                forceCompact: useCompactMode,
                maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2),
                // 当加载中传递空回调，即使加载成功(加载成功后是false)如果没有权限也传递空回调
                onDeleteAction:
                    _isLoadingData && !_checkCanEditOrDeleteGame(game)
                        ? null
                        : () {
                            _handleDeleteGame(game);
                          }, // onDeleteAction 是 VoidCallback?
                onEditAction: _isLoadingData && !_checkCanEditOrDeleteGame(game)
                    ? null
                    : () => _handleEditGame(game),
              ),
            );
          }
        },
      );
    });
  }

  /// Builds a navigation tile (Previous or Next).
  Widget _buildNavigationTile(
      {required bool isPrevious, required double cardRatio}) {
    final bool canNavigate =
        isPrevious ? (_currentPage > 1) : (_currentPage < _totalPages);
    final IconData icon =
        isPrevious ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios;
    final String label = isPrevious ? '上一页' : '下一页';
    final String pageInfo = isPrevious
        ? '(${_currentPage - 1}/$_totalPages)'
        : '(${_currentPage + 1}/$_totalPages)';
    // --- 修正: 定义 action 为 VoidCallback? 并使用函数体 ---
    final VoidCallback? action = (_isLoadingData || !canNavigate)
        ? null
        : (isPrevious
            ? () {
                _goToPreviousPageInternal();
              }
            : () {
                _goToNextPageInternal();
              });

    return AspectRatio(
      aspectRatio: cardRatio,
      child: Opacity(
        opacity: action != null ? 1.0 : 0.5,
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: action, // onTap 是 VoidCallback?
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 24, color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  pageInfo,
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withSafeOpacity(0.7)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state widget. (Corrected onPressed)
  Widget _buildEmptyState() {
    String message;
    Widget? actionButton;

    // --- vv 修改空状态消息和按钮 vv ---
    if (_currentCategory != null) {
      message = '没有找到分类为 “$_currentCategory” 的游戏';
      actionButton = FunctionalButton(
          onPressed: _isLoadingData ? null : _clearCategoryFilter, // <<< 清除分类
          label: '查看全部游戏',
          icon: Icons.list_alt);
    } else if (_currentTag != null) {
      message = '没有找到标签为 “$_currentTag” 的游戏';
      actionButton = FunctionalButton(
          onPressed: _isLoadingData ? null : _clearTagFilter, // <<< 清除标签
          label: '查看全部游戏',
          icon: Icons.list_alt);
    } else {
      message = '这里还没有游戏呢';
      actionButton = FunctionalButton(
          onPressed: _isLoadingData ? null : _handleAddGame,
          label: '添加一个游戏',
          icon: Icons.add);
    }

    return EmptyStateWidget(
      iconData: Icons.videogame_asset_off_outlined,
      message: message,
      action: actionButton,
    );
  }

  /// Builds the Floating Action Button.
  Widget? _buildFab() {
    if (_isLoadingData) return null; // 加载时不显示

    return widget.authProvider.isLoggedIn ? _addGameFab() : _toLoginFab();
  }

  Widget _addGameFab() {
    return GenericFloatingActionButton(
      onPressed: _handleAddGame, // onPressed 是 VoidCallback?
      icon: Icons.add,
      tooltip: '添加游戏',
      heroTag: 'games_list_fab',
    );
  }

  Widget _toLoginFab() {
    return GenericFloatingActionButton(
      onPressed: () =>
          NavigationUtils.navigateToLogin(context), // onPressed 是 VoidCallback?
      icon: Icons.login,
      tooltip: '登录后可以添加游戏',
      heroTag: 'login_frm_games_list_fab',
    );
  }

  /// Builds the floating pagination controls if needed.
  Widget? _buildFloatingPaginationControlsIfNeeded() {
    // 关键逻辑：只有在初始化完成并且总页数大于1时才需要显示分页控件
    // PaginationControls 组件内部会处理 totalPages <= 1 的情况，所以这里主要判断是否初始化
    if (!_isInitialized) {
      return null; // 初始化完成前不显示任何东西
    }

    // 直接使用你提供的 PaginationControls 组件
    return PaginationControls(
      currentPage: _currentPage,
      totalPages: _totalPages,
      isLoading: _isLoadingData,
      onPreviousPage: _goToPreviousPageInternal,
      onNextPage: _goToNextPageInternal,
      onPageSelected: _goToPage, // 当用户在下拉框选择页码时，调用 _goToPage
    );
  }
}
