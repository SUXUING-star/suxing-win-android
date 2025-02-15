// lib/widgets/update/update_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update/update_service.dart';
import '../dialogs/force_update_dialog.dart';

class UpdateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        if (updateService.isChecking) {
          return _buildLoadingIndicator();
        }

        return GestureDetector(
          onTap: () => _handleUpdateTap(context, updateService),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: updateService.updateAvailable
                  ? (updateService.forceUpdate
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.system_update_outlined,
              size: 24,
              color: updateService.updateAvailable
                  ? (updateService.forceUpdate ? Colors.red : Colors.blue)
                  : Colors.grey[400],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  Future<void> _handleUpdateTap(BuildContext context, UpdateService updateService) async {
    if (!updateService.updateAvailable) {
      // 手动检查更新
      await updateService.checkForUpdates();
      if (!updateService.updateAvailable && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('当前已是最新版本')),
        );
      }
      return;
    }

    if (updateService.forceUpdate) {
      // 显示强制更新对话框
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // 禁止点击外部关闭
          builder: (context) => ForceUpdateDialog(
            currentVersion: updateService.latestVersion ?? '',
            latestVersion: updateService.latestVersion ?? '',
            updateMessage: updateService.updateMessage,
            changelog: updateService.changelog,
            updateUrl: updateService.updateUrl ?? '',
          ),
        );
      }
    } else {
      // 显示普通更新对话框
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('发现新版本'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('是否更新到新版本 ${updateService.latestVersion}？'),
                if (updateService.changelog != null &&
                    updateService.changelog!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('更新内容：'),
                  ...updateService.changelog!.map((change) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• '),
                        Expanded(child: Text(change)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('稍后'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (updateService.updateUrl != null) {
                    await launchUrl(Uri.parse(updateService.updateUrl!));
                  }
                },
                child: Text('更新'),
              ),
            ],
          ),
        );
      }
    }
  }
}