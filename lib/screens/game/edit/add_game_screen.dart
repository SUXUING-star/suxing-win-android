// lib/screens/game/add/add_game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
// import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 可以不用
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart'; // 引入 Mixin
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/form/gameform/game_form.dart';
import '../../../widgets/ui/dialogs/confirm_dialog.dart';

class AddGameScreen extends StatefulWidget {
  // 改为 StatefulWidget
  const AddGameScreen({super.key});

  @override
  _AddGameScreenState createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen>
    with SnackBarNotifierMixin {
  bool _hasInitializedDependencies = false;
  late final GameService _gameService;
  late final AuthProvider _authProvider;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _gameService = context.read<GameService>();
      _hasInitializedDependencies = true;
    }
  }
  // 使用 Mixin

  Future<void> _handleGameFormSubmit(Game gameDataFromForm) async {
    if (!mounted) return;

    try {
      await _gameService.addGame(gameDataFromForm);

      if (!mounted) return;
      // 添加成功后，直接显示审核通知对话框

      if (!_authProvider.isAdmin) {
        // 编辑模式且非管理员
        _showReviewNoticeDialogAfterApiSuccess();
      } else {
        // 添加模式成功，或管理员编辑成功，直接返回上一页并传递成功标记
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      showSnackbar(
          message: '添加失败: ${e.toString().replaceFirst("Exception: ", "")}',
          type: SnackbarType.error);
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

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context); // Mixin 的方法

    return Scaffold(
      appBar: CustomAppBar(
        title: '添加新游戏',
      ),
      body: GameForm(
        currentUser: _authProvider.currentUser,
        onSubmit: _handleGameFormSubmit, // 传递 State 的方法
      ),
    );
  }
}
