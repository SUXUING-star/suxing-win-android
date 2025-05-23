// lib/screens/game/edit/edit_game_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/components/form/gameform/game_form.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class EditGameScreen extends StatefulWidget {
  final String gameId;
  final GameCollectionService gameCollectionService;
  final UserFollowService followService;
  final RateLimitedFileUpload fileUpload;
  final GameService gameService;
  final AuthProvider authProvider;
  final UserInfoProvider infoProvider;
  final GameListFilterProvider gameListFilterProvider;
  final SidebarProvider sidebarProvider;
  const EditGameScreen({
    super.key,
    required this.gameId,
    required this.gameCollectionService,
    required this.fileUpload,
    required this.gameService,
    required this.followService,
    required this.authProvider,
    required this.infoProvider,
    required this.gameListFilterProvider,
    required this.sidebarProvider,
  });

  @override
  _EditGameScreenState createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen>
    with SnackBarNotifierMixin {
  bool _hasInitializedDependencies = false;
  bool _isLoading = false;
  Game? _game;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadGameData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      setState(() => _isLoading = true);

      final Game? game = await widget.gameService.getGameById(widget.gameId);
      if (game != null) {
        if (mounted) {
          setState(() {
            _game = game;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showSnackbar(
          message: '加载帖子数据失败: ${e.toString()}', type: SnackbarType.error);
    }
  }

  Future<void> _handleGameFormSubmit(Game gameDataFromForm) async {
    // 这个方法由 GameForm 的 onSubmit 回调触发
    // GameForm 内部的 _isProcessing 会处理按钮的加载状态
    // _EditGameScreenState 可以在这里处理 API 调用后的导航和对话框

    if (!mounted) return;

    try {
      await widget.gameService.updateGame(gameDataFromForm);

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
      if (!mounted) return;
      // API 调用失败，GameForm 内部通常会显示一个即时的错误 SnackBar
      // _EditGameScreenState 可以在这里显示一个更具体的错误提示或执行其他错误处理
      showSnackbar(
          message: '操作失败: ${e.toString().replaceFirst("Exception: ", "")}',
          type: SnackbarType.error);
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

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context); // SnackBarNotifierMixin 的方法

    final String appBarTitle = '编辑游戏: ${_game?.title}';

    if (_isLoading) {
      return LoadingWidget.fullScreen(message: "正在加载数据");
    }

    if (_game == null) {
      // 保持这个检查
      return const CustomErrorWidget(title: '无法加载游戏数据');
    }
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;
        final String? currentUserId = currentUser?.id;
        final bool isAdmin = currentUser?.isAdmin ?? false;
        if (currentUser == null) {
          return const LoginPromptWidget();
        }
        final canEdit = isAdmin ? true : currentUserId == _game?.authorId;
        if (!canEdit) {
          return CustomErrorWidget(
            errorMessage: "你没有权限编辑",
            title: "错误",
            retryText: "返回上一页",
            onRetry: () => NavigationUtils.pop(context),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: appBarTitle,
            // 如果 GameForm 内部有 _isProcessing 状态来禁用返回，这里可能不需要特殊处理
            // 否则，如果需要阻止返回，可以考虑 EditGameScreen 的状态
          ),
          body: Column(
            children: [
              if (!isAdmin) _buildNeedToPending(),
              Expanded(
                child: GameForm(
                  fileUpload: widget.fileUpload,
                  sidebarProvider: widget.sidebarProvider,
                  gameListFilterProvider: widget.gameListFilterProvider,
                  gameCollectionService: widget.gameCollectionService,
                  authProvider: widget.authProvider,
                  gameService: widget.gameService,
                  followService: widget.followService,
                  infoProvider: widget.infoProvider,
                  currentUser: widget.authProvider.currentUser,
                  game: _game,
                  onSubmit: _handleGameFormSubmit, // 传递 State 的方法作为回调
                  // isSubmitting 属性现在由 GameForm 内部的 _isProcessing 控制
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
