// lib/screens/forum/forum_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/components/loading/loading_route_observer.dart';
import 'package:suxingchahui/widgets/components/form/postform/config/post_taglists.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/post_card.dart';
import 'package:suxingchahui/widgets/components/screen/forum/tag_filter.dart';
import 'package:suxingchahui/widgets/components/screen/forum/panel/forum_right_panel.dart';
import 'package:suxingchahui/widgets/components/screen/forum/panel/forum_left_panel.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'refresh_controller.dart';

class ForumScreen extends StatefulWidget {
  final String? tag;

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with WidgetsBindingObserver {
  final ForumService _forumService = ForumService();
  final List<String> _tags = PostTagLists.filterTags;
  String _selectedTag = '全部';
  List<Post>? _posts;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  // --- 状态变量 ---
  bool _isVisible = false; // Widget 是否可见
  bool _isLoadingData = false; // 是否正在执行加载操作 (API 调用或强制刷新)
  bool _isInitialized = false; // 是否已尝试过首次加载
  bool _needsRefresh = false; // 是否需要在变为可见或后台恢复时刷新

  final RefreshController _refreshController = RefreshController();

  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  LoadingRouteObserver? _routeObserver;

  // --- 缓存监听 ---
  StreamSubscription<dynamic>? _cacheSubscription;
  String _currentWatchIdentifier = ''; // 用于标识当前监听的参数组合

  // --- Debounce Timer ---
  Timer? _refreshDebounceTimer;

  static const double _hideRightPanelThreshold = 950.0;
  static const double _hideLeftPanelThreshold = 750.0;

  @override
  void initState() {
    super.initState();
    if (widget.tag != null && _tags.contains(widget.tag!)) {
      _selectedTag = widget.tag!;
    }
    WidgetsBinding.instance.addObserver(this);
    print("ForumScreen initState: Tag=$_selectedTag");
    // 不在此处加载，依赖 VisibilityDetector
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observers = NavigationUtils
        .of(context)
        .widget
        .observers;
    _routeObserver = observers
        .whereType<LoadingRouteObserver>()
        .firstOrNull;
    print("ForumScreen didChangeDependencies");
    // Maybe trigger load if visible here? Or rely solely on VisibilityDetector
  }

  @override
  void dispose() {
    print("ForumScreen dispose: Tag=$_selectedTag");
    _stopWatchingCache(); // 停止监听
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    _refreshDebounceTimer?.cancel(); // 取消 debounce timer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("ForumScreen: App resumed.");
      // 如果需要刷新，并且当前可见，则刷新
      if (_needsRefresh && _isVisible) {
        print(
            "ForumScreen: Needs refresh on resume and visible, triggering refresh.");
        // 使用 Debounce 避免过于频繁的刷新
        _refreshDataIfNeeded(reason: "App Resumed with NeedsRefresh");
        _needsRefresh = false; // 重置标记
      } else if (_isVisible) {
        // 如果只是恢复且可见，也检查一下
        print(
            "ForumScreen: App resumed and visible, checking for potential refresh.");
        _refreshDataIfNeeded(reason: "App Resumed");
      }
      // 如果恢复时不可见，则在 VisibilityDetector 变为可见时处理 _needsRefresh
    } else if (state == AppLifecycleState.paused) {
      print("ForumScreen: App paused.");
      _needsRefresh = true; // App 进入后台，标记下次回来时需要检查刷新
    }
  }

  // --- 核心加载逻辑 ---
  Future<void> _loadPosts({required int page,
    bool isInitialLoad = false,
    bool isRefresh = false}) async {
    // 防止在加载过程中重复触发（除非是强制刷新）
    if (_isLoadingData && !isRefresh) {
      print("ForumScreen _loadPosts: Skipped, already loading page $page.");
      return;
    }
    if (!mounted) return;

    print(
        "ForumScreen _loadPosts: Loading page $page. Initial: $isInitialLoad, Refresh: $isRefresh");
    _isInitialized = true; // 标记已尝试加载

    // --- 设置加载状态，触发 UI 重建显示 Loading ---
    // 只有在首次加载、强制刷新或分页时才清空旧数据并显示 Loading
    // 缓存事件触发的刷新，我们希望尽量平滑过渡
    setState(() {
      _isLoadingData = true;
      _errorMessage = null; // 清除旧错误
      if (isInitialLoad || isRefresh || _posts == null) {
        // 首次加载、刷新、或之前就没有数据时，清空
        print("ForumScreen _loadPosts: Clearing posts to show loading state.");
        _posts = null;
      }
      // 分页加载时，不清空 _posts，让旧数据显示，只在分页控件显示 loading
      // _isLoadingPage = (page != _currentPage && !isRefresh); // 这个状态似乎多余了
    });

    // 只有强制刷新或首次加载（且无缓存）时显示全局路由 Loading
    final bool showRouteLoading =
        isRefresh || (isInitialLoad && _posts == null);
    if (showRouteLoading) _routeObserver?.showLoading();

    // --- 调用 Service 获取数据 ---
    try {
      final result = await _forumService.getPostsPage(
        tag: _selectedTag == '全部' ? null : _selectedTag,
        page: page,
        limit: _limit,
      );

      if (!mounted) return; // 获取数据后检查组件是否还在

      // --- *** 处理结果并强制 setState *** ---
      if (result != null) {
        final List<Post> fetchedPosts = result['posts'] ?? [];
        final Map<String, dynamic> pagination = result['pagination'] ?? {};
        final int serverPage = pagination['page'] ?? page;
        final int serverTotalPages = pagination['pages'] ?? 1;

        // *** 无论如何，获取到数据后就调用 setState 更新状态 ***
        setState(() {
          _posts = fetchedPosts;
          _currentPage = serverPage; // 使用服务器返回的页码
          _totalPages = serverTotalPages;
          _errorMessage = null; // 清除错误
          print(
              "ForumScreen _loadPosts: Success. setState triggered. Page: $_currentPage/$_totalPages. Posts: ${_posts
                  ?.length}");
        });

        // --- !!! 数据加载成功后，确保监听器指向当前页 !!! ---
        _startOrUpdateWatchingCache();
      } else {
        // 如果 service 返回 null (例如内部解析错误)
        throw Exception("ForumService returned null data.");
      }
    } catch (e, s) {
      print('ForumScreen _loadPosts: Error (page $page): $e\nStackTrace: $s');
      if (!mounted) return;
      // *** 出错也要 setState 更新错误信息 ***
      setState(() {
        _errorMessage = '加载帖子失败: $e';
        // 如果是首次加载或刷新出错，清空帖子列表
        if (isInitialLoad || isRefresh) {
          _posts = []; // 显示空/错误状态
          _currentPage = 1;
          _totalPages = 1;
        }
        // 分页出错，可以选择保留旧数据，只显示错误信息
      });
      // 出错时停止监听？可以考虑，避免无效监听
      // _stopWatchingCache();
    } finally {
      if (mounted) {
        // *** 加载结束（无论成功失败）都要 setState 更新加载状态 ***
        setState(() {
          _isLoadingData = false;
        });
        if (showRouteLoading) _routeObserver?.hideLoading();
        if (isRefresh) _refreshController.refreshCompleted();
      }
    }
  }

  // --- 刷新数据 (调用 _loadPosts 强制刷新第一页) ---
  Future<void> _refreshData() async {
    if (_isLoadingData) return;
    if (!mounted) return;
    print("ForumScreen: Refresh triggered, loading page 1 forcefully.");
    setState(() {
      _currentPage = 1; // 重置到第一页
      // _totalPages = 1; // 可以在加载成功后更新
    });
    await _loadPosts(page: 1, isRefresh: true);
  }

  // --- 触发首次加载 (仅在未初始化时调用) ---
  void _triggerInitialLoad() {
    if (!_isInitialized && !_isLoadingData) {
      print("ForumScreen: Triggering initial load (page 1).");
      _loadPosts(page: 1, isInitialLoad: true); // 加载第一页
    } else if (!_isLoadingData && _posts == null) {
      print("ForumScreen: Initialized but no posts, triggering reload.");
      // 如果初始化了但没数据（可能上次失败），也重新加载
      _loadPosts(page: 1, isInitialLoad: true, isRefresh: true);
    }
  }

  // --- 开始/更新监听缓存 ---
  void _startOrUpdateWatchingCache() {
    final String newWatchIdentifier = "${_selectedTag}_${_currentPage}";
    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      // print("ForumScreen: Watch identifier hasn't changed ($newWatchIdentifier). Keeping current subscription.");
      return;
    }

    _stopWatchingCache(); // 停止旧的
    _currentWatchIdentifier = newWatchIdentifier;
    print(
        "ForumScreen: Starting/Updating cache watch for Identifier: $_currentWatchIdentifier");

    try {
      _cacheSubscription = _forumService
          .watchForumPageChanges(
        tag: _selectedTag == '全部' ? null : _selectedTag,
        page: _currentPage,
        limit: _limit,
      )
          .listen(
            (dynamic event) {
          // --- *** 监听到变化后的核心处理 *** ---
          print(
              "ForumScreen: Cache change detected for $_currentWatchIdentifier. Event: ${event
                  ?.runtimeType}");
          if (_isVisible) {
            print(
                "ForumScreen: Visible, triggering debounced refresh due to cache change.");
            // 使用 Debounce 避免短时间内多次无效的刷新
            _refreshDataIfNeeded(reason: "Cache Changed");
          } else {
            print(
                "ForumScreen: Not visible, marking for refresh on next visibility/resume.");
            _needsRefresh = true; // 标记需要刷新
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          print(
              "ForumScreen: Error listening to cache changes ($_currentWatchIdentifier): $error\n$stackTrace");
          _stopWatchingCache();
        },
        onDone: () {
          print(
              "ForumScreen: Cache watch stream done ($_currentWatchIdentifier).");
          // 如果是当前监听结束，清空标识符
          if (_currentWatchIdentifier == newWatchIdentifier) {
            _currentWatchIdentifier = '';
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      print(
          "ForumScreen: Failed to start watching cache ($_currentWatchIdentifier): $e");
      _currentWatchIdentifier = ''; // 出错清空
    }
  }

  // --- 停止监听缓存 ---
  void _stopWatchingCache() {
    if (_cacheSubscription != null) {
      print(
          "ForumScreen: Stopping cache watch (Identifier: $_currentWatchIdentifier).");
      _cacheSubscription!.cancel();
      _cacheSubscription = null;
      // Optionally clear identifier immediately
      // _currentWatchIdentifier = '';
    }
  }

  // --- Debounced 刷新 ---
  void _refreshDataIfNeeded({required String reason}) {
    // if (_isLoadingData) { // Debounce 期间也可能 isLoadingData=true，允许覆盖 timer
    //   print("ForumScreen: Refresh skipped (already loading data), triggered by: $reason");
    //   return;
    // }
    if (!mounted) return;

    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // 稍微加长 debounce 时间
      if (mounted && _isVisible && !_isLoadingData) {
        // 确保执行时可见且不在加载
        print(
            "ForumScreen: Debounced refresh executing, triggered by: $reason");
        // --- *** Debounce 后强制刷新当前页 *** ---
        _loadPosts(page: _currentPage, isRefresh: true);
      } else if (mounted) {
        print(
            "ForumScreen: Debounced refresh skipped (not visible or already loading). Triggered by: $reason");
        if (!_isVisible) _needsRefresh = true; // 如果是因为不可见而跳过，还是要标记
      }
    });
  }

  // --- 处理标签选择 ---
  void _onTagSelected(String tag) {
    if (_selectedTag == tag || _isLoadingData) return;
    print("ForumScreen: Tag selected: $tag");
    setState(() {
      _selectedTag = tag;
      _currentPage = 1; // 重置到第一页
      _totalPages = 1;
      _posts = null; // 清空旧数据，准备显示 Loading
      _errorMessage = null;
      _isInitialized = false; // 重置初始化状态
      _needsRefresh = false; // 清除刷新标记
      _isLoadingData = false; // 确保不在加载状态
    });
    // 停止旧标签的监听
    _stopWatchingCache();
    // 如果当前可见，立即触发新标签的加载
    if (_isVisible) {
      print(
          "ForumScreen: Tag changed and visible, triggering initial load for new tag.");
      _triggerInitialLoad(); // 这会调用 _loadPosts(isInitialLoad: true)
    }
  }

  // --- 翻页逻辑 ---
  void _goToNextPage() {
    if (_currentPage < _totalPages && !_isLoadingData) {
      print("ForumScreen: Going to next page (${_currentPage + 1})");
      // 先停止当前页的监听
      _stopWatchingCache();
      setState(() {
        _currentPage++;
        _posts = null; // 清空帖子以显示 Loading
        _errorMessage = null;
      });
      // 加载新页，非强制刷新
      _loadPosts(page: _currentPage, isInitialLoad: false, isRefresh: false);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoadingData) {
      print("ForumScreen: Going to previous page (${_currentPage - 1})");
      // 先停止当前页的监听
      _stopWatchingCache();
      setState(() {
        _currentPage--;
        _posts = null; // 清空帖子以显示 Loading
        _errorMessage = null;
      });
      // 加载新页，非强制刷新
      _loadPosts(page: _currentPage, isInitialLoad: false, isRefresh: false);
    }
  }

  // --- 导航到帖子详情页 ---
  void _navigateToPostDetail(Post post) async {
    _stopWatchingCache(); // 进入详情页前停止监听列表
    print(
        "ForumScreen: Navigating to detail for post ${post
            .id}, stopped watching list cache.");

    await NavigationUtils.pushNamed(context, AppRoutes.postDetail,
        arguments: post.id);

    // 从详情页返回
    print("ForumScreen: Returned from detail.");
    if (mounted) {
      // 重新启动监听并检查是否需要刷新
      _startOrUpdateWatchingCache(); // 监听返回时的当前页
      if (_isVisible) {
        // 只有可见时才检查刷新
        print(
            "ForumScreen: Returned from detail and visible, checking for refresh.");
        _refreshDataIfNeeded(reason: "Returned From Detail");
      }
    }
  }

  // --- 其他 UI 相关方法保持不变 ---
  void _toggleRightPanel() {
    setState(() {
      _showRightPanel = !_showRightPanel;
    });
  }

  void _toggleLeftPanel() {
    setState(() {
      _showLeftPanel = !_showLeftPanel;
    });
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery
        .of(context)
        .size
        .width > 600;
  }

  void _navigateToCreatePost() async {
    final result =
    await NavigationUtils.pushNamed(context, AppRoutes.createPost);
    // 如果创建成功 (result == true)，刷新列表 (回到第一页)
    if (result == true && mounted) {
      _refreshData();
    }
  }

  Future<void> _handleDeletePostFromCard(String postId) async {
    print("ForumScreen: Received delete request for post $postId from card.");
    // 使用确认对话框，确保用户意图
    await CustomConfirmDialog.show(
      context: context,
      title: '确认删除',
      message: '确定要从列表删除此帖子吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          // 调用 Service 删除
          await _forumService.deletePost(postId);
          if (!mounted) return;
          AppSnackBar.showSuccess(context, '帖子已删除');
          // 删除成功后，刷新列表（通常回到第一页）
          _refreshData(); // 或者根据需求刷新当前页 _loadPosts(page: _currentPage, isRefresh: true);
        } catch (e) {
          if (!mounted) return;
          AppSnackBar.showError(context, '删除失败: $e');
          // Rethrow ? 或许不需要，已经在 SnackBar 显示错误
          // throw e; // 让 PostCard 那边的 try-catch 捕获 (但现在不需要了)
        }
      },
    );
  }

  void _handleEditPostFromCard(Post post) async {
    // 直接导航到编辑页面
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post.id, // 传递整个 Post 对象给编辑页
    );

    // 如果编辑成功，刷新当前页
    if (result == true && mounted) {
      // 刷新当前页数据，而不是回到第一页
      _loadPosts(page: _currentPage, isRefresh: true);
    }
  }

  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final isDesktop = _isDesktop(context);
    final bool canShowLeftPanelBasedOnWidth =
        screenWidth >= _hideLeftPanelThreshold;
    final bool canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold;
    final bool actuallyShowLeftPanel =
        isDesktop && _showLeftPanel && canShowLeftPanelBasedOnWidth;
    final bool actuallyShowRightPanel =
        isDesktop && _showRightPanel && canShowRightPanelBasedOnWidth;
    final Color secondaryColor = Theme
        .of(context)
        .colorScheme
        .secondary;
    final Color disabledColor = Colors.white54;
    final Color enabledColor = Colors.white;

    print(
        "ForumScreen build: Tag=$_selectedTag, Page=$_currentPage, IsLoading=$_isLoadingData, IsVisible=$_isVisible, Posts=${_posts
            ?.length}, Error=$_errorMessage");

    return VisibilityDetector(
      // *** 使用 Tag 和 Page 作为 Key，确保切换时重建 VisibilityDetector 状态 ***
      key: Key('forum_screen_visibility_${_selectedTag}_$_currentPage'),
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          print(
              "ForumScreen Visibility Changed: now ${currentlyVisible
                  ? 'Visible'
                  : 'Hidden'} (Tag: $_selectedTag, Page: $_currentPage)");
          _isVisible = currentlyVisible;
          if (mounted) setState(() {}); // 更新可见状态

          if (_isVisible) {
            // --- 变为可见 ---
            _triggerInitialLoad(); // 确保首次加载被触发（如果还没加载过）
            _startOrUpdateWatchingCache(); // 启动或更新监听
            // 如果需要刷新（例如后台回来，或缓存事件发生时不可见）
            if (_needsRefresh) {
              print(
                  "ForumScreen: Became visible and needs refresh, triggering refresh.");
              _refreshDataIfNeeded(reason: "Became Visible with NeedsRefresh");
              _needsRefresh = false; // 重置标记
            } else if (_isInitialized && _posts == null && !_isLoadingData) {
              // 如果初始化过但没数据（可能上次加载失败），也尝试重新加载
              print(
                  "ForumScreen: Became visible, initialized but no posts, triggering reload.");
              _loadPosts(page: _currentPage, isRefresh: true);
            }
          } else {
            // --- 变为不可见 ---
            _stopWatchingCache(); // 停止监听
            _refreshDebounceTimer?.cancel(); // 取消可能存在的 debounce
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: '论坛',
          actions: [
            // AppBar 按钮
            // 桌面端左侧面板切换按钮
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () =>
                  NavigationUtils.pushNamed(context, AppRoutes.searchPost),
              tooltip: '搜索游戏',
            ),
            if (isDesktop)
              IconButton(
                icon: Icon(Icons.menu_open,
                    color: actuallyShowLeftPanel
                        ? secondaryColor
                        : (_showLeftPanel ? disabledColor : enabledColor)),
                onPressed:
                canShowLeftPanelBasedOnWidth ? _toggleLeftPanel : null,
                tooltip: _showLeftPanel
                    ? (canShowLeftPanelBasedOnWidth
                    ? '隐藏分类'
                    : '屏幕宽度不足')
                    : (canShowLeftPanelBasedOnWidth
                    ? '显示分类'
                    : '屏幕宽度不足'),
              ),
            // 桌面端右侧面板切换按钮
            if (isDesktop)
              IconButton(
                icon: Icon(Icons.bar_chart,
                    color: actuallyShowRightPanel
                        ? secondaryColor
                        : (_showRightPanel ? disabledColor : enabledColor)),
                onPressed:
                canShowRightPanelBasedOnWidth ? _toggleRightPanel : null,
                tooltip: _showRightPanel
                    ? (canShowRightPanelBasedOnWidth
                    ? '隐藏统计'
                    : '屏幕宽度不足')
                    : (canShowRightPanelBasedOnWidth
                    ? '显示统计'
                    : '屏幕宽度不足'),
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
                  icon:
                  Icon(Icons.add_circle_outline, color: Colors.white),
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
            if (!isDesktop)
              TagFilter(
                tags: _tags,
                selectedTag: _selectedTag,
                onTagSelected: _onTagSelected,
              ),
            Expanded(
              child: _buildBodyContent(
                  isDesktop, actuallyShowLeftPanel, actuallyShowRightPanel),
            ),
            // 分页控件: 数据加载完成，帖子非null，且总页数大于1时显示
            if (!_isLoadingData && _posts != null && _totalPages > 1)
              PaginationControls(
                currentPage: _currentPage,
                totalPages: _totalPages,
                isLoading: false,
                // 控件本身不显示加载状态了
                onPreviousPage: _goToPreviousPage,
                onNextPage: _goToNextPage,
              ),
          ],
        ),
      ),
    );
  }

  // --- 构建 Body 内容 ---
  Widget _buildBodyContent(bool isDesktop, bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel) {
    // 1. 如果出错，并且没有帖子数据显示（或者帖子为空）
    if (_errorMessage != null && (_posts == null || _posts!.isEmpty)) {
      print("  -> Showing ErrorWidget");
      return InlineErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: () => _loadPosts(page: _currentPage, isRefresh: true), // 重试当前页
      );
    }

    // 2. 如果正在加载，并且没有旧帖子数据显示 (_posts 为 null)
    if (_isLoadingData && _posts == null) {
      print("  -> Showing LoadingWidget (initial/page change)");
      return LoadingWidget.inline(message: '正在加载帖子...');
    }

    // 3. 如果加载完成，但帖子列表为空
    if (!_isLoadingData && _posts != null && _posts!.isEmpty) {
      return EmptyStateWidget(message: "啥也没有"); // 调用独立的空状态构建方法
    }

    // 4. 如果有帖子数据（无论是否正在后台加载刷新）
    if (_posts != null && _posts!.isNotEmpty) {
      print("  -> Building Layout with posts");
      // 构建主布局，列表构建函数内部会处理 _posts!
      return isDesktop
          ? _buildDesktopLayout(actuallyShowLeftPanel, actuallyShowRightPanel)
          : _buildMobileLayout();
    }

    // 5. 其他情况（理论上不应到达，例如 _posts 为 null 但不在加载也没错误）
    print("  -> Fallback: Showing initial loading prompt or empty SizedBox");
    // 可能是在初始化但还不可见，或者状态异常
    return LoadingWidget.inline(message: "等待加载..."); // 或者 SizedBox.shrink()
  }

  // --- 构建桌面布局 (Row + Panels + List) ---
  Widget _buildDesktopLayout(bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel) {
    // 定义面板动画参数
    const Duration panelAnimationDuration = Duration(milliseconds: 300);
    const Duration leftPanelDelay = Duration(milliseconds: 50);
    const Duration rightPanelDelay = Duration(milliseconds: 100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 左侧分类面板带动画 ---
        if (actuallyShowLeftPanel)
          FadeInSlideLRItem( // <--- 包裹左面板
            key: const ValueKey('forum_left_panel'),
            slideDirection: SlideDirection.left,
            duration: panelAnimationDuration,
            delay: leftPanelDelay,
            child: ForumLeftPanel(
              tags: _tags,
              selectedTag: _selectedTag,
              onTagSelected: _onTagSelected,
            ),
          ),
        // 中间帖子列表区域
        Expanded(
          child: _buildPostsList(
              true, actuallyShowLeftPanel, actuallyShowRightPanel), // 传递布局信息
        ),
        // 右侧统计面板
        // --- 右侧统计面板带动画 ---
        if (actuallyShowRightPanel)
        // 仅当 _posts 非 null 且非空时才尝试构建右侧面板
          (_posts != null && _posts!.isNotEmpty)
              ? FadeInSlideLRItem( // <--- 包裹右面板
            key: const ValueKey('forum_right_panel'),
            slideDirection: SlideDirection.right,
            duration: panelAnimationDuration,
            delay: rightPanelDelay,
            child: ForumRightPanel(
              currentPosts: _posts!,
              selectedTag: _selectedTag == '全部' ? null : _selectedTag,
              onTagSelected: _onTagSelected,
            ),
          )
              : const SizedBox.shrink(),
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
  Widget _buildPostsList(bool isDesktop,
      [bool actuallyShowLeftPanel = false,
        bool actuallyShowRightPanel = false]) {
    // 安全检查：如果 _posts 是 null (理论上在调用此方法前已被处理，但加一层保险)
    if (_posts == null) {
      print(
          "ForumScreen _buildPostsList: Error - _posts is null unexpectedly!");
      return InlineErrorWidget(errorMessage: "无法构建帖子列表");
    }

    final listOrGridWidget = isDesktop
        ? _buildDesktopPostsGrid(actuallyShowLeftPanel, actuallyShowRightPanel,
        onDeleteAction: _handleDeletePostFromCard,
        onEditAction: _handleEditPostFromCard)
        : _buildMobilePostsList(
        onDeleteAction: _handleDeletePostFromCard,
        onEditAction: _handleEditPostFromCard);

    return isDesktop
        ? listOrGridWidget
        : RefreshIndicator(
      key: ValueKey(_selectedTag),
      onRefresh: _refreshData,
      child: listOrGridWidget,
    );
  }

  // --- 构建移动端帖子列表 (ListView) ---
  Widget _buildMobilePostsList({
    required Future<void> Function(String postId) onDeleteAction,
    required void Function(Post post) onEditAction,
  }) {
    if (_posts == null) return const SizedBox.shrink();

    // 定义卡片动画参数
    const Duration cardAnimationDuration = Duration(milliseconds: 350);
    const Duration cardDelayIncrement = Duration(milliseconds: 40);

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return FadeInSlideUpItem( // <--- 包裹卡片
          key: ValueKey(post.id), // 使用 post.id 作为 Key
          duration: cardAnimationDuration,
          delay: cardDelayIncrement * index, // 交错延迟
          child: GestureDetector(
            onTap: () => _navigateToPostDetail(post),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: PostCard(
                post: post,
                isDesktopLayout: false,
                onDeleteAction: onDeleteAction,
                onEditAction: onEditAction,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 构建桌面端帖子网格 (MasonryGridView) ---
  Widget _buildDesktopPostsGrid(bool actuallyShowLeftPanel,
      bool actuallyShowRightPanel, {
        required Future<void> Function(String postId) onDeleteAction,
        required void Function(Post post) onEditAction,
      }) {
    if (_posts == null) return const SizedBox.shrink();

    // 定义卡片动画参数 (可以和移动端不同)
    const Duration cardAnimationDuration = Duration(milliseconds: 400);
    const Duration cardDelayIncrement = Duration(milliseconds: 50);

    int crossAxisCount = 3;
    if (actuallyShowLeftPanel && actuallyShowRightPanel) {
      crossAxisCount = 2;
    } else if (!actuallyShowLeftPanel && !actuallyShowRightPanel) {
      crossAxisCount = 4;
    }

    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return FadeInSlideUpItem( // <--- 包裹卡片
          key: ValueKey(post.id), // 使用 post.id 作为 Key
          duration: cardAnimationDuration,
          delay: cardDelayIncrement * index, // 交错延迟
          child: PostCard(
            post: post,
            isDesktopLayout: true,
            onDeleteAction: onDeleteAction,
            onEditAction: onEditAction,
            // 桌面 PostCard 内部可能处理 onTap，如果需要外部处理，则加 GestureDetector
          ),
        );
      },
    );
  }
}
