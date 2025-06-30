// lib/widgets/ui/utils/share_code_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/utils/share/share_utils.dart'; // 导入 ShareUtils
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

/// 处理分享口令的UI交互
class ShareCodeHandler {
  static Future<void> showShareCodeInputDialog(BuildContext context) async {
    final controller = TextEditingController();

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    if (!context.mounted) return;

    if (clipboardData?.text != null) {
      // 预填充，不关心是什么类型
      controller.text = clipboardData!.text!;
    }

    await BaseInputDialog.show<void>(
      context: context,
      title: '使用分享口令',
      iconData: Icons.vpn_key_outlined,
      confirmButtonText: '走起',
      contentBuilder: (dialogContext) => TextInputField(
        controller: controller,
        autofocus: true,
        maxLines: 5,
        minLines: 3,
        showSubmitButton: false,
        decoration: const InputDecoration(
          labelText: '在此处粘贴完整分享消息',
          hintText: '【${GlobalConstants.appName}】...',
          border: OutlineInputBorder(),
        ),
      ),
      onConfirm: () async {
        final message = controller.text.trim();
        if (message.isEmpty) {
          AppSnackBar.showError('口令不能为空');
          throw Exception('Empty code');
        }

        final result = ShareUtils.parseShareMessage(message);

        if (result != null) {
          // 解析成功，根据类型进行不同导航
          switch (result.type) {
            case ShareUtils.shareGame:
              NavigationUtils.pushNamed(context, AppRoutes.gameDetail,
                  arguments: result.id);
              break;
            case ShareUtils.sharePost:
              NavigationUtils.pushNamed(context, AppRoutes.postDetail,
                  arguments: result.id);
              break;
          }
        } else {
          AppSnackBar.showError('无效或错误的口令');
          throw Exception('Invalid code');
        }
      },
    );
  }
}
