// lib/screens/game/edit/edit_game_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/form/gameform/game_form.dart';
import '../../../widgets/ui/toaster/toaster.dart';
import '../../../widgets/ui/dialogs/confirm_dialog.dart'; // <--- 导入你的自定义对话框

class EditGameScreen extends StatelessWidget {
  final Game game;
  final GameService _gameService = GameService();

  EditGameScreen({required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '编辑游戏',
      ),
      body: Column(
        children: [
          // 添加审核通知信息框 (保持不变)
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
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
          ),
          // 游戏表单
          Expanded(
            child: GameForm(
              game: game,
              onSubmit: (Game updatedGame) async {
                try {
                  await _gameService.updateGame(updatedGame);
                  AppSnackBar.showSuccess(context, "修改成功");
                  // 显示审核通知对话框 (使用新的方法)
                  _showReviewNoticeDialog(context); // <--- 调用更新后的方法
                } catch (e) {
                  AppSnackBar.showError(context,'修改失败: ${e.toString()}');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 显示审核通知对话框 (使用 CustomConfirmDialog)
  void _showReviewNoticeDialog(BuildContext context) {
    // 将多行文本组合成一个 message 字符串
    String messageContent = '''您的游戏已成功修改，修改需要重新审核，正在等待管理员审核。\n\n审核通过后，您修改的游戏内容将显示在游戏列表中。\n\n您可以在个人主页查看您的游戏审核状态。''';

    CustomConfirmDialog.show(
      context: context,
      title: '游戏修改成功',
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
        // 导航到列表页（并传递结果，表示编辑成功）
        NavigationUtils.pop(context, true); // 返回列表页，true表示成功
        // 再跳转到我的游戏页
        NavigationUtils.pushNamed(context, AppRoutes.myGames);
      },
      onCancel: () {
        // 对应 "返回列表" 按钮的操作
        // CustomConfirmDialog 内部会 pop 对话框，所以这里只需要 pop EditGameScreen
        NavigationUtils.pop(context, true); // 返回列表页，true表示成功
      },
    );
  }
}