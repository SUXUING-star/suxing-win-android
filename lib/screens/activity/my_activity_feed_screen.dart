// lib/screens/activity/my_activity_feed_screen.dart

/// 该文件定义了 MyActivityFeedScreen 界面，用于显示指定用户的动态。
/// 该界面管理动态列表的加载、刷新、分页和交互操作。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:flutter/services.dart'; // 导入 HapticFeedback
import 'package:suxingchahui/constants/activity/activity_constants.dart'; // 活动常量
import 'package:suxingchahui/models/activity/activity_detail_param.dart';
import 'package:suxingchahui/models/activity/user_activity.dart'; // 用户动态模型
import 'package:suxingchahui/models/common/pagination.dart'; // 分页数据模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息 Provider
import 'package:suxingchahui/providers/windows/window_state_provider.dart'; // 窗口状态 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由
import 'package:suxingchahui/services/main/activity/activity_service.dart'; // 动态服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 渐入动画组件
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 自定义应用栏
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart'; // 可折叠动态列表组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart'; // 登录提示组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart'; // 懒加载布局构建器
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 确认对话框
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart'; // 应用 SnackBar
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具

/// `MyActivityFeedScreen` 类：显示指定用户动态的界面。
///
/// 该界面接收用户 ID 和所需服务，并显示用户的动态列表。
class MyActivityFeedScreen extends StatefulWidget {
  final String userId; // 目标用户 ID
  final String title; // 屏幕标题
  final AuthProvider authProvider; // 认证 Provider 实例
  final ActivityService activityService; // 动态服务实例
  final UserFollowService followService; // 用户关注服务实例
  final InputStateService inputStateService; // 输入状态服务实例
  final UserInfoService infoService; // 用户信息 Provider 实例
  final WindowStateProvider windowStateProvider; // 窗口状态 Provider 实例

  /// 构造函数。
  ///
  /// [userId]：目标用户 ID。
  /// [title]：屏幕标题，默认为“TA的动态”。
  const MyActivityFeedScreen({
    super.key,
    required this.userId,
    required this.authProvider,
    required this.activityService,
    required this.followService,
    required this.inputStateService,
    required this.infoService,
    required this.windowStateProvider,
    this.title = 'TA的动态',
  });

  @override
  _MyActivityFeedScreenState createState() => _MyActivityFeedScreenState();
}

/// `_MyActivityFeedScreenState` 类：`MyActivityFeedScreen` 的状态管理。
///
/// 该类管理动态列表的加载、显示、交互和 UI 模式。
class _MyActivityFeedScreenState extends State<MyActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  // --- UI 控制器 ---
  final ScrollController _scrollController = ScrollController(); // 滚动控制器
  late AnimationController _refreshAnimationController; // 刷新动画控制器

  // --- 数据状态 ---
  List<UserActivity> _activities = []; // 动态列表数据
  PaginationData? _pagination; // 分页数据
  int _currentPage = 1; // 当前页码
  late String _feedType;

  // --- 加载与错误状态 ---
  bool _isLoading = false; // 初始加载或刷新状态
  bool _isLoadingMore = false; // 分页加载更多状态
  String _error = ''; // 错误消息

  // --- UI 模式状态 ---
  FeedCollapseMode _collapseMode = FeedCollapseMode.none; // 动态折叠模式
  bool _useAlternatingLayout = true; // 动态交替布局模式

  // --- 刷新控制 ---
  DateTime? _lastRefreshTime; // 上次刷新时间
  final Duration _minUiRefreshInterval =
      const Duration(seconds: 3); // UI 刷新最小间隔
  Timer? _refreshDebounceTimer; // 刷新防抖计时器
  bool _hasInitializedDependencies = false; // 依赖是否已初始化标记
  bool _isInitialized = false; // 界面是否已初始化标记
  String? _currentUserId; // 当前用户 ID

  // === 生命周期方法 ===
  @override
  void initState() {
    super.initState();
    _feedType = ActivitiesFeedType.user;
    _refreshAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800)); // 初始化刷新动画控制器
    _scrollController.addListener(_scrollListener); // 添加滚动监听器
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies && !_isInitialized) {
      _fetchActivities(isInitialLoad: !_isInitialized); // 首次加载数据
      _currentUserId = widget.userId; // 设置当前用户 ID
      _isInitialized = true; // 标记为已初始化
    }
    if (_hasInitializedDependencies && _isInitialized) {
      if (_currentUserId != widget.userId) {
        // 用户 ID 变化时刷新数据
        _fetchActivities(isRefresh: true);
        _currentUserId = widget.userId;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // 移除滚动监听器
    _scrollController.dispose(); // 释放滚动控制器
    _refreshAnimationController.dispose(); // 释放刷新动画控制器
    _refreshDebounceTimer?.cancel(); // 取消防抖计时器
    super.dispose(); // 调用父类 dispose 方法
  }

  // === 数据获取逻辑 ===

  /// 获取当前页的动态。
  ///
  /// [isInitialLoad]：是否为首次加载。
  /// [isRefresh]：是否为刷新操作。
  /// 管理加载状态，清空列表，执行网络请求，并更新 UI。
  Future<void> _fetchActivities(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return; // 阻止并发加载
    if (!mounted) return; // 检查组件是否已挂载

    setState(() {
      _isLoading = true; // 设置加载状态
      _error = ''; // 清空错误消息
      if (isRefresh || isInitialLoad) {
        _currentPage = 1; // 重置页码
        _pagination = null; // 清空分页数据
        if (isInitialLoad || _activities.isEmpty) {
          _activities = []; // 首次加载或列表为空时清空列表
        }
      }
    });
    if (isRefresh) {
      _refreshAnimationController.forward(from: 0.0); // 启动刷新动画
    }

    try {
      final result = await widget.activityService.getUserActivities(
        // 获取用户动态
        widget.userId,
        page: _currentPage,
      );

      if (!mounted) return; // 再次检查组件是否已挂载

      final List<UserActivity> fetchedActivities = result.activities; // 获取动态列表
      final PaginationData fetchedPagination = result.pagination; // 获取分页数据

      setState(() {
        if (isRefresh || isInitialLoad) {
          _activities = fetchedActivities; // 刷新或首次加载时替换数据
        }
        _pagination = fetchedPagination; // 更新分页数据
        _isLoading = false; // 取消加载状态
        _lastRefreshTime = DateTime.now(); // 记录刷新时间
      });
    } catch (e) {
      if (!mounted) return; // 检查组件是否已挂载
      setState(() {
        if (_activities.isEmpty) {
          _error = '加载动态失败: $e'; // 列表为空时显示全屏错误
        } else {
          AppSnackBar.showError('刷新动态失败: $e'); // 否则显示 SnackBar 错误
        }
        _isLoading = false; // 取消加载状态
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false); // 确保加载状态重置
      }
      if (mounted) {
        _refreshAnimationController.reset(); // 重置刷新动画
      }
    }
  }

  /// 加载更多动态。
  ///
  /// 当滚动到底部附近时触发。
  Future<void> _loadMoreActivities() async {
    if (_isLoading || _isLoadingMore || !mounted) return; // 阻止不必要的调用
    if (_pagination == null || _currentPage >= _pagination!.pages) {
      return; // 检查是否有下一页
    }

    final nextPage = _currentPage + 1; // 计算下一页页码
    setState(() {
      _isLoadingMore = true; // 设置为加载更多状态
    });

    try {
      final result = await widget.activityService.getUserActivities(
        // 获取下一页动态
        widget.userId,
        page: nextPage,
      );

      if (!mounted) return; // 检查组件是否已挂载

      final List<UserActivity> newActivities = result.activities; // 获取新动态列表
      final PaginationData newPagination = result.pagination; // 获取新分页数据

      setState(() {
        _activities.addAll(newActivities); // 追加新动态
        _pagination = newPagination; // 更新分页信息
        _currentPage = nextPage; // 更新当前页码
        _isLoadingMore = false; // 取消加载更多状态
        _lastRefreshTime = DateTime.now(); // 记录刷新时间
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError('加载更多失败: ${e.toString()}'); // 显示错误 SnackBar
        setState(() {
          _isLoadingMore = false; // 取消加载更多状态
        });
      }
    } finally {
      if (mounted && _isLoadingMore) {
        setState(() => _isLoadingMore = false); // 确保重置加载更多状态
      }
    }
  }

  /// 滚动监听器。
  ///
  /// 当滚动到接近底部时触发加载更多动态。
  void _scrollListener() {
    if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent * 0.9 && // 接近底部
            !_isLoadingMore && // 未在加载更多
            !_isLoading && // 不在初始/刷新加载中
            _pagination != null &&
            _currentPage < _pagination!.pages // 有下一页
        ) {
      _loadMoreActivities(); // 加载更多动态
    }
  }

  /// 处理下拉刷新动作。
  Future<void> _refreshData() async {
    if (_isLoading || _isLoadingMore) return; // 阻止并发刷新
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      await Future.delayed(const Duration(milliseconds: 300)); // 延迟
      return;
    }
    setState(() {
      _currentPage = 1; // 重置页码为 1
      _error = ''; // 清空错误消息
    });
    await _fetchActivities(isRefresh: true); // 刷新数据
  }

  /// 处理刷新按钮点击。
  void _handleRefreshButtonPress() {
    if (_isLoading || _isLoadingMore || !mounted) return;
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      return;
    }
    _refreshDebounceTimer?.cancel(); // 取消上一个防抖计时器
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isLoading && !_isLoadingMore) {
        _refreshData(); // 防抖后执行刷新
      }
    });
  }

  // === UI 模式切换 ===

  /// 切换交替布局模式。
  void _toggleLayoutMode() {
    HapticFeedback.lightImpact(); // 轻微震动反馈
    setState(() => _useAlternatingLayout = !_useAlternatingLayout); // 切换布局模式
  }

  /// 切换动态折叠模式。
  void _toggleCollapseMode() {
    HapticFeedback.lightImpact(); // 轻微震动反馈
    setState(() {
      if (_collapseMode == FeedCollapseMode.none) {
        _collapseMode = FeedCollapseMode.byType; // 切换到按类型折叠
      } else {
        _collapseMode = FeedCollapseMode.none; // 切换回不折叠
      }
    });
  }

  // === 导航 ===

  /// 导航到动态详情界面。
  ///
  /// [activity]：要查看详情的动态。
  void _navigateToActivityDetail(UserActivity activity) {
    NavigationUtils.pushNamed(context, AppRoutes.activityDetail,
        arguments: ActivityDetailParam(
          activityId: activity.id,
          activity: activity,
          listPageNum: _currentPage,
          feedType: _feedType,
        )).then((result) {
      if (mounted && result == true) {
        _refreshData(); // 如果详情页返回 true，则刷新数据
      }
    });
  }

  /// 检查用户是否拥有编辑或删除动态的权限。
  ///
  /// [activity]：要检查的动态。
  /// 返回 true 表示拥有权限，false 表示没有权限。
  bool _checkCanEditOrCanDelete(UserActivity activity) {
    final bool isAuthor =
        activity.userId == widget.authProvider.currentUserId; // 是否为动态作者
    final bool isAdmin = widget.authProvider.isAdmin; // 是否为管理员
    final canEditOrDelete = isAdmin ? true : isAuthor; // 管理员或作者拥有权限
    return canEditOrDelete;
  }

  /// 处理删除动态操作。
  ///
  /// [activity]：要删除的动态。
  /// 显示确认对话框，确认后执行删除操作并更新 UI。
  Future<void> _handleDeleteActivity(UserActivity activity) async {
    if (!widget.authProvider.isLoggedIn) {
      // 检查登录状态
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      }
      return;
    }

    if (!_checkCanEditOrCanDelete(activity)) {
      // 检查权限
      if (mounted) {
        AppSnackBar.showPermissionDenySnackBar(); // 显示权限拒绝提示
      }
      return;
    }
    final activityId = activity.id; // 获取动态 ID

    await CustomConfirmDialog.show(
      context: context,
      title: "确认删除",
      message: "确定删除这条动态吗？此操作无法撤销。",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever_outlined,
      iconColor: Colors.red,
      onConfirm: () async {
        try {
          final success = await widget.activityService.deleteActivity(
            activity,
            feedType: _feedType,
          ); // 调用服务删除动态
          if (success && mounted) {
            // 删除成功且组件已挂载
            AppSnackBar.showSuccess('动态已删除'); // 显示成功提示
            setState(() {
              final initialTotal =
                  _pagination?.total ?? _activities.length; // 获取初始总数
              _activities.removeWhere((act) => act.id == activityId); // 从列表中移除
              if (_pagination != null && initialTotal > 0) {
                _pagination =
                    _pagination!.copyWith(total: initialTotal - 1); // 更新分页总数
              }
            });
            if (_activities.isEmpty && _currentPage > 1) {
              _refreshData(); // 列表为空且非第一页时刷新数据
            }
          } else if (mounted) {
            throw Exception("删除失败，请重试"); // 抛出删除失败异常
          }
        } catch (e) {
          AppSnackBar.showError('删除失败: $e'); // 显示错误提示
          rethrow; // 重新抛出异常
        }
      },
    );
  }

  /// 处理点赞活动。
  ///
  /// [activityId]：活动ID。
  Future<bool> _handleToggleLikeActivity(
    String activityId, {
    required bool action,
  }) async {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return false;
    }

    try {
      bool success;
      if (action) {
        success = await widget.activityService.likeActivity(
          activityId,
          feedType: _feedType,
        ); // 调用点赞服务
      } else {
        success = await widget.activityService.unlikeActivity(
          activityId,
          feedType: _feedType,
        ); // 调用取消点赞服务
      }

      if (success) {
        UserActivity? newActivity;
        setState(() {
          _activities = _activities.map((UserActivity a) {
            if (a.id == activityId) {
              if (action) {
                a.likesCount++;
                a.isLiked = action;
              }

              if (!action) {
                a.likesCount--;
                a.isLiked = action;
              }

              newActivity = a;
            }
            return a;
          }).toList();
        });
        final updatedActivity = newActivity;
        if (updatedActivity != null) {
          await widget.activityService
              .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
            updatedActivity,
            feedType: _feedType,
            pageNum: _currentPage,
          );
        }
        AppSnackBar.showSuccess("操作成功");
      } else {
        AppSnackBar.showSuccess("操作失败");
      }

      return success;
    } catch (e) {
      AppSnackBar.showError('操作失败: ${e.toString()}'); // 提示点赞失败
      return false;
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
      final comment = await widget.activityService.commentOnActivity(
        activityId,
        content,
        feedType: _feedType,
      ); // 调用添加评论服务
      if (comment != null) {
        UserActivity? newActivity;

        // 评论成功且组件挂载时
        AppSnackBar.showSuccess('评论成功'); // 提示评论成功
        setState(() {
          _activities = _activities.map((UserActivity a) {
            if (a.id == activityId) {
              a.comments.add(comment);
              a.commentsCount++;
              newActivity = a;
            }
            return a;
          }).toList();
        });

        final updatedActivity = newActivity;
        if (updatedActivity != null) {
          await widget.activityService
              .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
            updatedActivity,
            feedType: _feedType,
            pageNum: _currentPage,
          );
        }

        return comment; // 返回评论对象
      } else if (mounted) {
        // 无操作
      } else if (comment == null) {
        AppSnackBar.showError('评论失败'); // 提示评论失败
      }
    } catch (e) {
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
          final success = await widget.activityService.deleteComment(
            activityId,
            comment,
            feedType: _feedType,
          ); // 调用删除评论服务
          if (success) {
            // 删除成功且组件挂载时
            UserActivity? newActivity;
            setState(() {
              _activities = _activities.map((UserActivity a) {
                // 只对匹配的 activity 进行操作
                if (a.id == activityId) {
                  a.comments
                      .removeWhere((ActivityComment c) => c.id == comment.id);
                  a.commentsCount--;
                  if (a.commentsCount <= 0) a.commentsCount = 0;
                  newActivity = a;
                }

                // 确保总是返回 activity 对象
                return a;
              }).toList();
            });
            final updatedActivity = newActivity;
            if (updatedActivity != null) {
              await widget.activityService
                  .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
                updatedActivity,
                feedType: _feedType,
                pageNum: _currentPage,
              );
            }

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

  /// 处理点赞评论操作。
  ///
  /// [activityId]：评论所属动态的 ID。
  /// [commentId]：要点赞的评论 ID。
  /// 检查登录状态，调用服务点赞。
  Future<bool> _handleToggleLikeComment(
    String activityId,
    String commentId, {
    required bool action,
  }) async {
    if (!widget.authProvider.isLoggedIn) {
      // 检查登录状态
      AppSnackBar.showLoginRequiredSnackBar(context); // 显示登录提示
      return false;
    }
    try {
      bool success;
      if (action) {
        success = await widget.activityService.likeComment(
          activityId,
          commentId,
          feedType: _feedType,
        ); // 调用服务点赞评论
      } else {
        success = await widget.activityService.unlikeComment(
          activityId,
          commentId,
          feedType: _feedType,
        ); // 调用服务取消点赞评论
      }

      if (success) {
        UserActivity? newActivity;
        setState(() {
          _activities = _activities.map((a) {
            if (a.id == activityId) {
              final List<ActivityComment> newComments = a.comments.map((c) {
                if (commentId == c.id) {
                  if (action) {
                    c.isLiked = action;
                    c.likesCount++;
                  } else {
                    c.isLiked = action;
                    c.likesCount--;
                  }
                }
                return c;
              }).toList();
              UserActivity aCopy = a;
              aCopy.comments = newComments;
              newActivity = aCopy;
            }
            return a;
          }).toList();
        });
        AppSnackBar.showSuccess("操作成功");
        final updatedActivity = newActivity;
        if (updatedActivity != null) {
          await widget.activityService
              .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
            updatedActivity,
            feedType: _feedType,
            pageNum: _currentPage,
          );
        }
      } else {
        AppSnackBar.showError("操作失败");
      }

      return success;
    } catch (e) {
      AppSnackBar.showError('操作失败: ${e.toString()}'); // 显示错误提示
      return false;
    }
  }

  // === 构建方法 ===
  @override
  Widget build(BuildContext context) {
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        return Scaffold(
          appBar: CustomAppBar(
            title: widget.title, // 设置应用栏标题
          ),
          body: SafeArea(
            child: _buildBody(), // 构建主体内容
          ),
        );
      },
    );
  }

  /// 构建界面的主体内容。
  Widget _buildBody() {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时显示登录提示
      return const LoginPromptWidget();
    }
    if (widget.userId != widget.authProvider.currentUserId) {
      // 用户 ID 不匹配时显示错误
      return CustomErrorWidget(
        errorMessage: "不要偷窥其他人的动态啊？？",
        retryText: "返回上一页",
        onRetry: () => NavigationUtils.pop(context), // 返回上一页
      );
    }
    // --- 1. 初始加载状态 ---
    if (_isLoading && _activities.isEmpty) {
      return const FadeInItem(
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    }

    // --- 2. 错误状态（仅当列表为空时）---
    if (_error.isNotEmpty && _activities.isEmpty) {
      return CustomErrorWidget(
        errorMessage: _error,
        onRetry: _refreshData, // 提供重试机制
      );
    }

    // --- 3. 主体内容布局 ---
    return Column(
      children: [
        // --- 顶部操作栏 ---
        _buildTopActionBar(),

        // --- 动态列表 ---
        Expanded(
          child: _buildCollapsibleActivities(), // 构建可折叠动态列表
        ),
      ],
    );
  }

  /// 构建可折叠动态列表。
  Widget _buildCollapsibleActivities() {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream, // 监听当前用户 Stream
      initialData: widget.authProvider.currentUser, // 初始当前用户数据
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data; // 获取当前用户数据
        if (_currentUserId != currentUser?.id) {
          // 用户 ID 变化时更新
          setState(() {
            _currentUserId = currentUser?.id;
          });
        }

        return CollapsibleActivityFeed(
          key: ValueKey(
              'my_feed_${widget.userId}_${_collapseMode.index}'), // 唯一键
          activities: _activities, // 动态列表
          inputStateService: widget.inputStateService, // 输入状态服务
          infoService: widget.infoService, // 用户信息 Provider
          followService: widget.followService, // 关注服务
          currentUser: currentUser, // 当前用户
          isLoading: _isLoading && _activities.isEmpty, // 加载状态
          isLoadingMore: _isLoadingMore, // 加载更多状态
          error: _error.isNotEmpty && _activities.isEmpty ? _error : '', // 错误消息
          collapseMode: _collapseMode, // 当前折叠模式
          useAlternatingLayout: _useAlternatingLayout, // 当前布局模式
          scrollController: _scrollController, // 滚动控制器
          onActivityTap: _navigateToActivityDetail, // 动态点击回调
          onRefresh: _refreshData, // 刷新回调
          onLoadMore: _loadMoreActivities, // 加载更多回调
          onDeleteActivity: _handleDeleteActivity, // 删除动态回调
          onLikeActivity: (activityId) =>
              _handleToggleLikeActivity(activityId, action: true), // 点赞活动回调
          onUnlikeActivity: (activityId) =>
              _handleToggleLikeActivity(activityId, action: false), // 取消点赞活动回调
          onAddComment: _handleAddComment, // 添加评论回调
          onDeleteComment: _handleDeleteComment, // 删除评论回调
          onLikeComment: (activityId, commentId) => _handleToggleLikeComment(
              activityId, commentId,
              action: true), // 点赞评论回调
          onUnlikeComment: (activityId, commentId) => _handleToggleLikeComment(
              activityId, commentId,
              action: false), // 取消点赞评论回调
          onEditActivity: null,
        );
      },
    );
  }

  /// 构建顶部操作栏。
  Widget _buildTopActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // 折叠模式切换按钮
          Expanded(
            child: InkWell(
              onTap: _toggleCollapseMode, // 点击切换折叠模式
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withSafeOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primaryContainer)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        ActivityTypeUtils.getCollapseModeIcon(
                            _collapseMode), // 获取折叠模式图标
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                        ActivityTypeUtils.getCollapseModeText(
                            _collapseMode), // 获取折叠模式文本
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

          // 刷新按钮
          IconButton(
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0)
                  .animate(_refreshAnimationController), // 刷新动画
              child: const Icon(Icons.refresh_outlined),
            ),
            tooltip: '刷新',
            onPressed: (_isLoading || _isLoadingMore)
                ? null
                : _handleRefreshButtonPress, // 禁用按钮
            splashRadius: 20,
          ),

          // 布局切换按钮
          IconButton(
            icon: Icon(_useAlternatingLayout
                ? Icons.view_stream_outlined
                : Icons.view_agenda_outlined), // 布局模式图标
            tooltip: _useAlternatingLayout ? '切换标准布局' : '切换气泡布局',
            onPressed: _toggleLayoutMode, // 点击切换布局模式
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
