import 'dart:async'; // Stream needed if using StreamBuilder
import 'package:flutter/material.dart';
// --- 移除 VisibilityDetector (Builder会处理初始状态) ---
// import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/form/gameform/config/category_list.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/game_category_tag.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../models/game/game.dart';
import '../../../models/tag/tag.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/check/admin_check.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/components/screen/gamelist/tag/tag_bar.dart';
import '../../../widgets/components/screen/gamelist/panel/game_left_panel.dart';
import '../../../widgets/components/screen/gamelist/panel/game_right_panel.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class CommonGameListScreen extends StatefulWidget {
  // --- 核心输入参数 ---
  final String title;
  // *** 修改: 接收 Future 或 Stream ***
  final Future<List<Game>>? gamesFuture; // 用于一次性加载
  final Stream<List<Game>>? gamesStream; // 用于流式更新 (可选)
  final Future<void> Function()? onRefreshTriggered;

  // --- UI 控制参数 (保持不变或微调) ---
  final bool showTagSelection;
  final String? selectedTag; // 标签选择仍由外部控制，影响标题和可能的过滤逻辑（如果需要）
  final bool showSortOptions;
  final bool showAddButton;
  final Widget? emptyStateIcon;
  final String emptyStateMessage;
  final bool showPanelToggles;
  final bool useScaffold;
  final bool showAddButtonInAppBar;
  final bool showMySubmissionsButton;
  final bool showSearchButton;
  final List<Tag>? availableTags; // 标签数据由外部传入

  // --- 回调 (保持不变) ---
  final void Function(BuildContext)? onFilterPressed;
  final void Function()? onMySubmissionsPressed;
  final void Function()? onAddPressed;
  final void Function(String? tag)? onTagSelectedInPanel;
  final Future<void> Function(String gameId) onDeleteGameAction; // 删除操作必须提供
  // final Future<void> Function(Game game) onEditGameAction;

  // --- 其他 (保持不变) ---
  final List<Widget>? additionalActions;
  final Widget Function(Game)? customCardBuilder;

  const CommonGameListScreen({
    super.key,
    required this.title,
    // *** 修改: 接收 Future 或 Stream ***
    this.gamesFuture,
    this.gamesStream,
    this.onRefreshTriggered, // 新增下拉刷新回调
    this.availableTags,
    this.showTagSelection = false,
    this.selectedTag,
    this.showSortOptions = false,
    this.showAddButton = false,
    this.emptyStateIcon,
    required this.emptyStateMessage,
    this.showPanelToggles = false,
    this.useScaffold = true, // 默认使用 Scaffold
    this.additionalActions,
    this.onFilterPressed,
    this.onMySubmissionsPressed,
    this.onAddPressed,
    this.showAddButtonInAppBar = false,
    this.showMySubmissionsButton = false,
    this.showSearchButton = false,
    this.customCardBuilder,
    // *** 移除: initialError, isInitiallyLoading ***
    required this.onDeleteGameAction,
    this.onTagSelectedInPanel,
  }) : assert(gamesFuture != null || gamesStream != null,
            'Either gamesFuture or gamesStream must be provided');

  @override
  _CommonGameListScreenState createState() => _CommonGameListScreenState();
}

class _CommonGameListScreenState extends State<CommonGameListScreen> {
  // --- 内部控制状态 (保留面板和 TagBar 状态) ---
  String? _selectedTag; // 仅用于 UI 显示同步
  bool _showTagFilter = false;
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  // --- 布局阈值 (不变) ---
  static const double _hideRightPanelThreshold = 1000.0;
  static const double _hideLeftPanelThreshold = 800.0;

  // === 生命周期 ===
  @override
  void initState() {
    super.initState();
    _selectedTag = widget.selectedTag; // 同步初始标签
    // *** 移除: _loadTopTags, 首次加载逻辑 (由 Builder 处理) ***
  }

  @override
  void didUpdateWidget(covariant CommonGameListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅同步 selectedTag UI 显示
    if (widget.selectedTag != oldWidget.selectedTag &&
        _selectedTag != widget.selectedTag) {
      setState(() => _selectedTag = widget.selectedTag);
    }
    // *** 移除: isInitiallyLoading 相关逻辑 ***
  }

  // === 数据加载相关 ===
  // *** 移除: _loadTopTags, _triggerInitialLoad, _loadGames ***

  // 下拉刷新处理 (调用父级 onRefreshTriggered 回调)
  Future<void> _refreshData() async {
    if (widget.onRefreshTriggered != null) {
      await widget.onRefreshTriggered!();
      // 父级应该改变传入的 Future 或 Stream (或 Key) 来触发重建和数据刷新
      // Base 自身不再管理刷新状态
    }
    // 如果没有提供 onRefreshTriggered，下拉刷新不做任何事
  }

  // === UI 交互处理 ===

  // 处理标签选择 (调用父级回调 - 不变)
  void _onTagSelected(String? tag) {
    if (!widget.showTagSelection) return;
    String? newTag = (_selectedTag == tag) ? null : tag;
    widget.onTagSelectedInPanel?.call(newTag);
    // UI 同步由 didUpdateWidget 处理
  }

  // 清除标签选择 (调用父级回调 - 不变)
  void _clearTagSelection() {
    if (!widget.showTagSelection || _selectedTag == null) return;
    widget.onTagSelectedInPanel?.call(null);
  }

  // UI 面板切换 (不变)
  void _toggleTagFilter() => setState(() => _showTagFilter = !_showTagFilter);
  void _toggleLeftPanel() => setState(() => _showLeftPanel = !_showLeftPanel);
  void _toggleRightPanel() =>
      setState(() => _showRightPanel = !_showRightPanel);

  // === 构建方法 ===

  @override
  Widget build(BuildContext context) {
    // *** 移除: VisibilityDetector ***
    return _buildActualContent(); // 直接构建内容
  }

  Widget _buildActualContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = DeviceUtils.isDesktop;
    // --- 使用 widget.selectedTag 来决定标题 ---
    final displayTitle = widget.selectedTag != null && widget.showTagSelection
        ? '标签: ${widget.selectedTag}'
        : widget.title;

    // --- 面板计算逻辑 (不变) ---
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

    // --- 构建 AppBar (如果 useScaffold) ---
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
            // TagBar 逻辑不变
            bottom: (!isDesktop &&
                    widget.showTagSelection &&
                    _showTagFilter &&
                    widget.availableTags != null &&
                    widget.availableTags!.isNotEmpty)
                ? TagBar(
                    tags: widget.availableTags!,
                    selectedTag: widget.selectedTag,
                    onTagSelected: _onTagSelected)
                : null,
          )
        : null;

    // --- 构建 FAB (如果 useScaffold) ---
    final floatingActionButton = (widget.useScaffold && widget.showAddButton)
        ? AdminCheck(
            child: GenericFloatingActionButton(
              onPressed: widget.onAddPressed ??
                  () => NavigationUtils.pushNamed(context, AppRoutes.addGame),
              icon: Icons.add,
              tooltip: '添加游戏',
              heroTag:
                  'base_game_list_fab_${widget.key?.toString() ?? widget.title}',
            ),
          )
        : null;

    // --- 构建 Body (使用 Builder 处理数据) ---
    Widget bodyContent;
    if (widget.gamesFuture != null) {
      bodyContent = FutureBuilder<List<Game>>(
        future: widget.gamesFuture, // 使用传入的 Future
        builder: (context, snapshot) {
          // *** FutureBuilder 处理连接状态 ***
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading("加载中..."); // 显示 Loading
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString()); // 显示错误
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // *** 有数据，构建列表 ***
            return _buildContentWrapper(snapshot.data!, isDesktop,
                actuallyShowLeftPanel, actuallyShowRightPanel);
          } else {
            // *** 无数据 (null 或空列表) ***
            return _buildEmptyState(context);
          }
        },
      );
    } else if (widget.gamesStream != null) {
      bodyContent = StreamBuilder<List<Game>>(
        stream: widget.gamesStream, // 使用传入的 Stream
        builder: (context, snapshot) {
          // *** StreamBuilder 处理连接状态 ***
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            // 初始等待且无旧数据
            return _buildLoading("加载中...");
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // *** 有数据 (新或旧)，构建列表 ***
            return _buildContentWrapper(snapshot.data!, isDesktop,
                actuallyShowLeftPanel, actuallyShowRightPanel);
          } else {
            return _buildEmptyState(context);
          }
        },
      );
    } else {
      // 不应该发生，因为构造函数有断言
      bodyContent = _buildError("未提供数据源 (Future 或 Stream)");
    }

    // --- 返回最终结构 ---
    if (widget.useScaffold) {
      return Scaffold(
          appBar: appBar,
          body: bodyContent,
          floatingActionButton: floatingActionButton);
    } else {
      // 如果不用 Scaffold，通常嵌入在其他地方
      return bodyContent;
    }
  }

  /// 构建 AppBar Actions (逻辑不变，依赖父级 props)
  List<Widget> _buildAppBarActions(
      bool isDesktop,
      bool showActualPanelToggles,
      bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel,
      bool canShowLeftPanelBasedOnWidth,
      bool canShowRightPanelBasedOnWidth) {
    final actions = <Widget>[];
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.white54; // 假设 AppBar 亮色背景
    final Color enabledColor = Colors.white; // 假设 AppBar 亮色背景

    if (widget.additionalActions != null) {
      actions.addAll(widget.additionalActions!);
    }
    if (widget.showAddButtonInAppBar) {
      actions.add(AdminCheck(
          child: IconButton(
              icon: Icon(Icons.add, color: enabledColor),
              onPressed: widget.onAddPressed ??
                  () => NavigationUtils.pushNamed(context, AppRoutes.addGame),
              tooltip: '添加游戏')));
    }
    if (widget.showMySubmissionsButton) {
      actions.add(IconButton(
          icon: Icon(Icons.history_edu, color: enabledColor),
          onPressed: widget.onMySubmissionsPressed ??
              () => NavigationUtils.pushNamed(context, AppRoutes.myGames),
          tooltip: '我的提交'));
    }
    if (widget.showSearchButton) {
      actions.add(IconButton(
          icon: Icon(Icons.search, color: enabledColor),
          onPressed: () =>
              NavigationUtils.pushNamed(context, AppRoutes.searchGame),
          tooltip: '搜索游戏'));
    }
    if (widget.showSortOptions && widget.onFilterPressed != null) {
      actions.add(IconButton(
          icon: Icon(Icons.filter_list, color: enabledColor),
          onPressed: () => widget.onFilterPressed!(context),
          tooltip: '排序/筛选'));
    }
    if (showActualPanelToggles) {
      actions.add(IconButton(
        icon: Icon(Icons.menu_open,
            color: actuallyShowLeftPanel
                ? secondaryColor
                : (_showLeftPanel ? disabledColor : enabledColor)),
        onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
        tooltip: _showLeftPanel
            ? (canShowLeftPanelBasedOnWidth ? '隐藏左侧面板' : '屏幕宽度不足')
            : (canShowLeftPanelBasedOnWidth ? '显示左侧面板' : '屏幕宽度不足'),
      ));
      actions.add(IconButton(
        icon: Icon(Icons.analytics_outlined,
            color: actuallyShowRightPanel
                ? secondaryColor
                : (_showRightPanel ? disabledColor : enabledColor)),
        onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
        tooltip: _showRightPanel
            ? (canShowRightPanelBasedOnWidth ? '隐藏右侧面板' : '屏幕宽度不足')
            : (canShowRightPanelBasedOnWidth ? '显示右侧面板' : '屏幕宽度不足'),
      ));
    }
    if (widget.selectedTag != null && widget.showTagSelection) {
      actions.add(IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: _clearTagSelection,
          tooltip: '清除标签筛选'));
    }
    if (!isDesktop && widget.showTagSelection) {
      actions.add(IconButton(
          icon: Icon(Icons.tag,
              color: _showTagFilter ? secondaryColor : enabledColor),
          onPressed: _toggleTagFilter,
          tooltip: _showTagFilter ? '隐藏标签栏' : '显示标签栏'));
    }
    return actions;
  }

  /// 包裹实际内容区域，添加 RefreshIndicator (如果需要)
  Widget _buildContentWrapper(List<Game> games, bool isDesktop,
      bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    Widget content = isDesktop
        ? _buildDesktopLayout(
            context, games, actuallyShowLeftPanel, actuallyShowRightPanel)
        : _buildMobileLayout(context, games);

    // 只有提供了 onRefreshTriggered 回调时才添加 RefreshIndicator
    if (widget.onRefreshTriggered != null) {
      return RefreshIndicator(
        onRefresh: _refreshData, // 调用内部 _refreshData，它会调用父级回调
        child: content,
      );
    } else {
      return content;
    }
  }

  /// 构建桌面布局 (需要传入 games 数据)
  Widget _buildDesktopLayout(BuildContext context, List<Game> games,
      bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actuallyShowLeftPanel && widget.availableTags != null)
          GameLeftPanel(
            tags: widget.availableTags!,
            selectedTag: widget.selectedTag, // 使用 widget 的 selectedTag
            onTagSelected: _onTagSelected, // 调用内部方法触发父级回调
          ),
        Expanded(
          child: _buildContentList(
              games: games, // 传递 games 数据
              isDesktop: true,
              actuallyShowLeftPanel: actuallyShowLeftPanel,
              actuallyShowRightPanel: actuallyShowRightPanel),
        ),
        if (actuallyShowRightPanel && games.isNotEmpty) // 仅当有数据时显示右面板
          GameRightPanel(
            currentPageGames: games, // 使用传入的 games
            totalGamesCount: 0, // Base 不知道总数，除非父级传入
            selectedTag: widget.selectedTag,
            onTagSelected: _onTagSelected,
            onCategorySelected: null,
            availableCategories: CategoryList.defaultCategory,
          ),
      ],
    );
  }

  /// 构建移动端布局 (需要传入 games 数据)
  Widget _buildMobileLayout(BuildContext context, List<Game> games) {
    return _buildContentList(games: games, isDesktop: false); // 传递 games 数据
  }

  /// 构建游戏网格 (需要传入 games 数据)
  Widget _buildContentList({
    required List<Game> games, // 接收游戏数据
    required bool isDesktop,
    bool actuallyShowLeftPanel = false, // 接收实际左面板状态
    bool actuallyShowRightPanel = false, // 接收实际右面板状态
  }) {
    // 1. 判断是否处于有面板的桌面模式
    final bool withPanels =
        isDesktop && (actuallyShowLeftPanel || actuallyShowRightPanel);

    // 2. 计算每行卡片数
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(context,
        withPanels: withPanels, // 传递是否有面板的状态
        leftPanelVisible: actuallyShowLeftPanel, // 传递实际左面板状态
        rightPanelVisible: actuallyShowRightPanel // 传递实际右面板状态
        );
    if (cardsPerRow <= 0) return InlineErrorWidget(errorMessage: "渲染错误");

    // 3. 决定是否强制使用紧凑模式
    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);

    // 4. 计算卡片宽高比
    //    根据是否有面板，调用不同的 DeviceUtils 方法
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio(
            // 调用带面板的计算
            context,
            actuallyShowLeftPanel,
            actuallyShowRightPanel,
            showTags: widget.showTagSelection) // 使用 widget 的 showTagSelection
        : DeviceUtils.calculateSimpleCardRatio(context, // 调用无面板的计算
            showTags: widget.showTagSelection); // 使用 widget 的 showTagSelection

    // 5. 构建 GridView
    return GridView.builder(
        key: ValueKey(
            'game_grid_${games.length}_${cardsPerRow}_${widget.selectedTag ?? "all"}_${cardRatio.toStringAsFixed(2)}'),
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 16 : 8), // 桌面端 padding 大一点
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow, // 使用计算出的每行数量
          childAspectRatio: cardRatio, // 使用计算出的宽高比
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          // ... 返回卡片，可能是 BaseGameCard 或自定义卡片 ...
          return widget.customCardBuilder != null
              ? widget.customCardBuilder!(game)
              : BaseGameCard(
                  key: ValueKey(game.id),
                  game: game,
                  isGridItem: true,
                  adaptForPanels: withPanels,
                  showTags: widget.showTagSelection,
                  showCollectionStats: true,
                  forceCompact: useCompactMode,
                  maxTags: useCompactMode ? 1 : (withPanels ? 1 : 2),
                  onDeleteAction: () => widget.onDeleteGameAction(game.id),
                );
        });
  }

  // --- 构建 Loading, Error, EmptyState (内部方法) ---
  Widget _buildLoading(String message) {
    return FadeInItem(
        child: LoadingWidget.fullScreen(message: message)); // 不加 const
  }

  Widget _buildError(String message) {
    // *** 移除 Center ***
    // *** onRetry 现在调用 _refreshData，它会触发父级回调 ***
    return FadeInItem(
        child: InlineErrorWidget(
            errorMessage: message, onRetry: _refreshData)); // 不加 const
  }

  Widget _buildEmptyState(BuildContext context) {
    String message = widget.selectedTag != null && widget.showTagSelection
        ? '没有找到标签为 “${widget.selectedTag}” 的游戏'
        : widget.emptyStateMessage;
    // *** 移除 const ***
    return EmptyStateWidget(
      iconData: Icons
          .sentiment_dissatisfied_outlined, // 默认图标或使用 widget.emptyStateIcon
      message: message,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.selectedTag != null && widget.showTagSelection) ...[
            FunctionalButton(
              onPressed: _clearTagSelection,
              label: '查看全部游戏',
              icon: Icons.list_alt,
            ),
            SizedBox(height: 16),
          ],
          // 添加按钮由外部 FAB 控制，这里不显示
          // if (widget.showAddButton && !widget.showAddButtonInAppBar) ...
        ],
      ),
    );
  }
} // End of _BaseGameListScreenState
