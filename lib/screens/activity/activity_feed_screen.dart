// lib/screens/activity/activity_feed_screen.dart

/// 该文件定义了 ActivityFeedScreen 组件，一个显示用户动态流的屏幕。
/// ActivityFeedScreen 加载和展示用户动态，支持刷新、分页、错误处理和多种布局模式。
library;

import 'dart:async'; // 导入异步操作所需
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter/services.dart'; // 导入 HapticFeedback
import 'package:hive/hive.dart'; // 导入 Hive 数据库，用于监听缓存事件
import 'package:suxingchahui/models/activity/user_activity.dart'; // 导入用户活动模型
import 'package:suxingchahui/models/common/pagination.dart'; // 导入分页数据模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/services/main/activity/activity_service.dart'; // 导入活动服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/components/screen/activity/panel/hot_activities_panel.dart'; // 导入热门活动面板
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart'; // 导入可折叠活动动态组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 导入确认对话框
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入应用 SnackBar 工具
import 'package:visibility_detector/visibility_detector.dart'; // 导入可见性检测器

/// `ActivityFeedScreen` 类：用户动态流显示屏幕。
///
/// 该屏幕负责从服务加载活动数据，管理其显示状态（加载中、错误、空），
/// 并提供用户交互功能，如刷新、分页、布局切换和活动操作。
class ActivityFeedScreen extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final ActivityService activityService; // 活动服务
  final UserFollowService followService; // 用户关注服务
  final UserInfoProvider infoProvider; // 用户信息 Provider
  final InputStateService inputStateService; // 输入状态 Provider
  final String title; // 屏幕标题
  final bool useAlternatingLayout; // 是否使用交替布局
  final bool showHotActivities; // 是否显示热门活动面板

  /// 构造函数。
  ///
  /// [authProvider]：认证 Provider。
  /// [activityService]：活动服务。
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [inputStateService]：输入状态 Provider。
  /// [title]：屏幕标题。
  /// [useAlternatingLayout]：是否使用交替布局。
  /// [showHotActivities]：是否显示热门活动。
  const ActivityFeedScreen({
    super.key,
    required this.authProvider,
    required this.activityService,
    required this.followService,
    required this.infoProvider,
    required this.inputStateService,
    this.title = '动态广场',
    this.useAlternatingLayout = true,
    this.showHotActivities = true,
  });

  /// 创建状态。
  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

/// `_ActivityFeedScreenState` 类：`ActivityFeedScreen` 的状态管理。
///
/// 管理 UI 控制器、数据状态、加载状态、可见性、缓存监听和应用生命周期变化。
class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController(); // 滚动控制器
  late AnimationController _refreshAnimationController; // 刷新动画控制器

  bool _useAlternatingLayout = true; // 是否使用交替布局
  bool _showHotActivities = true; // 是否显示热门活动面板
  FeedCollapseMode _collapseMode = FeedCollapseMode.none; // 折叠模式

  List<UserActivity> _activities = []; // 活动列表数据
  PaginationData? _pagination; // 分页数据
  String _error = ''; // 错误消息
  int _currentPage = 1; // 当前页码

  bool _isInitialized = false; // 是否已初始化数据
  bool _isVisible = false; // 屏幕是否可见
  bool _isLoadingData = false; // 是否正在加载数据
  bool _isLoadingMore = false; // 是否正在加载更多数据
  bool _needsRefresh = false; // 是否需要刷新

  StreamSubscription<BoxEvent>? _cacheSubscription; // 缓存订阅器
  String _currentWatchIdentifier = ''; // 当前缓存监听标识符
  Timer? _refreshDebounceTimer; // 刷新防抖计时器

  DateTime? _lastRefreshTime; // 上次刷新时间
  final Duration _minUiRefreshInterval =
      const Duration(seconds: 10); // 最小 UI 刷新间隔
  final Duration _refreshDebounceTime =
      const Duration(milliseconds: 800); // 刷新防抖时间

  bool _hasInitializedDependencies = false; // 依赖是否已初始化
  String? _currentUserId; // 当前用户ID

  @override
  void initState() {
    super.initState();
    _useAlternatingLayout = widget.useAlternatingLayout; // 初始化布局模式
    _showHotActivities = widget.showHotActivities; // 初始化热门活动面板显示状态

    _refreshAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800)); // 初始化刷新动画控制器
    _scrollController.addListener(_scrollListener); // 添加滚动监听器
    WidgetsBinding.instance.addObserver(this); // 添加应用生命周期观察者
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      // 依赖未初始化时
      _hasInitializedDependencies = true; // 标记为已初始化
    }
    if (_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户ID
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除应用生命周期观察者
    _stopWatchingCache(); // 停止监听缓存
    _refreshDebounceTimer?.cancel(); // 取消刷新防抖计时器
    _scrollController.removeListener(_scrollListener); // 移除滚动监听器
    _scrollController.dispose(); // 销毁滚动控制器
    _refreshAnimationController.dispose(); // 销毁刷新动画控制器
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ActivityFeedScreen oldWidget) {
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台恢复时
      if (_currentUserId != widget.authProvider.currentUserId) {
        _needsRefresh = true; // 标记需要刷新

        if (mounted) {
          setState(() {
            _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
          });
        }
      }

      if (_isVisible && _needsRefresh) {
        // 屏幕可见且需要刷新时
        _refreshCurrentPageData(reason: "应用恢复且需要刷新"); // 刷新数据
        _needsRefresh = false; // 重置刷新标记
      } else if (_isVisible) {
        // 屏幕可见时
        _refreshCurrentPageData(reason: "应用恢复且可见检查"); // 刷新数据
      }
    }
  }

  /// 启动或更新缓存监听。
  ///
  /// 该方法监听指定动态流的缓存变化，并在数据删除时触发刷新。
  void _startOrUpdateWatchingCache() {
    const String feedTypeStr = 'public'; // 动态流类型为公开
    final String newWatchIdentifier =
        "${feedTypeStr}_p${_currentPage}_l20"; // 新的监听标识符

    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      // 已经监听相同目标时返回
      return;
    }

    _stopWatchingCache(); // 停止之前的监听
    _currentWatchIdentifier = newWatchIdentifier; // 更新监听标识符

    try {
      _cacheSubscription = widget.activityService
          .watchActivityFeedChanges(
        feedType: feedTypeStr,
        page: _currentPage,
        limit: 20,
      )
          .listen(
        (BoxEvent event) {
          if (event.deleted) {
            // 缓存项被删除时
            if (_isVisible) {
              // 屏幕可见时立即刷新
              _refreshCurrentPageData(
                reason: "缓存删除事件",
                isCacheUpdated: true,
              );
            } else {
              // 屏幕不可见时标记需要刷新
              _needsRefresh = true;
            }
          }
        },
        onError: (error, stackTrace) {
          // 监听发生错误时
          _stopWatchingCache(); // 停止监听
          _currentWatchIdentifier = ''; // 重置标识符
        },
        onDone: () {
          // 监听完成时
          if (_currentWatchIdentifier == newWatchIdentifier) {
            _currentWatchIdentifier = ''; // 清除标识符
          }
        },
        cancelOnError: true, // 发生错误时自动取消监听
      );
    } catch (e) {
      _currentWatchIdentifier = ''; // 启动监听失败时重置标识符
    }
  }

  /// 停止监听缓存。
  void _stopWatchingCache() {
    _cacheSubscription?.cancel(); // 取消订阅
    _cacheSubscription = null; // 清空订阅器
  }

  /// 刷新当前页数据，带防抖和节流。
  ///
  /// [reason]：刷新原因。
  /// [isCacheUpdated]：是否因缓存更新触发。
  void _refreshCurrentPageData(
      {required String reason, bool isCacheUpdated = false}) {
    if (_isLoadingData || _isLoadingMore || !mounted) return; // 正在加载或组件未挂载时返回

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      // 节流控制
      return;
    }

    _refreshDebounceTimer?.cancel(); // 取消旧的防抖计时器
    _refreshDebounceTimer = Timer(_refreshDebounceTime, () {
      // 启动新的防抖计时器
      if (!mounted) return; // 组件未挂载时返回
      if (!_isVisible) {
        // 屏幕不可见时标记需要刷新
        _needsRefresh = true;
        return;
      }

      if (_isLoadingData || _isLoadingMore) {
        // 正在加载数据或更多时
        if (isCacheUpdated) {
          // 如果是缓存更新触发
          return;
        } else {
          _needsRefresh = true; // 标记需要刷新
          return;
        }
      }

      _loadActivities(isRefresh: true, pageToLoad: _currentPage); // 加载活动数据
    });
  }

  /// 触发初始加载。
  ///
  /// 当组件可见且未初始化时加载第一页数据。
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && !_isLoadingData) {
      // 屏幕可见且未初始化且未加载数据时
      _isInitialized = true; // 标记为已初始化
      _loadActivities(isInitialLoad: true, pageToLoad: 1); // 加载第一页活动数据
    }
  }

  /// 获取活动数据。
  ///
  /// [isInitialLoad]：是否为初始加载。
  /// [isRefresh]：是否为刷新。
  /// [forceRefresh]：是否强制刷新。
  /// [pageToLoad]：要加载的页码。
  Future<void> _loadActivities(
      {bool isInitialLoad = false,
      bool isRefresh = false,
      bool forceRefresh = false,
      int pageToLoad = 1}) async {
    if (_isLoadingData && !isRefresh) return; // 正在加载且非刷新时返回
    if (_isLoadingMore && isRefresh) return; // 正在加载更多且刷新时返回
    if (!mounted) return; // 组件未挂载时返回

    const String feedTypeStr = 'public'; // 动态流类型为公开
    final String newWatchIdentifier =
        "${feedTypeStr}_p${pageToLoad}_l20"; // 新的监听标识符
    if (_currentWatchIdentifier != newWatchIdentifier) {
      // 监听标识符变化时停止旧监听
      _stopWatchingCache();
    }

    setState(() {
      _isLoadingData = true; // 设置加载状态
      _error = ''; // 清空错误消息
      if (isRefresh || isInitialLoad) {
        // 刷新或初始加载时
        _currentPage = pageToLoad; // 更新当前页码
        if (isInitialLoad || _activities.isEmpty) {
          // 初始加载或活动列表为空时清空活动
          _activities = [];
        }
        _pagination = null; // 清空分页数据
      }
    });
    if (isRefresh && pageToLoad == 1) {
      // 刷新第一页时启动刷新动画
      _refreshAnimationController.forward(from: 0.0);
    }

    try {
      const int limit = 20; // 每页限制
      final result = await widget.activityService.getPublicActivities(
          page: pageToLoad, limit: limit, forceRefresh: forceRefresh); // 获取公开活动

      if (!mounted) return; // 组件未挂载时返回

      final List<UserActivity> fetchedActivities = result.activities; // 获取活动列表
      final PaginationData fetchedPagination = result.pagination; // 获取分页数据

      setState(() {
        if (isRefresh || isInitialLoad || pageToLoad != _currentPage) {
          // 刷新、初始加载或页码变化时更新活动
          _activities = fetchedActivities;
        }
        _pagination = fetchedPagination; // 更新分页信息
        _currentPage = pageToLoad; // 更新当前页码
        _isLoadingData = false; // 重置加载状态
        _error = ''; // 清空错误消息
        _lastRefreshTime = DateTime.now(); // 记录刷新时间
      });
      _startOrUpdateWatchingCache(); // 启动或更新缓存监听
    } catch (e) {
      if (!mounted) return; // 组件未挂载时返回
      setState(() {
        if (_activities.isEmpty) {
          // 活动列表为空时显示错误
          _error = '加载动态失败: $e';
        } else {
          // 否则显示 SnackBar 错误
          AppSnackBar.showError('刷新动态失败: $e');
        }
        _isLoadingData = false; // 重置加载状态
      });
      _stopWatchingCache(); // 停止缓存监听
    } finally {
      if (mounted && _isLoadingData) {
        // 确保加载状态重置
        setState(() => _isLoadingData = false);
      }
      if (mounted) {
        _refreshAnimationController.reset(); // 重置刷新动画
      }
    }
  }

  /// 处理下拉刷新手势。
  ///
  /// [forceRefresh]：是否强制刷新。
  Future<void> _refreshData({bool forceRefresh = false}) async {
    if (_isLoadingData || _isLoadingMore) return; // 正在加载时返回

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      // 节流控制
      await Future.delayed(const Duration(milliseconds: 300)); // 延迟以提供视觉反馈
      return;
    }

    _stopWatchingCache(); // 停止监听缓存
    setState(() {
      _currentPage = 1; // 重置为第一页
      _error = ''; // 清空错误消息
    });
    await _loadActivities(
        isRefresh: true,
        pageToLoad: 1,
        forceRefresh: forceRefresh); // 加载第一页活动数据
  }

  /// 处理刷新按钮点击。
  void _handleRefreshButtonPress() {
    if (_isLoadingData || _isLoadingMore || !mounted) return; // 正在加载或组件未挂载时返回

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      // 节流控制
      return;
    }

    _refreshDebounceTimer?.cancel(); // 取消旧的防抖计时器
    _refreshDebounceTimer = Timer(_refreshDebounceTime, () {
      // 启动新的防抖计时器
      if (mounted && !_isLoadingData && !_isLoadingMore) {
        _refreshData(forceRefresh: true); // 强制刷新数据
      }
    });
  }

  /// 加载更多活动数据。
  Future<void> _loadMoreActivities() async {
    if (!_isInitialized ||
        _error.isNotEmpty ||
        _isLoadingData ||
        _isLoadingMore ||
        _pagination == null ||
        _currentPage >= _pagination!.pages) {
      // 不满足加载更多条件时返回
      return;
    }
    if (!mounted) return; // 组件未挂载时返回

    final nextPage = _currentPage + 1; // 下一页页码
    _stopWatchingCache(); // 停止监听当前页缓存
    setState(() => _isLoadingMore = true); // 设置加载更多状态

    try {
      const int limit = 20; // 每页限制
      final result = await widget.activityService
          .getPublicActivities(page: nextPage, limit: limit); // 获取下一页公开活动

      if (!mounted) return; // 组件未挂载时返回

      final List<UserActivity> newActivities = result.activities; // 新加载的活动列表
      final PaginationData newPagination = result.pagination; // 新的分页数据

      setState(() {
        _activities.addAll(newActivities); // 追加新数据
        _pagination = newPagination; // 更新分页信息
        _currentPage = nextPage; // 更新当前页码
        _isLoadingMore = false; // 重置加载更多状态
        _lastRefreshTime = DateTime.now(); // 记录刷新时间
      });
      _startOrUpdateWatchingCache(); // 启动或更新缓存监听
    } catch (e) {
      if (mounted) {
        // 捕获错误时
        AppSnackBar.showError('加载更多失败: $e'); // 显示错误提示
        setState(() => _isLoadingMore = false); // 重置加载更多状态
      }
      _startOrUpdateWatchingCache(); // 尝试重新监听缓存
    } finally {
      if (mounted && _isLoadingMore) {
        // 确保加载状态重置
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// 监听滚动位置以触发加载更多。
  void _scrollListener() {
    if (_isInitialized &&
        !_isLoadingMore &&
        !_isLoadingData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        _pagination != null &&
        _currentPage < _pagination!.pages) {
      // 满足加载更多条件时
      _loadMoreActivities(); // 加载更多活动
    }
  }

  /// 切换布局模式。
  void _toggleLayoutMode() {
    HapticFeedback.lightImpact(); // 提供触觉反馈
    setState(() => _useAlternatingLayout = !_useAlternatingLayout); // 切换布局模式
  }

  /// 切换热门活动面板的可见性。
  void _toggleHotActivitiesPanel() {
    HapticFeedback.lightImpact(); // 提供触觉反馈
    setState(() => _showHotActivities = !_showHotActivities); // 切换热门活动面板可见性
  }

  /// 循环切换折叠模式。
  void _toggleCollapseMode() {
    HapticFeedback.lightImpact(); // 提供触觉反馈
    setState(() => _collapseMode = FeedCollapseMode.values[
        (_collapseMode.index + 1) %
            FeedCollapseMode.values.length]); // 循环切换折叠模式
  }

  /// 获取当前折叠模式的显示文本。
  String _getCollapseModeText() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return '标准视图';
      case FeedCollapseMode.byUser:
        return '按用户折叠';
      case FeedCollapseMode.byType:
        return '按类型折叠';
    }
  }

  /// 获取当前折叠模式的图标。
  IconData _getCollapseModeIcon() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return Icons.view_agenda_outlined;
      case FeedCollapseMode.byUser:
        return Icons.people_outline;
      case FeedCollapseMode.byType:
        return Icons.category_outlined;
    }
  }

  /// 导航到活动详情屏幕。
  ///
  /// [activity]：要导航到的活动。
  void _navigateToActivityDetail(UserActivity activity) {
    _stopWatchingCache(); // 导航时暂停监听缓存
    NavigationUtils.pushNamed(context, AppRoutes.activityDetail, arguments: {
      'activityId': activity.id,
      'activity': activity,
    }).then((_) {
      // 从详情页返回时
      if (mounted) {
        _startOrUpdateWatchingCache(); // 恢复监听缓存
        _refreshCurrentPageData(reason: "从详情页返回"); // 刷新当前页数据
      }
    });
  }

  /// 检查是否可编辑或删除活动。
  ///
  /// [activity]：要检查的活动。
  /// 返回 true 表示可编辑或删除，否则返回 false。
  bool _checkCanEditOrCanDelete(UserActivity activity) {
    final bool isAuthor =
        activity.userId == widget.authProvider.currentUserId; // 是否作者
    final bool isAdmin = widget.authProvider.isAdmin; // 是否管理员
    final canEditOrDelete = isAdmin ? true : isAuthor; // 管理员或作者可编辑删除
    return canEditOrDelete;
  }

  /// 处理删除活动。
  ///
  /// [activity]：要删除的活动。
  Future<void> _handleDeleteActivity(UserActivity activity) async {
    final activityId = activity.id; // 活动ID
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    if (!_checkCanEditOrCanDelete(activity)) {
      // 无权限时提示错误
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    await CustomConfirmDialog.show(
      // 显示确认对话框
      context: context,
      title: "确认删除",
      message: "确定删除这条动态吗？此操作无法撤销。",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever_outlined,
      iconColor: Colors.red,
      onConfirm: () async {
        // 确认删除回调
        try {
          final success =
              await widget.activityService.deleteActivity(activity); // 调用删除活动服务
          if (success && mounted) {
            // 删除成功且组件挂载时
            AppSnackBar.showSuccess('动态已删除'); // 提示删除成功
            setState(() {
              // 乐观更新 UI
              final initialTotal = _pagination?.total ?? _activities.length;
              _activities
                  .removeWhere((act) => act.id == activityId); // 从列表中移除活动
              if (_pagination != null && initialTotal > 0) {
                _pagination =
                    _pagination!.copyWith(total: initialTotal - 1); // 更新分页总数
              }
            });
            if (_activities.isEmpty && _currentPage > 1) {
              // 当前页为空且非第一页时刷新
              _refreshCurrentPageData(reason: "已删除页面上的最后一项");
            }
          } else if (mounted) {
            // 服务报告失败时
            throw Exception("服务未能成功删除动态");
          }
        } catch (e) {
          // 捕获错误时
          if (mounted) AppSnackBar.showError('删除失败: ${e.toString()}'); // 提示删除失败
          rethrow; // 重新抛出错误
        }
      },
    );
  }

  /// 处理点赞活动。
  ///
  /// [activityId]：活动ID。
  Future<void> _handleLikeActivity(String activityId) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    try {
      await widget.activityService.likeActivity(activityId); // 调用点赞服务
    } catch (e) {
      AppSnackBar.showError('点赞失败: ${e.toString()}'); // 提示点赞失败
    }
  }

  /// 处理取消点赞活动。
  ///
  /// [activityId]：活动ID。
  Future<void> _handleUnlikeActivity(String activityId) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    try {
      await widget.activityService.unlikeActivity(activityId); // 调用取消点赞服务
    } catch (e) {
      AppSnackBar.showError('取消点赞失败: $e'); // 提示取消点赞失败
    }
  }

  /// 处理添加评论。
  ///
  /// [activityId]：活动ID。
  /// [content]：评论内容。
  Future<ActivityComment?> _handleAddComment(
      String activityId, String content) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时抛出异常
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context); // 提示登录
      }
      throw Exception("你没有登录");
    }
    try {
      final comment = await widget.activityService
          .commentOnActivity(activityId, content); // 调用添加评论服务
      if (comment != null) {
        // 评论成功且组件挂载时
        AppSnackBar.showSuccess('评论成功'); // 提示评论成功
        return comment; // 返回评论对象
      } else if (mounted) {
        // 无操作
      }
    } catch (e) {
      // 捕获错误时
      AppSnackBar.showError('评论失败: $e'); // 提示评论失败
    }
    return null; // 返回 null 表示失败
  }

  /// 检查是否可删除评论。
  ///
  /// [comment]：要检查的评论。
  /// 返回 true 表示可删除，否则返回 false。
  bool _checkCanDeleteComment(ActivityComment comment) {
    final bool isAuthor =
        comment.userId == widget.authProvider.currentUserId; // 是否作者
    final bool isAdmin = widget.authProvider.isAdmin; // 是否管理员
    return isAdmin ? true : isAuthor; // 管理员或作者可删除
  }

  /// 处理删除评论。
  ///
  /// [activityId]：活动ID。
  /// [comment]：要删除的评论。
  Future<void> _handleDeleteComment(
      String activityId, ActivityComment comment) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    if (!_checkCanDeleteComment(comment)) {
      // 无权限时提示错误
      if (mounted) {
        AppSnackBar.showPermissionDenySnackBar();
      }
      return;
    }

    await CustomConfirmDialog.show(
      // 显示确认对话框
      context: context,
      title: "确认删除",
      message: "确定删除这条评论吗？",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_outline,
      iconColor: Colors.red,
      onConfirm: () async {
        // 确认删除回调
        try {
          final success = await widget.activityService
              .deleteComment(activityId, comment); // 调用删除评论服务
          if (success) {
            // 删除成功且组件挂载时
            AppSnackBar.showSuccess('评论已删除'); // 提示评论已删除
          } else if (mounted) {
            // 服务报告失败时
            throw Exception("未能成功删除评论");
          }
        } catch (e) {
          // 捕获错误时
          AppSnackBar.showError('删除评论失败: ${e.toString()}'); // 提示删除失败
          rethrow; // 重新抛出错误
        }
      },
    );
  }

  /// 处理点赞评论。
  ///
  /// [activityId]：活动ID。
  /// [commentId]：评论ID。
  Future<void> _handleLikeComment(String activityId, String commentId) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await widget.activityService
          .likeComment(activityId, commentId); // 调用点赞评论服务
    } catch (e) {
      AppSnackBar.showError('点赞评论失败: $e'); // 提示点赞失败
    }
  }

  /// 处理取消点赞评论。
  ///
  /// [activityId]：活动ID。
  /// [commentId]：评论ID。
  Future<void> _handleUnlikeComment(String activityId, String commentId) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await widget.activityService
          .unlikeComment(activityId, commentId); // 调用取消点赞评论服务
    } catch (e) {
      AppSnackBar.showError('取消点赞评论失败: $e'); // 提示取消点赞失败
    }
  }

  /// 处理可见性变化。
  ///
  /// [info]：可见性信息。
  void _handleVisibilityChange(VisibilityInfo info) {
    final bool currentlyVisible = info.visibleFraction > 0.8; // 认为屏幕可见
    if (currentlyVisible != _isVisible) {
      // 可见性状态发生变化时
      if (_currentUserId != widget.authProvider.currentUserId) {
        // 用户ID变化时
        _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        _needsRefresh = true; // 标记需要刷新
        if (mounted) {
          setState(() {});
        }
      }

      final bool wasVisible = _isVisible; // 记录旧的可见性状态
      _isVisible = currentlyVisible; // 更新当前可见性状态
      if (_isVisible) {
        // 如果变为可见
        _triggerInitialLoad(); // 触发初始加载
        _startOrUpdateWatchingCache(); // 开始监听缓存
        if (!wasVisible) {
          _refreshCurrentPageData(reason: "变为可见"); // 如果刚变为可见，刷新数据
        }
      } else {
        // 如果变为不可见
        _stopWatchingCache(); // 停止监听缓存
      }
    }
  }

  /// 构建屏幕主内容。
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(
          'activity_feed_visibility_${widget.key?.toString() ?? widget.title}'), // 可见性检测器 Key
      onVisibilityChanged: _handleVisibilityChange, // 可见性变化回调
      child: Scaffold(
        body: SafeArea(
          child: _buildBodyContent(), // 构建主内容区域
        ),
      ),
    );
  }

  /// 构建页面主体内容。
  Widget _buildBodyContent() {
    if (!_isInitialized && !_isLoadingData) {
      // 未初始化且未加载数据时显示准备加载
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "等待加载...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (_isLoadingData && _activities.isEmpty) {
      // 正在加载数据且活动列表为空时显示正在加载
      // 全屏加载组件
      return const LoadingWidget(
        isOverlay: true,
        message: "少女正在祈祷中...",
        overlayOpacity: 0.4,
        size: 36,
      ); //
    }

    if (_error.isNotEmpty && _activities.isEmpty) {
      // 发生错误且活动列表为空时显示错误组件
      return CustomErrorWidget(
          errorMessage: _error,
          onRetry: () =>
              _loadActivities(isRefresh: true, pageToLoad: 1)); // 提供重试按钮
    }

    Widget topActionBar = _buildTopActionBar(); // 构建顶部动作栏
    Widget mainFeedContent = _buildMainFeedContent(); // 构建主要动态流内容

    return LayoutBuilder(
      // 布局构建器，用于响应式布局
      builder: (context, constraints) {
        const double desktopBreakpoint = 720.0; // 桌面布局断点

        if (constraints.maxWidth >= desktopBreakpoint &&
            widget.showHotActivities) {
          // 宽屏幕且显示热门活动时
          return Column(
            children: [
              topActionBar, // 顶部动作栏
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
                  children: [
                    Expanded(
                      flex: 3, // 动态流占据更多空间
                      child: mainFeedContent, // 主要动态流内容
                    ),
                    VerticalDivider(
                        // 垂直分隔线
                        width: 1,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                        color: Colors.grey.shade200),
                    if (_showHotActivities) // 显示热门活动面板
                      SizedBox(
                        width: 300, // 面板固定宽度
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, right: 8.0, bottom: 8.0), // 内边距
                          child: HotActivitiesPanel(
                            activityService: widget.activityService,
                            userInfoProvider: widget.infoProvider,
                            followService: widget.followService,
                            currentUser: widget.authProvider.currentUser,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // 移动布局
          return Column(
            children: [
              topActionBar,
              Expanded(child: mainFeedContent),
            ],
          );
        }
      },
    );
  }

  /// 构建可折叠活动动态组件。
  Widget _buildMainFeedContent() {
    return CollapsibleActivityFeed(
      key: ValueKey('public_feed_${_collapseMode.index}'), // 唯一键
      currentUser: widget.authProvider.currentUser, // 当前用户
      followService: widget.followService, // 关注服务
      inputStateService: widget.inputStateService, // 输入状态服务
      infoProvider: widget.infoProvider, // 用户信息 Provider
      activities: _activities, // 活动列表
      isLoading: _isLoadingData && _activities.isEmpty, // 是否加载中
      isLoadingMore: _isLoadingMore, // 是否加载更多
      error: _error.isNotEmpty && _activities.isEmpty ? _error : '', // 错误消息
      collapseMode: _collapseMode, // 折叠模式
      useAlternatingLayout: _useAlternatingLayout, // 是否使用交替布局
      scrollController: _scrollController, // 滚动控制器
      onActivityTap: _navigateToActivityDetail, // 活动点击回调
      onRefresh: _refreshData, // 刷新回调
      onLoadMore: _loadMoreActivities, // 加载更多回调
      onDeleteActivity: _handleDeleteActivity, // 删除活动回调
      onLikeActivity: _handleLikeActivity, // 点赞活动回调
      onUnlikeActivity: _handleUnlikeActivity, // 取消点赞活动回调
      onAddComment: _handleAddComment, // 添加评论回调
      onDeleteComment: _handleDeleteComment, // 删除评论回调
      onLikeComment: _handleLikeComment, // 点赞评论回调
      onUnlikeComment: _handleUnlikeComment, // 取消点赞评论回调
      onEditActivity: null, // 编辑功能未实现
    );
  }

  /// 构建顶部动作栏。
  Widget _buildTopActionBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // 内边距
      child: Row(
        children: [
          Expanded(
            // 折叠模式切换按钮
            child: InkWell(
              onTap: _toggleCollapseMode, // 点击切换折叠模式
              borderRadius: BorderRadius.circular(20), // 圆角
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8), // 内边距
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withSafeOpacity(0.5), // 背景色
                    borderRadius: BorderRadius.circular(20), // 圆角
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer)), // 边框
                child: Row(
                  mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
                  mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
                  children: [
                    Icon(_getCollapseModeIcon(), // 图标
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6), // 间距
                    Text(_getCollapseModeText(), // 文本
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8), // 间距

          IconButton(
            // 刷新按钮
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0)
                  .animate(_refreshAnimationController), // 旋转动画
              child: const Icon(Icons.refresh_outlined), // 图标
            ),
            tooltip: '刷新', // 提示
            onPressed: (_isLoadingData || _isLoadingMore) // 禁用条件
                ? null
                : _handleRefreshButtonPress, // 点击回调
            splashRadius: 20, // 水波纹半径
          ),

          IconButton(
            // 布局切换按钮
            icon: Icon(_useAlternatingLayout
                ? Icons.view_stream_outlined
                : Icons.view_agenda_outlined), // 图标
            tooltip: _useAlternatingLayout ? '切换标准布局' : '切换气泡布局', // 提示
            onPressed: _toggleLayoutMode, // 点击回调
            splashRadius: 20, // 水波纹半径
          ),

          if (widget.showHotActivities) // 条件显示热门活动面板切换按钮
            IconButton(
              icon: Icon(_showHotActivities
                  ? Icons.visibility_off_outlined
                  : Icons.local_fire_department_outlined), // 图标
              onPressed: _toggleHotActivitiesPanel, // 点击回调
              tooltip: _showHotActivities ? '隐藏热门' : '显示热门', // 提示
              splashRadius: 20, // 水波纹半径
            ),
        ],
      ),
    );
  }
}
