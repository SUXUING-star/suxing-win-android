// lib/widgets/components/form/gameform/field/game_download_links_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';

class GameDownloadLinksField extends StatelessWidget {
  final List<GameDownloadLink> downloadLinks;
  final ValueChanged<List<GameDownloadLink>> onChanged;
  final InputStateService inputStateService;

  const GameDownloadLinksField({
    super.key,
    required this.downloadLinks,
    required this.onChanged,
    required this.inputStateService,
  });

  Future<void> _quickAddFromClipboard(BuildContext context) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;

    final String? clipboardText = clipboardData?.text;

    if (clipboardText == null || clipboardText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('剪贴板内容为空')),
      );
      return;
    }

    final lines = clipboardText.split('\n');
    String? title;
    String? url;
    String? description;

    for (final line in lines) {
      if (line.contains('链接：')) {
        url = line.replaceAll('链接：', '').trim();
      } else if (line.contains('提取码：')) {
        description =
            '${description ?? ''}${description != null && description.isNotEmpty ? '; ' : ''}提取码：${line.replaceAll('提取码：', '').trim()}';
      } else if (title == null &&
          line.isNotEmpty &&
          !line.contains('http') &&
          !line.contains('https')) {
        title = line.trim();
      }
    }

    if (title != null && url != null) {
      final newLinks = List<GameDownloadLink>.from(downloadLinks);
      newLinks.add(GameDownloadLink(
        id: mongo.ObjectId().oid,
        title: title,
        url: url,
        description: description ?? '',
      ));
      onChanged(newLinks);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已从剪贴板添加: $title')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未能从剪贴板解析有效链接')),
        );
      }
    }
  }

  void _addDownloadLink(BuildContext context) {
    _showLinkDialog(
      context: context,
      dialogTitle: '添加下载链接',
      confirmButtonText: '添加',
      onConfirmAction: (title, url, description) {
        final newLinks = List<GameDownloadLink>.from(downloadLinks);
        newLinks.add(GameDownloadLink(
          id: mongo.ObjectId().oid,
          title: title,
          url: url,
          description: description,
        ));
        onChanged(newLinks);
      },
    );
  }

  void _editDownloadLink(BuildContext context, int index) {
    final link = downloadLinks[index];
    _showLinkDialog(
      context: context,
      dialogTitle: '编辑下载链接',
      initialTitle: link.title,
      initialUrl: link.url,
      initialDescription: link.description,
      confirmButtonText: '保存',
      onConfirmAction: (title, url, description) {
        final newLinks = List<GameDownloadLink>.from(downloadLinks);
        newLinks[index] = GameDownloadLink(
          id: link.id,
          title: title,
          url: url,
          description: description,
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
    String initialDescription = '',
    required String confirmButtonText,
    required void Function(String title, String url, String description)
        onConfirmAction,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final urlController = TextEditingController(text: initialUrl);
    final descriptionController =
        TextEditingController(text: initialDescription);

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
                hintText: '例如：网盘',
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              inputStateService: inputStateService,
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '下载链接（最好只放网盘的链接）',
                hintText: 'https://',
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              inputStateService: inputStateService,
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述/提取码等',
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
          onConfirmAction(title, url, description);
          return;
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('链接标题和链接地址不能为空！'),
                behavior: SnackBarBehavior.floating,
              ),
            );
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
