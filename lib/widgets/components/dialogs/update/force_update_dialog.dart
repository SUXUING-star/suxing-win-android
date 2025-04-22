// lib/widgets/dialogs/force_update_dialog.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String? updateMessage;
  final List<String>? changelog;
  final String updateUrl;

  const ForceUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    this.updateMessage,
    this.changelog,
    required this.updateUrl,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁止返回键关闭对话框
      child: AlertDialog(
        title: Text('发现新版本'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前版本：$currentVersion'),
              Text('最新版本：$latestVersion'),
              SizedBox(height: 16),
              if (updateMessage != null) ...[
                Text(
                  updateMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (changelog != null && changelog!.isNotEmpty) ...[
                Text(
                  '更新内容：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...changelog!.map((change) => Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• '),
                      Expanded(child: Text(change)),
                    ],
                  ),
                )),
              ],
              SizedBox(height: 16),
              Text(
                '此为强制更新，请立即更新到最新版本',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(updateUrl))) {
                await launchUrl(Uri.parse(updateUrl));
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('无法打开更新链接')),
                  );
                }
              }
            },
            child: Text('立即更新'),
          ),
        ],
      ),
    );
  }
}