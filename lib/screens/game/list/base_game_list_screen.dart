// lib/screens/game/base_game_list_screen.dart
import 'dart:async'; // Timer for potential future use, or remove if truly unused

import 'package:flutter/material.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:visibility_detector/visibility_detector.dart'; // Lazy loading library
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../models/game/game.dart';
import '../../../models/tag/tag.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/check/admin_check.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/components/screen/gamelist/tag/tag_bar.dart';
import '../../../widgets/components/screen/gamelist/panel/game_left_panel.dart';
import '../../../widgets/components/screen/gamelist/panel/game_right_panel.dart';
import '../../../widgets/components/loading/loading_route_observer.dart'; // For optional global loading indicator
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class BaseGameListScreen extends StatefulWidget {
  final String title;
  // Function signature updated: no isLoadMore parameter needed
  final Future<List<Game>> Function(String? selectedTag) loadGamesFunction;
  final Future<void> Function()?
      refreshFunction; // Optional external refresh logic
  final void Function(Game game)? onItemTap;
  final bool showTagSelection;
  final String? selectedTag;
  final bool showSortOptions;
  final bool showAddButton;
  final Widget? emptyStateIcon;
  final String emptyStateMessage;
  // enablePagination removed as scroll pagination logic is deleted
  final bool showPanelToggles;
  final bool useScaffold;
  final List<Widget>? additionalActions;
  final Function(BuildContext)?
      onFilterPressed; // Callback for sort/filter button
  final Function()?
      onMySubmissionsPressed; // Callback for my submissions button
  final Function()? onAddPressed; // Callback for add button (FAB or AppBar)
  final bool showAddButtonInAppBar;
  final bool showMySubmissionsButton;
  final Widget Function(Game)?
      customCardBuilder; // Optional custom card builder

  const BaseGameListScreen({
    Key? key, // Accept key from parent
    required this.title,
    required this.loadGamesFunction, // Use updated signature
    this.refreshFunction,
    this.onItemTap,
    this.showTagSelection = false,
    this.selectedTag,
    this.showSortOptions = false,
    this.showAddButton = false,
    this.emptyStateIcon,
    required this.emptyStateMessage,
    this.showPanelToggles = false,
    this.useScaffold = true,
    this.additionalActions,
    this.onFilterPressed,
    this.onMySubmissionsPressed,
    this.onAddPressed,
    this.showAddButtonInAppBar = false,
    this.showMySubmissionsButton = false,
    this.customCardBuilder,
  }) : super(key: key); // Pass key to StatefulWidget

  @override
  _BaseGameListScreenState createState() => _BaseGameListScreenState();
}

class _BaseGameListScreenState extends State<BaseGameListScreen> {
  final GameService _gameService = GameService();
  // ScrollController and scrollDebounce removed

  // Data State
  List<Game> _games = [];
  List<Tag> _topTags = [];
  String? _errorMessage;
  String? _selectedTag;

  // UI Control State
  bool _showTagFilter = false; // Mobile tag bar toggle
  bool _showLeftPanel = true; // User's preference for left panel
  bool _showRightPanel = true; // User's preference for right panel

  // Loading & Cache State
  DateTime? _lastLoadTime; // For potential cache logic if needed later
  static const Duration _minRefreshInterval =
      Duration(minutes: 1); // Example cache duration

  // --- Lazy Loading Core State ---
  bool _isInitialized = false; // Has the initial load completed?
  bool _isVisible = false; // Is the widget currently visible?
  bool _isLoading = false; // Is a load operation (initial/refresh) in progress?
  // isLoadingMore removed

  // Layout Thresholds (unchanged)
  static const double _hideRightPanelThreshold = 1000.0;
  static const double _hideLeftPanelThreshold = 800.0;

  @override
  void initState() {
    super.initState();
    _selectedTag =
        widget.selectedTag; // Initialize selected tag from widget property

    // Load tags if needed (usually small data, can load upfront)
    if (widget.showTagSelection) {
      _loadTopTags();
    }

    // Scroll listener removed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No initial load here
  }

  @override
  void dispose() {
    // Scroll related cleanup removed
    super.dispose();
  }

  // --- Core: Trigger Initial Data Load ---
  void _triggerInitialLoad() {
    // Only execute if visible and not yet initialized
    if (_isVisible && !_isInitialized) {
      print(
          "BaseGameListScreen (${widget.title}): Now visible and not initialized. Triggering initial load.");
      _isInitialized = true; // Mark as initialized to prevent re-triggering
      // Call the simplified _loadGames, marking it as the initial load
      _loadGames(isInitialLoad: true);
      // Also load tags if needed and not already loaded
      if (widget.showTagSelection && _topTags.isEmpty) {
        _loadTopTags();
      }
    } else {
      // Optional: log why it didn't trigger
      // print("BaseGameListScreen (${widget.title}): Visibility changed, but conditions not met for initial load (isVisible: $_isVisible, isInitialized: $_isInitialized).");
    }
  }

  // --- Load Game Data (Core Method - Simplified) ---
  Future<void> _loadGames(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    // Prevent concurrent loads (except for refresh)
    if (_isLoading && !isRefresh) {
      return;
    }
    // Prevent loading if not initialized (unless triggered by initial load or refresh)
    if (!_isInitialized && !isInitialLoad && !isRefresh) {
      return;
    }

    if (!mounted) return; // Check if widget is still in the tree

    // Set loading state
    setState(() {
      _isLoading = true; // Start loading indicator
      _errorMessage = null; // Clear previous errors
      // Clear list for visual feedback on refresh or initial load
      if (isRefresh || isInitialLoad) {
        _games = [];
      }
    });

    // (Optional) Show global loading indicator via Observer
    LoadingRouteObserver? loadingObserver;
    try {
      loadingObserver = Navigator.of(context)
          .widget
          .observers
          .whereType<LoadingRouteObserver>()
          .firstOrNull;
      loadingObserver?.showLoading();
    } catch (e) {
      print("Error showing loading observer: $e");
    }

    try {
      // --- Call the external function provided by the parent (e.g., GamesListScreen) ---
      // It's responsible for fetching data for the current state (page, tag, sort)
      final List<Game> newGames = await widget.loadGamesFunction(_selectedTag);

      if (!mounted) return; // Re-check after async operation

      // Update last load time (useful for potential future cache checks)
      _lastLoadTime = DateTime.now();

      // Update UI state with the new data
      setState(() {
        // Always replace the list, as pagination is handled externally
        _games = newGames; // Replace the games list
        _isLoading = false; // End loading state
      });
    } catch (e, s) {
      // Catch error and stack trace
      print(
          'BaseGameListScreen (${widget.title}): Load games error: $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载游戏失败: $e'; // Set error message
        _games = []; // Clear list on error
        _isLoading = false; // End loading state
      });
    } finally {
      // (Optional) Hide global loading indicator
      if (mounted) {
        loadingObserver?.hideLoading();
      }
    }
  }

  // --- Refresh Data ---
  Future<void> _refreshData() async {
    // Prevent refresh if already loading or unmounted
    if (!mounted || _isLoading) {
      return;
    }
    print("BaseGameListScreen (${widget.title}): Refresh triggered.");

    // Option 1: Use external refresh function if provided
    if (widget.refreshFunction != null) {
      print(
          "BaseGameListScreen (${widget.title}): Calling external refresh function.");
      setState(() => _isLoading = true); // Show loading state
      try {
        await widget.refreshFunction!(); // Execute external logic
        print(
            "BaseGameListScreen (${widget.title}): External refresh function finished.");
        // Assume external function handles state, or reset loading here if needed
        if (mounted) setState(() => _isLoading = false); // Ensure loading ends
      } catch (e) {
        print("External refresh failed: $e");
        if (mounted)
          setState(() {
            _errorMessage = "刷新失败: $e";
            _isLoading = false;
            _games = [];
          });
      }
    }
    // Option 2: Use internal default refresh logic
    else {
      print(
          "BaseGameListScreen (${widget.title}): Calling internal refresh logic.");
      _lastLoadTime = null; // Invalidate cache time marker

      // *** 改动: 使用 GameService 失效标签相关缓存 ***
      if (widget.showTagSelection && _selectedTag != null) {
        try {
          // 调用 GameService 的方法
          await _gameService.invalidateTagRelatedCaches([_selectedTag!]);
          print(
              "BaseGameListScreen (${widget.title}): Invalidated cache for tag '$_selectedTag'.");
        } catch (e) {
          print("Error invalidating tag cache via GameService: $e");
        }
      }

      // Call _loadGames marking it as a refresh action
      await _loadGames(isRefresh: true);
      // Optionally refresh tags as well
      if (widget.showTagSelection) {
        await _loadTopTags(); // 重新加载标签列表
      }
    }
  }

  // loadMoreGames method removed

  // onScroll method removed

  // --- Load Top Tags (unchanged logic) ---
  Future<void> _loadTopTags() async {
    if (!widget.showTagSelection) return;
    print("BaseGameListScreen (${widget.title}): Loading top tags...");
    try {
      // *** 改动: 使用 GameService 获取所有标签 ***
      final tags = await _gameService.getAllTags();
      if (!mounted) return;
      setState(() {
        // 限制数量的逻辑保持不变
        _topTags = tags.take(50).toList();
      });
    } catch (e) {}
  }

  // --- Handle Tag Selection ---
  void _onTagSelected(String tag) {
    if (!widget.showTagSelection) return;
    String? newTag = (_selectedTag == tag) ? null : tag; // Toggle selection

    if (_selectedTag != newTag) {
      print("BaseGameListScreen (${widget.title}): Tag selected: $newTag");
      // Reset state to force reload for the new tag/all games
      setState(() {
        _selectedTag = newTag;
        _isInitialized = false; // Mark as uninitialized for the new context
        _isVisible = false; // Reset visibility state
        _games = []; // Clear current game list
        _errorMessage = null; // Clear any previous error
        _isLoading = false; // Reset loading state
        // ScrollController related reset removed
      });
      print(
          "BaseGameListScreen (${widget.title}): State reset for new tag, waiting for visibility trigger.");
      // Use microtask to check visibility and trigger load *after* current build cycle
      // This often provides a better user experience than waiting strictly for the next scroll/visibility event
      Future.microtask(() {
        if (mounted && _isVisible) {
          _triggerInitialLoad(); // Try loading immediately if still visible
        }
      });
    }
  }

  // --- Clear Tag Selection ---
  void _clearTagSelection() {
    if (!widget.showTagSelection || _selectedTag == null) return;
    print("BaseGameListScreen (${widget.title}): Clearing tag selection.");
    // Reset state to force reload for all games
    setState(() {
      _selectedTag = null;
      _isInitialized = false; // Mark as uninitialized
      _isVisible = false; // Reset visibility
      _games = []; // Clear list
      _errorMessage = null; // Clear error
      _isLoading = false; // Reset loading
      // ScrollController related reset removed
    });
    print(
        "BaseGameListScreen (${widget.title}): State reset after clearing tag, waiting for visibility trigger.");
    // Use microtask to check visibility and trigger load
    Future.microtask(() {
      if (mounted && _isVisible) {
        _triggerInitialLoad(); // Try loading immediately if still visible
      }
    });
  }

  // --- UI Toggle Methods (unchanged logic) ---
  void _toggleTagFilter() {
    setState(() => _showTagFilter = !_showTagFilter);
  }

  void _toggleLeftPanel() {
    setState(() => _showLeftPanel = !_showLeftPanel);
  }

  void _toggleRightPanel() {
    setState(() => _showRightPanel = !_showRightPanel);
  }

  // --- Build AppBar Actions (Complete Implementation) ---
  List<Widget> _buildAppBarActions(
      bool isDesktop,
      bool showActualPanelToggles,
      bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel,
      bool canShowLeftPanelBasedOnWidth,
      bool canShowRightPanelBasedOnWidth) {
    final actions = <Widget>[];
    // Define colors for icons based on theme or explicitly
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.white54; // Example disabled color
    final Color enabledColor = Colors.white; // Example enabled color

    // Add any additional actions passed from the parent
    if (widget.additionalActions != null) {
      actions.addAll(widget.additionalActions!);
    }

    // Add Game Button (if configured for AppBar)
    if (widget.showAddButtonInAppBar) {
      actions.add(AdminCheck(
        // Optional: Wrap with permission check
        child: IconButton(
          icon: Icon(Icons.add, color: enabledColor),
          // Use provided callback or default navigation
          onPressed: widget.onAddPressed ??
              () => NavigationUtils.pushNamed(context, AppRoutes.addGame),
          tooltip: '添加游戏',
        ),
      ));
    }

    // My Submissions Button (if configured for AppBar)
    if (widget.showMySubmissionsButton) {
      actions.add(IconButton(
        icon: Icon(Icons.history_edu, color: enabledColor), // Example icon
        // Use provided callback or default navigation
        onPressed: widget.onMySubmissionsPressed ??
            () => NavigationUtils.pushNamed(
                context, AppRoutes.myGames), // Adjust route if needed
        tooltip: '我的提交',
      ));
    }

    // Search Button (Always shown in this example)
    actions.add(
      IconButton(
        icon: Icon(Icons.search, color: enabledColor),
        onPressed: () => NavigationUtils.pushNamed(
            context, AppRoutes.searchGame), // Adjust route if needed
        tooltip: '搜索游戏',
      ),
    );

    // Filter/Sort Button (if configured)
    if (widget.showSortOptions && widget.onFilterPressed != null) {
      actions.add(IconButton(
        icon: Icon(Icons.filter_list, color: enabledColor),
        onPressed: () =>
            widget.onFilterPressed!(context), // Call provided callback
        tooltip: '排序/筛选',
      ));
    }

    // Panel Toggle Buttons (Desktop only, if configured)
    if (showActualPanelToggles) {
      // Left Panel Toggle Button
      actions.add(IconButton(
        icon: Icon(
          Icons.menu_open, // Example icon
          // Color indicates state: secondary if shown, disabled if hidden but should be shown, enabled otherwise
          color: actuallyShowLeftPanel
              ? secondaryColor
              : (_showLeftPanel ? disabledColor : enabledColor),
        ),
        // Disable button if width doesn't allow panel
        onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
        tooltip: _showLeftPanel
            ? (canShowLeftPanelBasedOnWidth ? '隐藏左侧面板' : '屏幕宽度不足')
            : (canShowLeftPanelBasedOnWidth ? '显示左侧面板' : '屏幕宽度不足'),
      ));
      // Right Panel Toggle Button
      actions.add(IconButton(
        icon: Icon(
          Icons.analytics_outlined, // Example icon
          color: actuallyShowRightPanel
              ? secondaryColor
              : (_showRightPanel ? disabledColor : enabledColor),
        ),
        onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
        tooltip: _showRightPanel
            ? (canShowRightPanelBasedOnWidth ? '隐藏右侧面板' : '屏幕宽度不足')
            : (canShowRightPanelBasedOnWidth ? '显示右侧面板' : '屏幕宽度不足'),
      ));
    }

    // Clear Tag Button (only shown if a tag is selected)
    if (_selectedTag != null && widget.showTagSelection) {
      actions.add(IconButton(
        icon: Icon(Icons.clear, color: Colors.white), // Clear icon
        onPressed: _clearTagSelection, // Call clear function
        tooltip: '清除标签筛选',
      ));
    }

    // Mobile Tag Bar Toggle Button (Mobile only, if tags are enabled)
    if (!isDesktop && widget.showTagSelection) {
      actions.add(IconButton(
        icon: Icon(
          Icons.tag, // Tag icon
          // Color indicates if the tag bar is currently shown
          color: _showTagFilter ? secondaryColor : enabledColor,
        ),
        onPressed: _toggleTagFilter, // Call toggle function
        tooltip: _showTagFilter ? '隐藏标签栏' : '显示标签栏',
      ));
    }

    return actions; // Return the list of action widgets
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    // Wrap the entire content with VisibilityDetector for lazy loading
    return VisibilityDetector(
      // Use a unique key based on widget's key or title for state association
      key: ValueKey(
          'visibility_detector_${widget.key?.toString() ?? widget.title}'),
      // Callback when visibility changes
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        // Update state only if visibility actually changes
        if (currentlyVisible != _isVisible) {
          // Use microtask to ensure setState happens after build phase if needed
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _isVisible = currentlyVisible;
              });
            } else {
              _isVisible = currentlyVisible;
            } // Update variable even if unmounted

            // If widget just became visible, try to trigger initial load
            if (_isVisible) {
              _triggerInitialLoad();
            }
          });
        }
      },
      // Build the actual UI content based on state
      child: _buildActualContent(),
    );
  }

  // --- Build the Scaffold/AppBar/FAB Structure ---
  Widget _buildActualContent() {
    // Calculate layout parameters
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = DeviceUtils.isDesktop;
    final displayTitle = _selectedTag != null && widget.showTagSelection
        ? '标签: $_selectedTag'
        : widget.title;

    // Determine actual panel visibility based on settings, preferences, and width
    final bool panelsAreRelevant = isDesktop && widget.showTagSelection;
    final bool canShowLeftPanelBasedOnWidth =
        screenWidth >= _hideLeftPanelThreshold;
    final bool canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold;
    final bool actuallyShowLeftPanel =
        panelsAreRelevant && _showLeftPanel && canShowLeftPanelBasedOnWidth;
    final bool actuallyShowRightPanel =
        panelsAreRelevant && _showRightPanel && canShowRightPanelBasedOnWidth;
    final bool showActualPanelToggles =
        isDesktop && widget.showPanelToggles && widget.showTagSelection;

    // Build AppBar if using Scaffold
    final appBar = widget.useScaffold
        ? CustomAppBar(
            title: displayTitle,
            actions: _buildAppBarActions(
                isDesktop,
                showActualPanelToggles,
                actuallyShowLeftPanel,
                actuallyShowRightPanel,
                canShowLeftPanelBasedOnWidth,
                canShowRightPanelBasedOnWidth),
            // Mobile Tag Bar at the bottom of AppBar
            bottom: (!isDesktop &&
                    widget.showTagSelection &&
                    _showTagFilter &&
                    _topTags.isNotEmpty)
                ? TagBar(
                    tags: _topTags,
                    selectedTag: _selectedTag,
                    onTagSelected: _onTagSelected)
                : null,
          )
        : null;

    // Build FloatingActionButton if configured
    final floatingActionButton = widget.showAddButton && widget.useScaffold
        ? AdminCheck(
            // Optional permission check
            child: GenericFloatingActionButton(
              onPressed: widget.onAddPressed ??
                  () => NavigationUtils.pushNamed(context, AppRoutes.addGame),
              icon: Icons.add,
              tooltip: '添加游戏',
              backgroundColor: Colors.white, // Example styling
              foregroundColor:
                  Theme.of(context).colorScheme.primary, // Example styling
              // Use a unique heroTag to prevent conflicts across screens
              heroTag:
                  'base_game_list_fab_${widget.key?.toString() ?? widget.title}',
            ),
          )
        : null;

    // Determine the body content based on the current loading/error/data state
    final bodyContent = _buildBodyContent(
        isDesktop, actuallyShowLeftPanel, actuallyShowRightPanel);

    // Return the final structure (Scaffold or just the body)
    if (widget.useScaffold) {
      return Scaffold(
        appBar: appBar,
        body: bodyContent, // Use the determined body content
        floatingActionButton: floatingActionButton,
      );
    } else {
      // If not using Scaffold, return the body content directly
      // Ensure the body content handles its own layout (e.g., padding, centering)
      return bodyContent;
    }
  }

  // --- Build the Body Content Based on State ---
  Widget _buildBodyContent(
      bool isDesktop, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    // State 1: Not yet initialized (waiting for visibility or initial load failed silently)
    if (!_isInitialized && !_isLoading) {
      return _buildLoading("等待加载...");
    }
    // State 2: Loading initial data or refreshing, and list is currently empty
    else if (_isLoading && _games.isEmpty) {
      return _buildLoading("正在加载游戏...");
    }
    // State 3: Error occurred, and list is empty
    else if (_errorMessage != null && _games.isEmpty) {
      return _buildError(_errorMessage!);
    }
    // State 4: Data loaded (list might be populated or empty), or error occurred but list has old data
    else {
      // Show the main content list, wrapped in RefreshIndicator
      return RefreshIndicator(
        onRefresh: _refreshData, // Attach refresh handler
        // Build layout based on device type
        child: isDesktop
            ? _buildDesktopLayout(
                context, actuallyShowLeftPanel, actuallyShowRightPanel)
            : _buildMobileLayout(context),
      );
    }
  }

  // --- Build Desktop Layout (with Panels) ---
  Widget _buildDesktopLayout(BuildContext context, bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel) {
    // Row layout for Desktop
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align panels to the top
      children: [
        // Left Panel (conditionally rendered)
        if (actuallyShowLeftPanel)
          GameLeftPanel(
            // Assuming this widget exists and takes these parameters
            tags: _topTags,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),

        // Center Content Area (takes remaining space)
        Expanded(
          child: _buildContentList(
              // Call list builder
              isDesktop: true,
              actuallyShowLeftPanel: actuallyShowLeftPanel,
              actuallyShowRightPanel: actuallyShowRightPanel),
        ),

        // Right Panel (conditionally rendered)
        if (actuallyShowRightPanel)
          GameRightPanel(
            // Assuming this widget exists
            currentPageGames: _games, // Pass current games
            totalGamesCount:
                _games.length, // Placeholder for total count if available
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),
      ],
    );
  }

  // --- Build Mobile Layout (No Panels) ---
  Widget _buildMobileLayout(BuildContext context) {
    // Mobile just shows the content list directly
    return _buildContentList(isDesktop: false); // Call list builder
  }

  // --- Build the Game List (ListView or GridView) ---
  Widget _buildContentList({
    required bool isDesktop,
    bool actuallyShowLeftPanel = false,
    bool actuallyShowRightPanel = false,
  }) {
    // --- 如果列表为空，显示空状态 ---
    if (_games.isEmpty) {
      if (!_isLoading && _errorMessage == null) {
        return _buildEmptyState(context);
      }
      return const SizedBox.shrink();
    }

    // --- 正常构建 GridView (无占位符) ---
    final bool withPanels =
        isDesktop && (actuallyShowLeftPanel || actuallyShowRightPanel);
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(context,
        withPanels: withPanels,
        leftPanelVisible: actuallyShowLeftPanel,
        rightPanelVisible: actuallyShowRightPanel);

    if (cardsPerRow <= 0) {
      return InlineErrorWidget(errorMessage: "发生渲染错误");
    }

    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio(
            context, actuallyShowLeftPanel, actuallyShowRightPanel,
            showTags: widget.showTagSelection)
        : DeviceUtils.calculateSimpleCardRatio(context,
            showTags: widget.showTagSelection);

    // --- 直接使用实际游戏数量 ---
    final int actualItemCount = _games.length;

    return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 16,
        ),
        // --- itemCount 使用实际数量 ---
        itemCount: actualItemCount,
        itemBuilder: (context, index) {
          final game = _games[index];
          // --- 正常构建卡片 ---
          return widget.customCardBuilder != null
              ? widget.customCardBuilder!(game)
              : BaseGameCard(
                  key: ValueKey(game.id), // 添加 Key
                  game: game,
                  isGridItem: true,
                  adaptForPanels: withPanels,
                  showTags: widget.showTagSelection,
                  showCollectionStats: true,
                  forceCompact: useCompactMode,
                  maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2),
                  // *** 把点击事件传递给卡片 ***
                  // 注意：BaseGameCard 内部已经处理了 onTap 跳转，这里不需要再包一层 InkWell 或 GestureDetector
                  // 如果你的 BaseGameCard 没有处理 onTap，你需要在这里加上：
                  // onTap: () => widget.onItemTap?.call(game),
                );
        });
  }

  // --- Build Loading State Widget ---
  Widget _buildLoading(String message) {
    // Centered loading indicator with message
    return LoadingWidget.inline(message: message);
  }

  // --- Build Error State Widget ---
  Widget _buildError(String message) {
    // Centered error message with a retry button
    return InlineErrorWidget(
      // Assuming InlineErrorWidget exists
      errorMessage: message, // Specific error message
      // Retry action should trigger a refresh
      onRetry: () => _loadGames(isRefresh: true),
    );
  }

  // --- Build Empty State Widget ---
  Widget _buildEmptyState(BuildContext context) {
    // Determine the appropriate message based on whether a tag is selected
    String message = _selectedTag != null && widget.showTagSelection
        ? '没有找到标签为 “$_selectedTag” 的游戏' // Message when filtered by tag
        : widget.emptyStateMessage; // Default empty message from parent

    // Centered column with icon, message, and optional buttons
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Generous padding
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          children: [
            // Icon (use provided icon or default)
            widget.emptyStateIcon ??
                Icon(Icons.sentiment_dissatisfied_outlined,
                    size: 70, color: Colors.grey[400]), // Example icon
            SizedBox(height: 24), // Spacing
            // Empty state message text
            Text(
              message,
              style:
                  TextStyle(fontSize: 17, color: Colors.grey[600]), // Styling
              textAlign: TextAlign.center, // Center align text
            ),
            SizedBox(height: 30), // Spacing
            // "View All" button (only if currently filtered by tag)
            if (_selectedTag != null && widget.showTagSelection)
              FunctionalButton(
                // Your custom button widget
                onPressed: _clearTagSelection, // Action to clear the tag filter
                label: '查看全部游戏',
                icon: Icons.list_alt, // Example icon
              ),
            SizedBox(height: 16), // Spacing between buttons if both appear
            // "Add Game" button (if enabled and not shown in AppBar)
            if (widget.showAddButton && !widget.showAddButtonInAppBar)
              AdminCheck(
                // Optional permission check
                child: FunctionalButton(
                  icon: Icons.add_circle_outline,
                  label: '添加新游戏',
                  // Use provided callback or default navigation
                  onPressed: widget.onAddPressed ??
                      () =>
                          NavigationUtils.pushNamed(context, AppRoutes.addGame),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
