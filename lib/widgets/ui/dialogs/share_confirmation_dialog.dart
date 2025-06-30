// lib/widgets/ui/dialogs/share_confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

/// 一个通用的、用于显示分享内容并确认复制的对话框。
class ShareConfirmationDialog extends StatelessWidget {
  /// 需要在对话框中可选择和复制的分享内容。
  final String shareableContent;

  const ShareConfirmationDialog({
    super.key,
    required this.shareableContent,
  });

  /// 静态方法，用于快速显示此对话框。
  ///
  /// [context]: BuildContext。
  /// [shareableContent]: 要显示的完整分享消息。
  /// [title]: 对话框的标题，默认为“分享口令已生成”。
  static Future<void> show({
    required BuildContext context,
    required String shareableContent,
    String title = '分享口令已生成',
  }) {
    // BaseInputDialog 提供了标准的对话框外壳（标题、按钮等）
    return BaseInputDialog.show<void>(
      context: context,
      title: title,
      iconData: Icons.celebration_rounded,
      showCancelButton: false, // 通常这种确认框只需要一个按钮
      confirmButtonText: '搞定',
      onConfirm: () async {
        // 点击“搞定”直接关闭对话框，什么都不用做
        return;
      },
      // contentBuilder 负责构建对话框的核心内容
      contentBuilder: (dialogContext) {
        // 我们把具体的 UI 实现封装在 ShareConfirmationDialog 组件里
        return ShareConfirmationDialog(
          shareableContent: shareableContent,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 这是对话框内容的具体 UI 实现
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppText('已复制到剪贴板，快去分享吧！', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            shareableContent,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}