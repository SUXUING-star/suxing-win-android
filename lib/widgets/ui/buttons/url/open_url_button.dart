// lib/widgets/ui/buttons/url/open_url_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/network/open_web_url_utils.dart';

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
    this.color, // 允许自定义颜色
    this.tooltip = '打开方式...', // 提供默认提示
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 如果 URL 无效，则禁用按钮
    final bool isValidUrl =
        url != null && url!.isNotEmpty && Uri.tryParse(url!) != null;

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
              OpenWebUrlUtils.showOpenOptions(context, url!, webViewTitle);
            }
          : null, // URL 无效时禁用按钮
    );
  }
}
