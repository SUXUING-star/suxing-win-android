// lib/screens/forum/post_list_screen.dart

/// 该文件定义了 PostListScreen 组件，一个用于显示论坛帖子列表的屏幕。
/// PostListScreen 负责加载和展示帖子数据，支持筛选、分页和帖子操作。
library;

import 'dart:async'; // 导入异步操作所需
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/constants/common/app_bar_actions.dart'; // 导入 AppBar 动作常量
import 'package:suxingchahui/constants/post/post_constants.dart'; // 导入帖子常量
import 'package:suxingchahui/models/common/pagination.dart'; // 导入分页数据模型
import 'package:suxingchahui/models/post/post_list_pagination.dart'; // 导入帖子列表分页模型
import 'package:suxingchahui/providers/post/post_list_filter_provider.dart'; // 导入帖子列表筛选 Provider
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart'; // 导入动画列表视图组件
import 'package:suxingchahui/widgets/ui/animation/animated_masonry_grid_view.dart'; // 导入动画瀑布流网格视图组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart'; // 导入左右滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart'; // 导入功能图标按钮
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 导入空状态组件
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 导入确认对话框
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入应用 SnackBar 工具
import 'package:visibility_detector/visibility_detector.dart'; // 导入可见性检测器
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/components/pagination_controls.dart'; // 导入分页控件
import 'package:suxingchahui/models/post/post.dart'; // 导入帖子模型
import 'package:suxingchahui/services/main/forum/post_service.dart'; // 导入帖子服务
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart'; // 导入基础帖子卡片
import 'package:suxingchahui/widgets/components/screen/forum/tag_filter.dart'; // 导入标签筛选组件
import 'package:suxingchahui/widgets/components/screen/forum/panel/post_right_panel.dart'; // 导入帖子右侧面板
import 'package:suxingchahui/widgets/components/screen/forum/panel/post_left_panel.dart'; // 导入帖子左侧面板
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件
import 'refresh_controller.dart'; // 导入刷新控制器

/// `PostListScreen` 类：论坛帖子列表屏幕。
///
/// 该屏幕负责加载、展示帖子数据，支持筛选、分页和帖子操作。
class PostListScreen extends StatefulWidget {
  final String? tag; // 初始筛选标签
  final AuthProvider authProvider; // 认证 Provider
  final PostService postService; // 帖子服务
  final UserFollowService followService; // 用户关注服务
  final UserInfoProvider infoProvider; // 用户信息 Provider
  final PostListFilterProvider postListFilterProvider; // 帖子列表筛选 Provider

  /// 构造函数。
  ///
  /// [tag]：初始标签。
  /// [authProvider]：认证 Provider。
  /// [postService]：帖子服务。
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [postListFilterProvider]：帖子列表筛选 Provider。
  const PostListScreen({
    super.key,
    this.tag,
    required this.authProvider,
    required this.postService,
    required this.followService,
    required this.infoProvider,
    required this.postListFilterProvider,
  });

  /// 创建状态。
  @override
  _PostListScreenState createState() => _PostListScreenState();
}

/// `_PostListScreenState` 类：`PostListScreen` 的状态管理。
///
/// 管理数据加载、筛选、分页、缓存监听和 UI 状态。
class _PostListScreenState extends State<PostListScreen>
    with WidgetsBindingObserver {
  final List<PostTag> _tags = PostConstants.availablePostTags; // 可用标签列表
  PostTag? _selectedTag; // 当前选中的标签
  List<Post>? _posts; // 帖子列表数据
  String? _errorMessage; // 错误消息

  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  final int _postListLimit = PostService.postListLimit; // 每页帖子数量限制

  String? _currentUserId; // 当前用户ID

  bool _isVisible = false; // Widget 是否可见
  bool _isLoadingData = false; // 是否正在执行数据加载操作
  bool _isInitialized = false; // 是否已尝试过首次加载
  bool _needsRefresh = false; // 是否需要在变为可见或后台恢复时刷新

  final RefreshController _refreshController = RefreshController(); // 刷新控制器

  bool _showLeftPanel = true; // 是否显示左侧面板
  bool _showRightPanel = true; // 是否显示右侧面板

  StreamSubscription<dynamic>? _cacheSubscription; // 缓存订阅器
  String _currentWatchIdentifier = ''; // 用于标识当前监听的参数组合

  Timer? _refreshDebounceTimer; // 刷新防抖计时器
  Timer? _checkProviderDebounceTimer; // Provider 检查防抖计时器

  bool _hasInitializedDependencies = false; // 依赖是否已初始化

  static const double _hideRightPanelThreshold = 950.0; // 隐藏右侧面板的屏幕宽度阈值
  static const double _hideLeftPanelThreshold = 750.0; // 隐藏左侧面板的屏幕宽度阈值

  bool _isPerformingForumRefresh = false; // 标记是否正在执行论坛下拉刷新操作
  DateTime? _lastForumRefreshAttemptTime; // 上次尝试论坛下拉刷新的时间戳
  static const Duration _minForumRefreshInterval =
      Duration(seconds: 30); // 最小刷新间隔
  static const Duration _cacheDebounceDuration = Duration(seconds: 2); // 缓存防抖时长
  static const Duration _checkProviderDebounceDuration =
      Duration(milliseconds: 800); // Provider 检查防抖时长

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加应用生命周期观察者
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedDependencies) {
      // 依赖未初始化时
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户ID

      final providerTagString = widget
          .postListFilterProvider.selectedTagString; // 获取 Provider 中的标签字符串
      final providerTagWasSet =
          widget.postListFilterProvider.tagHasBeenSet; // 获取 Provider 中标签是否已设置标记

      String? initialTagString; // 初始标签字符串

      if (providerTagWasSet && providerTagString != null) {
        // Provider 标签已设置且非空时
        initialTagString = providerTagString; // 使用 Provider 中的标签
        widget.postListFilterProvider.resetTagFlag(); // 重置 Provider 标签标记
      } else if (widget.tag != null) {
        // 否则使用 widget 传入的标签
        initialTagString = widget.tag;
      }

      if (initialTagString != null) {
        // 初始标签字符串非空时
        _selectedTag =
            PostTagsUtils.tagFromString(initialTagString); // 转换为 PostTag
        if (_selectedTag == PostTag.other &&
            initialTagString != PostTag.other.displayText) {
          // "other" 标签特殊处理
          _selectedTag = null; // 无效的 "other" 设为 null
        }
      } else {
        _selectedTag = null; // 否则设为 null
      }
      _hasInitializedDependencies = true; // 标记依赖已初始化
    }
  }

  @override
  void dispose() {
    _stopWatchingCache(); // 停止监听缓存
    WidgetsBinding.instance.removeObserver(this); // 移除应用生命周期观察者
    _refreshController.dispose(); // 销毁刷新控制器
    _refreshDebounceTimer?.cancel(); // 取消刷新防抖计时器
    _checkProviderDebounceTimer?.cancel(); // 取消 Provider 检查防抖计时器
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != widget.authProvider.currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
    if (widget.tag != oldWidget.tag && // widget.tag 变化且 Provider 标签未设置时
        !widget.postListFilterProvider.tagHasBeenSet) {
      PostTag? newTagFromWidget = widget.tag != null
          ? PostTagsUtils.tagFromString(widget.tag!)
          : null; // 从 widget.tag 获取新标签
      if (newTagFromWidget == PostTag.other &&
          widget.tag != PostTag.other.displayText) {
        // "other" 标签特殊处理
        newTagFromWidget = null;
      }
      if (_selectedTag != newTagFromWidget) {
        // 选中标签变化时
        _onTagSelected(newTagFromWidget,
            fromProvider: false); // 触发标签选择回调，标记非来自 Provider
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 应用从后台恢复时
      if (widget.authProvider.currentUserId != _currentUserId) {
        // 用户ID变化时
        if (mounted) {
          setState(() {
            _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
          });
        }
      }
      if (_isVisible) {
        // 屏幕可见时
        _checkProviderAndApplyFilterIfNeeded(
            reason: "应用恢复"); // 检查 Provider 并应用筛选
        if (_needsRefresh) {
          // 需要刷新时
          _refreshDataIfNeeded(reason: "应用恢复且需要刷新"); // 刷新数据
          _needsRefresh = false; // 重置刷新标记
        } else {
          _refreshDataIfNeeded(reason: "应用恢复"); // 刷新数据
        }
      } else {
        // 屏幕不可见时
        _needsRefresh = true; // 标记，等可见时刷新
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时
      _needsRefresh = true; // 标记需要刷新
    }
  }

  /// 检查 Provider 是否需要更新内部状态并应用筛选。
  ///
  /// [reason]：检查原因。
  void _checkProviderAndApplyFilterIfNeeded({required String reason}) {
    _checkProviderDebounceTimer?.cancel(); // 取消上一个计时器
    _checkProviderDebounceTimer = Timer(_checkProviderDebounceDuration, () {
      // 启动新的计时器
      if (!mounted || !_isVisible) return; // 组件未挂载或不可见时返回

      final providerTagString =
          widget.postListFilterProvider.selectedTagString; // 获取 Provider 中的标签
      final bool providerTagWasSet =
          widget.postListFilterProvider.tagHasBeenSet; // 标签是否已设置

      if (providerTagWasSet) {
        // 标签已设置时
        PostTag? newTagFromProvider; // 从 Provider 获取的新标签
        if (providerTagString != null) {
          // 标签字符串非空时
          newTagFromProvider =
              PostTagsUtils.tagFromString(providerTagString); // 转换为 PostTag
          if (newTagFromProvider == PostTag.other &&
              providerTagString != PostTag.other.displayText) {
            // "other" 标签特殊处理
            newTagFromProvider = null;
          }
        } else {
          newTagFromProvider = null; // 否则设为 null
        }

        widget.postListFilterProvider.resetTagFlag(); // 重置标签标记

        if (_selectedTag != newTagFromProvider) {
          // 选中标签变化时
          _onTagSelected(newTagFromProvider,
              fromProvider: true); // 触发标签选择回调，标记来自 Provider
        }
      }
    });
  }

  /// 处理帖子卡片的锁定/解锁请求。
  ///
  /// [postId]：要操作的帖子 ID。
  Future<void> _handleToggleLockFromCard(String postId) async {
    if (!widget.authProvider.isLoggedIn) {
      // 用户未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanLockPost()) {
      // 无权限时提示错误
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    try {
      await widget.postService.togglePostLock(postId); // 调用切换帖子锁定状态服务
      if (!mounted) return; // 组件未挂载时返回
      AppSnackBar.showSuccess(context, '帖子状态已切换'); // 提示状态已切换
      await _loadPosts(page: _currentPage, isRefresh: true); // 刷新当前页数据
    } catch (e) {
      if (!mounted) return; // 组件未挂载时返回
      AppSnackBar.showError(context, '操作失败: $e'); // 提示操作失败
    } finally {
      // routeObserver?.hideLoading(); // 隐藏加载状态
    }
  }

  /// 加载帖子数据。
  ///
  /// [page]：要加载的页码。
  /// [isInitialLoad]：是否为初始加载。
  /// [isRefresh]：是否为刷新。
  /// [forceRefresh]：是否强制刷新。
  Future<void> _loadPosts({
    required int page,
    bool isInitialLoad = false,
    bool isRefresh = false,
    bool forceRefresh = false,
  }) async {
    if (_isLoadingData && !isRefresh) {
      // 正在加载数据且非刷新时返回
      return;
    }
    if (!mounted) return; // 组件未挂载时返回

    _isInitialized = true; // 标记为已尝试加载

    setState(() {
      _isLoadingData = true; // 设置加载状态
      _errorMessage = null; // 清空错误消息
      if (isInitialLoad || isRefresh || _posts == null) {
        // 初始加载、刷新或 _posts 为空时清空帖子
        _posts = null;
      }
    });

    try {
      final String? tagParam = _selectedTag?.displayText; // 标签参数
      final PostListPagination result = await widget.postService.getPostsPage(
        tag: tagParam, // 标签
        page: page, // 页码
        limit: _postListLimit, // 限制
        forceRefresh: forceRefresh, // 强制刷新
      );

      if (!mounted) return; // 组件未挂载时返回

      final List<Post> fetchedPosts = result.posts; // 获取帖子列表
      final PaginationData pagination = result.pagination; // 获取分页信息
      final int serverPage = pagination.page; // 服务器返回的页码
      final int serverTotalPages = pagination.pages; // 服务器返回的总页数

      setState(() {
        _posts = fetchedPosts; // 更新帖子列表
        _currentPage = serverPage; // 更新当前页码
        _totalPages = serverTotalPages; // 更新总页数
        _errorMessage = null; // 清空错误消息
      });

      _startOrUpdateWatchingCache(); // 启动或更新缓存监听
    } catch (e) {
      if (!mounted) return; // 组件未挂载时返回
      setState(() {
        _errorMessage = '加载帖子失败: $e'; // 设置错误消息
        if (isInitialLoad || isRefresh) {
          // 初始加载或刷新出错时清空帖子列表和重置分页
          _posts = [];
          _currentPage = 1;
          _totalPages = 1;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false; // 重置加载状态
        });
        if (isRefresh) _refreshController.refreshCompleted(); // 刷新完成
      }
    }
  }

  /// 刷新数据主逻辑。
  ///
  /// [needCheck]：是否需要进行时间间隔检查。
  Future<void> _refreshData({bool needCheck = true}) async {
    if (_isPerformingForumRefresh) {
      // 正在执行刷新时返回
      return;
    }

    final now = DateTime.now();
    if (needCheck) {
      // 需要检查时
      if (_lastForumRefreshAttemptTime != null &&
          now.difference(_lastForumRefreshAttemptTime!) <
              _minForumRefreshInterval) {
        // 时间间隔不足时
        final remainingSeconds = (_minForumRefreshInterval.inSeconds -
            now.difference(_lastForumRefreshAttemptTime!).inSeconds);
        if (mounted) {
          AppSnackBar.showInfo(
            context,
            '手速太快了！请 $remainingSeconds 秒后再刷新',
            duration: const Duration(seconds: 2),
          );
        }
        _refreshController.refreshCompleted(); // 刷新完成
        return;
      }
    }

    _isPerformingForumRefresh = true; // 设置正在执行刷新标记
    _lastForumRefreshAttemptTime = now; // 记录本次尝试刷新时间

    try {
      if (_isLoadingData && !_isPerformingForumRefresh) {
        // 正在加载数据且非刷新中时返回
        _refreshController.refreshCompleted(); // 刷新完成
        _isPerformingForumRefresh = false; // 重置标记
        return;
      }
      if (!mounted) {
        // 组件未挂载时返回
        _isPerformingForumRefresh = false; // 重置标记
        return;
      }

      setState(() {
        _currentPage = 1; // 重置到第一页
      });

      await _loadPosts(
          page: 1, isRefresh: true, forceRefresh: true); // 加载第一页并强制刷新

      if (mounted) {
        // 组件挂载时
        _refreshController.refreshCompleted(); // 刷新完成
      }
    } catch (e) {
      if (mounted) {
        // 捕获错误时
        _refreshController.refreshCompleted(); // 刷新完成
      }
    } finally {
      if (mounted) {
        _isPerformingForumRefresh = false; // 清除刷新状态标记
      } else {
        _isPerformingForumRefresh = false; // 组件已卸载也要清理状态
      }
    }
  }

  /// 触发首次加载。
  ///
  /// 仅在未初始化或无数据时调用。
  void _triggerInitialLoad() {
    if (!_isInitialized && !_isLoadingData) {
      // 未初始化且未加载数据时
      _loadPosts(page: 1, isInitialLoad: true); // 加载第一页
    } else if (!_isLoadingData && _posts == null) {
      // 已初始化但无数据且未加载数据时
      _loadPosts(page: 1, isInitialLoad: true, isRefresh: true); // 重新加载并刷新
    }
  }

  /// 开始或更新缓存监听。
  ///
  /// 该方法根据当前的筛选条件和页码生成监听标识符，并监听论坛页的缓存变化。
  void _startOrUpdateWatchingCache() {
    final String tagKey = _selectedTag?.name ?? 'all'; // 标签键
    final String newWatchIdentifier = "${tagKey}_$_currentPage"; // 新的监听标识符
    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      // 已经在监听相同目标时返回
      return;
    }

    _stopWatchingCache(); // 停止旧的监听
    _currentWatchIdentifier = newWatchIdentifier; // 更新监听标识符

    try {
      final String? tagParam = _selectedTag?.displayText; // 标签参数
      _cacheSubscription = widget.postService
          .watchForumPageChanges(
        tag: tagParam,
        page: _currentPage,
        limit: _postListLimit,
      )
          .listen(
        (dynamic event) {
          if (_isVisible) {
            // 屏幕可见时
            _refreshDataIfNeeded(reason: "缓存变化"); // 刷新数据
          } else {
            _needsRefresh = true; // 标记需要刷新
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          // 监听错误时
          _stopWatchingCache(); // 停止监听
        },
        onDone: () {
          // 监听完成时
          if (_currentWatchIdentifier == newWatchIdentifier) {
            _currentWatchIdentifier = ''; // 清空标识符
          }
        },
        cancelOnError: true, // 发生错误时自动取消监听
      );
    } catch (e) {
      _currentWatchIdentifier = ''; // 启动监听失败时清空标识符
    }
  }

  /// 停止监听缓存变化。
  void _stopWatchingCache() {
    if (_cacheSubscription != null) {
      _cacheSubscription!.cancel(); // 取消订阅
      _cacheSubscription = null; // 清空订阅器
      _currentWatchIdentifier = ''; // 清空监听标识符
    }
  }

  /// 刷新数据，带防抖控制。
  ///
  /// [reason]：刷新原因。
  /// [isCacheUpdated]：是否因缓存更新触发。
  void _refreshDataIfNeeded({
    required String reason,
    bool isCacheUpdated = false,
  }) {
    if (!mounted) return; // 组件未挂载时返回
    _refreshDebounceTimer?.cancel(); // 取消旧的防抖计时器
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      // 启动新的防抖计时器
      if (!mounted) return; // 组件未挂载时返回
      if (!_isVisible) {
        // 屏幕不可见时
        _needsRefresh = true; // 标记需要刷新
        return;
      }
      if (_isLoadingData) {
        // 正在加载数据时
        if (isCacheUpdated) {
          // 如果是缓存更新触发
          return;
        } else {
          _needsRefresh = true; // 标记需要刷新
          return;
        }
      }
      _loadPosts(page: _currentPage, isRefresh: true); // 加载帖子数据
    });
  }

  /// 处理标签选择。
  ///
  /// [newTag]：新选中的标签。
  /// [fromProvider]：是否来自 Provider。
  void _onTagSelected(PostTag? newTag, {bool fromProvider = false}) {
    if (_selectedTag == newTag || _isLoadingData) {
      // 选中标签未变化或正在加载时返回
      return;
    }

    setState(() {
      _selectedTag = newTag; // 更新选中标签
      _currentPage = 1; // 重置页码
      _totalPages = 1; // 重置总页数
      _posts = null; // 清空帖子列表
      _errorMessage = null; // 清空错误消息
      _isInitialized = false; // 重置初始化标记
      _needsRefresh = false; // 重置刷新标记
    });

    _stopWatchingCache(); // 停止监听缓存

    if (!fromProvider) {
      // 非来自 Provider 时更新 Provider 状态
      widget.postListFilterProvider
          .setTag(newTag?.displayText); // 设置 Provider 标签
      widget.postListFilterProvider.resetTagFlag(); // 重置 Provider 标签标记
    }

    if (_isVisible) {
      // 屏幕可见时触发初始加载
      _triggerInitialLoad();
    } else {
      // 屏幕不可见时标记需要刷新
      _needsRefresh = true;
    }
  }

  /// 前往下一页。
  void _goToNextPage() {
    if (_currentPage < _totalPages && !_isLoadingData) {
      // 当前页小于总页数且未加载数据时
      _stopWatchingCache(); // 停止监听当前页缓存
      setState(() {
        _currentPage++; // 页码递增
        _posts = null; // 清空帖子以显示加载状态
        _errorMessage = null; // 清空错误消息
      });
      _loadPosts(
          page: _currentPage, isInitialLoad: false, isRefresh: false); // 加载新页
    }
  }

  /// 前往上一页。
  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoadingData) {
      // 当前页大于 1 且未加载数据时
      _stopWatchingCache(); // 停止监听当前页缓存
      setState(() {
        _currentPage--; // 页码递减
        _posts = null; // 清空帖子以显示加载状态
        _errorMessage = null; // 清空错误消息
      });
      _loadPosts(
        page: _currentPage,
        isInitialLoad: false,
        isRefresh: false,
      ); // 加载新页
    }
  }

  /// 前往指定页码。
  ///
  /// [pageNumber]：目标页码。
  void _goToPage(int pageNumber) {
    if (pageNumber > _totalPages ||
        pageNumber < 1 ||
        pageNumber == _currentPage) {
      // 目标页码无效或为当前页时返回
      return;
    }
    if (_currentPage > 1 && !_isLoadingData) {
      // 当前页大于 1 且未加载数据时
      _stopWatchingCache(); // 停止监听当前页缓存
      setState(() {
        _currentPage = pageNumber; // 更新当前页码
        _posts = null; // 清空帖子以显示加载状态
        _errorMessage = null; // 清空错误消息
      });
      _loadPosts(
        page: pageNumber,
        isInitialLoad: false,
        isRefresh: false,
      ); // 加载指定页
    }
  }

  /// 导航到帖子详情页。
  ///
  /// [post]：要导航到的帖子。
  void _navigateToPostDetail(Post post) async {
    _stopWatchingCache(); // 进入详情页前停止监听列表

    await NavigationUtils.pushNamed(context, AppRoutes.postDetail,
        arguments: post.id); // 导航到帖子详情页

    if (mounted) {
      // 从详情页返回时
      _startOrUpdateWatchingCache(); // 重新启动监听缓存
      if (_isVisible) {
        // 屏幕可见时刷新数据
        _refreshDataIfNeeded(reason: "从详情页返回");
      }
    }
  }

  /// 切换右侧面板可见性。
  void _toggleRightPanel() {
    setState(() {
      _showRightPanel = !_showRightPanel; // 切换右侧面板可见性
    });
  }

  /// 切换左侧面板可见性。
  void _toggleLeftPanel() {
    setState(() {
      _showLeftPanel = !_showLeftPanel; // 切换左侧面板可见性
    });
  }

  /// 判断是否为桌面布局。
  ///
  /// [context]：Build 上下文。
  /// 返回 true 表示是桌面布局，否则返回 false。
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 600; // 屏幕宽度大于 600 时判定为桌面
  }

  /// 导航到创建帖子页面。
  void _navigateToCreatePost() async {
    final result = await NavigationUtils.pushNamed(
        context, AppRoutes.createPost); // 导航到创建帖子页面
    if (result == true && mounted) {
      // 创建成功且组件挂载时
      _refreshData(); // 刷新数据
    }
  }

  /// 处理删除帖子。
  ///
  /// [post]：要删除的帖子。
  Future<void> _handleDeletePostFromCard(Post post) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(post)) {
      // 无权限时提示错误
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    await CustomConfirmDialog.show(
      // 显示确认对话框
      context: context,
      title: '确认删除',
      message: '确定要从列表删除此帖子吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        // 确认删除回调
        try {
          await widget.postService.deletePost(post); // 调用删除帖子服务
          if (!mounted) return; // 组件未挂载时返回
          AppSnackBar.showSuccess(context, '帖子已删除'); // 提示删除成功
          _refreshData(); // 刷新数据
        } catch (e) {
          if (!mounted) return; // 组件未挂载时返回
          AppSnackBar.showError(context, '删除失败: $e'); // 提示删除失败
        }
      },
    );
  }

  /// 处理编辑帖子。
  ///
  /// [post]：要编辑的帖子。
  void _handleEditPostFromCard(Post post) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(post)) {
      // 无权限时提示错误
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post.id, // 传递帖子 ID
    );

    if (result == true && mounted) {
      // 编辑成功且组件挂载时
      _loadPosts(page: _currentPage, isRefresh: true); // 刷新当前页数据
    }
  }

  /// 检查是否可锁定帖子。
  ///
  /// 返回 true 表示可锁定，否则返回 false。
  bool _checkCanLockPost() {
    return widget.authProvider.isAdmin; // 仅管理员可锁定
  }

  /// 检查是否可编辑或删除帖子。
  ///
  /// [post]：要检查的帖子。
  /// 返回 true 表示可编辑或删除，否则返回 false。
  bool _checkCanEditOrDeletePost(Post post) {
    return widget.authProvider.isAdmin // 管理员可操作
        ? true
        : widget.authProvider.currentUserId == post.authorId; // 或当前用户是作者
  }

  /// 处理可见性变化。
  ///
  /// [visibilityInfo]：可见性信息。
  void _handleVisibilityChange(VisibilityInfo visibilityInfo) {
    final bool currentlyVisible =
        visibilityInfo.visibleFraction > 0; // 判断当前是否可见

    if (widget.authProvider.currentUserId != _currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }

    if (currentlyVisible != _isVisible) {
      // 可见性状态变化时
      if (mounted) {
        setState(() {
          _isVisible = currentlyVisible; // 更新可见性状态
        });
      }

      if (_isVisible) {
        // 变为可见时
        _checkProviderAndApplyFilterIfNeeded(
            reason: "变为可见"); // 检查 Provider 并应用筛选

        if (!_isInitialized) {
          // 未初始化时
          _triggerInitialLoad(); // 触发初始加载
        }
        _startOrUpdateWatchingCache(); // 启动或更新缓存监听
        if (_needsRefresh) {
          // 需要刷新时
          _refreshDataIfNeeded(reason: "变为可见且需要刷新"); // 刷新数据
          _needsRefresh = false; // 重置刷新标记
        } else if (_isInitialized && _posts == null && !_isLoadingData) {
          // 已初始化但无数据且未加载数据时
          _loadPosts(page: _currentPage, isRefresh: true); // 加载帖子数据
        }
      } else {
        // 变为不可见时
        _stopWatchingCache(); // 停止监听缓存
        _refreshDebounceTimer?.cancel(); // 取消刷新防抖计时器
        _checkProviderDebounceTimer?.cancel(); // 取消 Provider 检查防抖计时器
      }
    }
  }

  /// 构建屏幕 UI。
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 屏幕宽度
    final isDesktop = _isDesktop(context); // 是否为桌面布局
    final bool canShowLeftPanelBasedOnWidth =
        screenWidth >= _hideLeftPanelThreshold; // 是否可显示左侧面板
    final bool canShowRightPanelBasedOnWidth =
        screenWidth >= _hideRightPanelThreshold; // 是否可显示右侧面板
    final bool actuallyShowLeftPanel = isDesktop &&
        _showLeftPanel &&
        canShowLeftPanelBasedOnWidth; // 实际是否显示左侧面板
    final bool actuallyShowRightPanel = isDesktop &&
        _showRightPanel &&
        canShowRightPanelBasedOnWidth; // 实际是否显示右侧面板
    final Color secondaryColor =
        Theme.of(context).colorScheme.secondary; // 次要颜色

    final Color leftPanelIconColor = actuallyShowLeftPanel // 左侧面板图标颜色
        ? secondaryColor
        : (canShowLeftPanelBasedOnWidth ? Colors.amber : Colors.white54);
    final Color rightPanelIconColor = actuallyShowRightPanel // 右侧面板图标颜色
        ? secondaryColor
        : (canShowRightPanelBasedOnWidth ? Colors.amber : Colors.white54);

    return VisibilityDetector(
      key: Key(
          'forum_screen_visibility_${_selectedTag}_$_currentPage'), // 可见性检测器 Key
      onVisibilityChanged: _handleVisibilityChange, // 可见性变化回调
      child: Scaffold(
        appBar: CustomAppBar(
          // 自定义 AppBar
          title: '论坛', // 标题
          actions: [
            // 动作按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // 水平内边距
              child: FunctionalIconButton(
                icon: AppBarAction.searchForumPost.icon, // 搜索图标
                tooltip: AppBarAction.searchForumPost.defaultTooltip!, // 提示
                iconColor:
                    AppBarAction.searchForumPost.defaultIconColor, // 图标颜色
                buttonBackgroundColor:
                    AppBarAction.searchForumPost.defaultBgColor, // 背景色
                onPressed: () => NavigationUtils.pushNamed(
                    context, AppRoutes.searchPost), // 点击导航到搜索帖子页面
                iconButtonPadding: EdgeInsets.zero, // 内边距
              ),
            ),
            if (isDesktop) // 桌面平台显示左侧面板切换按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FunctionalIconButton(
                  icon: AppBarAction.toggleLeftPanel.icon, // 图标
                  buttonBackgroundColor:
                      AppBarAction.toggleLeftPanel.defaultBgColor, // 背景色
                  iconColor: leftPanelIconColor, // 图标颜色
                  tooltip: _showLeftPanel // 提示
                      ? (canShowLeftPanelBasedOnWidth ? '隐藏分类' : '屏幕宽度不足')
                      : (canShowLeftPanelBasedOnWidth ? '显示分类' : '屏幕宽度不足'),
                  onPressed: canShowLeftPanelBasedOnWidth // 点击回调
                      ? _toggleLeftPanel
                      : null,
                  iconButtonPadding: EdgeInsets.zero, // 内边距
                ),
              ),
            if (isDesktop) // 桌面平台显示右侧面板切换按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FunctionalIconButton(
                  icon: AppBarAction.toggleRightPanel.icon, // 图标
                  buttonBackgroundColor:
                      AppBarAction.toggleRightPanel.defaultBgColor, // 背景色
                  iconColor: rightPanelIconColor, // 图标颜色
                  tooltip: _showRightPanel // 提示
                      ? (canShowRightPanelBasedOnWidth ? '隐藏统计' : '屏幕宽度不足')
                      : (canShowRightPanelBasedOnWidth ? '显示统计' : '屏幕宽度不足'),
                  onPressed: canShowRightPanelBasedOnWidth // 点击回调
                      ? _toggleRightPanel
                      : null,
                  iconButtonPadding: EdgeInsets.zero, // 内边距
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // 水平内边距
              child: FunctionalIconButton(
                icon: AppBarAction.refreshForum.icon, // 刷新图标
                tooltip: AppBarAction.refreshForum.defaultTooltip!, // 提示
                iconColor: AppBarAction.refreshForum.defaultIconColor, // 图标颜色
                buttonBackgroundColor:
                    AppBarAction.refreshForum.defaultBgColor, // 背景色
                onPressed: _isLoadingData ? null : _refreshData, // 点击回调
                iconButtonPadding: EdgeInsets.zero, // 内边距
              ),
            ),

            widget.authProvider.isLoggedIn // 登录时显示创建帖子按钮
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4.0), // 水平内边距
                    child: FunctionalIconButton(
                      icon: AppBarAction.createForumPost.icon, // 创建帖子图标
                      tooltip:
                          AppBarAction.createForumPost.defaultTooltip!, // 提示
                      iconColor:
                          AppBarAction.createForumPost.defaultIconColor, // 图标颜色
                      buttonBackgroundColor:
                          AppBarAction.createForumPost.defaultBgColor, // 背景色
                      onPressed: _navigateToCreatePost, // 点击导航到创建帖子页面
                      iconButtonPadding: EdgeInsets.zero, // 内边距
                    ),
                  )
                : const SizedBox.shrink() // 未登录时隐藏
          ],
        ),
        body: Column(
          children: [
            if (!isDesktop) // 移动端显示标签筛选
              TagFilter(
                tags: PostTagsUtils.tagsToStringList(_tags), // 标签列表
                selectedTag: _selectedTag, // 选中标签
                onTagSelected: _onTagSelected, // 点击标签回调
              ),
            Expanded(
              child: _buildBodyContent(isDesktop, actuallyShowLeftPanel,
                  actuallyShowRightPanel), // 主体内容
            ),
            if (!_isLoadingData && _posts != null && _totalPages > 1) // 显示分页控件
              PaginationControls(
                currentPage: _currentPage, // 当前页码
                totalPages: _totalPages, // 总页数
                isLoading: false, // 是否加载中
                onPreviousPage: _goToPreviousPage, // 上一页回调
                onNextPage: _goToNextPage, // 下一页回调
                onPageSelected: _goToPage, // 页码选择回调
              ),
          ],
        ),
      ),
    );
  }

  /// 构建页面主体内容。
  Widget _buildBodyContent(
      bool isDesktop, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    if (_errorMessage != null && (_posts == null || _posts!.isEmpty)) {
      // 发生错误且无数据时显示错误组件
      return FadeInItem(
          child: CustomErrorWidget(
        errorMessage: _errorMessage!, // 错误消息
        onRetry: () =>
            _loadPosts(page: _currentPage, isRefresh: true), // 点击重试加载
        useScaffold: false, // 不使用 Scaffold
      ));
    }

    if (_isLoadingData && _posts == null) {
      // 正在加载数据且无旧数据时显示全屏加载
      return FadeInItem(child: LoadingWidget.fullScreen(message: '正在加载帖子...'));
    }

    if (!_isLoadingData && _posts != null && _posts!.isEmpty) {
      // 加载完成但帖子列表为空时显示空状态
      return FadeInItem(child: const EmptyStateWidget(message: "啥也没有"));
    }

    if (_posts != null && _posts!.isNotEmpty) {
      // 有帖子数据时显示主要内容
      return _buildMainContent(
        isDesktop,
        actuallyShowLeftPanel: actuallyShowLeftPanel,
        actuallyShowRightPanel: actuallyShowRightPanel,
      );
    }

    return LoadingWidget.fullScreen(message: "等待加载..."); // 默认显示加载状态
  }

  /// 构建主要内容布局。
  Widget _buildMainContent(
    bool isDesktop, {
    bool actuallyShowLeftPanel = false,
    bool actuallyShowRightPanel = false,
  }) {
    return isDesktop
        ? _buildDesktopLayout(
            isDesktop,
            actuallyShowLeftPanel,
            actuallyShowRightPanel,
          ) // 桌面布局
        : _buildMobileLayout(
            isDesktop,
          ); // 移动端布局
  }

  /// 构建桌面布局。
  ///
  /// [isDesktop]：是否为桌面。
  /// [actuallyShowLeftPanel]：实际是否显示左侧面板。
  /// [actuallyShowRightPanel]：实际是否显示右侧面板。
  Widget _buildDesktopLayout(
      bool isDesktop, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    const Duration panelAnimationDuration =
        Duration(milliseconds: 300); // 面板动画时长
    const Duration leftPanelDelay = Duration(milliseconds: 50); // 左侧面板延迟
    const Duration rightPanelDelay = Duration(milliseconds: 100); // 右侧面板延迟

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
      children: [
        if (actuallyShowLeftPanel) // 显示左侧分类面板
          FadeInSlideLRItem(
            key: const ValueKey('forum_left_panel'), // 唯一键
            slideDirection: SlideDirection.left, // 滑动方向
            duration: panelAnimationDuration, // 动画时长
            delay: leftPanelDelay, // 延迟
            child: PostLeftPanel(
              tags: _tags, // 标签列表
              selectedTag: _selectedTag, // 选中标签
              onTagSelected: _onTagSelected, // 点击标签回调
            ),
          ),
        Expanded(
          child: _buildDesktopPostsGrid(
            // 桌面帖子网格
            isDesktop,
            actuallyShowLeftPanel,
            actuallyShowRightPanel,
          ),
        ),
        if (actuallyShowRightPanel) // 显示右侧统计面板
          FadeInSlideLRItem(
            key: const ValueKey('forum_right_panel'), // 唯一键
            slideDirection: SlideDirection.right, // 滑动方向
            duration: panelAnimationDuration, // 动画时长
            delay: rightPanelDelay, // 延迟
            child: PostRightPanel(
              currentPosts: _posts!, // 当前帖子列表
              selectedTag: _selectedTag, // 选中标签
              onTagSelected: _onTagSelected, // 点击标签回调
            ),
          )
      ],
    );
  }

  /// 构建移动端布局。
  ///
  /// [isDesktop]：是否为桌面。
  Widget _buildMobileLayout(bool isDesktop) {
    return _buildMobilePostsList(isDesktop); // 构建移动端帖子列表
  }

  /// 构建移动端帖子列表。
  ///
  /// [isDesktop]：是否为桌面。
  Widget _buildMobilePostsList(bool isDesktop) {
    if (_posts == null) return const SizedBox.shrink(); // 帖子列表为空时返回空组件

    return RefreshIndicator(
      key: ValueKey(_selectedTag), // 唯一键
      onRefresh: _refreshData, // 下拉刷新回调
      child: AnimatedListView<Post>(
        items: _posts!, // 帖子列表
        itemBuilder: (context, index, post) {
          return GestureDetector(
            onTap: () => _navigateToPostDetail(post), // 点击导航到帖子详情
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0), // 底部内边距
              child: _buildPostCard(
                isDesktop,
                post,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建帖子卡片。
  ///
  /// [isDesktop]：是否为桌面。
  /// [post]：帖子数据。
  Widget _buildPostCard(
    bool isDesktop,
    Post post,
  ) {
    return BasePostCard(
      currentUser: widget.authProvider.currentUser, // 当前用户
      post: post, // 帖子数据
      showPinnedStatus: true, // 显示置顶状态
      infoProvider: widget.infoProvider, // 用户信息 Provider
      followService: widget.followService, // 关注服务
      isDesktopLayout: isDesktop, // 是否为桌面布局
      onDeleteAction: _handleDeletePostFromCard, // 删除回调
      onEditAction: _handleEditPostFromCard, // 编辑回调
      onToggleLockAction: _handleToggleLockFromCard, // 切换锁定回调
    );
  }

  /// 构建桌面端帖子网格。
  ///
  /// [isDesktop]：是否为桌面。
  /// [actuallyShowLeftPanel]：实际是否显示左侧面板。
  /// [actuallyShowRightPanel]：实际是否显示右侧面板。
  Widget _buildDesktopPostsGrid(
      bool isDesktop, bool actuallyShowLeftPanel, bool actuallyShowRightPanel) {
    if (_posts == null) return const SizedBox.shrink(); // 帖子列表为空时返回空组件

    int crossAxisCount = 3; // 默认交叉轴数量
    if (actuallyShowLeftPanel && actuallyShowRightPanel) {
      // 左右面板都显示时
      crossAxisCount = 2; // 交叉轴数量为 2
    } else if (!actuallyShowLeftPanel && !actuallyShowRightPanel) {
      // 左右面板都不显示时
      crossAxisCount = 4; // 交叉轴数量为 4
    }

    return AnimatedMasonryGridView<Post>(
      crossAxisCount: crossAxisCount, // 交叉轴数量
      mainAxisSpacing: 8, // 主轴间距
      crossAxisSpacing: 16, // 交叉轴间距
      items: _posts!, // 帖子列表
      itemBuilder: (context, index, item) {
        return _buildPostCard(
          isDesktop,
          item,
        ); // 构建帖子卡片
      },
    );
  }
}
