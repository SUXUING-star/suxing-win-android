// lib/screens/game/base_game_list_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../models/tag/tag.dart';
import '../../../routes/app_routes.dart';
import '../../../services/main/game/tag/tag_service.dart';
import '../../../utils/check/admin_check.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/components/screen/gamelist/tag/tag_bar.dart';
import '../../../widgets/components/screen/gamelist/panel/game_left_panel.dart';
import '../../../widgets/components/screen/gamelist/panel/game_right_panel.dart';
import '../../../widgets/components/loading/loading_route_observer.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class BaseGameListScreen extends StatefulWidget {
  final String title;
  final Future<List<Game>> Function(String? selectedTag) loadGamesFunction;
  final Future<void> Function()? refreshFunction;
  final bool showTagSelection; // Controls if tag functionality (panels, bar) is enabled
  final String? selectedTag;
  final bool showSortOptions;
  final bool showAddButton;
  final Widget? emptyStateIcon;
  final String emptyStateMessage;
  final bool enablePagination;
  final bool showPanelToggles; // Controls if AppBar toggles are shown (requires showTagSelection=true)

  // AppBar 相关属性
  final bool useScaffold;
  final List<Widget>? additionalActions;
  final Function(BuildContext)? onFilterPressed;
  final Function()? onMySubmissionsPressed;
  final Function()? onAddPressed;
  final bool showAddButtonInAppBar;
  final bool showMySubmissionsButton;

  // 自定义卡片构建函数
  final Widget Function(Game)? customCardBuilder;

  const BaseGameListScreen({
    Key? key,
    required this.title,
    required this.loadGamesFunction,
    this.refreshFunction,
    this.showTagSelection = false,
    this.selectedTag,
    this.showSortOptions = false,
    this.showAddButton = false,
    this.emptyStateIcon,
    required this.emptyStateMessage,
    this.enablePagination = false,
    this.showPanelToggles = false, // Default to false if not provided
    this.useScaffold = true,
    this.additionalActions,
    this.onFilterPressed,
    this.onMySubmissionsPressed,
    this.onAddPressed,
    this.showAddButtonInAppBar = false,
    this.showMySubmissionsButton = false,
    this.customCardBuilder,
  }) : super(key: key);

  @override
  _BaseGameListScreenState createState() => _BaseGameListScreenState();
}

class _BaseGameListScreenState extends State<BaseGameListScreen> {
  final TagService _tagService = TagService();

  List<Game> _games = [];
  List<Tag> _topTags = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedTag;
  bool _showTagFilter = false; // Mobile tag bar toggle

  // 控制面板显示状态 (用户意图)
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  final ScrollController _scrollController = ScrollController();
  DateTime? _lastLoadTime;
  static const Duration _minRefreshInterval = Duration(minutes: 1); // Cache duration

  // --- 屏幕宽度阈值定义 (根据Game侧边栏调整) ---
  static const double _hideRightPanelThreshold = 1000.0; // 示例值
  static const double _hideLeftPanelThreshold = 800.0;  // 示例值

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.selectedTag;

    // Only load tags if tag selection is enabled
    if (widget.showTagSelection) {
      _loadTopTags();
    }
    // Initial game load happens in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;

    // Load games only if needed (initial load or cache expired)
    // Wrap in addPostFrameCallback to ensure context/navigator are ready
    if (_shouldLoad()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Use try-finally for loading observer safety
        LoadingRouteObserver? loadingObserver;
        try {
          loadingObserver = Navigator.of(context)
              .widget.observers
              .whereType<LoadingRouteObserver>()
              .firstOrNull; // Use firstOrNull
          loadingObserver?.showLoading();
          _loadGames().then((_) {
            if (!mounted) return;
            loadingObserver?.hideLoading();
          });
        } catch (e) {
          print("Error accessing LoadingRouteObserver or loading games: $e");
          loadingObserver?.hideLoading(); // Ensure hiding on error
        }
      });
    }

    if (widget.enablePagination) {
      _scrollController.addListener(_onScroll);
    } else {
      // Ensure listener is removed if pagination is disabled later
      _scrollController.removeListener(_onScroll);
    }
  }

  bool _shouldLoad() {
    if (_lastLoadTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastLoadTime!) >= _minRefreshInterval;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.enablePagination &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && // Increase threshold
        !_isLoading) {
      print("Reached end, loading more games..."); // Debug log
      _loadMoreGames();
    }
  }

  Future<void> _loadTopTags() async {
    if (!widget.showTagSelection) return; // Don't load if not needed
    // Avoid concurrent loads
    // if (_isLoading) return; // Maybe not needed for tags?

    try {
      final tags = await _tagService.getTagsImmediate();
      if (!mounted) return;
      setState(() {
        // Take a reasonable number of tags
        _topTags = tags.take(50).toList();
      });
    } catch (e) {
      print('Load top tags error: $e');
      if (mounted) {
        // Optionally show error to user or handle silently
      }
    }
  }

  Future<void> _loadGames({bool isLoadMore = false}) async {
    if (!mounted || (_isLoading && !isLoadMore)) return; // Prevent concurrent full loads

    setState(() {
      _isLoading = true;
      if (!isLoadMore) {
        _errorMessage = null; // Clear error only on full load/refresh
      }
    });

    try {
      // If loading more, we need pagination logic in loadGamesFunction
      // Assuming loadGamesFunction handles pagination if needed (e.g., takes page/offset)
      // For simplicity here, we assume it returns the full list on initial load
      // and potentially appends on loadMore (which needs specific implementation)
      final games = await widget.loadGamesFunction(_selectedTag);

      if (!mounted) return;

      if (!isLoadMore) {
        _lastLoadTime = DateTime.now(); // Update cache time only on full load
      }

      setState(() {
        if (isLoadMore) {
          // Append logic - Requires loadGamesFunction to support pagination
          // _games.addAll(games); // Example append
          print("Load more successful (append logic needed here)");
          // For now, simulate by replacing, assuming no pagination in base class
          _games = games;
        } else {
          _games = games; // Replace on full load/refresh
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('Load games error: $e'); // Log error
      setState(() {
        // Set error message only on full load failure
        if (!isLoadMore) {
          _errorMessage = '加载游戏失败: ${e.toString()}';
        }
        _isLoading = false; // Ensure loading state is reset
      });
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    // Use try-finally for loading observer
    LoadingRouteObserver? loadingObserver;
    try {
      loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .firstOrNull;
      loadingObserver?.showLoading();

      // Reset error and list for refresh visual cue
      setState(() {
        _errorMessage = null;
        _games = []; // Clear list immediately for refresh effect
        _isLoading = true; // Show loading state during refresh
      });

      // Call custom refresh or default logic
      if (widget.refreshFunction != null) {
        await widget.refreshFunction!();
        // Assuming custom refresh function updates _games itself or calls _loadGames
        if(mounted) setState(() => _isLoading = false); // Ensure loading stops if refresh handles it
      } else {
        _lastLoadTime = null; // Invalidate cache
        // Clear specific tag cache if a tag is selected
        if (widget.showTagSelection && _selectedTag != null) {
          try {
            await _tagService.clearTagCache(_selectedTag!);
          } catch (e) { print("Error clearing tag cache: $e"); }
        }
        // Reload games and potentially tags
        await _loadGames(); // This will set _isLoading=false on completion/error
        if (widget.showTagSelection) {
          await _loadTopTags(); // Refresh tags too
        }
      }
    } catch (e) {
      print("Refresh error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "刷新失败: $e";
          _isLoading = false;
          _games = []; // Ensure list is empty on refresh error
        });
      }
    } finally {
      if (mounted) {
        loadingObserver?.hideLoading();
      }
    }
  }


  void _onTagSelected(String tag) {
    if (!widget.showTagSelection) return;
    String? newTag;
    if (_selectedTag == tag) {
      newTag = null; // Deselect
    } else {
      newTag = tag; // Select new tag
    }
    // Only reload if tag actually changed
    if (_selectedTag != newTag) {
      setState(() {
        _selectedTag = newTag;
        _games = []; // Clear list on tag change
        _errorMessage = null;
      });
      _loadGames(); // Load games for the new tag
    }
  }

  void _clearTagSelection() {
    if (!widget.showTagSelection || _selectedTag == null) return;
    setState(() {
      _selectedTag = null;
      _games = []; // Clear list
      _errorMessage = null;
    });
    _loadGames(); // Load all games
  }

  // Placeholder for pagination - needs actual implementation in loadGamesFunction
  Future<void> _loadMoreGames() async {
    print("Attempting to load more games...");
    // This requires widget.loadGamesFunction to accept pagination parameters
    // e.g., loadGamesFunction(_selectedTag, page: currentPage + 1);
    // For now, it will just call the same function, likely reloading the first page.
    if (widget.enablePagination && ! _isLoading) {
      // Pass a flag or parameter indicating it's a load more operation
      await _loadGames(isLoadMore: true);
    }
  }

  // Toggle mobile tag bar visibility
  void _toggleTagFilter() {
    setState(() {
      _showTagFilter = !_showTagFilter;
    });
  }

  // Toggle user intent for panels
  void _toggleLeftPanel() {
    setState(() {
      _showLeftPanel = !_showLeftPanel;
    });
  }

  void _toggleRightPanel() {
    setState(() {
      _showRightPanel = !_showRightPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = DeviceUtils.isDesktop;
    final displayTitle = _selectedTag != null && widget.showTagSelection
        ? '标签: $_selectedTag'
        : widget.title;

    // --- Calculate actual panel visibility based on width and user intent ---
    // Panels are only relevant in desktop mode and if tag selection is enabled
    final bool panelsAreRelevant = isDesktop && widget.showTagSelection;

    final bool canShowLeftPanelBasedOnWidth = screenWidth >= _hideLeftPanelThreshold;
    final bool canShowRightPanelBasedOnWidth = screenWidth >= _hideRightPanelThreshold;

    // Actual visibility: Relevant AND User wants it AND Width allows it
    final bool actuallyShowLeftPanel = panelsAreRelevant && _showLeftPanel && canShowLeftPanelBasedOnWidth;
    final bool actuallyShowRightPanel = panelsAreRelevant && _showRightPanel && canShowRightPanelBasedOnWidth;

    // Decide if panel toggles in AppBar should be shown
    final bool showActualPanelToggles = isDesktop && widget.showPanelToggles && widget.showTagSelection;


    final appBar = widget.useScaffold ? CustomAppBar(
      title: displayTitle,
      // Pass actual visibility state to build actions
      actions: _buildAppBarActions(
          isDesktop,
          showActualPanelToggles,
          actuallyShowLeftPanel,
          actuallyShowRightPanel,
          canShowLeftPanelBasedOnWidth,
          canShowRightPanelBasedOnWidth
      ),
      // Mobile tag bar logic remains the same
      bottom: (!isDesktop && widget.showTagSelection && _showTagFilter && _topTags.isNotEmpty)
          ? TagBar(
        tags: _topTags,
        selectedTag: _selectedTag,
        onTagSelected: _onTagSelected,
      )
          : null,
    ) : null;

    // Pass actual visibility state to layout builders
    final body = RefreshIndicator(
      onRefresh: _refreshData,
      child: isDesktop
          ? _buildDesktopLayout(context, actuallyShowLeftPanel, actuallyShowRightPanel)
          : _buildMobileLayout(context),
    );

    // Floating action button logic remains the same
    final floatingActionButton = widget.showAddButton && widget.useScaffold ? AdminCheck(
      child: FloatingActionButton(
        onPressed: widget.onAddPressed ?? () {
          Navigator.pushNamed(context, AppRoutes.addGame); // Use correct route if needed
        },
        child: Icon(Icons.add),
        tooltip: '添加游戏',
      ),
    ) : null;

    if (widget.useScaffold) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    } else {
      return body;
    }
  }

  // Updated signature for AppBar actions builder
  List<Widget> _buildAppBarActions(
      bool isDesktop,
      bool showActualPanelToggles,
      bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel,
      bool canShowLeftPanelBasedOnWidth,
      bool canShowRightPanelBasedOnWidth)
  {
    final actions = <Widget>[];
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.white54;
    final Color enabledColor = Colors.white;

    if (widget.additionalActions != null) {
      actions.addAll(widget.additionalActions!);
    }
    if (widget.showAddButtonInAppBar) { /* ... Add button logic ... */ }
    if (widget.showMySubmissionsButton) { /* ... My Submissions logic ... */ }

    // --- Updated Panel Toggle Buttons ---
    if (showActualPanelToggles) {
      // Left Panel Toggle
      actions.add(
          IconButton(
            icon: Icon(
              Icons.menu,
              color: actuallyShowLeftPanel ? secondaryColor : (_showLeftPanel ? disabledColor : enabledColor),
            ),
            onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
            tooltip: _showLeftPanel
                ? (canShowLeftPanelBasedOnWidth ? '隐藏左侧面板' : '屏幕宽度不足')
                : (canShowLeftPanelBasedOnWidth ? '显示左侧面板' : '屏幕宽度不足'),
          )
      );
      // Right Panel Toggle
      actions.add(
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: actuallyShowRightPanel ? secondaryColor : (_showRightPanel ? disabledColor : enabledColor),
            ),
            onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
            tooltip: _showRightPanel
                ? (canShowRightPanelBasedOnWidth ? '隐藏右侧面板' : '屏幕宽度不足')
                : (canShowRightPanelBasedOnWidth ? '显示右侧面板' : '屏幕宽度不足'),
          )
      );
    }

    // Tag Clear Button (only if a tag is selected and tags are shown)
    if (_selectedTag != null && widget.showTagSelection) {
      actions.add(
          IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            onPressed: _clearTagSelection,
            tooltip: '清除标签筛选',
          )
      );
    }

    // Mobile Tag Toggle Button (only if not desktop and tags are shown)
    if (!isDesktop && widget.showTagSelection) {
      actions.add(
          IconButton(
            icon: Icon(
              Icons.tag,
              color: _showTagFilter ? secondaryColor : enabledColor, // Use theme color
            ),
            onPressed: _toggleTagFilter,
            tooltip: _showTagFilter ? '隐藏标签栏' : '显示标签栏',
          )
      );
    }

    // Sort Button
    if (widget.showSortOptions) {
      actions.add(
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => widget.onFilterPressed != null
                ? widget.onFilterPressed!(context)
                : _showFilterDialog(context), // Placeholder call
            tooltip: '排序/筛选',
          )
      );
    }

    return actions;
  }

  // Placeholder for filter dialog - implement in subclasses if needed
  void _showFilterDialog(BuildContext context) {
    print("Filter dialog not implemented in base class.");
    // Example: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("排序功能待实现")));
  }

  // Updated Desktop Layout builder signature
  Widget _buildDesktopLayout(BuildContext context, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Conditionally render left panel based on actual state
        if (actuallyShowLeftPanel) // No need for widget.showTagSelection check here, already incorporated
          GameLeftPanel(
            tags: _topTags,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),

        // Main content area - Pass actual state down
        Expanded(
          child: _buildContent(
              isDesktop: true,
              actuallyShowLeftPanel: actuallyShowLeftPanel,
              actuallyShowRightPanel: actuallyShowRightPanel
          ),
        ),

        // Conditionally render right panel based on actual state
        if (actuallyShowRightPanel) // No need for widget.showTagSelection check here
          GameRightPanel(
            currentPageGames: _games,
            totalGamesCount: _games.length, // Note: Might need total count from API for pagination
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),
      ],
    );
  }

  // Mobile layout builder
  Widget _buildMobileLayout(BuildContext context) {
    // Mobile layout doesn't have panels, pass false or defaults
    return _buildContent(isDesktop: false);
  }

  // Updated Content builder signature
  Widget _buildContent({
    required bool isDesktop,
    bool actuallyShowLeftPanel = false,
    bool actuallyShowRightPanel = false
  }) {
    // Error and Loading states handled first
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }
    // Show loading indicator centrally, consider list specific loading later
    if (_games.isEmpty && _isLoading) {
      return _buildLoading();
    }
    // Handle empty state after loading finishes
    if (_games.isEmpty && !_isLoading) {
      return _buildEmptyState(context);
    }

    // Determine if panels are actually shown (only relevant for desktop)
    final bool withPanels = isDesktop && (actuallyShowLeftPanel || actuallyShowRightPanel);

    // --- Use DeviceUtils with ACTUAL panel visibility ---
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(
        context,
        // Pass the actual visibility states received by this function
        withPanels: withPanels, // Simplified check: are *any* panels shown?
        leftPanelVisible: actuallyShowLeftPanel,
        rightPanelVisible: actuallyShowRightPanel
    );

    // Use compact mode calculation (or simplify if not needed)
    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);

    // Calculate card ratio based on ACTUAL panel visibility
    // Decide which calculation method to use based on whether *any* panel is visible
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio(
        context,
        actuallyShowLeftPanel,
        actuallyShowRightPanel,
        showTags: widget.showTagSelection // Pass tag visibility if it affects ratio
    )
        : DeviceUtils.calculateSimpleCardRatio(
        context,
        showTags: widget.showTagSelection
    );

    // print("Grid Calculated - CardsPerRow: $cardsPerRow, Ratio: $cardRatio, Compact: $useCompactMode"); // Debug log

    return GridView.builder(
      controller: _scrollController, // Attach scroll controller
      padding: const EdgeInsets.all(12), // Consistent padding
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cardsPerRow, // Use calculated cards per row
        childAspectRatio: cardRatio, // Use calculated aspect ratio
        crossAxisSpacing: 12, // Spacing
        mainAxisSpacing: 12,
      ),
      // Add 1 for loading indicator at the end if loading more
      itemCount: _games.length + (_isLoading && widget.enablePagination ? 1 : 0), // Show loading spinner only if paginating
      itemBuilder: (context, index) {
        if (index < _games.length) {
          final game = _games[index];
          // Use custom builder or default BaseGameCard
          if (widget.customCardBuilder != null) {
            return widget.customCardBuilder!(game);
          } else {
            return BaseGameCard(
              game: game,
              isGridItem: true, // Explicitly state it's for a grid
              // Adapt based on whether *any* panel is shown on desktop
              adaptForPanels: withPanels,
              showTags: widget.showTagSelection,
              showCollectionStats: true, // Or make configurable
              forceCompact: useCompactMode,
              // Adjust maxTags based on compactness or panel state
              maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2),
            );
          }
        } else {
          // Show loading indicator at the bottom during load more
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator()
              )
          );
        }
      },
    );
  }

  // Error, Loading, EmptyState widgets remain largely the same
  Widget _buildError(String message) { /* ... Implementation ... */
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('重试'),
              onPressed: _loadGames, // Retry loading current view
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLoading() { /* ... Implementation ... */
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  Widget _buildEmptyState(BuildContext context) { /* ... Implementation ... */
    String message = _selectedTag != null && widget.showTagSelection
        ? '没有找到标签为"$_selectedTag"的游戏'
        : widget.emptyStateMessage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.emptyStateIcon ?? Icon(Icons.videogame_asset_off_outlined, size: 60, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 24),
            if (_selectedTag != null && widget.showTagSelection)
              ElevatedButton(
                onPressed: _clearTagSelection,
                child: Text('查看全部'),
              ),
            // Keep SizedBox even if button above isn't shown, for consistent spacing
            SizedBox(height: 16),
            if (widget.showAddButton && !widget.showAddButtonInAppBar) // Show button here only if not in AppBar
              AdminCheck(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('添加游戏'),
                  onPressed: widget.onAddPressed ?? () {
                    Navigator.pushNamed(context, AppRoutes.addGame); // Adjust route if needed
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}