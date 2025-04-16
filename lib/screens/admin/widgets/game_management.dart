import 'dart:async'; // For Future
import 'package:flutter/material.dart';
// *** 确保这些 import 路径是正确的 ***
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../services/main/game/game_service.dart';
import '../../../models/game/game.dart';
import '../../../models/tag/tag.dart'; // 如果面板需要
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../game/edit/edit_game_screen.dart';
import '../../game/edit/add_game_screen.dart';
import '../../game/list/common_game_list_screen.dart';
import '../../../widgets/ui/dialogs/confirm_dialog.dart';
import '../../../widgets/ui/dialogs/edit_dialog.dart'; // 现在是 TextInputDialog
import '../../../widgets/ui/common/empty_state_widget.dart';


class GameManagement extends StatefulWidget {
  const GameManagement({Key? key}) : super(key: key);

  @override
  State<GameManagement> createState() => _GameManagementState();
}

// *** 移除 WidgetsBindingObserver，因为 BaseGameListScreen 不再依赖 visibility ***
class _GameManagementState extends State<GameManagement>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  late TabController _tabController;

  // State for Pending and Rejected tabs
  bool _isLoadingPendingRejected = false;
  List<Game> _pendingGames = [];
  List<Game> _rejectedGames = [];
  String? _pendingRejectedError;

  // *** 修改：_allGamesFuture 的初始化 ***
  late Future<List<Game>> _allGamesFuture;

  // --- 不再需要面板状态，因为 BaseGameListScreen 不再管理它们 ---
  // bool _showLeftPanel = true;
  // bool _showRightPanel = true;
  // List<Tag> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // *** 正确初始化 Future：直接赋值，不要 await ***
    _allGamesFuture = _loadAllGames();

    // _loadTagsForPanels(); // 如果其他 Tab 需要 Tags 再加载

    // Load data for the initially selected tab if it's not the first one
    if (_tabController.index != 0) {
      _loadPendingOrRejectedData();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Handles tab changes.
  void _handleTabChange() {
    // ... (Tab change logic remains the same) ...
    if (_tabController.indexIsChanging) return;
    if (mounted) {
      if (_tabController.index == 1 || _tabController.index == 2) {
        bool needsLoad = (_tabController.index == 1 &&
                (_pendingGames.isEmpty || _pendingRejectedError != null)) ||
            (_tabController.index == 2 &&
                (_rejectedGames.isEmpty || _pendingRejectedError != null));
        if (needsLoad && !_isLoadingPendingRejected) {
          _loadPendingOrRejectedData();
        }
      }
    }
  }

  // === Data Loading ===

  // Future<void> _loadTagsForPanels() async { /* ... */ } // Keep if needed for other tabs

  /// Loads data for Pending or Rejected tabs. **(Complete)**
  Future<void> _loadPendingOrRejectedData() async {
    if (!mounted || _isLoadingPendingRejected) return;
    setState(() {
      _isLoadingPendingRejected = true;
      _pendingRejectedError = null;
    });
    try {
      if (_tabController.index == 1) {
        final result =
            await _gameService.getPendingGamesWithInfo(page: 1, pageSize: 100);
        if (mounted)
          setState(() {
            _pendingGames = result['games'];
          });
      } else if (_tabController.index == 2) {
        final result = await _gameService.getUserRejectedGamesWithInfo(
            page: 1, pageSize: 100);
        if (mounted)
          setState(() {
            _rejectedGames = result['games'];
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingRejectedError = '加载数据失败: $e';
          if (_tabController.index == 1) _pendingGames = [];
          if (_tabController.index == 2) _rejectedGames = [];
        });
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoadingPendingRejected = false;
        });
    }
  }

  /// Returns a Future to load all games. **(Complete)**
  Future<List<Game>> _loadAllGames() async {
    // This method now simply returns the Future, no state changes here
    try {
      final result = await _gameService.getGamesPaginatedWithInfo(
        page: 1,
        pageSize: 200,
        sortBy: 'createTime',
        descending: true,
      );
      return result['games'] as List<Game>;
    } catch (e) {
      // Rethrow for FutureBuilder to catch
      throw Exception('加载游戏管理列表失败: $e');
    }
  }

  /// Refreshes the "All Games" tab. **(Complete)**
  Future<void> _refreshAllGames() async {
    if (!mounted) return;
    // Create a new Future instance to trigger FutureBuilder update
    setState(() {
      _allGamesFuture = _loadAllGames();
    });
  }

  // === Actions ===

  /// Handles deleting a game. **(Complete)**
  Future<void> _handleDeleteGame(String gameId, String gameTitle) async {
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
            await _gameService.deleteGame(gameId);
            if (mounted) {
              AppSnackBar.showSuccess(context, '游戏已删除');
              _refreshAllGames();
              if (_tabController.index == 1 || _tabController.index == 2) {
                _loadPendingOrRejectedData();
              }
            }
          } catch (e) {
            if (mounted) AppSnackBar.showError(context, '删除失败: $e');
            rethrow;
          }
        });
  }

  /// Handles editing a game. **(Complete)**
  Future<void> _handleEditGame(Game game) async {
    final result = await NavigationUtils.push(context,
        MaterialPageRoute(builder: (context) => EditGameScreen(game: game)));
    if (result == true && mounted) {
      _refreshAllGames();
      if (_tabController.index == 1 || _tabController.index == 2) {
        _loadPendingOrRejectedData();
      }
    }
  }

  /// Handles adding a game. **(Complete)**
  void _handleAddGame() {
    NavigationUtils.push(
      context,
      MaterialPageRoute(builder: (context) => AddGameScreen()),
    ).then((added) {
      if (added == true && mounted) {
        _refreshAllGames();
      }
    });
  }

  /// Handles the review action (approve/reject). **(Complete)**
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
          await _reviewGameApiCall(game.id, 'approved', '');
        },
      );
    } else {
      // --- Reject Case: Use EditDialog first to get the reason ---
      // *** Call EditDialog.show and provide the REQUIRED onSave callback ***
      await EditDialog.show( // Await the Future<void> returned by EditDialog.show
        context: context,
        title: '输入拒绝原因',
        initialText: '',       // Start with empty text
        hintText: '请详细说明拒绝的原因...',
        saveButtonText: '下一步', // Button text for getting reason
        maxLines: 3,
        iconData: Icons.comment_outlined,
        // *** Provide the onSave callback as required by EditDialog.show ***
        onSave: (String reason) async {
          // This code block executes *after* the user presses "下一步" in EditDialog
          // AND the internal validation (non-empty) passes.

          if (reason.trim().isEmpty) {
            // This check is technically redundant if EditDialog's internal validation
            // (via BaseInputDialog -> Form) works correctly, but acts as a safeguard.
            // If EditDialog allowed saving empty, show warning and stop.
            if(mounted) AppSnackBar.showWarning(context, '必须填写拒绝原因');
            // We need a way for onSave to signal failure *without* throwing an unhandled exception
            // if possible. If EditDialog's underlying BaseInputDialog handles onConfirm returning null
            // to keep the dialog open, we could return null or throw a specific validation exception.
            // For now, assume EditDialog closes on valid input only.
            return; // Stop further processing
          }

          // --- Got a valid reason, now show the FINAL confirmation dialog ---
          // This await needs to be INSIDE the onSave callback logic
          await CustomConfirmDialog.show(
            context: context,
            title: '确认拒绝',
            message: '确定要以原因 "${reason.trim()}" 拒绝游戏 "${game.title}" 吗？',
            confirmButtonText: '确认拒绝',
            confirmButtonColor: Colors.red,
            iconData: Icons.cancel_outlined,
            iconColor: Colors.red,
            onConfirm: () async {
              // When the *final* confirmation is pressed, call the API helper
              await _reviewGameApiCall(game.id, 'rejected', reason.trim());
            },
          );
          // --- End of CustomConfirmDialog call ---

        }, // --- End of onSave callback for EditDialog ---
      );
      // The Future<void> returned by EditDialog.show completes when the dialog
      // is closed (either by Save+onSave completing, Cancel, or barrier dismiss).
      // If onSave throws an error, that error will propagate here.
      // We generally don't need to 'await' the result specifically unless
      // we need to know *how* it closed, which we don't in this case.
    }
  }

  /// Internal helper to call the review API. **(Complete)**
  Future<void> _reviewGameApiCall(
      String gameId, String status, String comment) async {
    try {
      await _gameService.reviewGame(gameId, status, comment);
      if (mounted) {
        AppSnackBar.showSuccess(
            context, '游戏已${status == 'approved' ? '批准' : '拒绝'}');
        _loadPendingOrRejectedData();
        if (status == 'approved') {
          _refreshAllGames();
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '审核操作失败: $e');
    }
  }

  // === Build Methods ===
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '游戏管理'),
            Tab(text: '待审核 (${_pendingGames.length})'),
            Tab(text: '被拒绝 (${_rejectedGames.length})'),
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
              // 1. All Games Tab (Uses NEW BaseGameListScreen)
              _buildAllGamesTab(),
              // 2. Pending Games Tab
              RefreshIndicator(
                onRefresh: _loadPendingOrRejectedData,
                child: _buildPendingGamesList(),
              ),
              // 3. Rejected Games Tab
              RefreshIndicator(
                onRefresh: _loadPendingOrRejectedData,
                child: _buildRejectedGamesList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the "All Games" tab using the refactored BaseGameListScreen. **(Complete)**
  Widget _buildAllGamesTab() {
    return CommonGameListScreen(
      // Use a simple ValueKey, or manage a GlobalKey if external control is needed
      key: ValueKey(
          'all_games_management_${_allGamesFuture.hashCode}'), // Key changes when Future changes
      title: '游戏管理 (All)',
      useScaffold: false,
      gamesFuture: _allGamesFuture, // Pass the Future
      onRefreshTriggered: _refreshAllGames, // Pass the refresh callback
      emptyStateMessage: '没有找到任何游戏',
      showAddButton: false, // Add button managed externally if needed
      onAddPressed: _handleAddGame,
      onDeleteGameAction: (gameId) =>
          _handleDeleteGame(gameId, "该游戏"), // Need title
      customCardBuilder: (game) => _buildGameCardWithAdminActions(game),
      showTagSelection: false,
      showPanelToggles: false, // BaseGameListScreen no longer manages panels
    );
  }

  /// Builds the list/grid for "Pending Games". **(Complete, No Center)**
  Widget _buildPendingGamesList() {
    if (_isLoadingPendingRejected && _pendingGames.isEmpty) {
      return LoadingWidget.inline(message: "正在加载待审核..."); // No Center
    }
    if (_pendingRejectedError != null && _pendingGames.isEmpty) {
      return InlineErrorWidget(
          errorMessage: _pendingRejectedError!,
          onRetry: _loadPendingOrRejectedData); // No Center
    }
    if (!_isLoadingPendingRejected &&
        _pendingRejectedError == null &&
        _pendingGames.isEmpty) {
      return EmptyStateWidget(
        iconData: Icons.check_circle_outline,
        iconSize: 64,
        iconColor: Colors.grey,
        message: '没有待审核的游戏',
      ); // EmptyStateWidget handles centering
    }
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: _pendingGames.length,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) =>
          _buildPendingGameCard(_pendingGames[index]),
    );
  }

  /// Builds card for pending game with review actions. **(Complete)**
  Widget _buildPendingGameCard(Game game) {
    return Stack(
      children: [
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.8),
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
          top: 8,
          right: 8,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.check_circle, color: Colors.green),
                  tooltip: '批准',
                  onPressed: () => _handleReviewAction(game, true),
                ),
              ),
              SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.cancel, color: Colors.red),
                  tooltip: '拒绝',
                  onPressed: () => _handleReviewAction(game, false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the list/grid for "Rejected Games". **(Complete, No Center)**
  Widget _buildRejectedGamesList() {
    if (_isLoadingPendingRejected && _rejectedGames.isEmpty) {
      return LoadingWidget.inline(message: "正在加载被拒绝..."); // No Center
    }
    if (_pendingRejectedError != null && _rejectedGames.isEmpty) {
      return InlineErrorWidget(
          errorMessage: _pendingRejectedError!,
          onRetry: _loadPendingOrRejectedData); // No Center
    }
    if (!_isLoadingPendingRejected &&
        _pendingRejectedError == null &&
        _rejectedGames.isEmpty) {
      return EmptyStateWidget(
        iconData: Icons.block,
        iconSize: 64,
        iconColor: Colors.grey,
        message: '没有被拒绝的游戏',
      ); // EmptyStateWidget handles centering
    }
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: _rejectedGames.length,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) =>
          _buildRejectedGameCard(_rejectedGames[index]),
    );
  }

  /// Builds card for a rejected game. **(Complete)**
  Widget _buildRejectedGameCard(Game game) {
    return Stack(
      children: [
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
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
            bottom: 60,
            left: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '拒绝原因:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    game.reviewComment!,
                    style: TextStyle(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Builds card for the "All Games" tab with admin actions. **(Complete)**
  Widget _buildGameCardWithAdminActions(Game game) {
    return Stack(
      children: [
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              // Delete Button Only (Edit is via card tap)
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.7),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _handleDeleteGame(game.id, game.title),
                  tooltip: '删除',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} // End of _GameManagementState
