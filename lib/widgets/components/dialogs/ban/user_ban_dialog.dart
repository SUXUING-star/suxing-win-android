// lib/widgets/dialogs/user_ban_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'dart:async'; // BaseInputDialog.show 返回 Future
import 'package:suxingchahui/models/user/user_ban.dart';

class UserBanDialog {
  /// 显示用户封禁信息对话框 (定制化组件)
  ///
  /// 外部调用只需提供 [ban] 对象。样式和行为已内部固定。
  static Future<void> show({
    required BuildContext context,
    required UserBan ban,
  }) {
    // --- 内部固定的样式和行为 ---
    const String fixedTitle = '账号已被封禁';
    const IconData fixedIconData = Icons.block;
    const String fixedConfirmButtonText = '确认';
    const double fixedMaxWidth = 350; // 固定宽度
    const bool fixedIsDraggable = false; // 固定不可拖拽
    const bool fixedIsScalable = false; // 固定不可缩放
    // -------------------------

    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error; // 统一使用错误颜色

    // 调用 BaseInputDialog.show，所有样式和行为参数都在这里写死
    return BaseInputDialog.show<void>(
      context: context,
      title: fixedTitle, // 使用内部固定的标题
      iconData: fixedIconData, // 使用内部固定的图标
      iconColor: errorColor, // 图标颜色固定
      maxWidth: fixedMaxWidth, // 使用内部固定的宽度

      // --- contentBuilder 仍然使用传入的 ban 数据 ---
      contentBuilder: (dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '您的账号已被封禁处理',
              style: TextStyle(
                color: errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text('封禁原因：${ban.reason}'),
            const SizedBox(height: 8),
            Text('封禁时间：${ban.banTime.toLocal().toString().split('.')[0]}'),
            if (!ban.isPermanent) ...[
              const SizedBox(height: 8),
              Text('解封时间：${ban.endTime?.toLocal().toString().split('.')[0]}'),
            ],
            const SizedBox(height: 16),
            Text(
              ban.isPermanent ? '当前账号已被永久封禁...' : '账号在封禁期间...',
              style: TextStyle(
                color: errorColor,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
      // ------------------------------------------

      // --- 按钮和关闭行为固定 ---
      confirmButtonText: fixedConfirmButtonText, // 使用内部固定的按钮文字
      confirmButtonColor: errorColor, // 按钮颜色固定
      onConfirm: () async => (), // 固定：点击确认按钮不关闭
      showCancelButton: false, // 固定：不显示取消按钮
      barrierDismissible: false, // 固定：不可点击外部关闭
      allowDismissWhenNotProcessing: false, // 固定：不可使用返回键关闭
      // --- 交互行为固定 ---
      isDraggable: fixedIsDraggable,
      isScalable: fixedIsScalable,
    );
  }
}
