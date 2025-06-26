// lib/widgets/components/screen/game/download/game_download_link_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

class GameDownLoadLinkCard extends StatelessWidget {
  final GameDownloadLink link;
  const GameDownLoadLinkCard({
    super.key,
    required this.link,
  });

  /// 复制链接到剪贴板。
  ///
  /// [context]：Build 上下文。
  /// [text]：要复制的文本。
  void _copyToClipboard(BuildContext context, String? text) {
    if (text != null && text.isNotEmpty) {
      // 文本非空时
      Clipboard.setData(ClipboardData(text: text)); // 复制到剪贴板
      AppSnackBar.showSuccess('链接已复制'); // 显示成功提示
    } else {
      AppSnackBar.showError('复制失败，链接为空'); // 显示失败提示
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // 遍历下载链接列表
      margin:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // 外边距
      elevation: 2, // 阴影
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // 圆角
      child: ListTile(
        leading: const Icon(Icons.download_for_offline_outlined,
            color: Colors.blue), // 前导图标
        title: Text(link.title, // 标题
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(link.description, // 副标题
            style: TextStyle(color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
          children: [
            OpenUrlButton(
              url: link.url, // URL
              webViewTitle: link.title, // WebView 标题
              color: Colors.teal, // 颜色
              tooltip: '打开链接', // 提示
            ),
            IconButton(
              icon: const Icon(Icons.copy), // 复制图标
              tooltip: '复制链接', // 提示
              color: Colors.grey[700], // 颜色
              onPressed: () => _copyToClipboard(context, link.url), // 点击回调
            ),
          ],
        ),
      ),
    );
  }
}
