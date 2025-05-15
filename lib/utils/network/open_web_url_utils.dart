import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/navigation/navigation_utils.dart';

class OpenWebUrlUtils {
  /// 显示打开方式选项
  static void showOpenOptions(
      BuildContext context, String validUrl, String? title) {
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
                tileColor: Colors.white,
                leading: const Icon(Icons.open_in_new, color: Colors.teal),
                title: const Text('在应用内浏览器打开'),
                onTap: () {
                  Navigator.pop(context);
                  openInAppBrowser(context, validUrl, title);
                },
              ),
              ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.launch, color: Colors.orange),
                title: const Text('在外部浏览器打开'),
                onTap: () {
                  Navigator.pop(context);
                  launchExternalURL(context, validUrl);
                },
              ),
              const Divider(height: 1),
              ListTile(
                tileColor: Colors.white,
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
  static void openInAppBrowser(
      BuildContext context, String url, String? title) {
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
  static Future<void> launchExternalURL(
      BuildContext context, String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackBar.showError(context, '外部打开失败：链接格式无效');
      return;
    }

    final can = await canLaunchUrl(uri);
    if (can) {
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        //
      }
    } else {
      //
    }
  }
}
