// lib/widgets/components/badge/layout/update_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/main/update/update_service.dart';
import '../../dialogs/update/force_update_dialog.dart'; // 保留，用于强制更新

class UpdateButton extends StatelessWidget {
  const UpdateButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ... (build method remains the same) ...
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        // ... (unchanged part) ...
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

  // --- Helper function to format changelog for the message ---
  String _formatChangelogMessage(List<String>? changelog) {
    if (changelog == null || changelog.isEmpty) {
      return ''; // 没有更新日志时返回空字符串
    }
    // 添加标题和项目符号
    return '\n\n更新内容:\n${changelog.map((change) => '• $change').join('\n')}';
  }

  Future<void> _handleUpdateTap(BuildContext context, UpdateService updateService) async {
    if (!updateService.updateAvailable) {
      // 手动检查更新 (保持不变)
      await updateService.checkForUpdates();
      if (!updateService.updateAvailable && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('当前已是最新版本')),
        );
      }
      return;
    }

    if (updateService.forceUpdate) {
      // 强制更新：仍然使用 ForceUpdateDialog (保持不变)
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ForceUpdateDialog(
            currentVersion: updateService.currentVersion ?? '', // 确保传递 currentVersion
            latestVersion: updateService.latestVersion ?? '',
            updateMessage: updateService.updateMessage,
            changelog: updateService.changelog,
            updateUrl: updateService.updateUrl ?? '',
          ),
        );
      }
    } else {
      // --- 非强制更新：使用 CustomConfirmDialog ---
      if (context.mounted) {
        // 准备对话框消息，包含版本号和格式化的更新日志
        final messageContent =
            '发现新版本 ${updateService.latestVersion}。${_formatChangelogMessage(updateService.changelog)}';

        CustomConfirmDialog.show(
          context: context,
          title: '发现新版本', // 对话框标题
          message: messageContent, // 对话框消息 (包含更新日志)
          confirmButtonText: '更新', // 确认按钮文字
          cancelButtonText: '稍后', // 取消按钮文字
          confirmButtonColor: Colors.blue, // 确认按钮颜色 (蓝色适用于普通更新)
          iconData: Icons.system_update_outlined, // 使用更新相关的图标
          iconColor: Colors.blue,          // 图标颜色

          // --- 确认回调：执行更新操作 ---
          onConfirm: () async {
            // CustomConfirmDialog 会显示加载状态，但打开链接通常很快，
            // 加载状态可能一闪而过。主要目标是执行动作。
            if (!context.mounted) return; // 检查 context 是否仍然有效

            // 1. 手动关闭对话框 (因为 onConfirm 结束后 CustomConfirmDialog 不会自动关闭)
            Navigator.pop(context);

            // 2. 尝试启动更新链接
            if (updateService.updateUrl != null) {
              final uri = Uri.parse(updateService.updateUrl!);
              try {
                // 尝试使用外部应用打开链接
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  print('无法启动 URL: ${updateService.updateUrl}');
                  if (context.mounted) { // 再次检查
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('无法打开更新链接')),
                    );
                  }
                }
              } catch (e) {
                print('启动 URL 时出错: $e');
                if (context.mounted) { // 再次检查
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('打开更新链接时出错')),
                  );
                }
              }
            } else {
              print('更新 URL 为空');
              if (context.mounted) { // 再次检查
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('未找到有效的更新链接')),
                );
              }
            }
          },

          // onCancel 回调通常不需要，因为默认就是关闭对话框
          // onCancel: () {
          //   print('用户选择稍后更新');
          // },

          // 其他参数可以根据需要调整，例如动画效果
          // transitionCurve: Curves.fastOutSlowIn,
        );
      }
    }
  }
}