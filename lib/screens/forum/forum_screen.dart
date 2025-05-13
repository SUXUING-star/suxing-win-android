// lib/screens/forum/forum_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:suxingchahui/constants/common/app_bar_actions.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart';
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

  const ForumScreen({super.key, this.tag});

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with WidgetsBindingObserver {
  final List<PostTag> _tags = PostConstants.availablePostTags;
  PostTag? _selectedTag;
  List<Post>? _posts;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  // --- 状态变量 ---
  bool _isVisible = false; // Widget 是否可见
  bool _isLoadingData = false; // 是否正在执行加载操作 (API 调用或强制刷新)
  bool _isInitialized = false; // 是否已尝试过首次加载
  bool _needsRefresh = false; // 是否需要在变为可见或后台恢复时刷新

  final RefreshController _refreshController = RefreshController();

  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  // --- 缓存监听 ---
  StreamSubscription<dynamic>? _cacheSubscription;
  String _currentWatchIdentifier = ''; // 用于标识当前监听的参数组合

  // --- Debounce Timer ---
  Timer? _refreshDebounceTimer;

  static const double _hideRightPanelThreshold = 950.0;
  static const double _hideLeftPanelThreshold = 750.0;

  // --- 新增：下拉刷新节流相关状态 ---
  bool _isPerformingForumRefresh = false; // 标记是否正在执行论坛下拉刷新操作 (加个 Forum 区分)
  DateTime? _lastForumRefreshAttemptTime; // 上次尝试论坛下拉刷新的时间戳
  // 定义最小刷新间隔 (40 秒)
  static const Duration _minForumRefreshInterval = Duration(seconds: 40);

  @override
  void initState() {
    super.initState();
    // --- 初始化 selectedTag ---
    if (widget.tag != null) {
      // 尝试从路由字符串转换
      _selectedTag = PostTagsUtils.tagFromString(widget.tag!);
      // 如果转换结果是 other 但原始 tag 不是 other 的显示文本，视为无效，置为 null
      if (_selectedTag == PostTag.other &&
          widget.tag != PostTag.other.displayText) {
        _selectedTag = null;
      }
    } else {
      _selectedTag = null; // 默认 null (全部)
    }
    WidgetsBinding.instance.addObserver(this);
    // 不在此处加载，依赖 VisibilityDetector
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // print("ForumScreen dispose: Tag=$_selectedTag");
    _stopWatchingCache(); // 停止监听
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    _refreshDebounceTimer?.cancel(); // 取消 debounce timer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_needsRefresh && _isVisible) {
        _refreshDataIfNeeded(reason: "App Resumed with NeedsRefresh");
        _needsRefresh = false; // 重置标记
      } else if (_isVisible) {
        _refreshDataIfNeeded(reason: "App Resumed");
      }
      // 如果恢复时不可见，则在 VisibilityDetector 变为可见时处理 _needsRefresh
    } else if (state == AppLifecycleState.paused) {
      _needsRefresh = true; // App 进入后台，标记下次回来时需要检查刷新
    }
  }

  // --- 新增：处理来自 PostCard 的锁定/解锁请求 ---
  Future<void> _handleToggleLockFromCard(String postId) async {
    try {
      final forumService = context.read<ForumService>();
      // 调用 ForumService
      await forumService.togglePostLock(postId);
      if (!mounted) return; // 检查组件是否还在
      AppSnackBar.showSuccess(context, '帖子状态已切换');
      await _loadPosts(page: _currentPage, isRefresh: true);
    } catch (e) {
      if (!mounted) return;
      // print("ForumScreen: Failed to toggle lock for post $postId: $e");
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      // routeObserver?.hideLoading();
    }
  }

  // --- 核心加载逻辑 ---
  Future<void> _loadPosts({
    required int page,
    bool isInitialLoad = false,
    bool isRefresh = false,
    bool forceRefresh = false,
  }) async {
    // 防止在加载过程中重复触发（除非是强制刷新）
    if (_isLoadingData && !isRefresh) {
      return;
    }
    if (!mounted) return;

    _isInitialized = true; // 标记已尝试加载

    // --- 设置加载状态，触发 UI 重建显示 Loading ---
    // 只有在首次加载、强制刷新或分页时才清空旧数据并显示 Loading
    // 缓存事件触发的刷新，我们希望尽量平滑过渡
    setState(() {
      _isLoadingData = true;
      _errorMessage = null; // 清除旧错误
      if (isInitialLoad || isRefresh || _posts == null) {
        // 首次加载、刷新、或之前就没有数据时，清空
        _posts = null;
      }
      // 分页加载时，不清空 _posts，让旧数据显示，只在分页控件显示 loading
    });
    // --- 调用 Service 获取数据 ---
    try {
      final forumService = context.read<ForumService>();

      final String? tagParam = _selectedTag?.displayText;
      final result = await forumService.getPostsPage(
        tag: tagParam,
        page: page,
        limit: _limit,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return; // 获取数据后检查组件是否还在

      // --- *** 处理结果并强制 setState *** ---
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
      });

      // --- !!! 数据加载成功后，确保监听器指向当前页 !!! ---
      _startOrUpdateWatchingCache();
    } catch (e, s) {
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
        // if (showRouteLoading) _routeObserver?.hideLoading(); // <--- 删除了调用 hideLoading
        if (isRefresh) _refreshController.refreshCompleted();
      }
    }
  }

  // --- 刷新数据 (调用 _loadPosts 强制刷新第一页) - 加入节流 & 修正 ---
  Future<void> _refreshData() async {
    // 1. 防止重复触发
    if (_isPerformingForumRefresh) {
      // debugPrint("节流 (Forum): 已经在下拉刷新中，忽略本次触发"); // 可选调试日志
      return;
    }

    // 2. 检查时间间隔
    final now = DateTime.now();
    if (_lastForumRefreshAttemptTime != null &&
        now.difference(_lastForumRefreshAttemptTime!) <
            _minForumRefreshInterval) {
      final remainingSeconds = (_minForumRefreshInterval.inSeconds -
          now.difference(_lastForumRefreshAttemptTime!).inSeconds);
      if (mounted) {
        // --- 使用 AppSnackBar ---
        AppSnackBar.showInfo(
          context,
          '手速太快了！请 ${remainingSeconds} 秒后再刷新',
          duration: const Duration(seconds: 2),
        );
      }
      // --- 结束 RefreshIndicator 动画 ---
      _refreshController.refreshCompleted();
      return; // 时间不够，直接返回
    }

    // 3. 时间足够 或 首次刷新 -> 执行刷新逻辑

    // --- 设置节流状态 ---
    _isPerformingForumRefresh = true;
    _lastForumRefreshAttemptTime = now; // 记录本次尝试刷新的时间

    // --- 执行实际刷新逻辑 ---
    try {
      if (_isLoadingData && !_isPerformingForumRefresh) {
        _refreshController.refreshCompleted(); // 结束动画
        _isPerformingForumRefresh = false; // 重置标记（因为本次刷新未执行）
        return;
      }
      // 再次检查 mounted
      if (!mounted) {
        _isPerformingForumRefresh = false; // 重置标记
        return;
      }

      // 重置到第一页
      setState(() {
        _currentPage = 1;
      });

      // *** 调用核心加载方法，标记为 isRefresh ***
      await _loadPosts(page: 1, isRefresh: true, forceRefresh: true);

      // *** 加载成功后，结束 RefreshIndicator 动画 ***
      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      // 加载失败，也要结束 RefreshIndicator 动画
      if (mounted) {
        // 可以选择显示错误提示
        _refreshController.refreshCompleted(); // 仍然调用 completed 结束动画
      }
    } finally {
      // 4. 清除刷新状态标记 (无论成功失败)
      // 必须检查 mounted
      if (mounted) {
        _isPerformingForumRefresh = false; // 结束下拉刷新
      } else {
        _isPerformingForumRefresh = false; // 组件已卸载也要清理状态
      }
      // debugPrint("节流 (Forum): 下拉刷新操作完成 (finally)"); // 可选调试日志
    }
  }

  // --- 触发首次加载 (仅在未初始化时调用) ---
  void _triggerInitialLoad() {
    if (!_isInitialized && !_isLoadingData) {
      _loadPosts(page: 1, isInitialLoad: true); // 加载第一页
    } else if (!_isLoadingData && _posts == null) {
      // 如果初始化了但没数据（可能上次失败），也重新加载
      _loadPosts(page: 1, isInitialLoad: true, isRefresh: true);
    }
  }

  // --- 开始/更新监听缓存 ---
  void _startOrUpdateWatchingCache() {
    final String tagKey = _selectedTag?.name ?? 'all';
    final String newWatchIdentifier = "${tagKey}_$_currentPage";
    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      // print("ForumScreen: Watch identifier hasn't changed ($newWatchIdentifier). Keeping current subscription.");
      return;
    }

    _stopWatchingCache(); // 停止旧的
    _currentWatchIdentifier = newWatchIdentifier;

    try {
      final String? tagParam = _selectedTag?.displayText;
      final forumService = context.read<ForumService>();
      _cacheSubscription = forumService
          .watchForumPageChanges(
        tag: tagParam,
        page: _currentPage,
        limit: _limit,
      )
          .listen(
        (dynamic event) {
          // --- *** 监听到变化后的核心处理 *** ---
          if (_isVisible) {
            // 使用 Debounce 避免短时间内多次无效的刷新
            _refreshDataIfNeeded(reason: "Cache Changed");
          } else {
            _needsRefresh = true; // 标记需要刷新
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _stopWatchingCache();
        },
        onDone: () {
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
  void _onTagSelected(PostTag? tag) {
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
        "ForumScreen: Navigating to detail for post ${post.id}, stopped watching list cache.");

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
    return MediaQuery.of(context).size.width > 600;
  }

  void _navigateToCreatePost() async {
    final result =
        await NavigationUtils.pushNamed(context, AppRoutes.createPost);
    // 如果创建成功 (result == true)，刷新列表 (回到第一页)
    if (result == true && mounted) {
      _refreshData();
    }
  }

  Future<void> _handleDeletePostFromCard(Post post) async {
    // 使用确认对话框，确保用户意图
    await CustomConfirmDialog.show(
      context: context,
      title: '确认删除',
      message: '确定要从列表删除此帖子吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          final forumService = context.read<ForumService>();
          // 调用 Service 删除
          await forumService.deletePost(post);
          if (!mounted) return;
          AppSnackBar.showSuccess(context, '帖子已删除');
          // 删除成功后，刷新列表（通常回到第一页）
          _refreshData(); // 或者根据需求刷新当前页 _loadPosts(page: _currentPage, isRefresh: true);
        } catch (e) {
          if (!mounted) return;
          AppSnackBar.showError(context, '删除失败: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(context);
    final bool canShowLeftPanelBasedOnWidth =
        screenWidth >= _hideLeftPanelThreshold;
    final bool canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold;
    final bool actuallyShowLeftPanel =
        isDesktop && _showLeftPanel && canShowLeftPanelBasedOnWidth;
    final bool actuallyShowRightPanel =
        isDesktop && _showRightPanel && canShowRightPanelBasedOnWidth;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.white54;
    final Color enabledColor = Colors.amber;

    final Color leftPanelIconColor = actuallyShowLeftPanel
        ? secondaryColor
        : (canShowLeftPanelBasedOnWidth ? Colors.amber : Colors.white54);
    final Color rightPanelIconColor = actuallyShowRightPanel
        ? secondaryColor
        : (canShowRightPanelBasedOnWidth ? Colors.amber : Colors.white54);

    return VisibilityDetector(
      // *** 使用 Tag 和 Page 作为 Key，确保切换时重建 VisibilityDetector 状态 ***
      key: Key('forum_screen_visibility_${_selectedTag}_$_currentPage'),
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          _isVisible = currentlyVisible;
          if (mounted) setState(() {}); // 更新可见状态

          if (_isVisible) {
            // --- 变为可见 ---
            _triggerInitialLoad(); // 确保首次加载被触发（如果还没加载过）
            _startOrUpdateWatchingCache(); // 启动或更新监听
            // 如果需要刷新（例如后台回来，或缓存事件发生时不可见）
            if (_needsRefresh) {
              _refreshDataIfNeeded(reason: "Became Visible with NeedsRefresh");
              _needsRefresh = false; // 重置标记
            } else if (_isInitialized && _posts == null && !_isLoadingData) {
              // 如果初始化过但没数据（可能上次加载失败），也尝试重新加载
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
            // --- 使用 Padding 包裹每个按钮 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // 控制按钮左右间距
              child: FunctionalIconButton(
                icon: AppBarAction.searchForumPost.icon,
                tooltip: AppBarAction.searchForumPost.defaultTooltip!,
                iconColor: AppBarAction.searchForumPost.defaultIconColor,
                buttonBackgroundColor:
                    AppBarAction.searchForumPost.defaultBgColor,
                onPressed: () =>
                    NavigationUtils.pushNamed(context, AppRoutes.searchPost),
                iconButtonPadding: EdgeInsets.zero, // 可以覆盖内部默认值，让间距更小
              ),
            ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FunctionalIconButton(
                  icon: AppBarAction.toggleLeftPanel.icon,
                  buttonBackgroundColor:
                      AppBarAction.toggleLeftPanel.defaultBgColor,
                  iconColor: leftPanelIconColor, // 动态
                  tooltip: _showLeftPanel
                      ? (canShowLeftPanelBasedOnWidth ? '隐藏分类' : '屏幕宽度不足')
                      : (canShowLeftPanelBasedOnWidth
                          ? '显示分类'
                          : '屏幕宽度不足'), // 动态
                  onPressed: canShowLeftPanelBasedOnWidth
                      ? _toggleLeftPanel
                      : null, // 动态
                  iconButtonPadding: EdgeInsets.zero,
                ),
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FunctionalIconButton(
                  icon: AppBarAction.toggleRightPanel
                      .icon, // 注意这里用了 bar_chart_outlined，如果 Forum 要用 bar_chart，需要在枚举里调整或加新的
                  buttonBackgroundColor:
                      AppBarAction.toggleRightPanel.defaultBgColor,
                  iconColor: rightPanelIconColor, // 动态
                  tooltip: _showRightPanel
                      ? (canShowRightPanelBasedOnWidth ? '隐藏统计' : '屏幕宽度不足')
                      : (canShowRightPanelBasedOnWidth
                          ? '显示统计'
                          : '屏幕宽度不足'), // 动态
                  onPressed: canShowRightPanelBasedOnWidth
                      ? _toggleRightPanel
                      : null, // 动态
                  iconButtonPadding: EdgeInsets.zero,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FunctionalIconButton(
                icon: AppBarAction.refreshForum.icon,
                tooltip: AppBarAction.refreshForum.defaultTooltip!,
                iconColor: AppBarAction.refreshForum.defaultIconColor,
                buttonBackgroundColor: AppBarAction.refreshForum.defaultBgColor,
                onPressed: _isLoadingData ? null : _refreshData, // 动态
                iconButtonPadding: EdgeInsets.zero,
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return authProvider.isLoggedIn
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FunctionalIconButton(
                          icon: AppBarAction.createForumPost.icon,
                          tooltip: AppBarAction.createForumPost.defaultTooltip!,
                          iconColor:
                              AppBarAction.createForumPost.defaultIconColor,
                          buttonBackgroundColor:
                              AppBarAction.createForumPost.defaultBgColor,
                          onPressed: _navigateToCreatePost, // 动态
                          iconButtonPadding: EdgeInsets.zero,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            // --- 移除所有 SizedBox(width: 8) ---
          ],
        ),
        // Body 使用 Column 包含 Filter(Mobile)/Content/Pagination
        body: Column(
          children: [
            if (!isDesktop)
              TagFilter(
                tags: PostTagsUtils.tagsToStringList(_tags),
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
  Widget _buildBodyContent(
      bool isDesktop, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    // 1. 如果出错，并且没有帖子数据显示（或者帖子为空）
    if (_errorMessage != null && (_posts == null || _posts!.isEmpty)) {
      return FadeInItem(
          child: CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: () => _loadPosts(page: _currentPage, isRefresh: true), // 重试当前页
      ));
    }

    // 2. 如果正在加载，并且没有旧帖子数据显示 (_posts 为 null)
    if (_isLoadingData && _posts == null) {
      return FadeInItem(child: LoadingWidget.fullScreen(message: '正在加载帖子...'));
    }

    // 3. 如果加载完成，但帖子列表为空
    if (!_isLoadingData && _posts != null && _posts!.isEmpty) {
      return FadeInItem(
          child: const EmptyStateWidget(message: "啥也没有")); // 调用独立的空状态构建方法
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
    return LoadingWidget.fullScreen(message: "等待加载..."); // 或者 SizedBox.shrink()
  }

  // --- 构建桌面布局 (Row + Panels + List) ---
  Widget _buildDesktopLayout(
      bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    // 定义面板动画参数
    const Duration panelAnimationDuration = Duration(milliseconds: 300);
    const Duration leftPanelDelay = Duration(milliseconds: 50);
    const Duration rightPanelDelay = Duration(milliseconds: 100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 左侧分类面板带动画 ---
        if (actuallyShowLeftPanel)
          FadeInSlideLRItem(
            // <--- 包裹左面板
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
              ? FadeInSlideLRItem(
                  // <--- 包裹右面板
                  key: const ValueKey('forum_right_panel'),
                  slideDirection: SlideDirection.right,
                  duration: panelAnimationDuration,
                  delay: rightPanelDelay,
                  child: ForumRightPanel(
                    currentPosts: _posts!,
                    selectedTag: _selectedTag,
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
    required Future<void> Function(Post post) onDeleteAction,
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
        return FadeInSlideUpItem(
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
                onToggleLockAction: _handleToggleLockFromCard,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 构建桌面端帖子网格 (MasonryGridView) ---
  Widget _buildDesktopPostsGrid(
    bool actuallyShowLeftPanel,
    bool actuallyShowRightPanel, {
    required Future<void> Function(Post post) onDeleteAction,
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
        return FadeInSlideUpItem(
          key: ValueKey(post.id), // 使用 post.id 作为 Key
          duration: cardAnimationDuration,
          delay: cardDelayIncrement * index, // 交错延迟
          child: PostCard(
            post: post,
            isDesktopLayout: true,
            onDeleteAction: onDeleteAction,
            onEditAction: onEditAction,
            onToggleLockAction: _handleToggleLockFromCard,
          ),
        );
      },
    );
  }
}
