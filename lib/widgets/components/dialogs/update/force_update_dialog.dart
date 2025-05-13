// lib/widgets/components/dialogs/force_update_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class ForceUpdateDialog {
  static Future<void> show({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String updateUrl,
    String? filename, // 这个参数现在实际上用不到了，因为我们不直接下载文件
    String? updateMessage,
    List<String>? changelog,
  }) {
    const String fixedTitle = '发现新版本 (必须更新)';
    const IconData fixedIconData = Icons.security_update_good_outlined;
    const String fixedConfirmButtonText = '前往更新页面'; // 按钮文字更清晰
    const double fixedMaxWidth = 350;
    final theme = Theme.of(context);
    final Color fixedButtonColor = theme.colorScheme.error;
    final Color fixedIconColor = theme.colorScheme.error;

    // ！！！确保调用 BaseInputDialog.show 时不带不必要的泛型（如果它没有定义）！！！
    return BaseInputDialog.show(
      context: context,
      title: fixedTitle,
      iconData: fixedIconData,
      iconColor: fixedIconColor,
      maxWidth: fixedMaxWidth,
      contentBuilder: (dialogContext) {
        // --- ContentBuilder UI 保持不变，显示版本和更新信息 ---
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本：$currentVersion'),
            Text('最新版本：$latestVersion'),
            const SizedBox(height: 16),
            if (updateMessage != null && updateMessage.isNotEmpty) ...[
              Text(
                updateMessage,
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (changelog != null && changelog.isNotEmpty) ...[
              const Text('更新内容：',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: changelog
                    .map((change) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(change)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              '检测到重要安全或功能更新，请立即更新以继续使用。',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
      confirmButtonText: fixedConfirmButtonText,
      confirmButtonColor: fixedButtonColor,
      // ！！！核心修改：onConfirm 的行为就是打开传入的 updateUrl (即 AppConfig.releasePage)！！！
      onConfirm: () async {
        // onConfirm 是 Future<void> Function()
        if (updateUrl.isEmpty) {
          if (kDebugMode)
            print(
                'ForceUpdateDialog: Release Page URL (from updateUrl prop) is empty.');
          if (context.mounted) {
            // 使用 AppSnackBar 显示错误
            AppSnackBar.showError(context, '未配置有效的更新页面链接。');
          }
          // 对于强制更新，对话框不应因 URL无效而关闭，所以不返回或返回的方式应不让 BaseInputDialog 关闭
          return; // 提前返回，不执行后续 launchUrl
        }

        final Uri uri =
            Uri.parse(updateUrl); // updateUrl 就是 AppConfig.releasePage
        try {
          if (kDebugMode) {
            print("ForceUpdateDialog: Launching release page URL: $uri");
          }
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (kDebugMode) print('ForceUpdateDialog: Cannot launch URL: $uri');
            if (context.mounted) {
              AppSnackBar.showError(context, '无法打开更新页面，请尝试手动访问。');
            }
          }
        } catch (e) {
          if (kDebugMode)
            print("ForceUpdateDialog: Error launching URL $uri: $e");
          if (context.mounted) {
            AppSnackBar.showError(context,
                '打开链接时发生错误: ${e.toString().substring(0, (e.toString().length < 100 ? e.toString().length : 100))}');
          }
        }
      },
      showCancelButton: false, // 强制更新不显示取消按钮
      barrierDismissible: false, // 强制更新不可点击外部关闭
      allowDismissWhenNotProcessing: false, // 强制更新不可使用返回键关闭
      isDraggable: false, // 通常强制更新对话框不应能拖拽
      isScalable: false, // 通常强制更新对话框不应能缩放
    );
  }
}
