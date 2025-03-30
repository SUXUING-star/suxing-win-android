// lib/screens/game/add/add_game_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/form/gameform/game_form.dart';
import '../../../widgets/common/toaster/toaster.dart';
import '../../../widgets/ui/dialogs/confirm_dialog.dart'; // <--- 导入你的自定义对话框

class AddGameScreen extends StatelessWidget {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '添加游戏',
      ),
      body: GameForm(
        onSubmit: (Game game) async {
          try {
            await _gameService.addGame(game);
            ScaffoldMessenger.of(context).clearSnackBars();
            Toaster.success(context, '游戏提交成功');
            // 显示审核通知对话框 (使用新的方法)
            _showReviewNoticeDialog(context); // <--- 调用更新后的方法
          } catch (e) {
            Toaster.error(context, '提交失败：$e');
          }
        },
      ),
    );
  }

  // 显示审核通知对话框 (使用 CustomConfirmDialog)
  void _showReviewNoticeDialog(BuildContext context) {
    // 将多行文本组合成一个 message 字符串
    String messageContent = '''您的游戏已成功提交，正在等待管理员审核。\n\n审核通过后，您的游戏将显示在游戏列表中。\n\n每位普通用户每天最多可提交3个游戏。\n\n您可以在个人主页查看您的游戏审核状态。''';

    CustomConfirmDialog.show(
      context: context,
      title: '游戏提交成功',
      message: messageContent,
      iconData: Icons.info_outline, // 使用信息图标
      iconColor: Colors.blue,       // 使用蓝色图标
      confirmButtonText: '查看审核状态', // 确认按钮文本
      confirmButtonColor: Theme.of(context).primaryColor, // 使用主题色
      cancelButtonText: '返回列表',    // 取消按钮文本
      barrierDismissible: false,     // 不允许点击外部关闭
      onConfirm: () async {
        // 对应 "查看审核状态" 按钮的操作
        // CustomConfirmDialog 内部不再自动 pop，需要在这里处理
        NavigationUtils.pop(context); // 关闭对话框
        // *重要*: 添加游戏成功后，通常应该先返回列表页，再跳转到我的游戏
        // 如果希望直接跳转，可以只 pop 对话框，然后 pushNamed
        // 如果希望先回列表再跳转，则需要先 pop(context) 两次
        // NavigationUtils.pop(context); // 返回列表页 （如果需要先回列表页）
        NavigationUtils.pushNamed(context, AppRoutes.myGames); // 跳转到我的游戏
      },
      onCancel: () {
        // 对应 "返回列表" 按钮的操作
        // CustomConfirmDialog 内部会 pop 对话框，所以这里只需要 pop AddGameScreen
        NavigationUtils.pop(context); // 返回上一页（通常是游戏列表）
      },
    );
  }
}