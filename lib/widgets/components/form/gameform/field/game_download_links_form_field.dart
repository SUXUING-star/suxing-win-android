// lib/widgets/components/form/gameform/field/game_download_links_form_field.dart

/// 该文件定义了 [GameDownloadLinksFormField] 组件，用于在游戏表单中管理下载链接。
library;

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/models/game/game/game_download_link.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/utils/common/clipboard_link_parser.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/components/dialog/add_download_link_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

/// [GameDownloadLinksFormField] 类：一个用于在表单中添加、编辑、删除游戏下载链接的字段组件。
class GameDownloadLinksFormField extends StatelessWidget {
  /// 当前的下载链接列表。
  final List<GameDownloadLink> downloadLinks;

  /// 当链接列表发生变化时的回调。
  final ValueChanged<List<GameDownloadLink>> onChanged;

  /// 输入状态服务。
  final InputStateService inputStateService;

  /// 当前用户。
  final User currentUser;

  /// 构造函数。
  const GameDownloadLinksFormField({
    super.key,
    required this.downloadLinks,
    required this.onChanged,
    required this.inputStateService,
    required this.currentUser,
  });

  /// [复用] 工具类从剪贴板快速添加链接。
  Future<void> _quickAddFromClipboard(BuildContext context) async {
    final (newLink, error) = await ClipboardLinkParser.parseFromClipboard(
        currentUserId: currentUser.id);

    if (newLink != null) {
      final newLinks = List<GameDownloadLink>.from(downloadLinks);
      newLinks.add(newLink);
      onChanged(newLinks);
      if (context.mounted) {
        AppSnackBar.showSuccess('已从剪贴板添加: ${newLink.title}');
      }
    } else if (error != null) {
      if (context.mounted) {
        AppSnackBar.showInfo(error);
      }
    }
  }

  /// [完全复用] 对话框来添加新链接。
  void _addDownloadLink(BuildContext context) {
    AddDownloadLinkDialog.show(
      context: context,
      inputStateService: inputStateService,
      onConfirm: ({required title, required url, required description}) {
        final newLinks = List<GameDownloadLink>.from(downloadLinks);
        newLinks.add(GameDownloadLink(
          id: mongo.ObjectId().oid,
          userId: currentUser.id,
          title: title,
          url: url,
          description: description,
        ));
        onChanged(newLinks);
      },
    );
  }

  /// [完全复用] 对话框来编辑链接。
  void _editDownloadLink(BuildContext context, int index) {
    final linkToEdit = downloadLinks[index];
    AddDownloadLinkDialog.show(
      context: context,
      inputStateService: inputStateService,
      existingLink: linkToEdit, // 传入已有链接，进入编辑模式
      onConfirm: ({required title, required url, required description}) {
        final newLinks = List<GameDownloadLink>.from(downloadLinks);
        newLinks[index] = GameDownloadLink(
          id: linkToEdit.id,
          userId: currentUser.id,
          title: title,
          url: url,
          description: description,
        );
        onChanged(newLinks);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '下载链接',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  FunctionalButton(
                    onPressed: () => _quickAddFromClipboard(context),
                    icon: Icons.paste,
                    label: '快速添加',
                  ),
                  FunctionalButton(
                    onPressed: () => _addDownloadLink(context),
                    icon: Icons.add,
                    label: '添加链接',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (downloadLinks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                '暂无下载链接',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: downloadLinks.length,
            itemBuilder: (context, index) {
              final link = downloadLinks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(link.title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        link.url,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13),
                      ),
                      if (link.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: SelectableText(
                            link.description,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: Colors.blueGrey[600], size: 20),
                        tooltip: '编辑',
                        onPressed: () => _editDownloadLink(context, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red[400], size: 20),
                        tooltip: '删除',
                        onPressed: () {
                          final newLinks =
                              List<GameDownloadLink>.from(downloadLinks);
                          newLinks.removeAt(index);
                          onChanged(newLinks);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
