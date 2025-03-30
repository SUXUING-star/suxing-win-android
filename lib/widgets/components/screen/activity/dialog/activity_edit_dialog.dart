// 创建新文件 lib/widgets/components/screen/activity/dialog/activity_edit_dialog.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

class ActivityEditDialog extends StatefulWidget {
  final String initialContent;
  final Map<String, dynamic>? metadata;

  const ActivityEditDialog({
    Key? key,
    required this.initialContent,
    this.metadata,
  }) : super(key: key);

  @override
  _ActivityEditDialogState createState() => _ActivityEditDialogState();
}

class _ActivityEditDialogState extends State<ActivityEditDialog> {
  late TextEditingController _contentController;
  late Map<String, dynamic> _metadata;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _metadata = widget.metadata != null ? Map<String, dynamic>.from(widget.metadata!) : {};
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '编辑动态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '内容',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => NavigationUtils.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    NavigationUtils.of(context).pop({
                      'content': _contentController.text,
                      'metadata': _metadata,
                    });
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}