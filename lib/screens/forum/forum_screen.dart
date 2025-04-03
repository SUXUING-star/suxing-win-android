// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo; // For ObjectId check if needed
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Ensure import
import 'package:visibility_detector/visibility_detector.dart'; // <--- 引入懒加载库
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart'; // 引入分页控件
import '../../models/post/post.dart';
import '../../services/main/forum/forum_service.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/components/loading/loading_route_observer.dart'; // 可选：全局加载指示器
import '../../widgets/components/form/postform/config/post_taglists.dart'; // 标签列表
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/forum/card/post_card.dart'; // 帖子卡片
import '../../widgets/components/screen/forum/tag_filter.dart'; // 移动端标签过滤器
import '../../widgets/components/screen/forum/panel/forum_right_panel.dart'; // 右侧面板
import '../../widgets/components/screen/forum/panel/forum_left_panel.dart'; // 左侧面板
import '../../widgets/ui/common/error_widget.dart'; // <--- 引入错误提示 Widget
import '../../widgets/ui/common/loading_widget.dart'; // <--- 引入加载提示 Widget

class ForumScreen extends StatefulWidget {
  final String? tag; // 可选的初始标签

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

// --- 添加 WidgetsBindingObserver 以监听 App 生命周期 ---
class _ForumScreenState extends State<ForumScreen> with WidgetsBindingObserver {
  final ForumService _forumService = ForumService();
  final List<String> _tags = PostTagLists.filterTags; // 固定的标签列表
  String _selectedTag = '全部'; // 当前选中的标签
  List<Post>? _posts; // 当前页的帖子列表 (可为 null)
  String? _errorMessage; // 错误信息

  // --- 分页状态 ---
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10; // 每页数量

  // --- 懒加载与加载状态 ---
  bool _isInitialized = false; // 是否已完成首次加载尝试
  bool _isVisible = false;     // 当前 Widget 是否可见
  bool _isLoadingData = false; // 是否正在加载（首次/刷新/翻页时都会触发，用于锁定操作）
  bool _isLoadingPage = false; // 专用于 PaginationControls 的加载状态显示
  // --- 结束懒加载状态 ---

  // 使用简易 RefreshController 处理下拉刷新完成状态
  final RefreshController _refreshController = RefreshController();

  // UI 控制状态
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  // 路由观察者和后台刷新标记
  LoadingRouteObserver? _routeObserver; // 可选，用于全局加载提示
  bool _needsRefresh = false; // App 从后台恢复时是否需要刷新

  // 屏幕宽度阈值 (不变)
  static const double _hideRightPanelThreshold = 950.0;
  static const double _hideLeftPanelThreshold = 750.0;

  @override
  void initState() {
    super.initState();
    // 初始化选中标签
    if (widget.tag != null && _tags.contains(widget.tag!)) {
      _selectedTag = widget.tag!;
    }
    WidgetsBinding.instance.addObserver(this); // 注册 App 生命周期监听
    print("ForumScreen initState: Initialized, selectedTag: $_selectedTag, waiting for visibility.");
    // --- 不在 initState 中加载数据 ---
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取 LoadingRouteObserver (如果使用了全局加载提示)
    final observers = NavigationUtils.of(context).widget.observers;
    _routeObserver = observers.whereType<LoadingRouteObserver>().firstOrNull;
    // --- 不在此处触发初始加载 ---
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除监听
    _refreshController.dispose(); // 清理 Controller
    print("ForumScreen dispose: Cleaned up.");
    super.dispose();
  }

  // --- App 生命周期监听回调 (不变) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needsRefresh) {
      print("ForumScreen: App resumed and needs refresh.");
      _refreshData(); // 执行刷新
      _needsRefresh = false; // 重置标记
    } else if (state == AppLifecycleState.paused) {
      _needsRefresh = true; // 标记需要刷新
    }
  }

  // --- 核心：触发首次数据加载 ---
  void _triggerInitialLoad() {
    // 仅在 Widget 变得可见且尚未初始化时执行
    if (_isVisible && !_isInitialized) {
      print("ForumScreen: Now visible and not initialized. Triggering initial load.");
      _isInitialized = true; // 标记为已初始化，防止重复触发
      // 调用加载方法，标记为首次加载
      _loadPosts(page: 1, isInitialLoad: true);
    }
  }

  // --- 清除缓存并刷新 (可选功能，逻辑不变) ---
  Future<void> _clearCacheAndRefresh() async {
    try {
      final tag = _selectedTag == '全部' ? null : _selectedTag;
      print("ForumScreen: Clearing cache for tag: $tag");
      await _forumService.clearForumCache(tag);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('缓存已清除')));
      }
      // 缓存清除后，由 refreshData 触发重新加载
      _refreshData();
    } catch (e) {
      print('清除缓存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('清除缓存失败: $e')));
      }
    }
  }

  // --- 加载帖子数据（核心方法，支持分页和懒加载）---
  Future<void> _loadPosts({required int page, bool isInitialLoad = false, bool isRefresh = false}) async {
    // 防止并发加载
    if (_isLoadingData) {
      print("ForumScreen: LoadPosts skipped, already loading data.");
      return;
    }
    // 必须初始化过，或是由 initialLoad/refresh 触发
    if (!_isInitialized && !isInitialLoad && !isRefresh) {
      print("ForumScreen: LoadPosts skipped, not initialized and not initial/refresh trigger.");
      return;
    }

    if (!mounted) return; // 检查 Widget 是否还在树中

    print("ForumScreen: Starting _loadPosts(page: $page, isInitialLoad: $isInitialLoad, isRefresh: $isRefresh)");

    // 设置加载状态
    setState(() {
      _isLoadingData = true; // 标记核心加载开始
      // 如果是翻页，同时标记分页控件的加载状态
      if (!isInitialLoad && !isRefresh) {
        _isLoadingPage = true;
      }
      // 首次加载或刷新时，清除错误并将帖子设为 null 以显示 Loading
      if (isInitialLoad || isRefresh) {
        _errorMessage = null;
        _posts = null; // 清空帖子以显示 Loading
      }
      // 翻页时不清除 _posts 和 _errorMessage，避免闪烁，错误在 PaginationControls 处理
    });

    // (可选) 显示全局加载指示器（仅在首次或刷新时）
    if (isInitialLoad || isRefresh) {
      _routeObserver?.showLoading();
    }

    try {
      // --- 调用 Service 获取分页数据 ---
      final result = await _forumService.getPostsPage(
        tag: _selectedTag == '全部' ? null : _selectedTag,
        page: page,
        limit: _limit,
      );

      if (!mounted) return; // 异步后检查

      // 解析结果
      final List<Post> fetchedPosts = result['posts'] ?? [];
      final Map<String, dynamic> pagination = result['pagination'] ?? {};

      // 更新状态
      setState(() {
        _posts = fetchedPosts; // **替换**为当前页的数据
        _currentPage = pagination['page'] ?? page; // 使用后端返回的页码
        _totalPages = pagination['pages'] ?? 1; // 使用后端返回的总页数
        _errorMessage = null; // 加载成功，清除错误

        print("ForumScreen: Loaded page: $_currentPage / $_totalPages. Posts count: ${_posts?.length}");
      });

    } catch (e, s) { // 捕获错误
      print('ForumScreen: Load posts error (page $page): $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载帖子失败 (第 $page 页): $e';
        // 如果是首次/刷新失败，保持 _posts 为空以显示错误页
        if (isInitialLoad || isRefresh) {
          _posts = []; // 确保列表为空
          _currentPage = 1;
          _totalPages = 1;
        }
        // 如果是翻页失败，_posts 保持不变，错误信息会传递给 PaginationControls 或在底部显示
      });
    } finally {
      // 结束加载状态
      if (mounted) {
        setState(() {
          _isLoadingData = false; // 结束核心加载
          _isLoadingPage = false; // 结束分页控件加载状态
        });
        // (可选) 隐藏全局加载指示器
        if (isInitialLoad || isRefresh) {
          _routeObserver?.hideLoading();
          // 如果是下拉刷新，通知 RefreshController 完成
          if (isRefresh) {
            _refreshController.refreshCompleted();
          }
        }
        print("ForumScreen: Finished _loadPosts(page: $page, isInitialLoad: $isInitialLoad, isRefresh: $isRefresh)");
      }
    }
  }

  // --- 刷新数据 (调用 _loadPosts) ---
  Future<void> _refreshData() async {
    // 防止重复刷新
    if (_isLoadingData) {
      print("ForumScreen: Refresh skipped, already loading.");
      return;
    }
    if (!mounted) return;
    print("ForumScreen: Refresh triggered.");
    // 直接调用加载第一页，并标记为刷新
    await _loadPosts(page: 1, isRefresh: true);
  }

  // --- UI 切换方法 (逻辑不变) ---
  void _toggleRightPanel() { setState(() { _showRightPanel = !_showRightPanel; }); }
  void _toggleLeftPanel() { setState(() { _showLeftPanel = !_showLeftPanel; }); }

  // --- 处理标签选择 (重置状态并加载) ---
  void _onTagSelected(String tag) {
    // 防止重复选择或在加载时切换
    if (_selectedTag == tag || _isLoadingData) return;
    print("ForumScreen: Tag selected: $tag");
    setState(() {
      _selectedTag = tag;
      _isInitialized = false; // 重置初始化状态，强制重新加载
      _isVisible = false;     // 重置可见状态
      _posts = null;        // 清空帖子以显示 Loading
      _errorMessage = null;   // 清除错误
      _currentPage = 1;     // 重置到第一页
      _totalPages = 1;
      _isLoadingData = false; // 重置加载锁
      _isLoadingPage = false;
    });
    print("ForumScreen: State reset for new tag, waiting for visibility trigger.");
    // 使用 microtask 尝试立即触发加载（如果仍然可见）
    Future.microtask(() {
      if (mounted && _isVisible) {
        _triggerInitialLoad();
      }
    });
  }

  // --- 判断是否为桌面布局 (逻辑不变) ---
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 600; // 阈值可调整
  }

  // --- 导航到创建帖子页面 (逻辑不变，刷新后回第一页) ---
  void _navigateToCreatePost() async {
    final result = await NavigationUtils.pushNamed(context, AppRoutes.createPost);
    // 如果创建成功 (result == true)，刷新列表 (回到第一页)
    if (result == true && mounted) {
      print("ForumScreen: Post created, refreshing data...");
      _refreshData();
    }
  }

  // --- 导航到帖子详情页 (增加浏览量逻辑) ---
  void _navigateToPostDetail(Post post) async {
    // 1. 尝试增加浏览量 (后台操作，不阻塞导航)
    try {
      // 确保 post.id 是有效的 ObjectId 字符串
      final postIdString = post.id is mongo.ObjectId ? (post.id as mongo.ObjectId).toHexString() : post.id.toString();
      if (postIdString.isNotEmpty) {
        print("ForumScreen: Incrementing view count for post $postIdString");
        // 注意：这里是异步调用，但我们不 await 它，让它在后台执行
        _forumService.incrementPostView(postIdString).catchError((e) {
          print("ForumScreen: Failed to increment view count silently: $e");
        });
      }
    } catch (e) {
      // 即使增加浏览量失败，也继续导航
      print("ForumScreen: Error preparing to increment view count: $e");
    }

    // 2. 执行导航
    print("ForumScreen: Navigating to post detail for ${post.id}");
    final result = await NavigationUtils.pushNamed(
        context, AppRoutes.postDetail,
        arguments: post.id // 传递帖子 ID
    );

    // 3. 处理从详情页返回的结果
    if (!mounted) return; // 返回后检查 mounted

    if (result == true) { // 通用成功标记？可能需要刷新
      print("ForumScreen: Returned from detail with generic success, refreshing data...");
      _refreshData();
    } else if (result is Map) {
      if (result['deleted'] == true) { // 帖子被删除了
        print("ForumScreen: Post deleted from detail, refreshing data...");
        _refreshData(); // 刷新整个列表（回到第一页）
      } else if (result['updated'] == true) { // 帖子被更新了
        print("ForumScreen: Post updated from detail, refreshing current page...");
        // 刷新当前页数据，而不是回到第一页
        _loadPosts(page: _currentPage, isRefresh: true); // 标记为刷新以重新获取
      }
    }
  }

  // --- 翻页逻辑 ---
  void _goToNextPage() {
    // 必须有下一页，并且当前不在加载中
    if (_currentPage < _totalPages && !_isLoadingData) {
      print("ForumScreen: Going to next page (${_currentPage + 1})");
      _loadPosts(page: _currentPage + 1); // 加载下一页
    } else {
      print("ForumScreen: Cannot go to next page (currentPage: $_currentPage, totalPages: $_totalPages, isLoading: $_isLoadingData)");
    }
  }

  void _goToPreviousPage() {
    // 必须不是第一页，并且当前不在加载中
    if (_currentPage > 1 && !_isLoadingData) {
      print("ForumScreen: Going to previous page (${_currentPage - 1})");
      _loadPosts(page: _currentPage - 1); // 加载上一页
    } else {
      print("ForumScreen: Cannot go to previous page (currentPage: $_currentPage, isLoading: $_isLoadingData)");
    }
  }

  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    // 获取布局和颜色信息 (不变)
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(context);
    final bool canShowLeftPanelBasedOnWidth = screenWidth >= _hideLeftPanelThreshold;
    final bool canShowRightPanelBasedOnWidth = screenWidth >= _hideRightPanelThreshold;
    final bool actuallyShowLeftPanel = isDesktop && _showLeftPanel && canShowLeftPanelBasedOnWidth;
    final bool actuallyShowRightPanel = isDesktop && _showRightPanel && canShowRightPanelBasedOnWidth;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.white54;
    final Color enabledColor = Colors.white;

    // 使用 VisibilityDetector 包裹 Scaffold
    return VisibilityDetector(
      key: Key('forum_screen_visibility'), // 唯一 Key
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          Future.microtask(() { // 安全地更新状态
            if (mounted) {
              setState(() { _isVisible = currentlyVisible; });
            } else { _isVisible = currentlyVisible; }
            // 如果变为可见，尝试触发初始加载
            if (_isVisible) { _triggerInitialLoad(); }
          });
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: '论坛',
          actions: [ // AppBar 按钮
            // 桌面端左侧面板切换按钮
            if (isDesktop)
              IconButton(
                icon: Icon(Icons.menu_open, color: actuallyShowLeftPanel ? secondaryColor : (_showLeftPanel ? disabledColor : enabledColor)),
                onPressed: canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
                tooltip: _showLeftPanel ? (canShowLeftPanelBasedOnWidth ? '隐藏分类' : '屏幕宽度不足') : (canShowLeftPanelBasedOnWidth ? '显示分类' : '屏幕宽度不足'),
              ),
            // 桌面端右侧面板切换按钮
            if (isDesktop)
              IconButton(
                icon: Icon(Icons.bar_chart, color: actuallyShowRightPanel ? secondaryColor : (_showRightPanel ? disabledColor : enabledColor)),
                onPressed: canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
                tooltip: _showRightPanel ? (canShowRightPanelBasedOnWidth ? '隐藏统计' : '屏幕宽度不足') : (canShowRightPanelBasedOnWidth ? '显示统计' : '屏幕宽度不足'),
              ),
            // 刷新按钮 (加载中禁用)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoadingData ? null : _refreshData, // 核心加载锁
              tooltip: '刷新帖子',
            ),
            // 发布新帖按钮 (登录后可见)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return authProvider.isLoggedIn
                    ? IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: _navigateToCreatePost,
                  tooltip: '发布新帖子',
                )
                    : const SizedBox.shrink(); // 未登录不显示
              },
            ),
          ],
        ),
        // Body 使用 Column 包含 Filter(Mobile)/Content/Pagination
        body: Column(
          children: [
            // 移动端标签过滤器
            if (!isDesktop)
              TagFilter(
                tags: _tags,
                selectedTag: _selectedTag,
                onTagSelected: _onTagSelected, // 绑定回调
              ),
            // 主内容区域，需要 Expanded
            Expanded(
              child: _buildBodyContent(isDesktop, actuallyShowLeftPanel, actuallyShowRightPanel),
            ),
            // 分页控件
            PaginationControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              isLoading: _isLoadingPage, // 使用分页加载状态
              onPreviousPage: _goToPreviousPage, // 绑定上一页回调
              onNextPage: _goToNextPage,       // 绑定下一页回调
            ),
          ],
        ),
      ),
    );
  }

  // --- 构建 Body 内容 (根据状态显示 Loading/Error/List) ---
  Widget _buildBodyContent(bool isDesktop, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    // State 1: Not initialized
    if (!_isInitialized && !_isLoadingData) {
      print("ForumScreen Body: Not initialized, showing Loading.");
      return const Center(child: LoadingWidget(message: "等待加载论坛..."));
    }
    // State 2: Loading initial data or refreshing, and list is currently null/empty
    else if (_isLoadingData && (_posts == null || _posts!.isEmpty)) {
      print("ForumScreen Body: Loading initial/refresh, showing Loading.");
      return const Center(child: LoadingWidget(message: '正在加载帖子...'));
    }
    // State 3: Error occurred, and list is null/empty (initial/refresh error)
    else if (_errorMessage != null && (_posts == null || _posts!.isEmpty)) {
      print("ForumScreen Body: Error and no data, showing ErrorWidget.");
      return Center( // 居中显示错误
        child: CustomErrorWidget( // 或 InlineErrorWidget
          title: "加载失败",
          errorMessage: _errorMessage!,
          // 重试总是加载第一页并视为刷新
          onRetry: () => _loadPosts(page: 1, isRefresh: true),
        ),
      );
    }
    // State 4: Data is ready (list might be populated or empty), or pagination error occurred
    else {
      print("ForumScreen Body: Data ready or pagination error, building layout.");
      // 构建桌面或移动端布局
      // 注意：RefreshIndicator 现在只包裹移动端的列表，桌面端不直接包裹 Row
      return isDesktop
          ? _buildDesktopLayout(actuallyShowLeftPanel, actuallyShowRightPanel)
          : _buildMobileLayout(); // 移动布局内部处理 RefreshIndicator
    }
  }


  // --- 构建桌面布局 (Row + Panels + List) ---
  Widget _buildDesktopLayout(bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧分类面板
        if (actuallyShowLeftPanel)
          ForumLeftPanel( // 假设组件存在
            tags: _tags,
            selectedTag: _selectedTag,
            onTagSelected: _onTagSelected,
          ),
        // 中间帖子列表区域
        Expanded(
          child: _buildPostsList(true, actuallyShowLeftPanel, actuallyShowRightPanel), // 传递布局信息
        ),
        // 右侧统计面板
        if (actuallyShowRightPanel)
        // 仅当 _posts 非 null 且非空时才尝试构建右侧面板
          (_posts != null && _posts!.isNotEmpty)
              ? ForumRightPanel( // 假设组件存在
            currentPosts: _posts!, // 传递当前页帖子
            selectedTag: _selectedTag == '全部' ? null : _selectedTag,
            onTagSelected: _onTagSelected,
          )
              : const SizedBox.shrink(), // 如果帖子为空，不显示右侧面板
      ],
    );
  }

  // --- 构建移动端布局 (仅列表，由外部 Column 添加 Filter 和 Pagination) ---
  Widget _buildMobileLayout() {
    // 移动端布局只包含帖子列表，由 _buildPostsList 构建
    // RefreshIndicator 包裹在 _buildPostsList 返回的 Widget 外部（如果需要）
    // 或者在 _buildPostsList 内部返回 RefreshIndicator 包裹的列表
    return _buildPostsList(false); // 调用列表构建器
  }

  // --- 构建帖子列表/网格 (处理空状态和 Null) ---
  Widget _buildPostsList(bool isDesktop, [bool actuallyShowLeftPanel = false, bool actuallyShowRightPanel = false]) {
    // 安全检查：如果 _posts 是 null (理论上在调用此方法前已被处理，但加一层保险)
    if (_posts == null) {
      print("ForumScreen PostsList: Safety check failed, _posts is null.");
      // 可以返回一个错误提示或空的 SizedBox
      return const Center(child: Text("内部错误：帖子数据丢失"));
      // return const SizedBox.shrink();
    }

    // 处理空列表状态 (加载完成但无数据)
    if (_posts!.isEmpty && !_isLoadingData) { // 确保不是在加载过程中判断为空
      print("ForumScreen PostsList: List is empty, showing empty state.");
      // 可以使用之前的 InlineErrorWidget 或专门的空状态组件
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column( // 使用 Column 组织图标和文字
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 60, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                _selectedTag == '全部' ? '论坛暂无帖子' : '“$_selectedTag”分类下暂无帖子',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // 提供刷新或发布按钮
              TextButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("刷新试试"),
                onPressed: _refreshData,
              ),
              Consumer<AuthProvider>(builder: (ctx, auth, _) => auth.isLoggedIn
                  ? TextButton.icon(icon: Icon(Icons.add), label: Text("发布一篇"), onPressed: _navigateToCreatePost)
                  : SizedBox.shrink()
              ),
            ],
          ),
        ),
      );
    }

    // --- 构建实际的列表或网格 ---
    print("ForumScreen PostsList: Building list/grid with ${_posts!.length} items.");
    final listOrGridWidget = isDesktop
        ? _buildDesktopPostsGrid(actuallyShowLeftPanel, actuallyShowRightPanel)
        : _buildMobilePostsList();

    // --- RefreshIndicator 只包裹移动端的列表 ---
    return isDesktop
        ? listOrGridWidget // 桌面版不加顶层 RefreshIndicator (如果需要可以加)
        : RefreshIndicator(
      key: ValueKey(_selectedTag), // Key 变化时会重建 RefreshIndicator 状态
      onRefresh: _refreshData,     // 绑定下拉刷新回调
      child: listOrGridWidget,     // 包裹移动端列表
    );
  }

  // --- 构建移动端帖子列表 (ListView) ---
  Widget _buildMobilePostsList() {
    // Safety check (already done in _buildPostsList, but good practice)
    if (_posts == null) return const SizedBox.shrink();

    // 使用 ListView.builder
    return ListView.builder(
      // physics: const AlwaysScrollableScrollPhysics(), // 已移到 RefreshIndicator
      padding: const EdgeInsets.all(8), // 列表边距
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        // 使用 GestureDetector 包裹卡片以处理点击导航
        return GestureDetector(
          onTap: () => _navigateToPostDetail(post), // 点击跳转详情页
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 卡片间距
            child: PostCard( // 帖子卡片组件
              post: post,
              isDesktopLayout: false, // 明确是移动端布局
              onDeleted: () { // 删除回调
                print("ForumScreen: Post deleted via mobile card, refreshing...");
                _refreshData(); // 刷新列表
              },
              // 可能需要添加 onUpdated 回调等
            ),
          ),
        );
      },
    );
  }

  // --- 构建桌面端帖子网格 (MasonryGridView) ---
  Widget _buildDesktopPostsGrid(bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    // Safety check
    if (_posts == null) return const SizedBox.shrink();

    // 动态计算列数 (不变)
    int crossAxisCount = 3; // Default
    if (actuallyShowLeftPanel && actuallyShowRightPanel) { crossAxisCount = 2; }
    else if (!actuallyShowLeftPanel && !actuallyShowRightPanel) { crossAxisCount = 4; }

    // 使用 MasonryGridView
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount, // 列数
      mainAxisSpacing: 8, // 垂直间距
      crossAxisSpacing: 16, // 水平间距
      padding: const EdgeInsets.all(16), // 网格内边距
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        // 桌面版 PostCard 通常内部处理点击，如果需要外部处理则加 GestureDetector
        return PostCard( // 帖子卡片组件
          post: post,
          isDesktopLayout: true, // 明确是桌面布局
          onDeleted: () { // 删除回调
            print("ForumScreen: Post deleted via desktop card, refreshing...");
            _refreshData(); // 刷新列表
          },
          // 可能需要 onUpdated 等回调
        );
      },
    );
  }
}

// --- RefreshController 类 (保持不变) ---
class RefreshController {
  VoidCallback? _onRefreshCompletedCallback;
  void addListener(VoidCallback listener) {
    _onRefreshCompletedCallback = listener;
  }
  void refreshCompleted() {
    _onRefreshCompletedCallback?.call();
  }
  void dispose() {
    _onRefreshCompletedCallback = null;
  }
}