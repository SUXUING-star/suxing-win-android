// lib/widgets/components/screen/game/download/add_game_download_actions.dart

/// 该文件定义了 [AddGameDownloadActions] 组件。
///
/// 该组件提供一组操作按钮，包括“快速添加”和“添加链接”，用于为游戏添加下载链接。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/utils/common/clipboard_link_parser.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/components/dialog/add_download_link_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

/// [AddGameDownloadActions] 类：提供添加下载链接相关操作的按钮组。
class AddGameDownloadActions extends StatelessWidget {
  /// 添加新链接的【异步】回调函数。
  final Future<void> Function(GameDownloadLink)? onAddLink;

  /// 指示当前是否正在执行添加操作的标志。
  final bool isAdding;

  /// 当前登录用户的ID。
  final String? currentUserId;

  /// 是否为预览模式。
  final bool isPreviewMode;

  /// 输入状态服务。
  final InputStateService inputStateService;

  /// 构造函数。
  const AddGameDownloadActions({
    super.key,
    this.onAddLink,
    required this.isAdding,
    required this.currentUserId,
    required this.isPreviewMode,
    required this.inputStateService,
  });

  /// 调用工具类从剪贴板快速添加链接。
  Future<void> _quickAddFromClipboard(BuildContext context) async {
    if (currentUserId == null || onAddLink == null) return;

    final (newLink, error) = await ClipboardLinkParser.parseFromClipboard(
        currentUserId: currentUserId!);

    if (newLink != null) {
      await onAddLink!(newLink);
      if (context.mounted) {
        AppSnackBar.showSuccess('已从剪贴板添加: ${newLink.title}');
      }
    } else if (error != null) {
      if (context.mounted) {
        AppSnackBar.showInfo(error);
      }
    }
  }

  /// [完全复用] 调用抽离出来的对话框。
  void _showAddLinkDialog(BuildContext context) {
    if (currentUserId == null || onAddLink == null) return;

    AddDownloadLinkDialog.show(
      context: context,
      inputStateService: inputStateService,
      // 这里的回调是异步的，因为它调用的是外部的 onAddLink
      onConfirm: ({required title, required url, required description}) async {
        final newLink = GameDownloadLink(
          id: '', // API 模式下，ID由后端生成，这里为空
          userId: currentUserId!,
          title: title,
          url: url,
          description: description,
        );
        await onAddLink!(newLink);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) return const LoginPromptWidget();
    if (isPreviewMode) {
      return const InlineErrorWidget(
        errorMessage: "预览模式无法添加下载链接",
      );
    }
    if (isAdding) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: LoadingWidget(size: 24),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.end,
      children: [
        FunctionalButton(
          onPressed: () => _quickAddFromClipboard(context),
          icon: Icons.paste,
          label: '快速添加',
        ),
        FunctionalButton(
          onPressed: () => _showAddLinkDialog(context),
          icon: Icons.add_link,
          label: '添加链接',
        ),
      ],
    );
  }
}
