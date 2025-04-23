// lib/screens/mygames/my_games_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/game_status_overlay.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../models/game/game.dart'; // 确保这里引用的是你正确的模型路径
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class MyGamesScreen extends StatefulWidget {
  const MyGamesScreen({super.key});

  @override
  _MyGamesScreenState createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends State<MyGamesScreen> {
  final GameService _gameService = GameService();
  final ScrollController _scrollController = ScrollController();

  List<Game> _myGames = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true; // For initial load
  bool _isFetchingMore = false; // For pagination loading indicator
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialGames();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // --- Data Loading ---

  Future<void> _loadInitialGames() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1; // Reset page number for refresh/initial load
      _myGames.clear(); // Clear existing games on refresh/initial load
    });

    try {
      final result = await _gameService.getMyGamesWithInfo(
        page: 1, // Always load page 1 initially
        pageSize: 10, // Or your preferred page size
        // sortBy: 'updateTime', // Example sorting, adjust as needed
        // descending: true,
      );

      if (!mounted) return;

      setState(() {
        _myGames = result['games'];
        _totalPages = result['pagination']?['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '加载我的游戏列表失败: $e';
      });
      AppSnackBar.showError(context, '加载失败，请稍后重试');
    }
  }

  Future<void> _loadMoreGames() async {
    // Prevent multiple fetches and fetching beyond last page
    if (_isFetchingMore ||
        _currentPage >= _totalPages ||
        _isLoading ||
        _hasError) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _gameService.getMyGamesWithInfo(
        page: nextPage,
        pageSize: 10,
        // sortBy: 'updateTime', // Consistent sorting
        // descending: true,
      );

      if (!mounted) return;

      setState(() {
        _myGames.addAll(result['games']);
        _currentPage = nextPage;
        _totalPages = result['pagination']?['totalPages'] ??
            _totalPages; // Update total pages if needed
        _isFetchingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('加载更多我的游戏失败: $e');
      // Optionally show a snackbar or allow retry
      setState(() {
        _isFetchingMore = false;
        AppSnackBar.showWarning(context, '加载更多失败');
      });
    }
  }

  void _scrollListener() {
    // Trigger load more when near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreGames();
    }
  }

  Future<void> _handleResubmit(Game game) async {
    // 使用 CustomConfirmDialog 进行确认
    await CustomConfirmDialog.show(
      // 或者 showConfirm，取决于你的实现
      context: context,
      title: '确认重新提交？',
      message: '您确定要将《${game.title}》重新提交审核吗？',
      confirmButtonText: '重新提交',
      confirmButtonColor: Colors.blue,
      iconData: Icons.help_outline,
      iconColor: Colors.blue,
      onConfirm: () async {
        // 用户确认后，调用实际的提交逻辑
        await _executeResubmit(game);
      },
      // onCancel 不提供，默认关闭对话框
    );
  }

  /// 2. 执行实际的重新提交逻辑 (被 onConfirm 调用)
  Future<void> _executeResubmit(Game game) async {
    // 检查状态，虽然理论上按钮只在 rejected 时显示
    if (game.approvalStatus != 'rejected') return;

    // 这里可以加一个 Loading 状态，但确认对话框自带了，所以可能不需要
    try {
      await _gameService.resubmitGame(game.id);
      if (!mounted) return; // 检查 context 是否有效

      // 使用 AppSnackBar 显示成功信息
      AppSnackBar.showSuccess(context, '《${game.title}》已重新提交审核');

      // 刷新列表以更新状态
      await _loadInitialGames(); // 使用 await 确保刷新完成后再继续
    } catch (e) {
      if (!mounted) return; // 检查 context 是否有效
      print('重新提交失败: $e');
      // 使用 AppSnackBar 显示错误信息
      AppSnackBar.showError(context, '重新提交失败: $e');
    }
  }

  // --- UI Building ---

  /// 3. 显示拒绝原因 -> 弹出信息对话框
  void _showReviewCommentDialog(String comment) {
    // 使用 CustomInfoDialog 显示信息
    CustomInfoDialog.show(
      context: context,
      title: '拒绝原因',
      message: comment, // 将拒绝原因作为消息显示
      iconData: Icons.comment_outlined, // 可以用评论相关的图标
      iconColor: Colors.orange, // 橙色或红色系
      closeButtonText: '知道了',
      // onClose 回调可以留空，如果不需要关闭后执行特定操作
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '我的游戏', // Changed title
        // No bottom TabBar needed
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialGames, // Pull to refresh loads page 1
        child: _buildBody(),
      ),
      floatingActionButton: GenericFloatingActionButton(
        onPressed: () async {
          // Navigate and potentially refresh list after returning
          final result =
              await NavigationUtils.pushNamed(context, AppRoutes.addGame);
          if (result == true) {
            // Check if add game screen indicates success
            _loadInitialGames();
          }
        },
        icon: Icons.add,
        tooltip: '提交新游戏',
      ),
    );
  }

  Widget _buildBody() {
    // 4. 计算卡片宽高比
    //    根据是否有面板，调用不同的 DeviceUtils 方法
    final cardRatio =

        DeviceUtils.calculateSimpleCardRatio(context); // 使用 widget 的 showTagSelection
    if (_isLoading) {
      return LoadingWidget.inline();
    }
    // 2. 计算每行卡片数
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(context);
    if (cardsPerRow <= 0) return InlineErrorWidget(errorMessage: "渲染错误");
    final isDesktop = DeviceUtils.isDesktop;

    // 使用 _errorMessage 来显示具体的错误信息
    if (_hasError) {
      // 错误提示也加个动画
      return InlineErrorWidget(
        onRetry: _loadInitialGames,
        errorMessage: _errorMessage.isNotEmpty ? _errorMessage : '加载失败，请点击重试',
      );
    }

    // --- 空状态 ---
    if (_myGames.isEmpty) {
      // 空状态提示也加个动画
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '您还没有提交过游戏',
          action: FunctionalTextButton(
              onPressed: () {
                NavigationUtils.pushNamed(context, AppRoutes.addGame)
                    .then((result) {
                  if (result == true && mounted) {
                    _loadInitialGames();
                  }
                });
              },
              label: '创建新游戏',
              icon: Icons.videogame_asset_rounded),
        ),
      );
    }

    // ListView + GridView 结构保持不变
    return ListView(
        key: ValueKey<int>(_myGames.length),
        controller: _scrollController,
        padding: EdgeInsets.all(8),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cardsPerRow, // 使用计算出的每行数量
              childAspectRatio: cardRatio, // 使用计算出的宽高比
              crossAxisSpacing: 8,
              mainAxisSpacing: isDesktop ? 16 : 8,
            ),
            itemCount: _myGames.length,
            itemBuilder: (context, index) {
              final game = _myGames[index];
              // *** 为每个 Grid Item 应用动画 ***
              return FadeInSlideUpItem(
                // 根据索引计算延迟，实现交错效果
                delay: Duration(milliseconds: 50 * index),
                duration: Duration(milliseconds: 350), // 可以调整动画时长
                child: _buildGameCard(game), // 构建卡片本身
              );
            },
          ),
          // --- 加载更多指示器 ---
          if (_isFetchingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              // 加载更多也简单淡入
              child:
                  FadeInItem(child: LoadingWidget.inline(message: "加载更多...")),
            )
        ]);
  }

  /// 构建游戏卡片 (现在使用 GameStatusOverlay)
  Widget _buildGameCard(Game game) {
    return Stack(
      children: [
        // 基础卡片内容
        BaseGameCard(
          game: game,
          showTags: true,
          maxTags: 1,
        ),

        // 游戏状态、评论、操作按钮的 Overlay
        GameStatusOverlay(
          game: game,
          // 传递处理函数引用
          onResubmit: () => _handleResubmit(game),
          onShowReviewComment: _showReviewCommentDialog,
        ),
      ],
    );
  }
}
