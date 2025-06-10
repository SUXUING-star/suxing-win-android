// lib/widgets/ui/components/badge/update_button.dart

/// 该文件定义了 UpdateButton 组件，一个显示应用更新状态的按钮。
/// UpdateButton 根据更新服务状态显示不同 UI，并支持点击触发更新检查或跳转到更新页面。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:provider/provider.dart'; // Provider 状态管理
import 'package:suxingchahui/services/main/update/update_service.dart'; // 更新服务
import 'package:suxingchahui/widgets/components/dialogs/update/force_update_dialog.dart'; // 强制更新对话框
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 确认对话框
import 'package:url_launcher/url_launcher.dart'; // URL 启动器
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart'; // 应用 Snackbar
import 'package:suxingchahui/config/app_config.dart'; // 应用配置

/// `UpdateButton` 类：应用更新按钮。
///
/// 该组件通过 `Consumer` 监听 `UpdateService` 的状态，
/// 根据是否正在检查更新、是否有可用更新或是否强制更新来显示不同的 UI 样式。
/// 点击时，触发更新检查或引导用户前往更新。
class UpdateButton extends StatelessWidget {
  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  const UpdateButton({super.key});

  /// 构建更新按钮 UI。
  ///
  /// [context]：Build 上下文。
  /// [updateService]：UpdateService 实例。
  /// 根据 `updateService` 的状态显示不同的 UI。
  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      // 监听 UpdateService 状态
      builder: (context, updateService, _) {
        // 构建器函数
        if (updateService.isChecking) {
          // 正在检查更新时
          return const SizedBox(
            // 显示加载指示器
            width: 24,
            height: 24,
            child: LoadingWidget(),
          );
        }

        if (updateService.updateAvailable) {
          // 有可用更新时
          return GestureDetector(
            // 可点击手势检测器
            onTap: () => _handleUpdateTap(context, updateService), // 点击处理更新
            child: Container(
              // 徽章容器
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                // 装饰
                color: updateService.forceUpdate // 根据是否强制更新设置颜色
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle, // 圆形
                boxShadow: [
                  // 阴影
                  BoxShadow(
                    color: Colors.black.withSafeOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                // 图标
                Icons.system_update_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          );
        }
        return GestureDetector(
          // 无更新时
          onTap: () => _handleUpdateTap(context, updateService), // 点击时依然会触发检查更新
          child: Icon(
            // 图标
            Icons.system_update_outlined,
            size: 24,
            color: Theme.of(context).iconTheme.color ?? Colors.white,
          ),
        );
      },
    );
  }

  /// 格式化更新日志消息。
  ///
  /// [changelog]：更新日志列表。
  /// 返回格式化后的更新日志字符串。
  String _formatChangelogMessage(List<String>? changelog) {
    if (changelog == null || changelog.isEmpty) return ''; // 日志为空时返回空字符串
    return '\n\n更新内容:\n${changelog.map((change) => '• $change').join('\n')}'; // 格式化日志
  }

  /// 处理更新按钮点击事件。
  ///
  /// [context]：Build 上下文。
  /// [updateService]：UpdateService 实例。
  /// 如果无更新，则触发更新检查并显示提示。
  /// 如果有可用更新，则根据是否强制更新显示不同对话框，并引导用户前往下载页面。
  Future<void> _handleUpdateTap(
      BuildContext context, UpdateService updateService) async {
    if (!updateService.updateAvailable) {
      // 无可用更新时
      await updateService.checkForUpdates(); // 触发更新检查
      // 检查上下文是否挂载
      if (!updateService.updateAvailable) {
        AppSnackBar.showInfo('当前已是最新版本'); // 显示信息提示
      }
      return; // 首次点击且无更新时，检查完就返回
    }

    final String releasePageUrl = AppConfig.releasePage; // 获取发布页面 URL

    if (releasePageUrl.isEmpty) {
      // 发布页面 URL 为空时

      AppSnackBar.showError('未配置有效的发布页面链接。'); // 显示错误提示

      return;
    }

    final Uri uri = Uri.parse(releasePageUrl); // 解析 URL

    if (updateService.forceUpdate) {
      // 强制更新时
      if (context.mounted) {
        ForceUpdateDialog.show(
          // 显示强制更新对话框
          context: context,
          currentVersion: UpdateService.currentVersion,
          latestVersion: updateService.latestVersion ?? 'N/A',
          updateMessage: updateService.updateMessage,
          changelog: updateService.changelog,
          updateUrl: releasePageUrl,
        );
      }
    } else {
      // 非强制更新时
      if (context.mounted) {
        final messageContent =
            '发现新版本 ${updateService.latestVersion ?? "未知"}。${_formatChangelogMessage(updateService.changelog)}'; // 构建消息内容

        CustomConfirmDialog.show(
          // 显示确认对话框
          context: context,
          title: '发现新版本',
          message: messageContent,
          confirmButtonText: '前往查看',
          cancelButtonText: '稍后',
          confirmButtonColor: Theme.of(context).colorScheme.primary,
          iconData: Icons.system_update_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          onConfirm: () async {
            // 确认回调
            try {
              if (await canLaunchUrl(uri)) {
                // 检查是否可以启动 URL
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication); // 启动外部应用
              } else {
                AppSnackBar.showError('无法打开发布页面链接'); // 显示错误提示
              }
            } catch (e) {
              AppSnackBar.showError("操作失败,${e.toString()}");
            }
          },
        );
      }
    }
  }
}
