// lib/widgets/components/dialogs/force_update_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'dart:async'; // BaseInputDialog.show 返回 Future
import 'package:url_launcher/url_launcher.dart'; // 用于打开链接

class ForceUpdateDialog {

  /// 显示强制更新对话框 (定制化组件)
  ///
  /// 外部调用只需提供版本信息和更新链接。样式和行为已内部固定。
  static Future<void> show({
    required BuildContext context,
    // *** 外部调用只需要传递这些核心数据 ***
    required String currentVersion,
    required String latestVersion,
    required String updateUrl,
    String? updateMessage,
    List<String>? changelog,
  }) {
    // --- 内部固定的样式和行为 ---
    const String fixedTitle = '发现新版本';
    const IconData fixedIconData = Icons.system_update;
    const String fixedConfirmButtonText = '立即更新';
    const double fixedMaxWidth = 350; // 固定宽度
    const bool fixedIsDraggable = false; // 固定不可拖拽
    const bool fixedIsScalable = false; // 固定不可缩放
    // -------------------------

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor; // 统一使用主题色
    final errorColor = theme.colorScheme.error; // 用于提示文字

    // 调用 BaseInputDialog.show，所有样式和行为参数都在这里写死
    return BaseInputDialog.show<void>(
      context: context,
      title: fixedTitle, // 使用内部固定的标题
      iconData: fixedIconData, // 使用内部固定的图标
      iconColor: primaryColor, // 图标颜色固定
      maxWidth: fixedMaxWidth, // 使用内部固定的宽度

      // --- contentBuilder 仍然使用传入的数据 ---
      contentBuilder: (dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本：$currentVersion'),
            Text('最新版本：$latestVersion'),
            const SizedBox(height: 16),
            if (updateMessage != null) ...[
              Text( updateMessage, style: TextStyle( color: errorColor, fontWeight: FontWeight.bold,),),
              const SizedBox(height: 16),
            ],
            if (changelog != null && changelog.isNotEmpty) ...[
              const Text( '更新内容：', style: TextStyle(fontWeight: FontWeight.bold),),
              const SizedBox(height: 8),
              Column( crossAxisAlignment: CrossAxisAlignment.start, children: changelog.map((change) => Padding( padding: const EdgeInsets.only(bottom: 4.0), child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(change)),],),)).toList(),),
              const SizedBox(height: 16),
            ],
            Text( '检测到重要更新，请立即更新...', style: TextStyle( color: errorColor, fontSize: 12,),),
          ],
        );
      },
      // --------------------------------------

      // --- 按钮和关闭行为固定 ---
      confirmButtonText: fixedConfirmButtonText, // 使用内部固定的按钮文字
      confirmButtonColor: primaryColor, // 按钮颜色固定
      onConfirm: () async { // 固定：点击执行打开链接逻辑
        final Uri uri = Uri.parse(updateUrl); // <-- 使用传入的 updateUrl
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('无法打开更新链接: $updateUrl')),);}
            print('Could not launch $updateUrl');
          }
        } catch (e) {
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('打开链接时出错: $e')),);}
          print("Error launching URL $updateUrl: $e");
        }
        return null; // 固定：点击按钮不关闭对话框
      },
      showCancelButton: false, // 固定：不显示取消按钮
      barrierDismissible: false, // 固定：不可点击外部关闭
      allowDismissWhenNotProcessing: false, // 固定：不可使用返回键关闭
      // -------------------------

      // --- 交互行为固定 ---
      isDraggable: fixedIsDraggable,
      isScalable: fixedIsScalable,
      // --------------------
    );
  }
}