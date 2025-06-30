// lib/widgets/ui/components/dialog/add_download_link_dialog.dart

/// 该文件定义了可复用的 [AddDownloadLinkDialog]，用于添加或编辑游戏下载链接。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game/game_download_link.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

/// 静态类，提供显示添加或编辑下载链接对话框的方法。
class AddDownloadLinkDialog {
  /// 显示一个对话框来收集或修改下载链接信息。
  ///
  /// [context]: 当前的 BuildContext。
  /// [inputStateService]: 用于管理输入框状态的服务。
  /// [onConfirm]: 当用户确认时调用的回调，返回包含所有输入值的元组。
  /// [existingLink]: 如果是编辑模式，传入已有的链接对象以填充初始值。
  static void show({
    required BuildContext context,
    required InputStateService inputStateService,
    required void Function(
            {required String title,
            required String url,
            required String description})
        onConfirm,
    GameDownloadLink? existingLink, // 可选参数，用于编辑模式
  }) {
    final isEditing = existingLink != null;
    final dialogTitle = isEditing ? '编辑下载链接' : '添加下载链接';
    final confirmButtonText = isEditing ? '保存' : '添加';

    final titleController =
        TextEditingController(text: existingLink?.title ?? '');
    final urlController = TextEditingController(text: existingLink?.url ?? '');
    final descriptionController =
        TextEditingController(text: existingLink?.description ?? '');

    BaseInputDialog.show<void>(
      context: context,
      title: dialogTitle,
      contentBuilder: (BuildContext dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextInputField(
              inputStateService: inputStateService,
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '链接标题',
                hintText: '例如：百度网盘',
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              inputStateService: inputStateService,
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '下载链接',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              inputStateService: inputStateService,
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述/提取码等（可选）',
                hintText: '例如：提取码: abcd',
              ),
              maxLines: 2,
            ),
          ],
        );
      },
      confirmButtonText: confirmButtonText,
      onConfirm: () async {
        final title = titleController.text.trim();
        final url = urlController.text.trim();
        final description = descriptionController.text.trim();

        if (title.isNotEmpty && url.isNotEmpty) {
          onConfirm(title: title, url: url, description: description);
        } else {
          AppSnackBar.showWarning('链接标题和链接地址不能为空！');
          throw Exception('输入校验失败');
        }
      },
    );
  }
}
