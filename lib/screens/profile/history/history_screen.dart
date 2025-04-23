// lib/screens/profile/history_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import 'tab/game/game_history_tab.dart'; // 导入游戏历史标签页组件
import 'tab/post/post_history_tab.dart'; // 导入帖子历史标签页组件

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  final ForumService _forumService = ForumService();

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
    if (_gameHistoryLoaded) return; // 如果已经加载过，直接返回

    setState(() {
      _error = null; // 清除之前的错误，准备加载
    });

    // 这里仅仅是标记状态，实际加载在 Tab 组件内部触发
    // 简单的状态标记不需要 try-catch，除非标记过程本身有异常风险（这里没有）
    if (!mounted) return;
    setState(() {
      _gameHistoryLoaded = true; // <--- 修正这里！标记游戏历史已“触发”加载
    });
    // 注意：这里不再需要 try-catch 和 finally，因为没有执行实际的异步IO操作
    // 错误处理应该在 GameHistoryTab 的 _loadHistory 方法中进行
  }


  // 只加载帖子历史
  Future<void> _loadPostHistory() async {
    if (_postHistoryLoaded) return;

    setState(() {
      _error = null; // 清除之前的错误
    });


    try {
      if (!mounted) return;
      setState(() {
        _postHistoryLoaded = true;
        // _error = null; // 已在上面设置
      });
    } catch (e) {
      setState(() {
        _error = '触发加载帖子历史失败: $e'; // 错误信息可以更通用
        _postHistoryLoaded = false; // 加载失败，允许重试
      });
    } finally {

    }
  }

  // 刷新当前选中的历史
  // 刷新当前选中的历史 (这里也要对应调整)
  Future<void> _refreshCurrentHistory() async {
    if (!mounted || _tabController == null) return;
    int currentTab = _tabController!.index;

    // 重置加载状态标记，让对应的 Tab 重新加载
    if (currentTab == 0) {
      setState(() {
        _gameHistoryLoaded = false; // <--- 重置游戏历史加载状态
        _error = null;
      });
      // 通过改变 isLoaded 状态，GameHistoryTab 的 didUpdateWidget 会被触发
      // 或者如果 GameHistoryTab 暴露了刷新方法，可以调用它
      // 重新触发加载（或者说，允许它下次被触发时加载）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 确保是在下一帧触发状态更新，让 GameHistoryTab 有机会接收到 isLoaded=false
        // 然后再触发一次加载，使其接收 isLoaded=true
        if(mounted) {
          _loadGameHistory(); // 再次调用，将 isLoaded 设置为 true，触发 GameHistoryTab 的加载逻辑
        }
      });
    } else {
      setState(() {
        _postHistoryLoaded = false; // <--- 重置帖子历史加载状态
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          _loadPostHistory();
        }
      });
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
    return InlineErrorWidget(
      onRetry: _loadInitialTab,
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
            gameService: _gameService,
          ),
          // 帖子历史标签页 - 使用组件拆分提高性能
          PostHistoryTab(
            isLoaded: _postHistoryLoaded,
            onLoad: _loadPostHistory,
            forumService: _forumService,
          ),
        ],
      ),
    );
  }
}