// lib/widgets/components/form/gameform/field/game_external_links_field.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

class GameExternalLinksField extends StatelessWidget {
  final List<GameExternalLink> externalLinks;
  final ValueChanged<List<GameExternalLink>> onChanged;
  final InputStateService inputStateService;

  const GameExternalLinksField({
    super.key,
    required this.externalLinks,
    required this.onChanged,
    required this.inputStateService,
  });

  void _addExternalLink(BuildContext context) {
    _showLinkDialog(
      context: context,
      dialogTitle: '添加关联链接',
      confirmButtonText: '添加',
      onConfirmAction: (title, url) {
        final newLinks = List<GameExternalLink>.from(externalLinks);
        newLinks.add(GameExternalLink(
          title: title,
          url: url,
        ));
        onChanged(newLinks);
      },
    );
  }

  void _editExternalLink(BuildContext context, int index) {
    final link = externalLinks[index];
    _showLinkDialog(
      context: context,
      dialogTitle: '编辑关联链接',
      initialTitle: link.title,
      initialUrl: link.url,
      confirmButtonText: '保存',
      onConfirmAction: (title, url) {
        final newLinks = List<GameExternalLink>.from(externalLinks);
        newLinks[index] = GameExternalLink(
          title: title,
          url: url,
        );
        onChanged(newLinks);
      },
    );
  }

  void _showLinkDialog({
    required BuildContext context,
    required String dialogTitle,
    String initialTitle = '',
    String initialUrl = '',
    required String confirmButtonText,
    required void Function(String title, String url) onConfirmAction,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final urlController = TextEditingController(text: initialUrl);

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
                hintText: '例如：官方网站, Steam页面',
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              inputStateService: inputStateService,
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '链接 URL',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        );
      },
      confirmButtonText: confirmButtonText,
      onConfirm: () async {
        final title = titleController.text.trim();
        final url = urlController.text.trim();

        if (title.isNotEmpty && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri == null ||
              (!uri.isScheme("HTTP") && !uri.isScheme("HTTPS")) ||
              uri.host.isEmpty) {
            if (context.mounted) {
              AppSnackBar.showWarning('请输入有效的 HTTP 或 HTTPS 链接！');
            }
            throw Exception('URL 格式无效');
          }
          onConfirmAction(title, url);
          return;
        } else {
          if (context.mounted) {
            AppSnackBar.showWarning('链接标题和 URL 不能为空！');
          }
          throw Exception('输入校验失败');
        }
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
                '其他关联链接',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FunctionalButton(
                onPressed: () => _addExternalLink(context),
                icon: Icons.add_link, // 换个图标
                label: '添加链接',
              ),
            ],
          ),
        ),
        if (externalLinks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                '暂无其他关联链接',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: externalLinks.length,
            itemBuilder: (context, index) {
              final link = externalLinks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.link), // 加个图标
                  title: Text(link.title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: SelectableText(
                    link.url,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, // 换个图标
                            color: Colors.blueGrey[600],
                            size: 20),
                        tooltip: '编辑',
                        onPressed: () => _editExternalLink(context, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever_outlined, // 换个图标
                            color: Colors.red[400],
                            size: 20),
                        tooltip: '删除',
                        onPressed: () {
                          final newLinks =
                              List<GameExternalLink>.from(externalLinks);
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
