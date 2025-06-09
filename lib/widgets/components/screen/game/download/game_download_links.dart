// lib/widgets/components/screen/game/download/game_download_links.dart

/// 该文件定义了 GameDownloadLinks 组件，一个用于显示游戏下载链接的 StatelessWidget。
/// GameDownloadLinks 根据用户登录状态展示下载链接列表或登录提示。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter/services.dart'; // 导入 Clipboard
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart'; // 导入打开 URL 按钮
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 导入空状态组件
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入应用 SnackBar 工具
import 'package:suxingchahui/models/game/game.dart'; // 导入游戏模型

/// `GameDownloadLinks` 类：显示游戏下载链接的组件。
///
/// 该组件根据当前用户是否登录来显示下载链接列表或登录提示。
class GameDownloadLinks extends StatelessWidget {
  final List<GameDownloadLink> downloadLinks; // 游戏下载链接列表
  final User? currentUser; // 当前登录用户

  /// 构造函数。
  ///
  /// [currentUser]：当前用户。
  /// [downloadLinks]：下载链接。
  const GameDownloadLinks({
    super.key,
    required this.currentUser,
    required this.downloadLinks,
  });

  /// 构建游戏下载链接组件。
  ///
  /// 根据当前用户是否登录，显示下载链接列表或登录提示。
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      // 用户未登录时
      return _buildLoginRequiredMessage(context); // 显示登录提示
    }

    if (downloadLinks.isEmpty) {
      // 下载链接为空时
      return const EmptyStateWidget(
        message: '暂无下载链接', // 消息
        iconData: Icons.link_off, // 图标
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 8.0), // 内边距
          child: Text(
            '下载资源', // 标题
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold), // 样式
          ),
        ),
        ...downloadLinks.map((link) => Card(
              // 遍历下载链接列表
              margin: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 6.0), // 外边距
              elevation: 2, // 阴影
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)), // 圆角
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
                      onPressed: () =>
                          _copyToClipboard(context, link.url), // 点击回调
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  /// 构建需要登录才能查看消息的组件。
  ///
  /// [context]：Build 上下文。
  /// 返回一个提示用户登录并提供登录按钮的卡片。
  Widget _buildLoginRequiredMessage(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0), // 外边距
      elevation: 2, // 阴影
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // 形状
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 内边距
        child: Column(
          children: [
            const Icon(
              Icons.lock_person_outlined, // 图标
              size: 50, // 大小
              color: Colors.deepPurpleAccent, // 颜色
            ),
            const SizedBox(height: 16), // 间距
            Text(
              '查看下载链接需登录', // 文本
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // 居中对齐
            ),
            const SizedBox(height: 8), // 间距
            Text(
              '登录后即可查看和管理游戏资源', // 文本
              textAlign: TextAlign.center, // 居中对齐
              style: Theme.of(context).textTheme.bodyMedium, // 样式
            ),
            const SizedBox(height: 24), // 间距
            FunctionalButton(
              label: '前往登录', // 按钮文本
              icon: Icons.login, // 图标
              onPressed: () =>
                  NavigationUtils.navigateToLogin(context), // 点击导航到登录页
            ),
          ],
        ),
      ),
    );
  }

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
}
