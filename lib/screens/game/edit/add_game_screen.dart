// lib/screens/game/edit/add_game_screen.dart
import 'package:flutter/material.dart';
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
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/components/form/gameform/game_form.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class AddGameScreen extends StatefulWidget {
  final GameService gameService;
  final AuthProvider authProvider;
  final RateLimitedFileUpload fileUpload;
  final SidebarProvider sidebarProvider;
  final GameListFilterProvider gameListFilterProvider;
  final GameCollectionService gameCollectionService;
  final UserFollowService followService;
  final UserInfoService infoService;
  final WindowStateProvider windowStateProvider;
  final InputStateService inputStateService;
  const AddGameScreen({
    super.key,
    required this.gameCollectionService,
    required this.gameListFilterProvider,
    required this.sidebarProvider,
    required this.gameService,
    required this.fileUpload,
    required this.authProvider,
    required this.followService,
    required this.windowStateProvider,
    required this.infoService,
    required this.inputStateService,
  });

  @override
  _AddGameScreenState createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  // _hasInitializedDependencies 在这里似乎没有实际用途，可以保留或移除，
  // 因为没有像 EditGameScreen 那样在 didChangeDependencies 中进行数据加载。
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      // 在这里添加初始化依赖的逻辑，如果需要的话
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleGameFormSubmit(Game gameDataFromForm) async {
    if (!mounted) return;

    try {
      await widget.gameService.addGame(gameDataFromForm);

      if (!mounted) return;
      // 添加成功后，直接显示审核通知对话框

      if (!widget.authProvider.isAdmin) {
        // 非管理员提交，显示审核通知
        _showReviewNoticeDialogAfterApiSuccess();
      } else {
        // 管理员提交，直接返回上一页并传递成功标记
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      AppSnackBar.showError('添加失败: ${e.toString()}');
    }
  }

  void _showReviewNoticeDialogAfterApiSuccess() {
    if (!mounted) return;

    String messageContent =
        '''您的游戏已成功提交，正在等待管理员审核。\n\n审核通过后，您的游戏将显示在游戏列表中。\n\n每位普通用户每天最多可提交3个游戏。\n\n您可以在个人主页查看您的游戏审核状态。''';

    CustomConfirmDialog.show(
      context: context, // 使用 _AddGameScreenState 的 context
      title: '游戏提交成功',
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
        Navigator.of(context)
            .pop(true); // 关闭 AddGameScreen, 返回 true (如果列表页需要知道结果)
        if (!mounted) return;
        Navigator.of(context).pushNamed(AppRoutes.myGames);
      },
      onCancel: () {
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭 Dialog
        if (!mounted) return;
        Navigator.of(context).pop(true); // 关闭 AddGameScreen, 返回 true
      },
    );
  }

  // 私有方法：构建页面主体内容，包含 StreamBuilder
  Widget _buildBody() {
    return StreamBuilder<String?>(
      stream: widget.authProvider.currentUserIdStream,
      initialData: widget.authProvider.currentUserId,
      builder: (context, currentUserIdSnapshot) {
        final String? currentUserId = currentUserIdSnapshot.data;

        // 如果用户未登录，显示登录提示
        if (currentUserId == null) {
          return const LoginPromptWidget();
        }

        // 用户已登录，显示游戏表单
        return GameForm(
          inputStateService: widget.inputStateService,
          fileUpload: widget.fileUpload,
          windowStateProvider: widget.windowStateProvider,
          sidebarProvider: widget.sidebarProvider,
          gameListFilterProvider: widget.gameListFilterProvider,
          gameCollectionService: widget.gameCollectionService,
          authProvider: widget.authProvider,
          followService: widget.followService,
          infoService: widget.infoService,
          gameService: widget.gameService,
          currentUser: widget.authProvider.currentUser, // 确保 currentUser 传给表单
          onSubmit: _handleGameFormSubmit, // 传递 State 的方法
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '添加新游戏',
      ),
      body: _buildBody(), // 调用私有方法来构建 body
    );
  }
}
