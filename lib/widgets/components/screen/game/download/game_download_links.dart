// lib/widgets/components/screen/game/download/game_download_links.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/models/game/game.dart';

class GameDownloadLinks extends StatelessWidget {
  final List<GameDownloadLink> downloadLinks;
  final User? currentUser;

  const GameDownloadLinks({
    super.key,
    required this.currentUser,
    required this.downloadLinks,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildLoginRequiredMessage(context);
    }

    if (downloadLinks.isEmpty) {
      return const EmptyStateWidget(
        message: '暂无下载链接',
        iconData: Icons.link_off,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 卡片左对齐
      children: [
        // 可以加一个标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '下载资源',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // 链接列表
        ...downloadLinks.map((link) => Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 6.0), // 调整卡片间距
              elevation: 2, // 给点阴影
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)), // 圆角
              child: ListTile(
                leading: const Icon(Icons.download_for_offline_outlined,
                    color: Colors.blue), // 加个图标
                title: Text(link.title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(link.description,
                    style: TextStyle(color: Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OpenUrlButton(
                      url: link.url,
                      webViewTitle: link.title, // 把链接标题传给 WebView
                      color: Colors.teal, // 可以保持颜色
                      tooltip: '打开链接', // 可以改个更明确的 tooltip
                    ),
                    // --- 复制链接按钮 ---
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: '复制链接',
                      color: Colors.grey[700],
                      onPressed: () => _copyToClipboard(context, link.url),
                    ),
                  ],
                ),
                // onTap: link.url == null ? null : () => _openInAppBrowser(context, link.url!, link.title), // 让整个 Tile 也能点击打开
              ),
            )),
      ],
    );
  }

  Widget _buildLoginRequiredMessage(BuildContext context) {
    // --- 可以用你的 LoginErrorWidget (如果它适合这种场景) ---
    // 或者保持现有的样式，确保使用了你定义的 Button
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 加大内边距
        child: Column(
          children: [
            const Icon(
              Icons.lock_person_outlined, // 换个更相关的图标
              size: 50,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 16),
            Text(
              '查看下载链接需登录', // 稍微修改文本
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '登录后即可查看和管理游戏资源',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // --- 使用你的 FunctionalTextButton ---
            FunctionalButton(
              label: '前往登录', // 按钮文字
              icon: Icons.login, // 可以给按钮加图标
              onPressed: () => NavigationUtils.navigateToLogin(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 复制链接到剪贴板
  void _copyToClipboard(BuildContext context, String? text) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      AppSnackBar.showSuccess(context, '链接已复制'); // 简洁提示
    } else {
      AppSnackBar.showError(context, '复制失败，链接为空');
    }
  }
}
