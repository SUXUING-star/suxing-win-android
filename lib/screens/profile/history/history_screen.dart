// lib/screens/profile/history_screen.dart
import 'package:flutter/material.dart';
import '../../../services/main/history/game_history_service.dart';
import '../../../services/main/history/post_history_service.dart';
import '../../../utils/load/loading_route_observer.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import 'tab/game/game_history_tab.dart'; // 导入游戏历史标签页组件
import 'tab/post/post_history_tab.dart'; // 导入帖子历史标签页组件

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final GameHistoryService _gameHistoryService = GameHistoryService();
  final PostHistoryService _postHistoryService = PostHistoryService();

  TabController? _tabController;
  String? _error;

  // 标记是否已经加载过数据
  bool _gameHistoryLoaded = false;
  bool _postHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 监听标签页变化，实现懒加载
    _tabController!.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 应用启动时只预加载当前选中的标签页数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTab();
    });
  }

  // 加载初始标签页数据
  void _loadInitialTab() {
    if (_tabController!.index == 0) {
      _loadGameHistory();
    } else {
      _loadPostHistory();
    }
  }

  // 处理标签页变化事件，实现懒加载
  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      return;
    }

    if (_tabController!.index == 0 && !_gameHistoryLoaded) {
      _loadGameHistory();
    } else if (_tabController!.index == 1 && !_postHistoryLoaded) {
      _loadPostHistory();
    }
  }

  // 只加载游戏历史
  Future<void> _loadGameHistory() async {
    if (_gameHistoryLoaded) return;

    final loadingObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      // 只获取游戏历史数据
      await _gameHistoryService.getGameHistoryWithDetails(1, 10);
      setState(() {
        _gameHistoryLoaded = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载游戏历史失败: $e';
      });
    } finally {
      loadingObserver.hideLoading();
    }
  }

  // 只加载帖子历史
  Future<void> _loadPostHistory() async {
    if (_postHistoryLoaded) return;

    final loadingObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      // 只获取帖子历史数据
      await _postHistoryService.getPostHistoryWithDetails(1, 10);
      setState(() {
        _postHistoryLoaded = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载帖子历史失败: $e';
      });
    } finally {
      loadingObserver.hideLoading();
    }
  }

  // 刷新当前选中的历史
  Future<void> _refreshCurrentHistory() async {
    int currentTab = _tabController!.index;

    if (currentTab == 0) {
      // 刷新游戏历史
      setState(() {
        _gameHistoryLoaded = false;
      });
      await _loadGameHistory();
    } else {
      // 刷新帖子历史
      setState(() {
        _postHistoryLoaded = false;
      });
      await _loadPostHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '浏览历史'),
      body: RefreshIndicator(
        onRefresh: _refreshCurrentHistory,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorContent();
    }

    return Column(
      children: [
        _buildTabBar(),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(_error!),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialTab,
            child: Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: '游戏浏览历史'),
        Tab(text: '帖子浏览历史'),
      ],
    );
  }

  Widget _buildTabContent() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // 游戏历史标签页 - 使用组件拆分提高性能
          GameHistoryTab(
            isLoaded: _gameHistoryLoaded,
            onLoad: _loadGameHistory,
            gameHistoryService: _gameHistoryService,
          ),
          // 帖子历史标签页 - 使用组件拆分提高性能
          PostHistoryTab(
            isLoaded: _postHistoryLoaded,
            onLoad: _loadPostHistory,
            postHistoryService: _postHistoryService,
          ),
        ],
      ),
    );
  }
}