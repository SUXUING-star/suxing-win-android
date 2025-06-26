// lib/widgets/components/screen/game/external/game_external_link_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/models/game/game.dart'; // GameExternalLink 应该在 game.dart 或其独立文件中
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

/// 一个卡片组件，用于显示单个外部链接。
///
/// 包含链接标题，并提供“打开链接”和“复制链接”的操作按钮。
class GameExternalLinkCard extends StatelessWidget {
  /// 要显示的外部链接数据。
  final GameExternalLink link;

  const GameExternalLinkCard({
    super.key,
    required this.link,
  });

  /// 复制链接到剪贴板。
  ///
  /// [context]：Build 上下文。
  /// [text]：要复制的文本。
  void _copyToClipboard(BuildContext context, String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      AppSnackBar.showSuccess('链接已复制');
    } else {
      AppSnackBar.showError('复制失败，链接为空');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 4.0, vertical: 6.0), // 稍微调整边距以适应布局
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 4.0), // 调整内边距
        leading:
            const Icon(Icons.link_rounded, color: Colors.purple), // 换一个更合适的图标
        title: Text(link.title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        // 外部链接通常没有描述，所以移除了 subtitle
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OpenUrlButton(
              url: link.url,
              webViewTitle: link.title,
              color: Colors.teal,
              tooltip: '打开链接',
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: '复制链接',
              color: Colors.grey[700],
              onPressed: () => _copyToClipboard(context, link.url),
            ),
          ],
        ),
      ),
    );
  }
}
