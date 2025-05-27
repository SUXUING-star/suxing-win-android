// lib/screens/activity/my_activity_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class MyActivityFeedScreen extends StatefulWidget {
  final String userId; // 必须提供用户ID
  final String title; // 屏幕标题
  final AuthProvider authProvider;
  final ActivityService activityService;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final UserInfoProvider infoProvider;

  const MyActivityFeedScreen({
    super.key,
    required this.userId,
    required this.authProvider,
    required this.activityService,
    required this.followService,
    required this.inputStateService,
    required this.infoProvider,
    this.title = 'TA的动态', // 默认标题可以改得通用些
  });

  @override
  _MyActivityFeedScreenState createState() => _MyActivityFeedScreenState();
}

class _MyActivityFeedScreenState extends State<MyActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  // --- UI Controllers ---
  final ScrollController _scrollController = ScrollController();
  late AnimationController _refreshAnimationController;

  // --- Data State ---
  List<UserActivity> _activities = [];
  PaginationData? _pagination;
  int _currentPage = 1;

  // --- Loading & Error State ---
  bool _isLoading = false; // For initial load or refresh
  bool _isLoadingMore = false; // For pagination
  String _error = ''; // Error message

  // --- UI Mode State ---
  FeedCollapseMode _collapseMode =
      FeedCollapseMode.none; // Default: Standard view
  bool _useAlternatingLayout = true; // Default: Alternating layout

  // --- Refresh Control ---
  DateTime? _lastRefreshTime;
  final Duration _minUiRefreshInterval =
      const Duration(seconds: 3); // Shorter interval for UI feedback
  Timer? _refreshDebounceTimer;
  bool _hasInitializedDependencies = false;
  bool _isInitialized = false;
  String? _currentUserId;

  // === Lifecycle Methods ===
  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scrollController
        .addListener(_scrollListener); // Add scroll listener for pagination
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies && !_isInitialized) {
      _fetchActivities(isInitialLoad: !_isInitialized); // Fetch data on init
      _currentUserId = widget.userId;
      _isInitialized = true;
    }
    if (_hasInitializedDependencies && _isInitialized) {
      if (_currentUserId != widget.userId) {
        _fetchActivities(isRefresh: true);
        _currentUserId = widget.userId;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshAnimationController.dispose();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  // === Data Fetching Logic ===

  /// Fetches activities for the current page (initial load or refresh).
  Future<void> _fetchActivities(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return; // Prevent concurrent loads
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
      if (isRefresh || isInitialLoad) {
        _currentPage = 1;
        _pagination = null;
        if (isInitialLoad || _activities.isEmpty) {
          _activities = []; // Clear list only on initial load or if empty
        }
      }
    });
    if (isRefresh) {
      _refreshAnimationController.forward(from: 0.0); // Start refresh animation
    }

    try {
      // Fetch activities for the specific user, without type filtering
      final result = await widget.activityService.getUserActivities(
        widget.userId,
        page: _currentPage,
        limit: 20, // Standard page size
      );

      if (!mounted) return;

      final List<UserActivity> fetchedActivities = result.activities;
      final PaginationData fetchedPagination = result.pagination;

      setState(() {
        if (isRefresh || isInitialLoad) {
          _activities = fetchedActivities; // Replace data on refresh/initial
        }
        _pagination = fetchedPagination;
        _isLoading = false;
        _lastRefreshTime = DateTime.now(); // Record successful fetch time
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Show full screen error only if the list is empty
        if (_activities.isEmpty) {
          _error = '加载动态失败: $e';
        } else {
          // Otherwise, show snackbar for refresh errors
          AppSnackBar.showError(context, '刷新动态失败: $e');
        }
        _isLoading = false;
      });
    } finally {
      // Ensure loading state is reset and animation stops
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        _refreshAnimationController.reset();
      }
    }
  }

  /// Loads more activities when scrolling near the bottom.
  Future<void> _loadMoreActivities() async {
    // Check conditions to prevent unnecessary calls
    if (_isLoading || _isLoadingMore || !mounted) return;
    if (_pagination == null || _currentPage >= _pagination!.pages) return;

    final nextPage = _currentPage + 1;
    setState(() {
      _isLoadingMore = true; // Set loading more state
    });

    try {
      // Fetch next page of activities for the specific user
      final result = await widget.activityService.getUserActivities(
        widget.userId,
        page: nextPage,
        limit: 20,
      );

      if (!mounted) return;

      final List<UserActivity> newActivities = result.activities;
      final PaginationData newPagination = result.pagination;

      setState(() {
        _activities.addAll(newActivities); // Append new activities
        _pagination = newPagination; // Update pagination info
        _currentPage = nextPage; // Update current page number
        _isLoadingMore = false; // Reset loading more state
        _lastRefreshTime = DateTime.now(); // Also counts as a refresh
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '加载更多失败: $e'); // Show error in snackbar
        setState(() {
          _isLoadingMore = false; // Reset loading more state on error
        });
      }
    } finally {
      if (mounted && _isLoadingMore) {
        setState(() => _isLoadingMore = false); // Ensure reset
      }
    }
  }

  /// Scroll listener to trigger loading more activities.
  void _scrollListener() {
    if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent *
                    0.9 && // Near bottom
            !_isLoadingMore && // Not already loading more
            !_isLoading && // Not during initial/refresh load
            _pagination != null &&
            _currentPage < _pagination!.pages // Has next page
        ) {
      _loadMoreActivities();
    }
  }

  /// Handles pull-to-refresh action.
  Future<void> _refreshData() async {
    if (_isLoading || _isLoadingMore) return; // Prevent concurrent refresh
    final now = DateTime.now();
    // Simple throttling for pull-to-refresh
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      await Future.delayed(
          const Duration(milliseconds: 300)); // Visual feedback delay
      return;
    }
    setState(() {
      _currentPage = 1; // Reset to page 1
      _error = ''; // Clear previous errors
    });
    await _fetchActivities(isRefresh: true); // Fetch data with refresh flag
  }

  /// Handles refresh button press with debouncing/throttling.
  void _handleRefreshButtonPress() {
    if (_isLoading || _isLoadingMore || !mounted) return;
    final now = DateTime.now();
    // Throttle button presses
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      return;
    }
    _refreshDebounceTimer?.cancel(); // Cancel previous debounce timer
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isLoading && !_isLoadingMore) {
        _refreshData(); // Execute refresh after debounce
      }
    });
  }

  // === UI Mode Toggles ===

  /// Toggles between alternating and standard layout.
  void _toggleLayoutMode() {
    HapticFeedback.lightImpact(); // Provide feedback
    setState(() => _useAlternatingLayout = !_useAlternatingLayout);
  }

  /// Toggles between standard view and collapse-by-type view.
  void _toggleCollapseMode() {
    HapticFeedback.lightImpact();
    setState(() {
      // Only cycle between 'none' and 'byType'
      if (_collapseMode == FeedCollapseMode.none) {
        _collapseMode = FeedCollapseMode.byType;
      } else {
        _collapseMode = FeedCollapseMode.none; // If byType, switch back to none
      }
    });
  }

  /// Gets the display text for the current collapse mode.
  String _getCollapseModeText() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return '标准视图';
      case FeedCollapseMode.byType:
        return '按类型折叠';
      default:
        return '标准视图'; // Fallback
    }
  }

  /// Gets the icon for the current collapse mode.
  IconData _getCollapseModeIcon() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return Icons.view_agenda_outlined; // Use outlined icons for consistency
      case FeedCollapseMode.byType:
        return Icons.category_outlined;
      default:
        return Icons.view_agenda_outlined; // Fallback
    }
  }

  // === Navigation ===

  /// Navigates to the activity detail screen.
  void _navigateToActivityDetail(UserActivity activity) {
    NavigationUtils.pushNamed(
      context,
      AppRoutes.activityDetail,
      arguments: {
        'activityId': activity.id,
        'activity': activity,
      },
    ).then((result) {
      // Optional: Refresh if something might have changed on the detail screen
      if (mounted && result == true) {
        // Example: if detail screen returns true on change
        _refreshData();
      }
    });
  }

  bool _checkCanEditOrCanDelete(UserActivity activity) {
    final bool isAuthor = activity.userId == widget.authProvider.currentUserId;
    final bool isAdmin = widget.authProvider.isAdmin;
    final canEditOrDelete = isAdmin ? true : isAuthor;
    return canEditOrDelete;
  }

  // === Interaction Callbacks (Passed to CollapsibleActivityFeed) ===

  /// Handles deleting an activity after confirmation.
  Future<void> _handleDeleteActivity(UserActivity activity) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    if (!_checkCanEditOrCanDelete(activity)) {
      if (mounted) {
        AppSnackBar.showError(context, '您没有权限删除此动态');
      }
      return;
    }
    final activityId = activity.id;

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
          final success = await widget.activityService.deleteActivity(activity);
          if (success && mounted) {
            AppSnackBar.showSuccess(context, '动态已删除');
            // Optimistically remove from list and update pagination
            setState(() {
              final initialTotal = _pagination?.total ?? _activities.length;
              _activities.removeWhere((act) => act.id == activityId);
              if (_pagination != null && initialTotal > 0) {
                _pagination = _pagination!.copyWith(total: initialTotal - 1);
                // Optional: Re-calculate pages in copyWith if needed
              }
            });
            // Optional: Refresh if the current page becomes empty
            if (_activities.isEmpty && _currentPage > 1) {
              _refreshData();
            }
          } else if (mounted) {
            throw Exception("删除失败，请重试");
          }
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除失败: $e');
          rethrow; // Propagate error to dialog
        }
      },
    );
  }

  /// Handles liking an activity.
  Future<void> _handleLikeActivity(String activityId) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await widget.activityService.likeActivity(activityId);
      // Optional: If service doesn't return updated activity, you might need
      // to manually update the state here or trigger a refresh for the specific item.
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '点赞失败: $e');
      // Trigger UI rollback in ActivityCard if optimistic update was done.
    }
  }

  /// Handles unliking an activity.
  Future<void> _handleUnlikeActivity(String activityId) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    try {
      await widget.activityService.unlikeActivity(activityId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '取消点赞失败: $e');
      // Trigger UI rollback.
    }
  }

  /// Handles adding a comment to an activity.
  Future<ActivityComment?> _handleAddComment(
      String activityId, String content) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      throw Exception("你没登录");
    }
    try {
      final comment =
          await widget.activityService.commentOnActivity(activityId, content);
      if (comment != null && mounted) {
        AppSnackBar.showSuccess(context, '评论成功');
        // The new comment object is returned. The ActivityCard should handle
        // adding this comment to its internal state/display.
        return comment;
      } else if (mounted) {
        throw Exception("未能添加评论");
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '评论失败: $e');
    }
    return null; // Return null on failure
  }

  bool _checkCanDeleteComment(ActivityComment comment) {
    final bool isAuthor = comment.userId == widget.authProvider.currentUserId;
    final bool isAdmin = widget.authProvider.isAdmin;
    return isAdmin ? true : isAuthor;
  }

  /// Handles deleting a comment after confirmation.
  Future<void> _handleDeleteComment(
      String activityId, ActivityComment comment) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    if (!_checkCanDeleteComment(comment)) {
      if (mounted) {
        AppSnackBar.showError(context, "你没有权限删除这条评论");
      }
      return;
    }

    await CustomConfirmDialog.show(
      context: context,
      title: "确认删除",
      message: "确定删除这条评论吗？",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_outline,
      iconColor: Colors.red,
      onConfirm: () async {
        try {
          final success =
              await widget.activityService.deleteComment(activityId, comment);
          if (success && mounted) {
            AppSnackBar.showSuccess(context, '评论已删除');
          } else if (mounted) {
            throw Exception("删除评论失败");
          }
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除评论失败: $e');
          rethrow;
        }
      },
    );
  }

  /// Handles liking a comment.
  Future<void> _handleLikeComment(String activityId, String commentId) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await widget.activityService.likeComment(activityId, commentId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '点赞评论失败: $e');
      // Trigger rollback in Comment widget.
    }
  }

  /// Handles unliking a comment.
  Future<void> _handleUnlikeComment(String activityId, String commentId) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await widget.activityService.unlikeComment(activityId, commentId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '取消点赞评论失败: $e');
      // Trigger rollback in Comment widget.
    }
  }

  // === Build Method ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title, // Use the title passed to the widget
      ),
      body: SafeArea(
        // Ensure content is within safe area
        child: _buildBody(),
      ),
    );
  }

  /// Builds the main content of the screen.
  Widget _buildBody() {
    if (!widget.authProvider.isLoggedIn) {
      return const LoginPromptWidget();
    }
    if (widget.userId != widget.authProvider.currentUserId) {
      return CustomErrorWidget(
        errorMessage: "不要偷窥其他人的动态啊？？",
        retryText: "返回上一页",
        onRetry: () => NavigationUtils.pop(context),
      );
    }
    // --- 1. Initial Loading State ---
    if (_isLoading && _activities.isEmpty) {
      return LoadingWidget.fullScreen(message: "正在加载动态...");
    }

    // --- 2. Error State (only when list is empty) ---
    if (_error.isNotEmpty && _activities.isEmpty) {
      return CustomErrorWidget(
        errorMessage: _error,
        onRetry: _refreshData, // Provide retry mechanism
      );
    }

    // --- 3. Main Content Layout ---
    return Column(
      children: [
        // --- Top Action Bar ---
        _buildTopActionBar(),

        // --- Activity Feed ---
        Expanded(
          child: _buildCollapsibleActivities(),
        ),
      ],
    );
  }

  Widget _buildCollapsibleActivities() {
    return StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream,
        initialData: widget.authProvider.currentUser,
        builder: (context, currentUserSnapshot) {
          final User? currentUser = currentUserSnapshot.data;
          if (_currentUserId != currentUser?.id) {
            setState(() {
              _currentUserId = currentUser?.id;
            });
          }

          return CollapsibleActivityFeed(
            key: ValueKey('my_feed_${widget.userId}_${_collapseMode.index}'),
            activities: _activities,
            inputStateService: widget.inputStateService,
            infoProvider: widget.infoProvider,
            followService: widget.followService,
            currentUser: currentUser,
            isLoading: _isLoading && _activities.isEmpty,
            isLoadingMore: _isLoadingMore,
            error: _error.isNotEmpty && _activities.isEmpty ? _error : '',
            collapseMode: _collapseMode, // Current collapse mode
            useAlternatingLayout: _useAlternatingLayout, // Current layout mode
            scrollController: _scrollController, // Pass the scroll controller-
            onActivityTap: _navigateToActivityDetail,
            onRefresh: _refreshData,
            onLoadMore: _loadMoreActivities,
            onDeleteActivity: _handleDeleteActivity,
            onLikeActivity: _handleLikeActivity,
            onUnlikeActivity: _handleUnlikeActivity,
            onAddComment: _handleAddComment,
            onDeleteComment: _handleDeleteComment,
            onLikeComment: _handleLikeComment,
            onUnlikeComment: _handleUnlikeComment,
            onEditActivity: null, // Edit not implemented yet
          );
        });
  }

  /// Builds the action bar containing view controls.
  Widget _buildTopActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Collapse Mode Toggle Button
          Expanded(
            child: InkWell(
              onTap: _toggleCollapseMode,
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
                  mainAxisSize: MainAxisSize.min, // Fit content size
                  mainAxisAlignment: MainAxisAlignment.center, // Center content
                  children: [
                    Icon(_getCollapseModeIcon(),
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(_getCollapseModeText(),
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
          const SizedBox(width: 8), // Spacer

          // Refresh Button
          IconButton(
            icon: RotationTransition(
              // Add rotation animation wrapper
              turns: Tween(begin: 0.0, end: 1.0)
                  .animate(_refreshAnimationController),
              child: const Icon(Icons.refresh_outlined),
            ),
            tooltip: '刷新',
            // Disable button while loading
            onPressed: (_isLoading || _isLoadingMore)
                ? null
                : _handleRefreshButtonPress,
            splashRadius: 20,
          ),

          // Layout Toggle Button
          IconButton(
            icon: Icon(_useAlternatingLayout
                ? Icons.view_stream_outlined // Icon for alternating layout
                : Icons.view_agenda_outlined), // Icon for standard layout
            tooltip: _useAlternatingLayout ? '切换标准布局' : '切换气泡布局',
            onPressed: _toggleLayoutMode, // Toggle layout mode on press
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
