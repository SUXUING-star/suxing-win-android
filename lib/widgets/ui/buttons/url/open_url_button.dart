// lib/widgets/ui/buttons/url/open_url_button.dart

/// 该文件定义了 OpenUrlButton 组件，一个用于打开网页链接的按钮。
/// 该组件提供一个可点击的图标按钮，用于显示打开链接的选项。
library;


import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/utils/network/open_web_url_utils.dart'; // 导入打开网页链接工具类

/// `OpenUrlButton` 类：用于打开网页链接的按钮组件。
///
/// 该组件提供一个图标按钮，点击后显示在应用内或外部浏览器打开链接的选项。
class OpenUrlButton extends StatelessWidget {
  final String? url; // 要打开的 URL
  final String? webViewTitle; // 在应用内 WebView 打开时显示的标题
  final IconData icon; // 按钮上显示的图标
  final Color? color; // 图标颜色
  final String tooltip; // IconButton 的提示文字
  final VoidCallback? onPressed; // 点击按钮时的回调

  /// 构造函数。
  ///
  /// [url]：要打开的 URL。
  /// [webViewTitle]：WebView 标题。
  /// [icon]：图标。
  /// [color]：图标颜色。
  /// [tooltip]：提示文字。
  /// [onPressed]：点击回调。
  const OpenUrlButton({
    super.key,
    required this.url,
    this.webViewTitle,
    this.icon = Icons.open_with,
    this.color,
    this.tooltip = '打开方式...',
    this.onPressed,
  });

  /// 构建打开 URL 的按钮。
  ///
  /// 如果 URL 无效，按钮将处于禁用状态。
  @override
  Widget build(BuildContext context) {
    final bool isValidUrl = url != null &&
        url!.isNotEmpty &&
        Uri.tryParse(url!) != null; // 判断 URL 是否有效

    return IconButton(
      icon: Icon(icon), // 按钮图标
      color: color ?? Theme.of(context).iconTheme.color, // 按钮颜色
      tooltip: tooltip, // 按钮提示
      onPressed: isValidUrl // 根据 URL 是否有效决定按钮是否可点击
          ? () {
              onPressed?.call(); // 执行传入的回调
              OpenWebUrlUtils.showOpenOptions(
                  context, url!, webViewTitle); // 显示打开方式选项
            }
          : null, // URL 无效时按钮禁用
    );
  }
}
