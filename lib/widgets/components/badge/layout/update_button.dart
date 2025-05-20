// lib/widgets/components/badge/layout/update_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/config/app_config.dart';

import '../../../../services/main/update/update_service.dart';
import '../../dialogs/update/force_update_dialog.dart';

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        if (updateService.isChecking) {
          return const SizedBox(
            width: 24, // 与图标大小一致，避免布局跳动
            height: 24,
            child: Center(
              // 让菊花居中
              child: SizedBox(
                width: 18, // 菊花可以比容器小一点
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors
                      .white, // 或者 Theme.of(context).colorScheme.onPrimary
                ),
              ),
            ),
          );
        }

        // ！！！更新可用时的 UI - 完整实现！！！
        if (updateService.updateAvailable) {
          return GestureDetector(
            onTap: () => _handleUpdateTap(context, updateService),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: updateService.forceUpdate
                    ? Theme.of(context).colorScheme.error // 强制更新用错误色 (红色)
                    : Theme.of(context).colorScheme.primary, // 普通更新用主题色 (蓝色)
                shape: BoxShape.circle,
                // 可以添加一点阴影让它更突出
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withSafeOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons
                    .system_update_alt, // 或者 Icons.arrow_downward, Icons.download
                size: 16, // 更新可用时图标小一点，因为有背景色
                color: Colors
                    .white, // 或者 Theme.of(context).colorScheme.onPrimary / onError
              ),
            ),
          );
        }
        // ！！！无更新时的 UI - 完整实现！！！
        else {
          return GestureDetector(
            onTap: () =>
                _handleUpdateTap(context, updateService), // 点击时依然会触发检查更新
            child: Icon(
              Icons.system_update_outlined, // 使用 outlined 版本表示当前无更新
              size: 24, // 无更新时图标大一点
              color:
                  Theme.of(context).iconTheme.color ?? Colors.white, // 使用主题图标颜色
            ),
          );
        }
      },
    );
  }

  String _formatChangelogMessage(List<String>? changelog) {
    if (changelog == null || changelog.isEmpty) return '';
    return '\n\n更新内容:\n${changelog.map((change) => '• $change').join('\n')}';
  }

  Future<void> _handleUpdateTap(
      BuildContext context, UpdateService updateService) async {
    if (!updateService.updateAvailable) {
      // 即使当前显示无更新，点击也应该触发一次检查
      await updateService.checkForUpdates(); // 确保调用不带 context 的版本
      if (context.mounted) {
        // 检查 context 是否仍然有效
        if (!updateService.updateAvailable) {
          AppSnackBar.showInfo(context, '当前已是最新版本');
        } else {
          // 如果检查后发现有更新，则再次调用 _handleUpdateTap 以显示对话框
          // 为避免无限递归（虽然不太可能），可以加个标志位或直接在这里处理对话框逻辑
          // 但更简单的是，用户会看到图标变化，再次点击即可
          // 或者，如果希望检查后立即弹窗，可以在这里复制弹窗逻辑，但这会有点重复
          // 当前设计是，用户看到图标变化（或没变化），再次点击会进入下面的逻辑
        }
      }
      return; // 首次点击且无更新时，检查完就返回，等待用户再次交互或UI自动更新
    }

    // 如果已经有可用更新 (updateService.updateAvailable is true)
    final String releasePageUrl = AppConfig.releasePage;

    if (releasePageUrl.isEmpty) {
      if (kDebugMode) print('UpdateButton: AppConfig.releasePage is empty!');
      if (context.mounted) AppSnackBar.showError(context, '未配置有效的发布页面链接。');
      return;
    }

    final Uri uri = Uri.parse(releasePageUrl);

    if (updateService.forceUpdate) {
      if (context.mounted) {
        ForceUpdateDialog.show(
          context: context,
          currentVersion: updateService.currentVersion ?? 'N/A',
          latestVersion: updateService.latestVersion ?? 'N/A',
          updateMessage: updateService.updateMessage,
          changelog: updateService.changelog,
          updateUrl: releasePageUrl, // 传递 releasePageUrl
          // filename: updateService.platformSpecificFilename, // 如果 ForceUpdateDialog 还需要显示文件名
        );
      }
    } else {
      if (context.mounted) {
        final messageContent =
            '发现新版本 ${updateService.latestVersion ?? "未知"}。${_formatChangelogMessage(updateService.changelog)}';

        CustomConfirmDialog.show(
          context: context,
          title: '发现新版本',
          message: messageContent,
          confirmButtonText: '前往查看',
          cancelButtonText: '稍后',
          confirmButtonColor: Theme.of(context).colorScheme.primary,
          iconData: Icons.system_update_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          onConfirm: () async {
            // BaseInputDialog 会在 onConfirm 后自动 pop
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  AppSnackBar.showError(context, '无法打开发布页面链接');
                }
              }
            } catch (e) {
              if (context.mounted) {
                AppSnackBar.showError(context,
                    '打开链接时出错: ${e.toString().substring(0, (e.toString().length < 100 ? e.toString().length : 100))}');
              }
            }
          },
        );
      }
    }
  }
}
