// widgets/form/gameform/game_download_links_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart';
import 'package:suxingchahui/models/game/game.dart';

class GameDownloadLinksField extends StatelessWidget {
  final List<GameDownloadLink> downloadLinks;
  final ValueChanged<List<GameDownloadLink>> onChanged;

  const GameDownloadLinksField({
    super.key,
    required this.downloadLinks,
    required this.onChanged,
  });

  Future<void> _quickAddFromClipboard(BuildContext context) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text == null) return;

    final text = clipboardData!.text!;
    final lines = text.split('\n');

    String? title;
    String? url;
    String? description;

    for (final line in lines) {
      if (line.contains('链接：')) {
        url = line.replaceAll('链接：', '').trim();
      } else if (line.contains('提取码：')) {
        description = '提取码：${line.replaceAll('提取码：', '').trim()}';
      } else if (title == null && line.isNotEmpty) {
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
    }
  }

  void _addDownloadLink(BuildContext context) {
    _showLinkDialog(
      context: context,
      title: '添加下载链接',
      confirmButtonText: '添加',
      onConfirm: (title, url, description) {
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
      title: '编辑下载链接',
      initialTitle: link.title,
      initialUrl: link.url,
      initialDescription: link.description,
      confirmButtonText: '保存',
      onConfirm: (title, url, description) {
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
    required String title,
    String initialTitle = '',
    String initialUrl = '',
    String initialDescription = '',
    required String confirmButtonText,
    required Function(String title, String url, String description) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController(text: initialTitle);
        final urlController = TextEditingController(text: initialUrl);
        final descriptionController =
            TextEditingController(text: initialDescription);

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '链接标题',
                  hintText: '例如：网盘',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: '下载链接',
                  hintText: 'https://',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '描述',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消 - Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  onConfirm(
                    titleController.text,
                    urlController.text,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(confirmButtonText),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('下载链接'),
            Row(
              children: [
                AppButton(
                  onPressed: () => _quickAddFromClipboard(context),
                  icon: Icon(Icons.paste),
                  text: '快速添加',
                  isMini: true,
                  isPrimaryAction: true,
                ),
                AppButton(
                  onPressed: () => _addDownloadLink(context),
                  icon: Icon(Icons.add),
                  text: '添加链接',
                  isMini: true,
                  isPrimaryAction: true,
                ),
              ],
            ),
          ],
        ),
        if (downloadLinks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: downloadLinks.length,
            itemBuilder: (context, index) {
              final link = downloadLinks[index];
              return Card(
                child: ListTile(
                  title: Text(link.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.url),
                      if (link.description.isNotEmpty)
                        Text(
                          link.description,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editDownloadLink(context, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
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
