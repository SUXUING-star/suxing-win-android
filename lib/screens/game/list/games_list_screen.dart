import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/tag/tag.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/game/game_service.dart'; // Correct path
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // Your Dialog
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // Correct widget
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // Correct widget
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/check/admin_check.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/tag/tag_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:visibility_detector/visibility_detector.dart';
// *** Import Desktop Panels ***
import 'package:suxingchahui/widgets/components/screen/gamelist/panel/game_left_panel.dart';
import 'package:suxingchahui/widgets/components/screen/gamelist/panel/game_right_panel.dart';

/// Displays a paginated list of games, inspired by ForumScreen's state management.
class GamesListScreen extends StatefulWidget {
  final String? selectedTag;

  const GamesListScreen({Key? key, this.selectedTag}) : super(key: key);

  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

// Add WidgetsBindingObserver mixin
class _GamesListScreenState extends State<GamesListScreen>
    with WidgetsBindingObserver {
  final GameService _gameService = GameService();

  // --- State Variables ---
  bool _isLoadingData =
      false; // Master loading flag for API calls/forced refresh
  bool _isInitialized = false; // Has the initial load attempt been made?
  bool _isVisible = false; // Is the widget currently visible on screen?
  bool _needsRefresh = false; // Should refresh on next visibility/resume?
  String? _errorMessage;
  bool _showMobileTagBar = false;
  // Desktop Panel Visibility State
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  List<Game> _gamesList = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _currentSortBy = 'createTime';
  bool _isDescending = true;
  String? _currentTag;
  List<Tag> _availableTags = [];

  StreamSubscription<BoxEvent>? _cacheSubscription;
  String _currentWatchIdentifier = '';
  Timer? _refreshDebounceTimer;

  static const int _pageSize = 10;
  static const Duration _cacheDebounceDuration =
      Duration(milliseconds: 300); // Slightly longer debounce
  final Map<String, String> _sortOptions = {
    'createTime': '最新发布',
    'viewCount': '最多浏览',
    'rating': '最高评分'
  };
  // Panel Width Thresholds
  static const double _hideRightPanelThreshold = 1000.0;
  static const double _hideLeftPanelThreshold = 800.0;

  // === Lifecycle ===
  @override
  void initState() {
    super.initState();
    _currentTag = widget.selectedTag;
    WidgetsBinding.instance.addObserver(this);
    _loadTags();
    // Initial load triggered by VisibilityDetector
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchingCache();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_needsRefresh && _isVisible) {
        _refreshDataIfNeeded(reason: "App Resumed with NeedsRefresh");
        _needsRefresh = false;
      } else if (_isVisible) {
        _refreshDataIfNeeded(reason: "App Resumed");
      }
    } else if (state == AppLifecycleState.paused) {
      _needsRefresh = true;
    }
  }

  // === Data Loading & Cache ===
  Future<void> _loadTags() async {
    try {
      final tags = await _gameService.getAllTags();
      if (mounted) setState(() => _availableTags = tags);
    } catch (e) {
      if (mounted) setState(() => _availableTags = []);
    }
  }

  /// Core data loading function. Handles concurrency and state updates. **(Complete)**
  Future<void> _loadGames(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    if (!mounted || _isLoadingData) return; // Mount check and Concurrency check

    _isInitialized = true; // Mark that an attempt to load has been made

    final bool isFullReload = isRefresh || isInitialLoad || _currentPage == 1;

    setState(() {
      // Set loading state
      _isLoadingData = true; // Set master loading flag
      _errorMessage = null; // Clear previous error
      // *** IMPORTANT: Clear list ONLY on INITIAL load to show full page loading ***
      // On refresh/filter, keep old data visible while _isLoadingData is true.
      if (isInitialLoad) {
        _gamesList = [];
      }
    });

    try {
      Map<String, dynamic> result;
      if (_currentTag != null) {
        result = await _gameService.getGamesByTagWithInfo(
            tag: _currentTag!,
            page: _currentPage,
            pageSize: _pageSize,
            sortBy: _currentSortBy,
            descending: _isDescending);
      } else {
        result = await _gameService.getGamesPaginatedWithInfo(
            page: _currentPage,
            pageSize: _pageSize,
            sortBy: _currentSortBy,
            descending: _isDescending);
      }

      if (!mounted) return;

      final games = result['games'] as List<Game>? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      final int serverPage = pagination['page'] ?? _currentPage;
      final int serverTotalPages = pagination['totalPages'] ?? _totalPages;

      setState(() {
        // Update state on success
        _gamesList = games; // Replace list with new data
        _currentPage = serverPage;
        _totalPages = serverTotalPages;
        _errorMessage = null; // Clear error on success
      });
      _startOrUpdateWatchingCache();
    } catch (e) {
      if (mounted) {
        // Update state on error
        setState(() {
          _errorMessage = '加载失败，请稍后重试。';
          // Clear list and reset pagination ONLY if initial load failed
          if (isInitialLoad) {
            _gamesList = [];
            _currentPage = 1;
            _totalPages = 1;
          }
          // On refresh/filter/pagination error, keep existing list data and show error?
          // Let's keep the existing data and show error via SnackBar or maybe an error overlay later.
          // For now, just setting the error message. The main content area will decide what to show.
        });
      }
      _stopWatchingCache();
    } finally {
      if (mounted) {
        // Reset loading state
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// Starts/Updates cache listener. **(Complete)**
  void _startOrUpdateWatchingCache() {
    final String newWatchIdentifier =
        "${_currentTag ?? 'all'}_${_currentPage}_${_currentSortBy}_$_isDescending";
    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) return;
    _stopWatchingCache();
    _currentWatchIdentifier = newWatchIdentifier;
    try {
      _cacheSubscription = _gameService
          .watchGameListPageChanges(
        tag: _currentTag,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
        scope: _currentTag != null ? 'tag' : 'all',
      )
          .listen((BoxEvent event) {
        if (_isVisible) {
          _refreshDataIfNeeded(reason: "Cache Change");
        } else {
          _needsRefresh = true;
        }
      },
              onError: (e, s) => _stopWatchingCache(),
              onDone: () => _stopWatchingCache(),
              cancelOnError: true);
    } catch (e) {
      _currentWatchIdentifier = '';
    }
  }

  /// Stops cache listener. **(Complete)**
  void _stopWatchingCache() {
    _cacheSubscription?.cancel();
    _cacheSubscription = null;
  }

  /// Debounced refresh trigger. **(Complete)**
  void _refreshDataIfNeeded({required String reason}) {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      if (mounted && _isVisible && !_isLoadingData) {
        _loadGames(isRefresh: true);
      } else if (mounted && !_isVisible) {
        _needsRefresh = true;
      }
    });
  }

  /// Triggers the very first load attempt. **(Complete)**
  void _triggerInitialLoad() {
    if (!_isInitialized && !_isLoadingData) {
      _loadGames(isInitialLoad: true);
    }
  }

  // === User Interactions ===

  /// Handles pull-to-refresh. **(Complete)**
  Future<void> _refreshData() async {
    _stopWatchingCache();
    setState(() {
      _currentPage = 1;
      _errorMessage = null;
    });
    await _loadGames(isRefresh: true);
  }

  /// Handles previous page navigation. **(Complete)**
  Future<void> _goToPreviousPage() async {
    if (_currentPage > 1 && !_isLoadingData) {
      _stopWatchingCache();
      setState(() => _currentPage--);
      await _loadGames();
    }
  }

  /// Handles next page navigation. **(Complete)**
  Future<void> _goToNextPage() async {
    if (_currentPage < _totalPages && !_isLoadingData) {
      _stopWatchingCache();
      setState(() => _currentPage++);
      await _loadGames();
    }
  }

  /// Shows filter/sort dialog. **(Complete)**
  void _showFilterDialog(BuildContext context) {
    String? tempSelectedTag = _currentTag;
    String tempSortBy = _currentSortBy;
    bool tempDescending = _isDescending;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('筛选与排序'),
              contentPadding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        ..._availableTags.map((tag) =>
                            DropdownMenuItem<String?>(
                                value: tag.name,
                                child: Text('${tag.name} (${tag.count})'))),
                      ],
                      onChanged: (String? newValue) =>
                          setDialogState(() => tempSelectedTag = newValue),
                    ),
                    const SizedBox(height: 16),
                    Text('排序方式:',
                        style: Theme.of(context).textTheme.titleMedium),
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
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _applyTagAndSort(
                        tempSelectedTag, tempSortBy, tempDescending);
                  },
                  child: const Text('应用'),
                )
              ],
            );
          },
        );
      },
    );
  }

  /// Builds sort option tile for the dialog. **(Complete)**
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
      selectedTileColor: Colors.grey.withOpacity(0.1),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: () {
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
              onPressed: () => onChanged(sortField, false),
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
              onPressed: () => onChanged(sortField, true),
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  /// Applies filter/sort and triggers refresh. **(Complete)**
  void _applyTagAndSort(String? newTag, String newSortBy, bool newDescending) {
    bool tagChanged = _currentTag != newTag;
    bool sortChanged =
        _currentSortBy != newSortBy || _isDescending != newDescending;
    if (tagChanged || sortChanged) {
      _stopWatchingCache();
      setState(() {
        _currentTag = newTag;
        _currentSortBy = newSortBy;
        _isDescending = newDescending;
        _currentPage = 1;
        _errorMessage = null;
      });
      _loadGames(isRefresh: true);
    }
  }

  /// Handles mobile TagBar selection. **(Complete)**
  void _handleTagBarSelected(String? tag) {
    final newTag = (_currentTag == tag) ? null : tag;
    if (_currentTag != newTag) {
      _applyTagAndSort(newTag, _currentSortBy, _isDescending);
    }
  }

  /// Handles delete action (using your original onConfirm logic). **(Complete)**
  Future<void> _handleDeleteGame(String gameId) async {
    await CustomConfirmDialog.show(
      context: context,
      title: '确认删除',
      message: '确定要删除这个游戏吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever,
      iconColor: Colors.red,
      onConfirm: () async {
        try {
          await _gameService.deleteGame(gameId);
          if (mounted) AppSnackBar.showSuccess(context, '游戏已删除，列表将自动刷新');
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除失败: $e');
        }
      },
    );
  }

  /// Handles add action. **(Complete)**
  void _handleAddGame() {
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((result) {
      if (result == true && mounted) {
        _refreshDataIfNeeded(reason: "Add Game Completed");
      }
    });
  }

  /// Toggles Desktop Left Panel. **(Complete)**
  void _toggleLeftPanel() => setState(() => _showLeftPanel = !_showLeftPanel);

  /// Toggles Desktop Right Panel. **(Complete)**
  void _toggleRightPanel() =>
      setState(() => _showRightPanel = !_showRightPanel);

  // === Build Methods ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: VisibilityDetector(
        key: const ValueKey('games_list_visibility_detector'),
        onVisibilityChanged: (visibilityInfo) {
          final double visibleFraction = visibilityInfo.visibleFraction;
          final bool nowVisible = visibleFraction > 0.1;
          if (mounted) {
            if (nowVisible && !_isVisible) {
              _isVisible = true;
              if (!_isInitialized) {
                _triggerInitialLoad();
              } else if (_needsRefresh) {
                _refreshDataIfNeeded(
                    reason: "Became Visible with NeedsRefresh");
                _needsRefresh = false;
              } else if (_gamesList.isEmpty &&
                  _errorMessage == null &&
                  !_isLoadingData) {
                _loadGames(isRefresh: true);
              }
            } else if (!nowVisible && _isVisible) {
              _isVisible = false;
              _stopWatchingCache();
              _refreshDebounceTimer?.cancel();
            }
          }
        },
        child: _buildBodyContent(),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  /// Builds the AppBar. **(Complete)**
  PreferredSizeWidget _buildAppBar() {
    final isDesktop = DeviceUtils.isDesktop;
    final title = _currentTag != null ? '标签: $_currentTag' : '游戏列表';
    final theme = Theme.of(context);
    final appBarColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final iconColor =
        ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final secondaryColor = theme.colorScheme.secondary;
    final screenWidth = MediaQuery.of(context).size.width;
    final canShowLeftPanelBasedOnWidth = screenWidth >= _hideLeftPanelThreshold;
    final canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold;

    return CustomAppBar(
      title: title,
      actions: [
        if (isDesktop)
          IconButton(
            icon: Icon(Icons.menu_open,
                color: _showLeftPanel && canShowLeftPanelBasedOnWidth
                    ? secondaryColor
                    : iconColor),
            tooltip: _showLeftPanel ? '隐藏左侧面板' : '显示左侧面板',
            onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
          ),
        if (isDesktop)
          IconButton(
            icon: Icon(Icons.bar_chart_outlined,
                color: _showRightPanel && canShowRightPanelBasedOnWidth
                    ? secondaryColor
                    : iconColor),
            tooltip: _showRightPanel ? '隐藏右侧面板' : '显示右侧面板',
            onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
          ),
        AdminCheck(
            child: IconButton(
          icon: Icon(Icons.add, color: iconColor),
          onPressed: _handleAddGame,
          tooltip: '添加游戏',
        )),
        IconButton(
          icon: Icon(Icons.history_edu, color: iconColor),
          onPressed: () =>
              NavigationUtils.pushNamed(context, AppRoutes.myGames),
          tooltip: '我的提交',
        ),
        IconButton(
          icon: Icon(Icons.search, color: iconColor),
          onPressed: () =>
              NavigationUtils.pushNamed(context, AppRoutes.searchGame),
          tooltip: '搜索游戏',
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: iconColor),
          onPressed: () => _showFilterDialog(context),
          tooltip: '筛选与排序',
        ),
        if (_currentTag != null)
          IconButton(
            icon: Icon(Icons.clear, color: iconColor),
            onPressed: () =>
                _applyTagAndSort(null, _currentSortBy, _isDescending),
            tooltip: '清除标签筛选',
          ),
        if (!isDesktop)
          IconButton(
            icon: Icon(Icons.tag,
                color: _showMobileTagBar ? secondaryColor : iconColor),
            onPressed: () =>
                setState(() => _showMobileTagBar = !_showMobileTagBar),
            tooltip: _showMobileTagBar ? '隐藏标签栏' : '显示标签栏',
          ),
      ],
      bottom: (!isDesktop && _showMobileTagBar && _availableTags.isNotEmpty)
          ? TagBar(
              tags: _availableTags,
              selectedTag: _currentTag,
              onTagSelected: _handleTagBarSelected,
            )
          : null,
    );
  }

  /// Builds the main body content, handling desktop/mobile layouts. **(Complete)**
  Widget _buildBodyContent() {
    final isDesktop = DeviceUtils.isDesktop;
    final screenWidth = MediaQuery.of(context).size.width;
    // Determine if panels *should* be shown based on state and screen width
    final bool shouldShowLeftPanel =
        isDesktop && _showLeftPanel && (screenWidth >= _hideLeftPanelThreshold);
    final bool shouldShowRightPanel = isDesktop &&
        _showRightPanel &&
        (screenWidth >= _hideRightPanelThreshold);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Stack(
        children: [
          // --- Build Desktop or Mobile Layout ---
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shouldShowLeftPanel)
                      GameLeftPanel(
                        tags: _availableTags,
                        selectedTag: _currentTag,
                        onTagSelected: _handleTagBarSelected,
                      ),
                    Expanded(
                      child: _buildMainContentArea(
                          isDesktop, shouldShowLeftPanel, shouldShowRightPanel),
                    ), // Pass panel state
                    // Show Right Panel only if enabled, width allows, AND we have data (or loading initial data)
                    if (shouldShowRightPanel &&
                        (_isInitialized || _gamesList.isNotEmpty))
                      GameRightPanel(
                        currentPageGames: _gamesList,
                        totalGamesCount: _totalPages * _pageSize,
                        selectedTag: _currentTag,
                        onTagSelected: _handleTagBarSelected,
                      ),
                  ],
                )
              : Column(
                  children: [
                    // Mobile Layout
                    Expanded(
                      child: _buildMainContentArea(isDesktop, false, false),
                    ), // No panels on mobile
                  ],
                ),

          // --- Pagination Controls (Overlay - Style Restored) ---
          if (_totalPages > 1)
            Align(
              alignment: Alignment.bottomCenter,
              // *** Restore original padding structure ***
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
                child: PaginationControls(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  isLoading: _isLoadingData, // Disable buttons during any load
                  onPreviousPage: _isLoadingData ? null : _goToPreviousPage,
                  onNextPage: _isLoadingData ? null : _goToNextPage,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the central content area (loading, error, empty, or grid). **(Complete with correct widgets)**
  Widget _buildMainContentArea(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    // 1. Initial Loading State (Before first load attempt completes)
    //    If _isInitialized is false, show initial loading.
    if (!_isInitialized) {
      // Use Inline Loading, positioned by parent (RefreshIndicator/Row/Column)
      return LoadingWidget.inline(message: '正在加载游戏...');
    }

    // 2. Loading State (Subsequent loads/refreshes/pagination)
    //    If data loading is in progress, show loading overlay *over* existing grid OR show inline loading if list is empty.
    //    Let's refine the logic: Always show the grid structure (or empty/error if needed) and overlay loading when _isLoadingData is true.
    //    The overlay logic is now handled within the Stack returned by this method if data exists.
    //    If loading AND list is empty (could be initial load error retry or refresh error) show inline error/loading.

    // 3. Error State (Show inline error only if list is empty after load attempt)
    if (_errorMessage != null && _gamesList.isEmpty && !_isLoadingData) {
      // Added !_isLoadingData check
      // Use Inline Error, positioned by parent
      return InlineErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: () => _loadGames(isRefresh: true),
      );
    }

    // 4. Empty State (Loaded successfully, no error, but list is empty)
    //    CRITICAL: Check !_isLoadingData here! Only show empty state when not actively loading.
    if (!_isLoadingData && _errorMessage == null && _gamesList.isEmpty) {
      return _buildEmptyState(); // Already centered
    }

    // 5. Content State (Display the grid)
    //    This covers: Data loaded, Refreshing (loading overlay handles indicator), Paginating (loading overlay handles indicator)
    return Stack(
      children: [
        _buildGameGrid(
            isDesktop, showLeftPanel, showRightPanel), // The main game grid

        // --- Loading Overlay for Refreshes/Filters ---
        // Show overlay IF loading is active AND we already have some data to show underneath
        if (_isLoadingData && _gamesList.isNotEmpty)
          Positioned.fill(
            child: LoadingWidget.inline(message: '加载中...'),
          ),

        // --- Loading Indicator when loading initial page or empty list ---
        // Show inline loading IF loading is active AND the list is currently empty
        // This covers the initial load scenario correctly now.
        if (_isLoadingData && _gamesList.isEmpty && _errorMessage == null)
          LoadingWidget.inline(message: '正在加载游戏...'),
      ],
    );
  }

  /// Builds the GridView of game cards. **(Complete)**
  Widget _buildGameGrid(
      bool isDesktop, bool showLeftPanel, bool showRightPanel) {
    // 1. 判断是否处于有面板的桌面模式
    final bool withPanels = isDesktop && (showLeftPanel || showRightPanel);

    // 2. 计算每行卡片数
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(context,
        withPanels: withPanels, // 传递是否有面板的状态
        leftPanelVisible: showLeftPanel, // 传递左面板状态
        rightPanelVisible: showRightPanel // 传递右面板状态
    );
    if (cardsPerRow <= 0) return InlineErrorWidget(errorMessage: "无法计算布局");

    // 3. 决定是否强制使用紧凑模式
    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);

    // 4. 计算卡片宽高比
    //    根据是否有面板，调用不同的 DeviceUtils 方法
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio( // 调用带面板的计算
        context, showLeftPanel, showRightPanel,
        showTags: true) // 假设游戏列表总是显示标签
        : DeviceUtils.calculateSimpleCardRatio(context, showTags: true); // 调用无面板的计算

    // 5. 构建 GridView
    return LayoutBuilder(builder: (context, constraints) {
      // 使用 ValueKey 包含关键变量，以便在布局变化时重建 Grid
      return GridView.builder(
        key: ValueKey('game_grid_content_${_gamesList.length}_${cardsPerRow}_${cardRatio.toStringAsFixed(2)}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            8.0, 8.0, 8.0, 80.0 + MediaQuery.of(context).padding.bottom), // 底部留出分页控件空间
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow,      // 使用计算出的每行数量
          childAspectRatio: cardRatio,     // 使用计算出的宽高比
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8, // 桌面行间距大一点
        ),
        itemCount: _gamesList.length,
        itemBuilder: (context, index) {
          final game = _gamesList[index];
          return BaseGameCard(
            key: ValueKey(game.id),
            game: game,
            isGridItem: true,
            adaptForPanels: withPanels, // 传递给卡片，让卡片内部可能也自适应
            showTags: true,
            showCollectionStats: true,
            forceCompact: useCompactMode, // 强制紧凑模式
            maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2), // 紧凑或有面板时少显示标签
            onDeleteAction: () => _handleDeleteGame(game.id),
          );
        },
      );
    });
  }

  /// Builds the empty state widget. **(Complete)**
  Widget _buildEmptyState() {
    String message =
        _currentTag != null ? '没有找到标签为 “$_currentTag” 的游戏' : '这里还没有游戏呢';
    // *** Remove const ***
    return EmptyStateWidget(
      iconData: Icons.videogame_asset_off_outlined,
      message: message,
      action: _currentTag != null
          ? FunctionalButton(
              onPressed: () =>
                  _applyTagAndSort(null, _currentSortBy, _isDescending),
              label: '查看全部游戏',
              icon: Icons.list_alt,
            )
          : null,
    );
  }

  /// Builds the Floating Action Button. **(Complete)**
  Widget? _buildFab() {
    return AdminCheck(
      child: GenericFloatingActionButton(
        onPressed: _handleAddGame,
        icon: Icons.add,
        tooltip: '添加游戏',
        heroTag: 'games_list_fab',
      ),
    );
  }
} // End of _GamesListScreenState
