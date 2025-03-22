// lib/widgets/components/badge/layout/update_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/main/update/update_service.dart';
import '../../dialogs/update/force_update_dialog.dart';

class UpdateButton extends StatelessWidget {
  const UpdateButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        if (updateService.isChecking) {
          return SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        }

        return GestureDetector(
          onTap: () => _handleUpdateTap(context, updateService),
          child: updateService.updateAvailable
              ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: updateService.forceUpdate ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.system_update_outlined,
              size: 16,
              color: Colors.white,
            ),
          )
              : Icon(
            Icons.system_update_outlined,
            size: 24,
            color: Colors.white,
          ),
        );
      },
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