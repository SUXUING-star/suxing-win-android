// lib/screens/activity/activity_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:hive/hive.dart'; // For cache watching (optional but kept)
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/activity/panel/hot_activities_panel.dart';
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ActivityFeedScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final UserActivityService activityService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final String title;
  final bool useAlternatingLayout;
  final bool showHotActivities;

  const ActivityFeedScreen({
    super.key,
    required this.authProvider,
    required this.activityService,
    required this.followService,
    required this.infoProvider,
    required this.inputStateService,
    this.title = '动态广场', // Default title for this screen
    this.useAlternatingLayout = true,
    this.showHotActivities = true, // Usually show hot panel on public feed
  });

  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // UI Controllers
  final ScrollController _scrollController = ScrollController();
  late AnimationController _refreshAnimationController;

  // UI Mode State
  bool _useAlternatingLayout = true;
  bool _showHotActivities = true;
  FeedCollapseMode _collapseMode = FeedCollapseMode.none;

  // Data State
  List<UserActivity> _activities = [];
  PaginationData? _pagination;
  String _error = '';
  int _currentPage = 1;

  // Loading & Visibility State
  bool _isInitialized = false;

  bool _isVisible = false;
  bool _isLoadingData = false; // For initial load or full refresh
  bool _isLoadingMore = false; // For pagination loading
  bool _needsRefresh = false; // Flag to refresh when app resumes

  // Cache Watching State (Optional feature)
  StreamSubscription<BoxEvent>? _cacheSubscription;
  String _currentWatchIdentifier = '';
  Timer? _refreshDebounceTimer;

  // UI Refresh Control
  DateTime? _lastRefreshTime;
  final Duration _minUiRefreshInterval = const Duration(seconds: 15);

  bool _hasInitializedDependencies = false;
  late final UserActivityService _activityService;
  late final AuthProvider _authProvider;
  late final UserFollowService _followService;
  late final UserInfoProvider _infoProvider;
  late final InputStateService _inputStateService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _useAlternatingLayout = widget.useAlternatingLayout;
    _showHotActivities = widget.showHotActivities;

    // Initialize controllers and listeners
    _refreshAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _activityService = widget.activityService;
      _authProvider = widget.authProvider;
      _followService = widget.followService;
      _infoProvider = widget.infoProvider;
      _inputStateService = widget.inputStateService;

      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUserId = _authProvider.currentUserId;
    }
  }

  @override
  void dispose() {
    // Clean up listeners and controllers
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchingCache();
    _refreshDebounceTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ActivityFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != _authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = _authProvider.currentUserId;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (e.g., refresh on resume)

    if (state == AppLifecycleState.resumed) {
      if (_currentUserId != _authProvider.currentUserId) {
        _needsRefresh = true;

        if (mounted) {
          setState(() {
            _currentUserId = _authProvider.currentUserId;
          });
        }
      }

      if (_isVisible && _needsRefresh) {
        _refreshCurrentPageData(reason: "App Resumed with NeedsRefresh");
        _needsRefresh = false;
      } else if (_isVisible) {
        // Check if refresh is needed even if not explicitly flagged
        _refreshCurrentPageData(reason: "App Resumed and Visible Check");
      }
    }
  }

  // --- Cache Watching Logic ---
  void _startOrUpdateWatchingCache() {
    // This screen always represents the public feed
    const String feedTypeStr = 'public';
    // Identifier includes feed type and current page
    final String newWatchIdentifier =
        "${feedTypeStr}_p${_currentPage}_l20"; // Assuming limit 20

    // Avoid restarting if already watching the same target
    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      return;
    }

    _stopWatchingCache(); // Stop previous watcher
    _currentWatchIdentifier = newWatchIdentifier; // Update identifier

    try {
      _cacheSubscription = _activityService
          .watchActivityFeedChanges(
        feedType: feedTypeStr, // Always 'public'
        page: _currentPage,
        limit: 20,
      )
          .listen(
        (BoxEvent event) {
          // Refresh only if an item is deleted (to update the list)
          if (event.deleted) {
            if (_isVisible) {
              // Refresh immediately if visible
              _refreshCurrentPageData(reason: "Cache Deleted Event");
            } else {
              // Mark for refresh when it becomes visible again
              _needsRefresh = true;
            }
          } // Ignore write/update events for now
        },
        onError: (error, stackTrace) {
          _stopWatchingCache(); // Stop on error
          _currentWatchIdentifier = ''; // Reset identifier
        },
        onDone: () {
          // Clear identifier if the watched stream closes naturally
          if (_currentWatchIdentifier == newWatchIdentifier) {
            _currentWatchIdentifier = '';
          }
        },
        cancelOnError: true, // Automatically cancel on error
      );
    } catch (e) {
      // Failed to start watcher
      _currentWatchIdentifier = '';
    }
  }

  void _stopWatchingCache() {
    _cacheSubscription?.cancel();
    _cacheSubscription = null;
    // Keep _currentWatchIdentifier for comparison in next start attempt
  }

  /// Refreshes the data for the current page with debouncing/throttling.
  void _refreshCurrentPageData({required String reason}) {
    // Avoid refreshing if already loading or not mounted
    if (_isLoadingData || _isLoadingMore || !mounted) return;

    // Throttle frequent refresh requests
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      return;
    }

    // Debounce the actual refresh call
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Check again if still mounted and not loading before refreshing
      if (mounted && !_isLoadingData && !_isLoadingMore) {
        // Load the *current* page again, marking it as a refresh
        _loadActivities(isRefresh: true, pageToLoad: _currentPage);
      } else if (mounted) {
        // If conditions changed during debounce, mark for later refresh
        _needsRefresh = true;
      }
    });
  }

  // --- Data Loading Logic ---
  /// Called by VisibilityDetector when the widget becomes visible.
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && !_isLoadingData) {
      _isInitialized = true; // Mark as initialized
      _loadActivities(
          isInitialLoad: true, pageToLoad: 1); // Load the first page
    }
  }

  /// Fetches activities (always public feed for this screen).
  Future<void> _loadActivities(
      {bool isInitialLoad = false,
      bool isRefresh = false,
      bool forceRefresh = false,
      int pageToLoad = 1}) async {
    // Prevent concurrent loads unless it's a refresh interrupting idle state
    if (_isLoadingData && !isRefresh) return;
    // Prevent refresh from interrupting pagination load
    if (_isLoadingMore && isRefresh) return;
    if (!mounted) return; // Check if widget is still in the tree

    // Update cache watch target if the page is changing
    const String feedTypeStr = 'public';
    final String newWatchIdentifier = "${feedTypeStr}_p${pageToLoad}_l20";
    if (_currentWatchIdentifier != newWatchIdentifier) {
      _stopWatchingCache();
    }

    // Set loading state and clear errors
    setState(() {
      _isLoadingData = true;
      _error = '';
      // Reset state if it's a refresh or initial load
      if (isRefresh || isInitialLoad) {
        _currentPage = pageToLoad;
        // Clear activities only on initial load or if list was empty before refresh
        if (isInitialLoad || _activities.isEmpty) {
          _activities = [];
        }
        _pagination = null;
      }
    });
    // Start refresh animation only for page 1 refreshes
    if (isRefresh && pageToLoad == 1) {
      _refreshAnimationController.forward(from: 0.0);
    }

    try {
      const int limit = 20; // Define page size

      // Always fetch the public activity feed
      final result = await _activityService.getPublicActivities(
          page: pageToLoad, limit: limit, forceRefresh: forceRefresh);

      if (!mounted) return; // Check mount status after async operation

      // Process the result
      final List<UserActivity> fetchedActivities = result['activities'] ?? [];
      final PaginationData? fetchedPagination = result['pagination'];

      // Check if the response structure is valid (e.g., pagination exists)
      if (fetchedPagination != null) {
        setState(() {
          // Replace data if refreshing, initial load, or loading a different page than current
          if (isRefresh || isInitialLoad || pageToLoad != _currentPage) {
            _activities = fetchedActivities;
          }
          _pagination = fetchedPagination;
          _currentPage = pageToLoad; // Update current page
          _isLoadingData = false; // Reset loading state
          _error = ''; // Clear error
          _lastRefreshTime = DateTime.now(); // Record success time
        });
        _startOrUpdateWatchingCache(); // Start/update cache watcher
      } else {
        // Handle cases where the response format is unexpected
        throw Exception("Invalid response format from server");
      }
    } catch (e) {
      if (!mounted) return;
      // Handle errors
      setState(() {
        // Show full screen error only if there's no data to display
        if (_activities.isEmpty) {
          _error = '加载动态失败: $e';
        } else {
          // Otherwise, show a snackbar for refresh errors
          AppSnackBar.showError(context, '刷新动态失败: $e');
        }
        _isLoadingData = false; // Reset loading state
      });
      _stopWatchingCache(); // Stop watcher on error
    } finally {
      // Ensure loading state is always reset
      if (mounted && _isLoadingData) {
        setState(() => _isLoadingData = false);
      }
      // Ensure animation is reset
      if (mounted) {
        _refreshAnimationController.reset();
      }
    }
  }

  /// Handles the pull-to-refresh gesture.
  Future<void> _refreshData({bool forceRefresh = false}) async {
    // Avoid concurrent refreshes
    if (_isLoadingData || _isLoadingMore) return;

    // Throttle pull-to-refresh
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      await Future.delayed(
          const Duration(milliseconds: 300)); // Brief delay for visual feedback
      return;
    }

    _stopWatchingCache(); // Stop watching during manual refresh
    setState(() {
      _currentPage = 1; // Reset to first page
      _error = ''; // Clear error
    });
    // Fetch page 1 with the refresh flag
    await _loadActivities(
        isRefresh: true, pageToLoad: 1, forceRefresh: forceRefresh);
  }

  /// Handles the press of the dedicated refresh button.
  void _handleRefreshButtonPress() {
    // Avoid concurrent refreshes
    if (_isLoadingData || _isLoadingMore || !mounted) return;

    // Throttle button presses
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      return;
    }

    // Debounce the refresh action
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isLoadingData && !_isLoadingMore) {
        _refreshData(forceRefresh: true); // Call the main refresh logic
      }
    });
  }

  /// Loads the next page of activities for pagination.
  Future<void> _loadMoreActivities() async {
    // Check conditions before loading more
    if (!_isInitialized ||
        _error.isNotEmpty ||
        _isLoadingData ||
        _isLoadingMore ||
        _pagination == null ||
        _currentPage >= _pagination!.pages) {
      return;
    }
    if (!mounted) return;

    final nextPage = _currentPage + 1; // Calculate next page number
    _stopWatchingCache(); // Stop watching current page
    setState(() => _isLoadingMore = true); // Set loading more state

    try {
      const int limit = 20;

      // Always fetch the public activity feed for the next page
      final result = await _activityService.getPublicActivities(
          page: nextPage, limit: limit);

      if (!mounted) return;

      // Process results
      final List<UserActivity> newActivities = result['activities'] ?? [];
      final PaginationData? newPagination = result['pagination'];

      setState(() {
        _activities.addAll(newActivities); // Append new data
        _pagination = newPagination; // Update pagination info
        _currentPage = nextPage; // Update current page number
        _isLoadingMore = false; // Reset loading more state
        _lastRefreshTime =
            DateTime.now(); // Consider load more a type of refresh
      });
      _startOrUpdateWatchingCache(); // Start watching the new (current) page
    } catch (e) {
      // Handle errors during load more
      if (mounted) {
        AppSnackBar.showError(context, '加载更多失败: $e');
        setState(() => _isLoadingMore = false); // Reset loading state
      }
      // Attempt to restart watcher on the previous page after error
      _startOrUpdateWatchingCache();
    } finally {
      // Ensure loading state is always reset
      if (mounted && _isLoadingMore) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  // --- Helper Methods & UI Toggles ---
  /// Listens to scroll position to trigger loading more.
  void _scrollListener() {
    // Check conditions for loading more
    if (_isInitialized &&
        !_isLoadingMore &&
        !_isLoadingData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        _pagination != null &&
        _currentPage < _pagination!.pages) {
      _loadMoreActivities();
    }
  }

  /// Toggles the layout mode between alternating and standard.
  void _toggleLayoutMode() {
    HapticFeedback.lightImpact(); // Provide tactile feedback
    setState(() => _useAlternatingLayout = !_useAlternatingLayout);
  }

  /// Toggles the visibility of the hot activities panel.
  void _toggleHotActivitiesPanel() {
    HapticFeedback.lightImpact();
    setState(() => _showHotActivities = !_showHotActivities);
  }

  /// Cycles through the available collapse modes.
  void _toggleCollapseMode() {
    HapticFeedback.lightImpact();
    // Cycle through all available FeedCollapseMode values
    setState(() => _collapseMode = FeedCollapseMode
        .values[(_collapseMode.index + 1) % FeedCollapseMode.values.length]);
  }

  /// Gets the display text for the current collapse mode.
  String _getCollapseModeText() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return '标准视图';
      case FeedCollapseMode.byUser:
        return '按用户折叠'; // Keep this for public feeds
      case FeedCollapseMode.byType:
        return '按类型折叠';
    }
  }

  /// Gets the icon for the current collapse mode.
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

  /// Navigates to the detail screen for a specific activity.
  void _navigateToActivityDetail(UserActivity activity) {
    _stopWatchingCache(); // Pause watching while navigating away
    NavigationUtils.pushNamed(context, AppRoutes.activityDetail,
        arguments: {'activityId': activity.id, 'activity': activity}).then((_) {
      // When returning from the detail screen
      if (mounted) {
        _startOrUpdateWatchingCache(); // Resume watching
        // Refresh the current page in case data changed (e.g., like count)
        _refreshCurrentPageData(reason: "Returned from Detail");
      }
    });
  }

  bool _checkCanEditOrCanDelete(UserActivity activity) {
    final bool isAuthor = activity.userId == _authProvider.currentUserId;
    final bool isAdmin = _authProvider.isAdmin;
    final canEditOrDelete = isAdmin ? true : isAuthor;
    return canEditOrDelete;
  }

  /// Handles deleting an activity after user confirmation.
  Future<void> _handleDeleteActivity(UserActivity activity) async {
    final activityId = activity.id;
    if (!_authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    if (!_checkCanEditOrCanDelete(activity)) {
      AppSnackBar.showError(context, "你没有权限删除活动");
      return;
    }
    await CustomConfirmDialog.show(
      context: context,
      title: "确认删除",
      message: "确定删除这条动态吗？此操作无法撤销。",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever_outlined,
      // More prominent icon
      iconColor: Colors.red,
      onConfirm: () async {
        try {
          final success = await _activityService.deleteActivity(activity);
          if (success && mounted) {
            AppSnackBar.showSuccess(context, '动态已删除');
            // Optimistically remove the item from the UI
            setState(() {
              final initialTotal = _pagination?.total ?? _activities.length;
              _activities.removeWhere((act) => act.id == activityId);
              // Adjust pagination total if available
              if (_pagination != null && initialTotal > 0) {
                _pagination = _pagination!.copyWith(total: initialTotal - 1);
              }
            });
            // If the current page became empty after deletion, refresh
            if (_activities.isEmpty && _currentPage > 1) {
              _refreshCurrentPageData(reason: "Deleted last item on page");
            }
          } else if (mounted) {
            // Handle cases where the service reports failure
            throw Exception("服务未能成功删除动态");
          }
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除失败: $e');
          rethrow; // Let the dialog know about the error
        }
      },
    );
  }

  /// Handles liking an activity.
  Future<void> _handleLikeActivity(String activityId) async {
    if (!_authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    try {
      await _activityService.likeActivity(activityId);
      // Success: If optimistic update wasn't perfect, could force refresh item here.
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '点赞失败: $e');
      // Failure: Trigger rollback of optimistic UI change in ActivityCard.
    }
  }

  /// Handles unliking an activity.
  Future<void> _handleUnlikeActivity(String activityId) async {
    if (!_authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    try {
      await _activityService.unlikeActivity(activityId);
      // Success: Potentially update state if needed.
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '取消点赞失败: $e');
      // Failure: Trigger rollback in ActivityCard.
    }
  }

  /// Handles adding a comment to an activity.
  Future<ActivityComment?> _handleAddComment(
      String activityId, String content) async {
    if (!_authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      throw Exception("你没有登录");
    }
    try {
      final comment =
          await _activityService.commentOnActivity(activityId, content);
      if (comment != null && mounted) {
        AppSnackBar.showSuccess(context, '评论成功');
        return comment;
      } else if (mounted) {
        // Handle cases where comment object is unexpectedly null
        throw Exception("服务器未能返回评论数据");
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '评论失败: $e');
    }
    return null; // Return null indicates failure
  }

  bool _checkCanDeleteComment(ActivityComment comment) {
    final bool isAuthor = comment.userId == _authProvider.currentUserId;
    final bool isAdmin = _authProvider.isAdmin;
    return isAdmin ? true : isAuthor;
  }

  /// Handles deleting a comment after user confirmation.
  Future<void> _handleDeleteComment(
      String activityId, ActivityComment comment) async {
    if (!_authProvider.isLoggedIn) {
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
              await _activityService.deleteComment(activityId, comment);
          if (success && mounted) {
            AppSnackBar.showSuccess(context, '评论已删除');
          } else if (mounted) {
            throw Exception("未能成功删除评论");
          }
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除评论失败: $e');
          rethrow; // Let dialog know about failure
        }
      },
    );
  }

  /// Handles liking a comment.
  Future<void> _handleLikeComment(String activityId, String commentId) async {
    if (!_authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await _activityService.likeComment(activityId, commentId);
      // Success
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '点赞评论失败: $e');
      // Failure: Trigger rollback in Comment widget.
    }
  }

  /// Handles unliking a comment.
  Future<void> _handleUnlikeComment(String activityId, String commentId) async {
    if (!_authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    try {
      await _activityService.unlikeComment(activityId, commentId);
      // Success
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '取消点赞评论失败: $e');
      // Failure: Trigger rollback in Comment widget.
    }
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    final bool currentlyVisible =
        info.visibleFraction > 0.8; // Consider visible if mostly on screen
    if (currentlyVisible != _isVisible) {
      if (_currentUserId != _authProvider.currentUserId) {
        _currentUserId = _authProvider.currentUserId;
        _needsRefresh = true;
        if (mounted) {
          setState(() {});
        }
      }

      // Check if visibility state changed
      final bool wasVisible = _isVisible; // Store previous state
      _isVisible = currentlyVisible; // Update current state
      // Trigger actions based on visibility change
      if (_isVisible) {
        _triggerInitialLoad(); // Attempt initial load if becoming visible
        _startOrUpdateWatchingCache(); // Start watching when visible
        // If it just became visible, check if a refresh is needed
        if (!wasVisible) _refreshCurrentPageData(reason: "Became Visible");
      } else {
        _stopWatchingCache(); // Stop watching when not visible to save resources
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // VisibilityDetector wraps the main Scaffold to control loading and watchers
    return VisibilityDetector(
      key: Key(
          'activity_feed_visibility_${widget.key?.toString() ?? widget.title}'),
      onVisibilityChanged: _handleVisibilityChange,
      child: Scaffold(
        // AppBar might be handled globally, or add one here if needed for this specific screen
        // appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          // Ensure content respects device safe areas
          child: _buildBodyContent(), // Build the main content
        ),
      ),
    );
  }

  /// Builds the main content area (action bar + feed/panel).
  Widget _buildBodyContent() {
    // State 1: Waiting for initial load (before VisibilityDetector triggers)
    if (!_isInitialized && !_isLoadingData) {
      return LoadingWidget.fullScreen(message: "准备加载动态...");
    }

    // State 2: Initial data load is in progress
    if (_isLoadingData && _activities.isEmpty) {
      return LoadingWidget.fullScreen(message: "正在加载动态...");
    }

    // State 3: Error occurred and no data is available to show
    if (_error.isNotEmpty && _activities.isEmpty) {
      return CustomErrorWidget(
          errorMessage: _error,
          // Provide a way to retry the initial load
          onRetry: () => _loadActivities(isRefresh: true, pageToLoad: 1));
    }

    // State 4: Build the main UI (action bar + responsive feed/panel)
    Widget topActionBar = _buildTopActionBar(); // Build the controls bar
    Widget mainFeedContent = _buildMainFeedContent(); // Build the feed itself

    // Use LayoutBuilder for responsive design (show hot panel on wide screens)
    return LayoutBuilder(
      builder: (context, constraints) {
        const double desktopBreakpoint = 720.0; // Define width threshold

        // Wide screen layout: Feed + Hot Panel (if enabled)
        if (constraints.maxWidth >= desktopBreakpoint &&
            widget.showHotActivities) {
          return Column(
            children: [
              topActionBar, // Show controls at the top
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Align items to top
                  children: [
                    // Main Feed area
                    Expanded(
                      flex: 3, // Feed takes more space
                      child: mainFeedContent,
                    ),
                    // Vertical divider between feed and panel
                    VerticalDivider(
                        width: 1,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                        color: Colors.grey.shade200),
                    // Hot Activities Panel area (conditional)
                    if (_showHotActivities) // Only build if toggled on
                      SizedBox(
                        width: 300, // Fixed width for the side panel
                        child: Padding(
                          // Add padding for visual spacing
                          padding: const EdgeInsets.only(
                              top: 8.0, right: 8.0, bottom: 8.0),
                          child: HotActivitiesPanel(
                            activityService: _activityService,
                            userInfoProvider: _infoProvider,
                            followService: _followService,
                            currentUser: _authProvider.currentUser,
                          ), // The hot activities widget
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }
        // Narrow screen layout (or wide screen if hot panel is disabled)
        else {
          return Column(
            children: [
              topActionBar,
              // Show controls at the top
              Expanded(child: mainFeedContent),
              // Feed takes all remaining space
              // Hot panel is not rendered here
            ],
          );
        }
      },
    );
  }

  /// Builds the CollapsibleActivityFeed widget.
  Widget _buildMainFeedContent() {
    return CollapsibleActivityFeed(
      // Use a key that changes only when necessary (e.g., collapse mode)
      key: ValueKey('public_feed_${_collapseMode.index}'),
      currentUser: _authProvider.currentUser,
      followService: _followService,
      inputStateService: _inputStateService,
      infoProvider: _infoProvider,
      activities: _activities,
      isLoading: _isLoadingData && _activities.isEmpty,
      isLoadingMore: _isLoadingMore,
      error: _error.isNotEmpty && _activities.isEmpty ? _error : '',
      collapseMode: _collapseMode,
      useAlternatingLayout: _useAlternatingLayout,
      scrollController: _scrollController,
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
      onEditActivity: null, // Edit function not implemented
    );
  }

  /// Builds the top action bar with view controls.
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
                    // Use theme colors for better adaptability
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
                    Icon(_getCollapseModeIcon(),
                        size: 18, // Slightly smaller icon
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(_getCollapseModeText(),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500, // Medium weight
                          fontSize: 13, // Slightly smaller text
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
              // Apply rotation animation
              turns: Tween(begin: 0.0, end: 1.0)
                  .animate(_refreshAnimationController),
              child: const Icon(Icons.refresh_outlined), // Use outlined icon
            ),
            tooltip: '刷新',
            // Disable when loading
            onPressed: (_isLoadingData || _isLoadingMore)
                ? null
                : _handleRefreshButtonPress,
            splashRadius: 20, // Smaller splash radius
          ),

          // Layout Toggle Button
          IconButton(
            icon: Icon(_useAlternatingLayout
                ? Icons.view_stream_outlined // Icon when alternating
                : Icons.view_agenda_outlined), // Icon when standard
            tooltip: _useAlternatingLayout ? '切换标准布局' : '切换气泡布局',
            onPressed: _toggleLayoutMode,
            splashRadius: 20,
          ),

          // Hot Activities Panel Toggle Button (Conditional)
          if (widget.showHotActivities) // Only show if widget allows it
            IconButton(
              icon: Icon(_showHotActivities
                  ? Icons.visibility_off_outlined // Icon to hide
                  : Icons.local_fire_department_outlined), // Icon to show
              onPressed: _toggleHotActivitiesPanel,
              tooltip: _showHotActivities ? '隐藏热门' : '显示热门',
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}
