// lib/utils/network/open_web_url_utils.dart

/// 该文件定义了 OpenWebUrlUtils 工具类，提供打开网页链接的功能。
/// 该类支持在应用内或外部浏览器打开网页链接。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart'; // 应用 SnackBar 工具
import 'package:url_launcher/url_launcher.dart'; // URL 启动器库

/// `OpenWebUrlUtils` 类：提供打开网页链接的实用方法。
///
/// 该类包含显示打开方式选项，并在应用内或外部浏览器打开指定链接的功能。
class OpenWebUrlUtils {
  /// 显示打开网页链接的选项弹窗。
  ///
  /// [context]：Build 上下文。
  /// [validUrl]：要打开的有效网页 URL。
  /// [title]：网页的标题。
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
                  Navigator.pop(context); // 关闭弹窗
                  openInAppBrowser(context, validUrl, title); // 在应用内浏览器打开
                },
              ),
              ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.launch, color: Colors.orange),
                title: const Text('在外部浏览器打开'),
                onTap: () {
                  Navigator.pop(context); // 关闭弹窗
                  launchExternalURL(context, validUrl); // 在外部浏览器打开
                },
              ),
              const Divider(height: 1), // 分隔线
              ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context), // 关闭弹窗
              ),
            ],
          ),
        );
      },
    );
  }

  /// 在应用内浏览器中打开指定链接。
  ///
  /// [context]：Build 上下文。
  /// [url]：要打开的 URL。
  /// [title]：网页的标题。
  static void openInAppBrowser(
      BuildContext context, String url, String? title) {
    if (Uri.tryParse(url) == null) {
      // URL 格式无效时显示错误
      AppSnackBar.showError('应用内打开失败：链接格式无效');
      return;
    }
    NavigationUtils.pushNamed(
      context,
      AppRoutes.webView, // 导航到 WebView 路由
      arguments: {"url": url, "title": title ?? '浏览页面'}, // 传递 URL 和标题
    );
  }

  /// 在外部浏览器中打开指定链接。
  ///
  /// [context]：Build 上下文。
  /// [url]：要打开的 URL。
  static Future<void> launchExternalURL(
      BuildContext context, String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      // URL 格式无效时显示错误
      AppSnackBar.showError('外部打开失败：链接格式无效');
      return;
    }

    final can = await canLaunchUrl(uri); // 检查是否可以启动 URL
    if (can) {
      // 可以启动时尝试启动
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 以外部应用模式启动
        );
      } catch (e) {
        // 启动 URL 发生异常时无操作
      }
    } else {
      // 无法启动 URL 时无操作
    }
  }
}
