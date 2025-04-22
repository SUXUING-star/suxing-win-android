// lib/widgets/ui/buttons/open_url_button.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../routes/app_routes.dart'; // 调整为你项目的实际路径
import '../../../../utils/navigation/navigation_utils.dart'; // 调整为你项目的实际路径
import '../snackbar/app_snackbar.dart'; // 调整为你项目的实际路径

class OpenUrlButton extends StatelessWidget {
  /// 要打开的 URL
  final String? url;

  /// 在应用内 WebView 打开时显示的标题 (可选)
  final String? webViewTitle;

  /// 按钮上显示的图标 (默认为 Icons.open_with)
  final IconData icon;

  /// 图标颜色 (可选)
  final Color? color;

  /// IconButton 的 tooltip 提示文字 (默认为 '打开方式...')
  final String tooltip;

  /// 点击按钮时的回调 (可选，在显示选项前触发)
  final VoidCallback? onPressed;

  const OpenUrlButton({
    super.key,
    required this.url,
    this.webViewTitle,
    this.icon = Icons.open_with, // 提供默认图标
    this.color,                // 允许自定义颜色
    this.tooltip = '打开方式...', // 提供默认提示
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 如果 URL 无效，则禁用按钮
    final bool isValidUrl = url != null && url!.isNotEmpty && Uri.tryParse(url!) != null;

    return IconButton(
      icon: Icon(icon),
      color: color ?? Theme.of(context).iconTheme.color, // 使用主题默认颜色或自定义颜色
      tooltip: tooltip,
      // 只有 URL 有效时才启用 onPressed
      onPressed: isValidUrl
          ? () {
        // 如果有提供 onPressed 回调，先执行它
        onPressed?.call();
        // 然后显示打开选项
        _showOpenOptions(context, url!, webViewTitle);
      }
          : null, // URL 无效时禁用按钮
    );
  }

  /// 显示打开方式选项 (私有辅助方法)
  void _showOpenOptions(BuildContext context, String validUrl, String? title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.teal),
                title: const Text('在应用内浏览器打开'),
                onTap: () {
                  Navigator.pop(context);
                  _openInAppBrowser(context, validUrl, title);
                },
              ),
              ListTile(
                leading: const Icon(Icons.launch, color: Colors.orange),
                title: const Text('在外部浏览器打开'),
                onTap: () {
                  Navigator.pop(context);
                  _launchExternalURL(context, validUrl);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 在应用内浏览器打开链接 (私有辅助方法)
  static void _openInAppBrowser(BuildContext context, String url, String? title) {
    // 确保 URL 是有效的（虽然调用前已检查，双重保险）
    if (Uri.tryParse(url) == null) {
      AppSnackBar.showError(context, '应用内打开失败：链接格式无效');
      return;
    }
    NavigationUtils.pushNamed(
      context,
      AppRoutes.webView, // 使用你的 WebView 路由名
      arguments: {"url": url, "title": title ?? '浏览页面'}, // 传递参数
    );
  }

  /// 在外部浏览器打开链接 (私有辅助方法)
  static Future<void> _launchExternalURL(BuildContext context, String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackBar.showError(context, '外部打开失败：链接格式无效');
      return;
    }

    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        AppSnackBar.showError(context, '无法打开外部链接: $e');
      }
    } else {
      AppSnackBar.showError(context, '不支持的链接类型或无法启动外部应用');
    }
  }
}