// lib/screens/admin/widgets/game_management.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/screens/game/list/common_game_list_screen.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';

class GameManagement extends StatefulWidget {
  final User? currentUser;
  final GameService gameService;
  final InputStateService inputStateService;
  final WindowStateProvider windowStateProvider;
  const GameManagement({
    super.key,
    required this.currentUser,
    required this.gameService,
    required this.inputStateService,
    required this.windowStateProvider,
  });

  @override
  State<GameManagement> createState() => _GameManagementState();
}

class _GameManagementState extends State<GameManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- 审核队列状态管理 (包含分页) ---
  List<Game> _reviewQueueGames = [];
  int _reviewQueueCurrentPage = 1;
  bool _reviewQueueHasMore = true;
  bool _isLoadingReviewQueue = true;
  bool _isLoadingMoreReviewQueue = false;
  String? _reviewQueueError;
  final ScrollController _pendingScrollController = ScrollController();
  final ScrollController _rejectedScrollController = ScrollController();

  bool _hasInitializedDependencies = false;
  User? _currentUser;

  // "All Games" Tab 的 Future (暂时保持不变)
  late Future<List<Game>> _allGamesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pendingScrollController.addListener(_onPendingScroll);
    _rejectedScrollController.addListener(_onRejectedScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _currentUser = widget.currentUser;
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadInitialReviewQueueData();
      _allGamesFuture = _loadAllGames();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingScrollController.removeListener(_onPendingScroll);
    _pendingScrollController.dispose();
    _rejectedScrollController.removeListener(_onRejectedScroll);
    _rejectedScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  // --- 数据加载 ---

  Future<void> _loadInitialReviewQueueData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviewQueue = true;
      _reviewQueueError = null;
      _reviewQueueCurrentPage = 1;
      _reviewQueueHasMore = true;
      _reviewQueueGames = [];
    });
    await _fetchReviewQueuePage(1);
    if (mounted) {
      setState(() {
        _isLoadingReviewQueue = false;
        if (_pendingScrollController.hasClients) {
          _pendingScrollController.jumpTo(0);
        }
        if (_rejectedScrollController.hasClients) {
          _rejectedScrollController.jumpTo(0);
        }
      });
    }
  }

  Future<void> _loadMoreReviewQueueData() async {
    if (!mounted ||
        _isLoadingReviewQueue ||
        _isLoadingMoreReviewQueue ||
        !_reviewQueueHasMore) {
      return;
    }
    setState(() {
      _isLoadingMoreReviewQueue = true;
    });
    final nextPage = _reviewQueueCurrentPage + 1;
    await _fetchReviewQueuePage(nextPage);
    if (mounted) {
      setState(() {
        _isLoadingMoreReviewQueue = false;
      });
    }
  }

  Future<void> _fetchReviewQueuePage(int page) async {
    try {
      final result = await widget.gameService.getAdminReviewQueueGamesWithInfo(
        page: page,
      );
      if (mounted) {
        final List<Game> newGames = result.games;
        final pagination = result.pagination;
        final int currentPage = pagination.page;
        final int totalItems = pagination.total;
        final int pageSize = pagination.limit;
        setState(() {
          if (page == 1) {
            _reviewQueueGames = newGames;
          } else {
            _reviewQueueGames.addAll(newGames);
          }
          _reviewQueueCurrentPage = currentPage;
          _reviewQueueHasMore = (currentPage * pageSize) < totalItems;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (page == 1) {
            _reviewQueueError = '加载审核队列失败: $e';
            _reviewQueueGames = [];
          } else {
            AppSnackBar.showError('加载更多失败: $e');
            _reviewQueueHasMore = false;
          }
        });
      }
    }
  }

  void _onPendingScroll() {
    if (_pendingScrollController.position.pixels >=
            _pendingScrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMoreReviewQueue &&
        _reviewQueueHasMore) {
      _loadMoreReviewQueueData();
    }
  }

  void _onRejectedScroll() {
    if (_rejectedScrollController.position.pixels >=
            _rejectedScrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMoreReviewQueue &&
        _reviewQueueHasMore) {
      _loadMoreReviewQueueData();
    }
  }

  Future<List<Game>> _loadAllGames() async {
    try {
      final result = await widget.gameService.getGamesPaginatedWithInfo(
        page: 1,
        sortBy: 'createTime',
        descending: true,
      );
      return result.games;
    } catch (e) {
      throw Exception('加载游戏管理列表失败: $e');
    }
  }

  Future<void> _refreshAllGames() async {
    if (!mounted) return;
    setState(() {
      _allGamesFuture = _loadAllGames();
    });
  }

  Future<void> _refreshReviewQueue() async {
    await _loadInitialReviewQueueData();
    if (mounted && _reviewQueueError == null) {
      AppSnackBar.showSuccess('审核队列已刷新');
    }
  }

  // === Actions (完整代码) ===

  Future<void> _handleDeleteGame(Game game, String gameTitle) async {
    await CustomConfirmDialog.show(
        context: context,
        title: '确认删除',
        message: '确定要删除游戏 "$gameTitle" 吗？此操作不可恢复！',
        confirmButtonText: '删除',
        confirmButtonColor: Colors.red,
        iconData: Icons.delete_forever,
        iconColor: Colors.red,
        onConfirm: () async {
          try {
            await widget.gameService.deleteGame(game);
            if (mounted) {
              AppSnackBar.showSuccess('游戏已删除');
              _refreshAllGames(); // 刷新 All Games
              _refreshReviewQueue(); // 刷新审核队列
            }
          } catch (e) {
            AppSnackBar.showError('删除失败: $e');
            rethrow; // 让 Dialog 知道出错了
          }
        });
  }

  Future<void> _handleEditGame(Game game) async {
    // 跳转到编辑页
    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game.id);
    // 如果编辑成功返回 true
    if (result == true && mounted) {
      AppSnackBar.showSuccess('游戏信息已更新');
      _refreshAllGames(); // 刷新 All Games
      _refreshReviewQueue(); // 刷新审核队列
    }
  }

  void _handleAddGame() {
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((added) {
      if (added == true && mounted) {
        AppSnackBar.showSuccess('游戏已添加');
        _refreshAllGames(); // 刷新 All Games (如果管理员添加直接 approved)
        _refreshReviewQueue(); // 刷新审核队列 (看到新提交的 pending)
      }
    });
  }

  Future<void> _handleReviewAction(Game game, bool approve) async {
    if (approve) {
      // --- Approve Case: Use CustomConfirmDialog directly ---
      await CustomConfirmDialog.show(
        context: context,
        title: '确认批准',
        message: '确定要批准游戏 "${game.title}" 吗？',
        confirmButtonText: '批准',
        confirmButtonColor: Colors.green,
        iconData: Icons.check_circle_outline,
        iconColor: Colors.green,
        onConfirm: () async {
          // Directly call the API helper which handles errors and refreshes
          await _reviewGameApiCall(game, 'approved', '');
        },
      );
    } else {
      // --- Reject Case: Use EditDialog first to get the reason ---
      await EditDialog.show(
        inputStateService: widget.inputStateService,
        context: context,
        title: '输入拒绝原因',
        initialText: '', // Start with empty text
        hintText: '请详细说明拒绝的原因...',
        saveButtonText: '下一步', // Button text for getting reason
        maxLines: 3,
        iconData: Icons.comment_outlined,
        onSave: (String reason) async {
          if (reason.trim().isEmpty) {
            AppSnackBar.showWarning('必须填写拒绝原因');
            return; // Stop further processing
          }
          // Got a valid reason, now show the FINAL confirmation dialog
          await CustomConfirmDialog.show(
            context: context, // Ensure correct context
            title: '确认拒绝',
            message: '确定要以原因 "${reason.trim()}" 拒绝游戏 "${game.title}" 吗？',
            confirmButtonText: '确认拒绝',
            confirmButtonColor: Colors.red,
            iconData: Icons.cancel_outlined,
            iconColor: Colors.red,
            onConfirm: () async {
              // When the *final* confirmation is pressed, call the API helper
              await _reviewGameApiCall(game, 'rejected', reason.trim());
            },
          );
        },
      );
    }
  }

  Future<void> _reviewGameApiCall(
      Game game, String status, String comment) async {
    try {
      await widget.gameService.reviewGame(game, status, comment);
      if (mounted) {
        AppSnackBar.showSuccess('游戏已${status == 'approved' ? '批准' : '拒绝'}');
        _refreshReviewQueue();
        if (status == 'approved') {
          _refreshAllGames();
        }
      }
    } catch (e) {
      AppSnackBar.showError('审核操作失败: $e');
      // 可选: rethrow 让 Dialog 知道失败了
    }
  }

  // === Build Methods ===
  @override
  Widget build(BuildContext context) {
    // --- 在 build 方法里过滤数据 ---
    final pendingGames = _reviewQueueGames
        .where((g) => g.approvalStatus == GameStatus.pending)
        .toList();
    final rejectedGames = _reviewQueueGames
        .where((g) => g.approvalStatus == GameStatus.rejected)
        .toList();

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '游戏管理'),
            Tab(
                text:
                    '待审核${_isLoadingReviewQueue && _reviewQueueGames.isEmpty ? "" : " (${pendingGames.length})"}'),
            Tab(
                text:
                    '被拒绝${_isLoadingReviewQueue && _reviewQueueGames.isEmpty ? "" : " (${rejectedGames.length})"}'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. All Games Tab (暂时保持 FutureBuilder)
              FutureBuilder<List<Game>>(
                  future: _allGamesFuture,
                  builder: (context, snapshot) {
                    return CommonGameListScreen(
                      title: '游戏管理',
                      useScaffold: false,
                      windowStateProvider: widget.windowStateProvider,
                      games: snapshot.hasData ? snapshot.data! : [],
                      currentUser: _currentUser,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                      error:
                          snapshot.hasError ? snapshot.error.toString() : null,
                      onRefreshTriggered: _refreshAllGames,
                      emptyStateMessage: '没有找到任何已发布的游戏',
                      showAddButton: true,
                      onAddPressed: _handleAddGame,
                      customCardBuilder: (game) =>
                          _buildGameCardWithAdminActions(game),
                      onDeleteGameAction: (game) =>
                          _handleDeleteGame(game, "该游戏"), // 简化标题传递
                    );
                  }),

              // 2. Pending Games Tab (使用辅助方法构建分页列表)
              _buildPaginatedList(
                context: context,
                isLoading: _isLoadingReviewQueue && pendingGames.isEmpty,
                error: _reviewQueueError,
                games: pendingGames,
                hasMore: _reviewQueueHasMore,
                isLoadingMore: _isLoadingMoreReviewQueue,
                scrollController:
                    _pendingScrollController, // 传递 Pending Controller
                onRefresh: _refreshReviewQueue,
                emptyMessage: '没有待审核的游戏',
                customCardBuilder: _buildPendingGameCard, // 传递卡片构建器
                onDeleteAction: (game) =>
                    _handleDeleteGame(game, "该游戏"), // 传递删除回调
              ),

              // 3. Rejected Games Tab (使用辅助方法构建分页列表)
              _buildPaginatedList(
                context: context,
                isLoading: _isLoadingReviewQueue && rejectedGames.isEmpty,
                error: _reviewQueueError,
                games: rejectedGames,
                hasMore: _reviewQueueHasMore,
                isLoadingMore: _isLoadingMoreReviewQueue,
                scrollController:
                    _rejectedScrollController, // 传递 Rejected Controller
                onRefresh: _refreshReviewQueue,
                emptyMessage: '没有被拒绝的游戏',
                customCardBuilder: _buildRejectedGameCard, // 传递卡片构建器
                onDeleteAction: (game) =>
                    _handleDeleteGame(game, "该游戏"), // 传递删除回调
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === 新增：构建分页列表的辅助方法 ===
  Widget _buildPaginatedList({
    required BuildContext context,
    required bool isLoading,
    required String? error,
    required List<Game> games,
    required bool hasMore,
    required bool isLoadingMore,
    required ScrollController scrollController,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
    required Widget Function(Game) customCardBuilder,
    required Future<void> Function(Game game) onDeleteAction,
  }) {
    if (isLoading) {
      return const LoadingWidget(message: "加载中...");
    }
    if (error != null) {
      return CustomErrorWidget(errorMessage: error, onRetry: onRefresh);
    }
    if (games.isEmpty) {
      return EmptyStateWidget(message: emptyMessage);
    }

    // 使用 CommonGameListScreen 来构建 GridView
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: NotificationListener<ScrollNotification>(
          // 使用 NotificationListener 监听滚动
          onNotification: (ScrollNotification scrollInfo) {
            // 检查是否滚动到底部附近
            if (!isLoadingMore &&
                hasMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 300) {
              // 触发加载更多，但 _loadMoreReviewQueueData 已有防抖，这里可以简单调用
              _loadMoreReviewQueueData();
              return true; // 阻止通知冒泡
            }
            return false;
          },
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(), // 保证 RefreshIndicator 可用
            children: [
              CommonGameListScreen(
                windowStateProvider: widget.windowStateProvider,
                title: "", // title 不重要
                useScaffold: false,
                currentUser: _currentUser,
                games: games,
                isLoading: false, // 外部处理
                error: null, // 外部处理
                onRefreshTriggered: null, // RefreshIndicator 在外部
                emptyStateMessage: emptyMessage, // 传递
                customCardBuilder: customCardBuilder,
                onDeleteGameAction: onDeleteAction,
              ),
              // 加载更多指示器
              if (hasMore && isLoadingMore) // 只有在加载更多时显示
                Container(
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.center,
                  child: const LoadingWidget(),
                ),
              // 如果 hasMore 但不在加载中，可以显示一个空的 SizedBox 或 "没有更多了"
              if (!hasMore && games.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.center,
                  child: Text("没有更多了"),
                ),
            ],
          ),
        ));
  }

  Widget _buildGameCard(Game game) {
    return BaseGameCard(
      game: game,
      currentUser: _currentUser,
      showTags: true, // 卡片上显示标签
      maxTags: 1, // 示例，根据卡片大小调整
    );
  }

  // --- 卡片构建方法 (完整代码) ---

  Widget _buildGameCardWithAdminActions(Game game) {
    return Stack(
      children: [
        _buildGameCard(game),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withSafeOpacity(0.8),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _handleEditGame(game),
                  tooltip: '编辑',
                ),
              ),
              SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.white.withSafeOpacity(0.8),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _handleDeleteGame(game, game.title),
                  tooltip: '删除',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingGameCard(Game game) {
    return Stack(
      children: [
        _buildGameCard(game),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withSafeOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '待审核',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ),
        Positioned(
            bottom: 8, // 放到底部
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  // 批准按钮
                  backgroundColor: Colors.white.withSafeOpacity(0.9),
                  radius: 18,
                  child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      tooltip: '批准',
                      onPressed: () => _handleReviewAction(game, true)),
                ),
                SizedBox(width: 6),
                CircleAvatar(
                  // 拒绝按钮
                  backgroundColor: Colors.white.withSafeOpacity(0.9),
                  radius: 18,
                  child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(Icons.cancel, color: Colors.red),
                      tooltip: '拒绝',
                      onPressed: () => _handleReviewAction(game, false)),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildRejectedGameCard(Game game) {
    return Stack(
      children: [
        _buildGameCard(game),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withSafeOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '已拒绝',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ),
        if (game.reviewComment != null && game.reviewComment!.isNotEmpty)
          Positioned(
              bottom: 8, // 放到底部
              left: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withSafeOpacity(0.7), // 半透明背景
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '原因: ${game.reviewComment}',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 2, // 最多显示两行
                  overflow: TextOverflow.ellipsis,
                ),
              )),
      ],
    );
  }
} // End of _GameManagementState
