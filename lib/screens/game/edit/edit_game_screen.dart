// lib/screens/game/edit/edit_game_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/components/form/gameform/game_form.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart';

class EditGameScreen extends StatefulWidget {
  final String gameId;
  final GameCollectionService gameCollectionService;
  final UserFollowService followService;
  final RateLimitedFileUpload fileUpload;
  final GameService gameService;
  final AuthProvider authProvider;
  final UserInfoService infoService;
  final GameListFilterProvider gameListFilterProvider;
  final SidebarProvider sidebarProvider;
  final InputStateService inputStateService;
  final WindowStateProvider windowStateProvider;

  const EditGameScreen({
    super.key,
    required this.gameId,
    required this.gameCollectionService,
    required this.fileUpload,
    required this.gameService,
    required this.followService,
    required this.authProvider,
    required this.infoService,
    required this.gameListFilterProvider,
    required this.windowStateProvider,
    required this.sidebarProvider,
    required this.inputStateService,
  });

  @override
  _EditGameScreenState createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  bool _hasInitializedDependencies = false;
  bool _isLoading = false;
  Game? _game; // _game 可以在加载完成后保存游戏数据

  @override
  void initState() {
    super.initState();
    // _loadGameData() 在 didChangeDependencies 中调用，确保 context 可用
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      // 首次进入时加载数据
      _hasInitializedDependencies = true;
      _loadGameData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      if (!mounted) return; // 确保 widget 仍然在树中
      setState(() => _isLoading = true);

      final Game? game = await widget.gameService.getGameById(widget.gameId);
      if (mounted) {
        setState(() {
          _game = game;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      AppSnackBar.showError('加载帖子数据失败: ${e.toString()}');
    }
  }

  Future<void> _handleGameFormSubmit(Game gameDataFromForm) async {
    if (!mounted) return;

    try {
      final oldGame = _game;
      if (oldGame == null) return;
      await widget.gameService
          .updateGame(updateGame: gameDataFromForm, oldGame: oldGame);

      // API 调用成功
      if (!mounted) return;

      if (!widget.authProvider.isAdmin) {
        // 编辑模式且非管理员
        _showReviewNoticeDialogAfterApiSuccess();
      } else {
        // 添加模式成功，或管理员编辑成功，直接返回上一页并传递成功标记
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      AppSnackBar.showError(
        '操作失败: ${e.toString()}',
      );
    }
  }

  void _showReviewNoticeDialogAfterApiSuccess() {
    if (!mounted) return;

    String messageContent =
        '''您的游戏已成功修改，修改需要重新审核，正在等待管理员审核。\n\n审核通过后，您修改的游戏内容将显示在游戏列表中。\n\n您可以在个人主页查看您的游戏审核状态。''';

    CustomConfirmDialog.show(
      context: context, // 使用 _EditGameScreenState 的 context
      title: '游戏修改成功',
      message: messageContent,
      iconData: Icons.info_outline,
      iconColor: Colors.blue,
      confirmButtonText: '查看审核状态',
      confirmButtonColor: Theme.of(context).primaryColor,
      cancelButtonText: '返回列表',
      barrierDismissible: false,
      onConfirm: () async {
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭 Dialog
        if (!mounted) return;
        Navigator.of(context).pop(true); // 关闭 EditGameScreen, 返回 true
        if (!mounted) return;
        Navigator.of(context).pushNamed(AppRoutes.myGames);
      },
      onCancel: () {
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭 Dialog
        if (!mounted) return;
        Navigator.of(context).pop(true); // 关闭 EditGameScreen, 返回 true
      },
    );
  }

  Widget _buildNeedToPending() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '提示：编辑游戏后，该游戏将需要重新审核，在审核通过前将不会在游戏列表中显示。',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 私有方法：构建页面主体内容，包含 StreamBuilder
  Widget _buildBody() {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;
        final String? currentUserId = currentUser?.id;
        final bool isAdmin = currentUser?.isAdmin ?? false;

        // 如果用户未登录，显示登录提示
        if (currentUser == null) {
          return const LoginPromptWidget();
        }

        // 检查用户是否有权限编辑此游戏
        // 因为在此处之前已经检查了 _game 是否为 null，所以 _game! 是安全的
        final canEdit = isAdmin ? true : currentUserId == _game!.authorId;
        if (!canEdit) {
          return CustomErrorWidget(
            errorMessage: "你没有权限编辑此游戏。",
            title: "权限不足",
            retryText: "返回上一页",
            onRetry: () => NavigationUtils.pop(context),
          );
        }

        // 实际的游戏编辑表单
        return Column(
          children: [
            // 非管理员用户显示审核提示
            if (!isAdmin) _buildNeedToPending(),
            Expanded(
              child: GameForm(
                windowStateProvider: widget.windowStateProvider,
                inputStateService: widget.inputStateService,
                fileUpload: widget.fileUpload,
                sidebarProvider: widget.sidebarProvider,
                gameListFilterProvider: widget.gameListFilterProvider,
                gameCollectionService: widget.gameCollectionService,
                authProvider: widget.authProvider,
                gameService: widget.gameService,
                followService: widget.followService,
                infoService: widget.infoService,
                currentUser: widget.authProvider.currentUser,
                game: _game!, // _game 在这里保证非空
                onSubmit: _handleGameFormSubmit,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在加载数据，显示全屏加载动画
    if (_isLoading) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    // 如果数据加载完成但 _game 为 null（例如，游戏ID不存在）
    if (_game == null) {
      return const CustomErrorWidget(
          title: '无法加载游戏数据', errorMessage: '游戏ID无效或不存在。');
    }

    // 确定 AppBar 标题
    // 因为 _game 在此处已经确保不为 null，所以可以直接使用 _game.title
    final String appBarTitle = '编辑游戏: ${_game!.title}';

    // 返回 Scaffold，appBar 和 body 分开处理
    return Scaffold(
      appBar: CustomAppBar(
        title: appBarTitle,
        // 如果需要，可以在这里根据 _isProcessing 状态禁用返回按钮
        // automaticallyImplyLeading: !(_isProcessing ?? false), // 假设 GameForm 内部有处理
      ),
      body: _buildBody(), // 调用私有方法来构建 body
    );
  }
}
