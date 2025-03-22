// lib/screens/game/base_game_list_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../models/tag/tag.dart';
import '../../../services/main/game/tag/tag_service.dart';
import '../../../utils/check/admin_check.dart';
import '../../../utils/device/device_utils.dart';
import '../../../utils/navigation/navigation_util.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/components/screen/gamelist/tag/tag_bar.dart';
import '../../../widgets/components/screen/gamelist/panel/game_left_panel.dart';
import '../../../widgets/components/screen/gamelist/panel/game_right_panel.dart';
import '../../../widgets/components/loading/loading_route_observer.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';

class BaseGameListScreen extends StatefulWidget {
  final String title;
  final Future<List<Game>> Function() loadGamesFunction;
  final Future<void> Function()? refreshFunction;
  final bool showTagSelection;
  final String? selectedTag;
  final bool showSortOptions;
  final bool showAddButton;
  final Widget? emptyStateIcon;
  final String emptyStateMessage;
  final bool enablePagination;
  final bool showPanelToggles;

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
    this.showPanelToggles = false,
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
  bool _showTagFilter = false;

  // 控制左右面板显示状态
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  final ScrollController _scrollController = ScrollController();
  DateTime? _lastLoadTime;
  static const Duration _minRefreshInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.selectedTag;

    if (widget.showTagSelection) {
      _loadTopTags();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!mounted) return;

    if (_shouldLoad()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final loadingObserver = Navigator.of(context)
            .widget.observers
            .whereType<LoadingRouteObserver>()
            .first;

        loadingObserver.showLoading();

        _loadGames().then((_) {
          if (!mounted) return;
          loadingObserver.hideLoading();
        });
      });
    }

    if (widget.enablePagination) {
      _scrollController.addListener(_onScroll);
    }
  }

  bool _shouldLoad() {
    // 如果从未加载过，则加载
    if (_lastLoadTime == null) {
      return true;
    }

    // 如果超过刷新间隔，则加载
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
    // 仅在启用分页的情况下处理滚动加载
    if (widget.enablePagination &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading) {
      _loadMoreGames();
    }
  }

  Future<void> _loadTopTags() async {
    try {
      final tags = await _tagService.getTagsImmediate();
      if (!mounted) return;
      setState(() {
        _topTags = tags.take(30).toList();
      });
    } catch (e) {
      print('Load top tags error: $e');
    }
  }

  Future<void> _loadGames() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final games = await widget.loadGamesFunction();

      if (!mounted) return;

      _lastLoadTime = DateTime.now();

      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      // 优先使用自定义刷新逻辑
      if (widget.refreshFunction != null) {
        await widget.refreshFunction!();
      } else {
        _lastLoadTime = null;
        if (widget.showTagSelection && _selectedTag != null) {
          await _tagService.clearTagCache(_selectedTag!);
        }
        await _loadGames();
        if (widget.showTagSelection) {
          await _loadTopTags();
        }
      }
    } finally {
      if (mounted) {
        loadingObserver.hideLoading();
      }
    }
  }

  void _onTagSelected(String tag) {
    setState(() {
      if (_selectedTag == tag) {
        _selectedTag = null;
      } else {
        _selectedTag = tag;
      }
    });
    _loadGames();
  }

  void _clearTagSelection() {
    setState(() {
      _selectedTag = null;
    });
    _loadGames();
  }

  Future<void> _loadMoreGames() async {
    // 此方法仅在子类中实现分页加载时有用
    // 基类中只提供接口
  }

  void _toggleTagFilter() {
    setState(() {
      _showTagFilter = !_showTagFilter;
    });
  }

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
    final isDesktop = DeviceUtils.isDesktop;
    final displayTitle = _selectedTag != null && widget.showTagSelection
        ? '标签: $_selectedTag'
        : widget.title;

    return Scaffold(
      appBar: CustomAppBar(
        title: displayTitle,
        actions: _buildAppBarActions(isDesktop),
        bottom: (!isDesktop && _showTagFilter && _topTags.isNotEmpty && widget.showTagSelection)
            ? TagBar(
          tags: _topTags,
          selectedTag: _selectedTag,
          onTagSelected: _onTagSelected,
        )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
      floatingActionButton: widget.showAddButton ? AdminCheck(
        child: FloatingActionButton(
          onPressed: () {
            NavigationUtil.navigateTo(context, '/game/add');
          },
          child: Icon(Icons.add),
        ),
      ) : null,
    );
  }

  List<Widget> _buildAppBarActions(bool isDesktop) {
    final actions = <Widget>[];

    // 只在需要时显示面板切换按钮
    if (isDesktop && widget.showPanelToggles) {
      actions.add(
          IconButton(
            icon: Icon(
              Icons.menu,
              color: _showLeftPanel ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleLeftPanel,
            tooltip: _showLeftPanel ? '隐藏左侧面板' : '显示左侧面板',
          )
      );

      actions.add(
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: _showRightPanel ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleRightPanel,
            tooltip: _showRightPanel ? '隐藏右侧面板' : '显示右侧面板',
          )
      );
    }

    // 标签清除按钮
    if (_selectedTag != null && widget.showTagSelection) {
      actions.add(
          IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            onPressed: _clearTagSelection,
            tooltip: '清除筛选',
          )
      );
    }

    // 移动端标签切换按钮
    if (!isDesktop && widget.showTagSelection) {
      actions.add(
          IconButton(
            icon: Icon(
              Icons.tag,
              color: _showTagFilter ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleTagFilter,
            tooltip: _showTagFilter ? '隐藏标签' : '显示标签',
          )
      );
    }

    // 排序按钮
    if (widget.showSortOptions) {
      actions.add(
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterDialog(context),
            tooltip: '排序',
          )
      );
    }

    return actions;
  }

  void _showFilterDialog(BuildContext context) {
    // 这个方法只在子类中需要实现
    // 基类中只提供接口
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧标签云面板（只在需要且显示时渲染）
        if (_showLeftPanel && widget.showTagSelection)
          GameLeftPanel(
            tags: _topTags,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),

        // 主内容区域
        Expanded(
          child: _buildContent(),
        ),

        // 右侧统计面板（只在需要且显示时渲染）
        if (_showRightPanel && widget.showTagSelection)
          GameRightPanel(
            currentPageGames: _games,
            totalGamesCount: _games.length,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    if (_games.isEmpty && _isLoading) {
      return _buildLoading();
    }

    if (_games.isEmpty) {
      return _buildEmptyState(context);
    }

    // 确定是否是桌面和面板状态
    final isDesktop = DeviceUtils.isDesktop;
    final withPanels = isDesktop && widget.showTagSelection;

    // 动态计算每行卡片数量
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(
        context,
        withPanels: withPanels,
        leftPanelVisible: _showLeftPanel,
        rightPanelVisible: _showRightPanel
    );

    // 检测是否应使用紧凑模式
    final useCompactMode = cardsPerRow > 3 || (cardsPerRow == 3 && withPanels);

    // 根据屏幕状态计算合适的卡片比例
    final cardRatio = withPanels
        ? DeviceUtils.calculateGameListCardRatio(
        context,
        _showLeftPanel,
        _showRightPanel,
        showTags: widget.showTagSelection
    )
        : DeviceUtils.calculateSimpleCardRatio(
        context,
        showTags: widget.showTagSelection
    );

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: cardRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12, // 增加垂直间距以防止卡片感觉太挤
      ),
      itemCount: _games.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _games.length) {
          // 使用BaseGameCard替代GameCard，以提供更好的适配性
          return BaseGameCard(
            game: _games[index],
            adaptForPanels: withPanels,
            showTags: widget.showTagSelection,
            showCollectionStats: true,
            forceCompact: useCompactMode,
            maxTags: useCompactMode ? 1 : 2,
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGames,
            child: Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message = _selectedTag != null && widget.showTagSelection
        ? '没有找到标签为"$_selectedTag"的游戏'
        : widget.emptyStateMessage;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.emptyStateIcon ?? Icon(Icons.games_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 24),
          if (_selectedTag != null && widget.showTagSelection)
            ElevatedButton(
              onPressed: _clearTagSelection,
              child: Text('查看全部游戏'),
            ),
          SizedBox(height: 16),
          if (widget.showAddButton)
            AdminCheck(
              child: ElevatedButton(
                onPressed: () {
                  NavigationUtil.navigateTo(context, '/game/add');
                },
                child: Text('添加游戏'),
              ),
            ),
        ],
      ),
    );
  }
}